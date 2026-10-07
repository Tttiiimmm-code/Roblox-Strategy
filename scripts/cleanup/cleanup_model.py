"""KI-Figurenmodelle für Roblox aufbereiten; Aufruf über scripts/cleanup.ps1."""

import argparse
import math
from pathlib import Path
import sys
import time
import traceback

import bmesh
import bpy
from mathutils import Vector


def activate(obj):
	if bpy.context.object and bpy.context.object.mode != 'OBJECT':
		bpy.ops.object.mode_set(mode='OBJECT')
	bpy.ops.object.select_all(action='DESELECT')
	obj.hide_set(False)
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj


def triangle_count(mesh):
	mesh.calc_loop_triangles()
	return len(mesh.loop_triangles)


def uv_islands(mesh, layer):
	parents = list(range(len(mesh.polygons)))

	def root(index):
		while parents[index] != index:
			parents[index] = parents[parents[index]]
			index = parents[index]
		return index

	edges = {}
	for face in mesh.polygons:
		loops = list(face.loop_indices)
		for i, loop in enumerate(loops):
			other = loops[(i + 1) % len(loops)]
			ends = []
			for index in (loop, other):
				uv = layer.data[index].uv
				ends.append((mesh.loops[index].vertex_index, round(uv.x, 6), round(uv.y, 6)))
			key = tuple(sorted(ends))
			if key in edges:
				parents[root(face.index)] = root(edges[key])
			else:
				edges[key] = face.index
	groups = {}
	for face in mesh.polygons:
		groups.setdefault(root(face.index), []).append(face.index)
	return list(groups.values())


def bounds(obj):
	points = [vertex.co for vertex in obj.data.vertices]
	return (Vector(tuple(min(p[i] for p in points) for i in range(3))),
		Vector(tuple(max(p[i] for p in points) for i in range(3))))


def import_model(args, report):
	bpy.ops.object.select_all(action='SELECT')
	bpy.ops.object.delete(use_global=False)
	if args.input.suffix.lower() == '.fbx':
		bpy.ops.import_scene.fbx(filepath=str(args.input.resolve()), use_anim=False)
	else:
		bpy.ops.import_scene.gltf(filepath=str(args.input.resolve()))
	meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
	if not meshes:
		raise ValueError('Die Datei enthält kein Mesh.')
	bpy.ops.object.select_all(action='DESELECT')
	for obj in meshes:
		if not obj.data.uv_layers:
			raise ValueError(f'Mesh {obj.name} hat keine Original-UV-Koordinaten.')
		active_uv = obj.data.uv_layers.active
		for layer in list(obj.data.uv_layers):
			if layer != active_uv:
				obj.data.uv_layers.remove(layer)
		active_uv.name = 'UV_alt'
		world = obj.matrix_world.copy()
		obj.parent = None
		obj.matrix_world = world
		obj.animation_data_clear()
		obj.modifiers.clear()
		obj.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	if len(meshes) > 1:
		bpy.ops.object.join()
	obj = bpy.context.object
	obj.name = args.name
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	for other in list(bpy.context.scene.objects):
		if other != obj:
			bpy.data.objects.remove(other, do_unlink=True)
	if not obj.data.uv_layers:
		raise ValueError('Das Modell hat keine UV-Koordinaten für die Originaltextur.')
	obj.data.uv_layers.active.name = 'UV_alt'
	for layer in list(obj.data.uv_layers):
		if layer.name != 'UV_alt':
			obj.data.uv_layers.remove(layer)
	angle = {'+X': -math.pi / 2, '-X': math.pi / 2, '+Y': math.pi, '-Y': 0}[args.front]
	obj.rotation_euler.z = angle
	bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
	low, high = bounds(obj)
	shift = Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z))
	for vertex in obj.data.vertices:
		vertex.co += shift
	obj.data.update()
	report['triangles_before'] = triangle_count(obj.data)
	report['vertices_before'] = len(obj.data.vertices)
	report['islands_before'] = len(uv_islands(obj.data, obj.data.uv_layers.active))
	original = obj.copy()
	original.data = obj.data.copy()
	original.name = args.name + '_original'
	bpy.context.collection.objects.link(original)
	original.hide_render = True
	original.hide_set(True)
	return obj, original


