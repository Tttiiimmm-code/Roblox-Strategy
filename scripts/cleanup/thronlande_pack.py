"""Zwölf bereinigte D2-Requisiten als ein geprüftes FBX-Importpaket ausgeben."""

import argparse
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector


MODELS = (
	('ruin_column', 'rim_ruin_column_1', 1500),
	('banner', 'rim_banner_1', 1000),
	('crystal_shrine', 'rim_crystal_shrine_1', 1500),
	('ruin_arch', 'rim_ruin_arch_1', 3000),
	('lantern', 'rim_lantern_1', 1000),
	('crystal_pedestal', 'rim_crystal_pedestal_1', 1000),
	('bridge', 'archbridge_2', 3000),
	('grass', 'deco_grass_2', 300),
	('flowers', 'deco_flower_4', 800),
	('barrels', 'rim_barrels_1', 1000),
	('stones', 'deco_stone_1', 300),
	('boulder', 'rock_50', 1500),
)


def bounds(obj):
	points = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
	return (Vector(tuple(min(point[i] for point in points) for i in range(3))),
		Vector(tuple(max(point[i] for point in points) for i in range(3))))


def inspect(obj, limit):
	obj.data.calc_loop_triangles()
	triangles = len(obj.data.loop_triangles)
	if not 0 < triangles <= limit:
		raise ValueError(f'{obj.name}: Dreieckslimit überschritten ({triangles}/{limit}).')
	images = [node.image for material in obj.data.materials if material and material.use_nodes
		for node in material.node_tree.nodes if node.type == 'TEX_IMAGE' and node.image]
	if not images or any(tuple(image.size) != (512, 512) or not image.packed_file for image in images):
		raise ValueError(f'{obj.name}: eingebettete 512-Pixel-Textur fehlt.')
	for material in obj.data.materials:
		shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
		if shader.inputs['Metallic'].default_value > 0.001 or shader.inputs['Roughness'].default_value < 0.99:
			raise ValueError(f'{obj.name}: Material ist nicht matt.')
	low, high = bounds(obj)
	return {'triangles': triangles, 'size_xyz': list(high - low)}


def main():
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument('--root', type=Path, default=Path('assets/raw/d2'))
	args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
	root = args.root.resolve()
	for source, _, _ in MODELS:
		if not (root / source / 'clean' / f'{source}_clean.fbx').is_file():
			raise ValueError(f'Bereinigtes Modell fehlt: {source}')
	bpy.ops.object.select_all(action='SELECT')
	bpy.ops.object.delete(use_global=False)
	objects, report = [], {}
	for source, target, limit in MODELS:
		before = set(bpy.context.scene.objects)
		bpy.ops.import_scene.fbx(filepath=str(root / source / 'clean' / f'{source}_clean.fbx'),
			use_anim=False, use_image_search=False)
		added = set(bpy.context.scene.objects) - before
		if len(added) != 1 or next(iter(added)).type != 'MESH':
			raise ValueError(f'{source}: genau ein Mesh erforderlich.')
		obj = added.pop()
		obj.name = obj.data.name = target
		obj.parent = None
		bpy.context.view_layer.objects.active = obj
		bpy.ops.object.select_all(action='DESELECT')
		obj.select_set(True)
		bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
		low, high = bounds(obj)
		shift = Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z))
		for vertex in obj.data.vertices:
			vertex.co += shift
		obj.data.update()
		report[target] = {'source': source, **inspect(obj, limit)}
		objects.append(obj)
	spacing = max(max(entry['size_xyz']) for entry in report.values()) + 2
	for index, obj in enumerate(objects):
		obj.location = ((index % 4) * spacing, (index // 4) * spacing, 0)
	bpy.ops.object.select_all(action='DESELECT')
	for obj in objects:
		obj.select_set(True)
	output = root / 'thronlande_pack.fbx'
	bpy.ops.export_scene.fbx(filepath=str(output), use_selection=True, object_types={'MESH'},
		use_mesh_modifiers=True, bake_anim=False, path_mode='COPY', embed_textures=True,
		axis_forward='-Z', axis_up='Y', apply_unit_scale=True,
		apply_scale_options='FBX_SCALE_UNITS', global_scale=1.0)
	# Re-Import prüft das Paket selbst, nicht nur die Szene vor dem Export.
	bpy.ops.object.select_all(action='SELECT')
	bpy.ops.object.delete(use_global=False)
	bpy.ops.import_scene.fbx(filepath=str(output), use_anim=False, use_image_search=False)
	imported = {obj.name: obj for obj in bpy.context.scene.objects if obj.type == 'MESH'}
	if set(imported) != set(report) or len(bpy.context.scene.objects) != len(MODELS):
		raise ValueError('Paket-Re-Import enthält falsche Namen, Zusatzobjekte oder fehlende Modelle.')
	for _, target, limit in MODELS:
		obj = imported[target]
		actual = inspect(obj, limit)
		if actual['triangles'] != report[target]['triangles'] or any(
			abs(a - b) > 1e-4 for a, b in zip(actual['size_xyz'], report[target]['size_xyz'])):
			raise ValueError(f'{target}: Geometrie beim Paketexport verändert.')
		low, high = bounds(obj)
		bottom = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
		if (obj.matrix_world.translation - bottom).length > 1e-4:
			raise ValueError(f'{target}: Pivot ist nicht unten mittig.')
	(root / 'thronlande_pack_bericht.json').write_text(json.dumps({
		'models': report, 'triangles_total': sum(entry['triangles'] for entry in report.values()),
		'fbx_bytes': output.stat().st_size, 'reimport_ok': True, 'studio_test': 'ungetestet',
	}, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
	print(f'OK: {len(imported)} Modelle, Paket-Re-Import, Pivot, Texturen und matte Materialien geprüft.')


if __name__ == '__main__':
	main()
