"""Gemeinsame Eingaben für Mal-Datei und Textur-Export."""

import argparse
from pathlib import Path
import sys

import bpy

from cleanup_model import activate


def arguments(setup=False):
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument('--dir', type=Path, required=True)
	parser.add_argument('--name', required=True)
	if setup:
		parser.add_argument('--force', action='store_true')
	args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
	if not args.name.strip() or any(c in args.name for c in '<>:"/\\|?*') or args.name in ('.', '..') or args.name.endswith('.'):
		parser.error('Name muss ein einfacher Dateiname sein.')
	args.dir = args.dir.resolve()
	args.output = args.dir / 'clean'
	required = [args.output / f'{args.name}_clean.glb', args.output / f'{args.name}_tex.png']
	if setup:
		required.extend(args.dir / f'ref_{side}.png' for side in ('vorne', 'hinten'))
	else:
		required.append(args.output / f'{args.name}_tex_bemalt.png')
	for path in required:
		if not path.is_file():
			parser.error(f'Eingabedatei fehlt: {path}')
	return args


def load_clean(args):
	bpy.ops.object.select_all(action='SELECT')
	bpy.ops.object.delete(use_global=False)
	bpy.ops.import_scene.gltf(filepath=str(args.output / f'{args.name}_clean.glb'))
	meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
	if len(meshes) != 1:
		raise ValueError('Aufbereitetes GLB muss genau ein Mesh enthalten.')
	obj = meshes[0]
	if len(obj.data.uv_layers) != 1:
		raise ValueError('Aufbereitetes GLB muss genau eine UV-Ebene enthalten.')
	# GLB transportiert UV-Koordinaten, aber nicht den Blender-Namen der Ebene.
	obj.data.uv_layers[0].name = 'UV_neu'
	obj.data.uv_layers.active_index = 0
	obj.data.uv_layers[0].active_render = True
	activate(obj)
	return obj
