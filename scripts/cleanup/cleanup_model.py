"""KI-Figurenmodelle für Roblox aufbereiten; Aufruf über scripts/cleanup.ps1."""

import argparse
import math
from pathlib import Path
import sys
import time
import traceback
import struct
import zlib

import bmesh
import bpy
import numpy as np
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
				ends.append((mesh.loops[index].vertex_index, uv.copy()))
			ends.sort(key=lambda item: item[0])
			key = tuple(item[0] for item in ends)
			for other_face, other_uv in edges.get(key, []):
				if all((ends[j][1] - other_uv[j]).length < 1e-5 for j in range(2)):
					parents[root(face.index)] = root(other_face)
			edges.setdefault(key, []).append((face.index, tuple(item[1] for item in ends)))
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


def uv_area(mesh, layer, head_faces):
	mesh.calc_loop_triangles()
	head = total = 0.0
	for triangle in mesh.loop_triangles:
		a, b, c = (layer.data[index].uv for index in triangle.loops)
		area = abs((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) / 2
		total += area
		if head_faces[triangle.polygon_index]:
			head += area
	return head / total if total else 0.0


def arrange_uv(obj, args, report):
	activate(obj)
	mesh = obj.data
	low, high = bounds(obj)
	height = high.z - low.z
	if height <= 0:
		raise ValueError('Das Modell hat keine Höhe.')
	head_faces = [face.center.z > high.z - 0.13 * height and
		math.hypot(face.center.x, face.center.y) < 0.12 * height for face in mesh.polygons]
	if not any(head_faces) or all(head_faces):
		raise ValueError('Kopfbereich nicht eindeutig erkannt; aufrechte Figur und Ausrichtung prüfen.')
	layer = mesh.uv_layers.new(name='UV_neu')
	mesh.uv_layers.active = layer
	layer.active_render = True
	bpy.context.scene.tool_settings.use_uv_select_sync = True
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.002)
	bpy.ops.object.mode_set(mode='OBJECT')
	layer = mesh.uv_layers['UV_neu']
	# Auch eine durchgehende Hals-Insel muss an der Kopfgrenze getrennt werden.
	for face in mesh.polygons:
		if head_faces[face.index]:
			for index in face.loop_indices:
				layer.data[index].uv.x += 2
	islands = uv_islands(mesh, layer)
	share = uv_area(mesh, layer, head_faces)
	if not 0 < share < 1:
		raise ValueError('Kopf oder Körper hat keine nutzbare UV-Fläche.')
	scale = math.sqrt(args.head_share * (1 - share) / (share * (1 - args.head_share)))
	for island in islands:
		if not head_faces[island[0]]:
			continue
		indices = [index for face in island for index in mesh.polygons[face].loop_indices]
		center = sum((layer.data[index].uv.copy() for index in indices), Vector((0, 0))) / len(indices)
		for index in indices:
			layer.data[index].uv = center + (layer.data[index].uv - center) * scale
	bpy.ops.object.mode_set(mode='EDIT')
	bpy.ops.mesh.select_all(action='SELECT')
	bpy.ops.uv.pack_islands(rotate=True, rotate_method='ANY', scale=True,
		margin_method='FRACTION', margin=4 / args.size, shape_method='CONCAVE')
	bpy.ops.object.mode_set(mode='OBJECT')
	layer = mesh.uv_layers['UV_neu']
	report['islands_after'] = len(uv_islands(mesh, layer))
	report['head_target'] = args.head_share
	report['head_actual'] = uv_area(mesh, layer, head_faces)
	print(f"UV-Inseln: {report['islands_before']} -> {report['islands_after']}; "
		f"Kopfanteil: {report['head_actual']:.2%} (Soll {args.head_share:.2%})", flush=True)
	return head_faces