def clean_geometry(obj, args, report):
	activate(obj)
	bm = bmesh.new()
	bm.from_mesh(obj.data)
	bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-5)
	remaining = set(bm.verts)
	removed = 0
	parts = 0
	while remaining:
		stack = [remaining.pop()]
		component = set(stack)
		while stack:
			for edge in stack.pop().link_edges:
				for vertex in edge.verts:
					if vertex in remaining:
						remaining.remove(vertex)
						component.add(vertex)
						stack.append(vertex)
		faces = {face for vertex in component for face in vertex.link_faces}
		if len(component) < 8 or sum(face.calc_area() for face in faces) < 1e-6:
			bmesh.ops.delete(bm, geom=list(component), context='VERTS')
			removed += 1
		else:
			parts += 1
	bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
	bm.to_mesh(obj.data)
	bm.free()
	if not obj.data.polygons:
		raise ValueError('Nach dem Entfernen winziger Teile bleibt keine Oberfläche.')
	if triangle_count(obj.data) > args.max_tris:
		modifier = obj.modifiers.new('Dreieckslimit', 'DECIMATE')
		modifier.ratio = args.max_tris / triangle_count(obj.data)
		bpy.ops.object.modifier_apply(modifier=modifier.name)
	bm = bmesh.new()
	bm.from_mesh(obj.data)
	bmesh.ops.triangulate(bm, faces=list(bm.faces))
	bm.to_mesh(obj.data)
	bm.free()
	bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40), keep_sharp_edges=False)
	report.update(triangles_after=triangle_count(obj.data), vertices_after=len(obj.data.vertices),
		removed_parts=removed, parts_after=parts)
	if report['triangles_after'] > args.max_tris:
		raise ValueError(f"Dreieckslimit überschritten: {report['triangles_after']} > {args.max_tris}")
	print(f"Geometrie: {report['triangles_before']} -> {report['triangles_after']} Dreiecke, "
		f"{report['vertices_before']} -> {report['vertices_after']} Punkte, {parts} Teile, {removed} entfernt", flush=True)


def arguments():
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument('--input', type=Path, required=True)
	parser.add_argument('--output', type=Path, required=True)
	parser.add_argument('--name', required=True)
	parser.add_argument('--front', choices=('+X', '-X', '+Y', '-Y'), default='+X')
	parser.add_argument('--size', type=int, default=1024)
	parser.add_argument('--head-share', type=float, default=0.25)
	parser.add_argument('--max-tris', type=int, default=19000)
	parser.add_argument('--cel', action='store_true')
	args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
	if not args.input.is_file():
		parser.error(f'Eingabedatei fehlt: {args.input}')
	if args.input.suffix.lower() not in ('.fbx', '.glb'):
		parser.error('Eingabe muss FBX oder GLB sein.')
	if not 0 < args.head_share < 1 or not 16 <= args.size <= 1024 or not 1 <= args.max_tris <= 20000:
		parser.error('Ungültige Werte für Kopfanteil, Texturgröße oder Dreieckslimit.')
	if not args.name.strip() or any(c in args.name for c in '<>:"/\\|?*') or args.name in ('.', '..'):
		parser.error('Name muss ein einfacher Dateiname sein.')
	args.output.mkdir(parents=True, exist_ok=True)
	return args


def main():
	args = arguments()
	started = time.monotonic()
	report = {}
	obj, original = import_model(args, report)
	clean_geometry(obj, args, report)
	print(f'Geometrie aufbereitet in {time.monotonic() - started:.1f} s.', flush=True)


if __name__ == '__main__':
	try:
		main()
	except Exception as error:
		print(f'Aufräumen fehlgeschlagen: {error}', file=sys.stderr, flush=True)
		traceback.print_exc()
		sys.exit(1)
