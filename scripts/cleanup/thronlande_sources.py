"""Nach Sichtprüfung erkannte, getrennte D2-Schattenscheiben entfernen; Rohdateien bleiben erhalten."""

from pathlib import Path
import bmesh
import bpy

# Dünne Komponenten unmittelbar am Boden; die echten Steinsockel bleiben erhalten.
MODELS = {'banner': (0.015, 0.015, 1), 'crystal_shrine': (0.025, 0.03, 1), 'lantern': (0.001, 0.002, 2), 'grass': (0.05, 0.2, 1), 'flowers': (0, 0, 0)}
ROOT = Path('assets/raw/d2').resolve()
for name, (thickness, bottom_margin, expected) in MODELS.items():
	bpy.ops.object.select_all(action='SELECT')
	bpy.ops.object.delete(use_global=False)
	bpy.ops.import_scene.gltf(filepath=str(ROOT / name / f'{name}.glb'))
	meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
	if len(meshes) != 1:
		raise ValueError(f'{name}: genau ein Roh-Mesh erwartet.')
	obj = meshes[0]
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.select_all(action='DESELECT')
	obj.select_set(True)
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	bm = bmesh.new()
	bm.from_mesh(obj.data)
	bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-5)
	bottom = min(vertex.co.z for vertex in bm.verts)
	if name == 'flowers':
		# Erde und grauer Rand sind verbunden; nur die vermessenen unteren Randflächen entfernen.
		if abs(bottom + 0.347412109375) > 0.0001:
			raise ValueError('flowers: Rohgeometrie verändert; Bodenrand erneut prüfen.')
		faces = [face for face in bm.faces if max(vertex.co.z for vertex in face.verts) <= bottom + 0.0352]
		if len(faces) != 107:
			raise ValueError('flowers: graue Randflächen nicht eindeutig gefunden.')
		print(f'flowers: {len(faces)} graue Randflächen entfernt; brauner Erdfleck erhalten.', flush=True)
		bmesh.ops.delete(bm, geom=faces, context='FACES')
		# Verbleibende braune Seitenflächen tragen am unteren Saum noch graue Texturpixel.
		bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
			plane_co=(0, 0, bottom + 0.0364), plane_no=(0, 0, 1), clear_inner=True)
	remaining, removed, vertices = set(bm.verts), 0, 0
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
		low = [min(vertex.co[i] for vertex in component) for i in range(3)]
		high = [max(vertex.co[i] for vertex in component) for i in range(3)]
		if low[2] <= bottom + bottom_margin and high[2] - low[2] <= thickness and min(
			high[0] - low[0], high[1] - low[1]) > 0.1:
			vertices += len(component)
			bmesh.ops.delete(bm, geom=list(component), context='VERTS')
			removed += 1
	if removed != expected:
		raise ValueError(f'{name}: {removed} Bodenscheiben gefunden, erwartet {expected}; Sichtprüfung nötig.')
	bm.to_mesh(obj.data)
	bm.free()
	out = ROOT / name / 'prepared'
	out.mkdir(exist_ok=True)
	bpy.ops.export_scene.gltf(filepath=str(out / f'{name}.glb'), export_format='GLB',
		use_selection=True, export_animations=False)
	print(f'{name}: {removed} getrennte Schattenscheiben entfernt ({vertices} Punkte), Original erhalten.', flush=True)