def base_image(material):
	if not material or not material.use_nodes:
		raise ValueError('Originalmaterial ohne Bildtextur gefunden.')
	principled = next((node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED'), None)
	if not principled:
		raise ValueError(f'Material {material.name}: Principled-Shader für Originalfarbe fehlt.')
	stack = [link.from_node for link in principled.inputs['Base Color'].links]
	seen = set()
	while stack:
		node = stack.pop()
		if node in seen:
			continue
		seen.add(node)
		if node.type == 'TEX_IMAGE' and node.image:
			if not node.image.has_data:
				node.image.reload()
			if not node.image.has_data:
				raise ValueError(f'Texturdatei fehlt: {node.image.filepath}')
			return node.image
		stack.extend(link.from_node for socket in node.inputs for link in socket.links)
	raise ValueError(f'Material {material.name}: kein Bild an Base Color gefunden.')


def save_png(image, path):
	image.filepath_raw = str(path.resolve())
	image.file_format = 'PNG'
	image.save()


def final_material(obj, image):
	material = bpy.data.materials.new(obj.name + '_Material')
	material.use_nodes = True
	nodes = material.node_tree.nodes
	shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
	shader.inputs['Roughness'].default_value = 1
	shader.inputs['Metallic'].default_value = 0
	uv = nodes.new('ShaderNodeUVMap')
	uv.uv_map = 'UV_neu'
	texture = nodes.new('ShaderNodeTexImage')
	texture.image = image
	material.node_tree.links.new(uv.outputs['UV'], texture.inputs['Vector'])
	material.node_tree.links.new(texture.outputs['Color'], shader.inputs['Base Color'])
	nodes.active = texture
	obj.data.materials.clear()
	obj.data.materials.append(material)
	for face in obj.data.polygons:
		face.material_index = 0
	return material


def bake_texture(obj, args, report):
	activate(obj)
	scene = bpy.context.scene
	scene.view_settings.view_transform = 'Standard'
	scene.view_settings.look = 'None'
	scene.view_settings.exposure = 0
	scene.view_settings.gamma = 1
	scene.render.engine = 'CYCLES'
	scene.cycles.device = 'CPU'
	scene.cycles.samples = 1
	scene.render.bake.margin = 16
	scene.render.bake.margin_type = 'EXTEND'
	scene.render.bake.use_clear = True
	scene.render.bake.use_selected_to_active = False
	image = bpy.data.images.new(args.name + '_tex', width=2 * args.size, height=2 * args.size, alpha=False)
	image.colorspace_settings.name = 'sRGB'
	for index, slot in enumerate(obj.material_slots):
		source_image = base_image(slot.material)
		material = bpy.data.materials.new(f'{args.name}_Bake_{index}')
		material.use_nodes = True
		slot.material = material
		nodes = material.node_tree.nodes
		nodes.clear()
		uv = nodes.new('ShaderNodeUVMap')
		uv.uv_map = 'UV_alt'
		source = nodes.new('ShaderNodeTexImage')
		source.image = source_image
		material.node_tree.links.new(uv.outputs['UV'], source.inputs['Vector'])
		emission = nodes.new('ShaderNodeEmission')
		material.node_tree.links.new(source.outputs['Color'], emission.inputs['Color'])
		output = nodes.new('ShaderNodeOutputMaterial')
		material.node_tree.links.new(emission.outputs['Emission'], output.inputs['Surface'])
		target = nodes.new('ShaderNodeTexImage')
		target.image = image
		nodes.active = target
	if not obj.material_slots:
		raise ValueError('Das Modell hat kein Material.')
	bpy.ops.object.bake(type='EMIT')
	image.scale(args.size, args.size)
	save_png(image, args.output / f'{args.name}_tex.png')
	final_material(obj, image)
	obj.data.uv_layers.remove(obj.data.uv_layers['UV_alt'])
	obj.data.uv_layers['UV_neu'].active_render = True
	report['texture_size'] = tuple(image.size)
	print(f'Textur gebacken und gespeichert: {args.size} × {args.size}', flush=True)
	return image


def texture_masks(mesh, head_faces, size):
	resolution = 2 * size
	head = np.zeros((resolution, resolution), dtype=bool)
	body = np.zeros_like(head)
	layer = mesh.uv_layers['UV_neu']
	mesh.calc_loop_triangles()
	for triangle in mesh.loop_triangles:
		uv = np.array([tuple(layer.data[index].uv) for index in triangle.loops]) * resolution
		minimum = np.maximum(np.floor(uv.min(axis=0)).astype(int), 0)
		maximum = np.minimum(np.ceil(uv.max(axis=0)).astype(int), resolution - 1)
		if np.any(maximum < minimum):
			continue
		x0, y0 = minimum
		x1, y1 = maximum
		y, x = np.mgrid[y0:y1 + 1, x0:x1 + 1]
		x = x + 0.5
		y = y + 0.5
		a, b, c = uv
		denominator = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
		if abs(denominator) < 1e-12:
			continue
		weight_a = ((b[1] - c[1]) * (x - c[0]) + (c[0] - b[0]) * (y - c[1])) / denominator
		weight_b = ((c[1] - a[1]) * (x - c[0]) + (a[0] - c[0]) * (y - c[1])) / denominator
		inside = (weight_a >= -1e-7) & (weight_b >= -1e-7) & (weight_a + weight_b <= 1 + 1e-7)
		mask = head if head_faces[triangle.polygon_index] else body
		mask[y0:y1 + 1, x0:x1 + 1] |= inside
	# Gemischte Randpixel bleiben erhalten; schon ein Kopf-Subpixel schützt das ganze Pixel.
	head = head.reshape(size, 2, size, 2).any(axis=(1, 3))
	body = body.reshape(size, 2, size, 2).all(axis=(1, 3)) & ~head
	return head, body


def nearest_colors(pixels, centers):
	labels = np.empty(len(pixels), dtype=np.int32)
	for start in range(0, len(pixels), 16384):
		chunk = pixels[start:start + 16384]
		distance = ((chunk[:, None, :] - centers[None, :, :]) ** 2).sum(axis=2)
		labels[start:start + len(chunk)] = distance.argmin(axis=1)
	return labels


def cel_texture(obj, image, head_faces, args, report):
	head, body = texture_masks(obj.data, head_faces, args.size)
	if not np.any(body):
		raise ValueError('Keine Körperpixel für die Cel-Farbreduktion gefunden.')
	buffer = np.empty(args.size * args.size * 4, dtype=np.float32)
	image.pixels.foreach_get(buffer)
	pixels = buffer.reshape(args.size, args.size, 4)
	colors = pixels[body, :3].copy()
	rng = np.random.default_rng(0)
	sample = colors[rng.choice(len(colors), min(len(colors), 32768), replace=False)]
	# K-Means++ erhält auch kleine Gold-/Silberbereiche in der Palette.
	centers = [sample[rng.integers(len(sample))]]
	distance = np.full(len(sample), np.inf)
	for _ in range(1, args.cel_colors):
		distance = np.minimum(distance, ((sample - centers[-1]) ** 2).sum(axis=1))
		if distance.sum() <= 1e-12:
			break
		centers.append(sample[rng.choice(len(sample), p=distance / distance.sum())])
	centers = np.array(centers, dtype=np.float32)
	for _ in range(24):
		labels = nearest_colors(sample, centers)
		updated = centers.copy()
		for index in range(len(centers)):
			selected = sample[labels == index]
			if len(selected):
				updated[index] = selected.mean(axis=0)
		if np.max(np.abs(updated - centers)) < 1e-5:
			centers = updated
			break
		centers = updated
	pixels[body, :3] = centers[nearest_colors(colors, centers)]
	cel = bpy.data.images.new(args.name + '_tex_cel', width=args.size, height=args.size, alpha=False)
	cel.colorspace_settings.name = 'sRGB'
	cel.pixels.foreach_set(buffer)
	cel.update()
	path = args.output / f'{args.name}_tex_cel.png'
	save_png(cel, path)
	before = np.flipud(png_pixels(args.output / f'{args.name}_tex.png'))[:, :, :3]
	after = np.flipud(png_pixels(path))[:, :, :3]
	count = len(np.unique(after[body], axis=0))
	unchanged = bool(np.array_equal(before[~body], after[~body]))
	if count > args.cel_colors or not unchanged:
		raise ValueError(f'Cel-Prüfung fehlgeschlagen: {count} Farben, Kopf/Rand unverändert: {unchanged}')
	report.update(cel_colors=count, cel_body_pixels=int(body.sum()), cel_head_pixels=int(head.sum()),
		cel_protected_unchanged=unchanged)
	final_material(obj, cel)
	print(f'Cel: {count} Farben auf {body.sum()} Körperpixeln; Kopf, Hintergrund und Ränder unverändert.', flush=True)
	return cel


def png_pixels(path):
	# Die Grenze von 12/255 bezieht sich auf gespeicherte sRGB-Werte, nicht lineare Renderwerte.
	data = path.read_bytes()
	if data[:8] != b'\x89PNG\r\n\x1a\n':
		raise ValueError(f'Kein PNG: {path}')
	compressed = bytearray()
	position = 8
	while position < len(data):
		length = struct.unpack_from('>I', data, position)[0]
		kind = data[position + 4:position + 8]
		chunk = data[position + 8:position + 8 + length]
		if kind == b'IHDR':
			width, height, depth, color, _, _, interlace = struct.unpack('>IIBBBBB', chunk)
		elif kind == b'IDAT':
			compressed.extend(chunk)
		position += 12 + length
	if depth != 8 or color not in (2, 6) or interlace:
		raise ValueError('Prüfrender muss ein nicht verschachteltes RGB/RGBA-PNG mit 8 Bit sein.')
	channels = 4 if color == 6 else 3
	stride = width * channels
	raw = zlib.decompress(compressed)
	rows = np.empty((height, stride), dtype=np.uint8)
	previous = np.zeros(stride, dtype=np.uint8)
	for y in range(height):
		start = y * (stride + 1)
		filter_type = raw[start]
		row = np.frombuffer(raw[start + 1:start + 1 + stride], dtype=np.uint8).copy()
		if filter_type == 2:
			row = ((row.astype(np.uint16) + previous) % 256).astype(np.uint8)
		elif filter_type in (1, 3, 4):
			for x in range(stride):
				left = int(row[x - channels]) if x >= channels else 0
				above = int(previous[x])
				upper_left = int(previous[x - channels]) if x >= channels else 0
				if filter_type == 1:
					predictor = left
				elif filter_type == 3:
					predictor = (left + above) // 2
				else:
					p = left + above - upper_left
					distances = [abs(p - left), abs(p - above), abs(p - upper_left)]
					predictor = (left, above, upper_left)[distances.index(min(distances))]
				row[x] = (int(row[x]) + predictor) % 256
		elif filter_type != 0:
			raise ValueError(f'Unbekannter PNG-Filter: {filter_type}')
		rows[y] = row
		previous = row
	return rows.reshape(height, width, channels)


def render_model(obj, other, camera, path, center, scale, back=False):
	obj.hide_render = False
	other.hide_render = True
	scene = bpy.context.scene
	camera.data.ortho_scale = scale
	camera.location = center + Vector((0, 4 * scale if back else -4 * scale, 0))
	camera.rotation_euler = (center - camera.location).to_track_quat('-Z', 'Y').to_euler()
	scene.render.filepath = str(path.resolve())
	bpy.ops.render.render(write_still=True)
	obj.hide_render = True


def proof_images(obj, original, args, report):
	scene = bpy.context.scene
	scene.render.engine = 'BLENDER_WORKBENCH'
	scene.render.resolution_x = 900
	scene.render.resolution_y = 900
	scene.render.resolution_percentage = 100
	scene.render.image_settings.file_format = 'PNG'
	scene.render.image_settings.color_mode = 'RGBA'
	scene.render.image_settings.color_depth = '8'
	scene.render.film_transparent = True
	scene.display.shading.light = 'FLAT'
	scene.display.shading.color_type = 'TEXTURE'
	scene.display.shading.show_shadows = False
	scene.display.shading.show_cavity = False
	scene.display.shading.show_specular_highlight = False
	scene.display.render_aa = '16'
	camera = bpy.data.objects.new('Prüfkamera', bpy.data.cameras.new('Prüfkamera'))
	camera.data.type = 'ORTHO'
	bpy.context.collection.objects.link(camera)
	scene.camera = camera
	low, high = bounds(original)
	height = high.z - low.z
	center = (low + high) / 2
	full_scale = max(height, high.x - low.x) * 1.08
	face_center = Vector((center.x, center.y, high.z - height * 0.08))
	front_path = args.output / f'{args.name}_vorne.png'
	before_path = args.output / f'{args.name}_vorne_original.png'
	render_model(original, obj, camera, before_path, center, full_scale)
	render_model(obj, original, camera, front_path, center, full_scale)
	render_model(obj, original, camera, args.output / f'{args.name}_hinten.png', center, full_scale, back=True)
	render_model(obj, original, camera, args.output / f'{args.name}_gesicht.png', face_center, height * 0.16)
	before = png_pixels(before_path)
	after = png_pixels(front_path)
	mask = (before[:, :, 3] >= 250) & (after[:, :, 3] >= 250)
	if not np.any(mask):
		raise ValueError('Keine Figurpixel im Farbtreue-Check; Prüfrender fehlgeschlagen.')
	deviation = np.abs(before[:, :, :3].astype(float) - after[:, :, :3].astype(float))[mask].mean(axis=0)
	report['color_deviation_channels'] = deviation.tolist()
	report['color_deviation'] = float(deviation.mean())
	report['color_pixels'] = int(mask.sum())
	# Kopien verhindern, dass das 1K-Vergleichsbild die 4K-Quelldaten verändert.
	for slot in original.material_slots:
		material = slot.material.copy()
		slot.material = material
		image = base_image(material).copy()
		image.scale(args.size, args.size)
		for node in material.node_tree.nodes:
			if node.type == 'TEX_IMAGE':
				node.image = image
				material.node_tree.nodes.active = node
	render_model(original, obj, camera, args.output / f'{args.name}_gesicht_original_1k.png', face_center, height * 0.16)
	obj.hide_render = False
	activate(obj)
	print(f"Farbabweichung: {report['color_deviation']:.2f}/255; RGB {deviation.round(2).tolist()}", flush=True)
	return bool(np.all(deviation <= 12))


def write_report(args, report, started):
	lines = [f'Modell: {args.name}', f'Eingabe: {args.input.resolve()}',
		f"Dreiecke vorher/nachher: {report['triangles_before']} / {report['triangles_after']}",
		f"Punkte vorher/nachher: {report['vertices_before']} / {report['vertices_after']}",
		f"Gelöschte Kleinteile: {report['removed_parts']}; erhaltene Teile: {report['parts_after']}",
		f"UV-Inseln vorher/nachher: {report['islands_before']} / {report['islands_after']}",
		f"Kopfanteil Soll/Ist (UV-Fläche): {report['head_target']:.4f} / {report['head_actual']:.4f}",
		f"Texturgröße: {report['texture_size']}",
		f"Mittlere Farbabweichung: {report['color_deviation']:.4f} / 255",
		f"Farbabweichung RGB: {report['color_deviation_channels']}; Figurpixel: {report['color_pixels']}",
		f'Farbtreue-Grenze: 12 / 255 pro Kanal; bei Cel nur informativ',
		f'Laufzeit: {time.monotonic() - started:.2f} s',
		'Studio-Test: ungetestet']
	if args.cel:
		lines.extend([f"Cel-Farben Soll/Ist: {args.cel_colors} / {report['cel_colors']}",
			f"Cel-Körperpixel: {report['cel_body_pixels']}; geschützte Kopf-Pixel: {report['cel_head_pixels']}",
			f"Kopf, Hintergrund und Randpixel unverändert: {report['cel_protected_unchanged']}"])
	(args.output / f'{args.name}_bericht.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')


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
	parser.add_argument('--cel-colors', type=int, default=16)
	args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
	if not args.input.is_file():
		parser.error(f'Eingabedatei fehlt: {args.input}')
	if args.input.suffix.lower() not in ('.fbx', '.glb'):
		parser.error('Eingabe muss FBX oder GLB sein.')
	if not 0 < args.head_share < 1 or not 16 <= args.size <= 1024 or not 1 <= args.max_tris <= 20000:
		parser.error('Ungültige Werte für Kopfanteil, Texturgröße oder Dreieckslimit.')
	if not args.name.strip() or any(c in args.name for c in '<>:"/\\|?*') or args.name in ('.', '..'):
		parser.error('Name muss ein einfacher Dateiname sein.')
	if not 2 <= args.cel_colors <= 256:
		parser.error('CelColors muss zwischen 2 und 256 liegen.')
	args.output.mkdir(parents=True, exist_ok=True)
	return args


def main():
	args = arguments()
	started = time.monotonic()
	report = {}
	obj, original = import_model(args, report)
	clean_geometry(obj, args, report)
	head_faces = arrange_uv(obj, args, report)
	image = bake_texture(obj, args, report)
	if args.cel:
		image = cel_texture(obj, image, head_faces, args, report)
	color_ok = proof_images(obj, original, args, report)
	write_report(args, report, started)
	if not args.cel and not color_ok:
		raise ValueError('Farbtreue-Check fehlgeschlagen: mindestens ein Kanal liegt über 12/255.')


if __name__ == '__main__':
	try:
		main()
	except Exception as error:
		print(f'Aufräumen fehlgeschlagen: {error}', file=sys.stderr, flush=True)
		traceback.print_exc()
		sys.exit(1)
