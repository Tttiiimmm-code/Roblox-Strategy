"""Eine geschützte Blender-Mal-Datei mit Schablonen und Pinseln erzeugen."""

from datetime import datetime
from pathlib import Path
import shutil
import sys
import traceback

import bpy
import gpu
import numpy as np

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from cleanup_model import activate, final_material, png_pixels, save_png
from paint_common import arguments, load_clean


def crop_reference(source, target):
	pixels = png_pixels(source)
	background = np.median(np.array([pixels[0, 0, :3], pixels[0, -1, :3],
		pixels[-1, 0, :3], pixels[-1, -1, :3]]), axis=0)
	foreground = np.max(np.abs(pixels[:, :, :3].astype(float) - background), axis=2) > 30
	if pixels.shape[2] == 4:
		foreground &= pixels[:, :, 3] > 0
	y, x = np.where(foreground)
	if not len(x):
		raise ValueError(f'Keine Figur vor dem Hintergrund erkannt: {source}')
	margin = max(1, round(max(x.max() - x.min() + 1, y.max() - y.min() + 1) * 0.02))
	x0, x1 = max(0, x.min() - margin), min(pixels.shape[1], x.max() + margin + 1)
	y0, y1 = max(0, y.min() - margin), min(pixels.shape[0], y.max() + margin + 1)
	image = bpy.data.images.load(str(source), check_existing=False)
	width, height = image.size
	data = np.empty(width * height * 4, dtype=np.float32)
	image.pixels.foreach_get(data)
	# Blender zählt die Bildzeilen von unten; PNG zählt von oben.
	data = data.reshape(height, width, 4)[height - y1:height - y0, x0:x1].copy()
	cut = bpy.data.images.new(target.stem, width=x1 - x0, height=y1 - y0, alpha=True)
	cut.colorspace_settings.name = 'sRGB'
	cut.pixels.foreach_set(data.ravel())
	save_png(cut, target)
	bpy.data.images.remove(image)
	bpy.data.images.remove(cut)
	print(f'Referenz zugeschnitten: {target.name}, {x1 - x0} × {y1 - y0}', flush=True)
	return bpy.data.images.load(str(target), check_existing=False)


def reference_texture(name, image):
	texture = bpy.data.textures.new(name, type='IMAGE')
	texture.image = image
	texture.use_fake_user = True
	return texture


def paint_brush(name, radius, texture=None):
	brush = bpy.data.brushes.new(name, mode='TEXTURE_PAINT')
	brush.image_brush_type = 'DRAW'
	brush.size = radius
	brush.strength = 1
	brush.color = (1, 1, 1)
	brush.blend = 'MIX'
	brush.curve_distance_falloff_preset = 'CONSTANT'
	brush.use_pressure_size = False
	brush.use_pressure_strength = False
	brush.use_fake_user = True
	if texture:
		brush.texture = texture
		brush.texture_slot.map_mode = 'STENCIL'
		width, height = texture.image.size
		brush.stencil_dimension = (256, 256 * height / width)
	brush.asset_mark()
	return brush


def uv_grid(obj, path):
	activate(obj)
	# Seit Blender 5.2 muss der PNG-Export die GPU auch headless initialisieren.
	gpu.init()
	bpy.ops.uv.export_layout(filepath=str(path), export_all=True, mode='PNG', size=(1024, 1024), opacity=0)
	grid = bpy.data.images.load(str(path), check_existing=False)
	data = np.empty(1024 * 1024 * 4, dtype=np.float32)
	grid.pixels.foreach_get(data)
	data[3::4] *= 0.5
	grid.pixels.foreach_set(data)
	save_png(grid, path)
	bpy.data.images.remove(grid)


def main():
	args = arguments(setup=True)
	blend_path = args.output / f'{args.name}_malen.blend'
	paint_path = args.output / f'{args.name}_tex_bemalt.png'
	if blend_path.exists() and not args.force:
		raise ValueError('Mal-Datei existiert bereits. Zum Malen öffnen; nur zum bewussten Neuerstellen --force verwenden.')
	if args.force and paint_path.exists():
		backup = args.output / f'{args.name}_tex_bemalt_{datetime.now():%Y%m%d_%H%M%S_%f}.png'
		shutil.copy2(paint_path, backup)
		print(f'Bemalte Textur gesichert: {backup.name}', flush=True)
	if not paint_path.exists():
		shutil.copy2(args.output / f'{args.name}_tex.png', paint_path)
	obj = load_clean(args)
	image = bpy.data.images.load(str(paint_path), check_existing=False)
	image.colorspace_settings.name = 'sRGB'
	final_material(obj, image)
	textures = {}
	for side in ('vorne', 'hinten'):
		cut = crop_reference(args.dir / f'ref_{side}.png', args.output / f'{args.name}_ref_{side}_zuschnitt.png')
		textures[side] = reference_texture(f'Referenz {side}', cut)
	front = paint_brush('Referenz vorne', 40, textures['vorne'])
	paint_brush('Flach malen', 15)
	uv_grid(obj, args.output / f'{args.name}_uv_raster.png')
	settings = bpy.context.scene.tool_settings.image_paint
	settings.mode = 'IMAGE'
	settings.canvas = image
	settings.use_symmetry_x = False
	settings.use_symmetry_y = False
	settings.use_symmetry_z = False
	settings.use_backface_culling = True
	settings.unified_paint_settings.use_unified_size = False
	settings.unified_paint_settings.use_unified_strength = False
	settings.unified_paint_settings.use_unified_color = False
	bpy.context.scene.view_settings.view_transform = 'Standard'
	bpy.context.scene.view_settings.look = 'None'
	for screen in bpy.data.screens:
		for area in screen.areas:
			for space in area.spaces:
				if space.type == 'VIEW_3D':
					space.shading.type = 'SOLID'
					space.shading.light = 'FLAT'
					space.shading.color_type = 'TEXTURE'
				elif space.type == 'IMAGE_EDITOR':
					space.image = image
	activate(obj)
	bpy.ops.object.mode_set(mode='TEXTURE_PAINT')
	bpy.ops.brush.asset_activate(asset_library_type='LOCAL', relative_asset_identifier=f'Brush/{front.name}')
	# Zuerst den Zieldateinamen setzen, damit // relativ zum Ordner clean aufgelöst wird.
	bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
	bpy.ops.file.make_paths_relative()
	bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
	print(f'Mal-Datei gespeichert: {blend_path}; zwei lokale Pinsel-Assets vorhanden.', flush=True)


if __name__ == '__main__':
	try:
		main()
	except Exception as error:
		print(f'Mal-Datei fehlgeschlagen: {error}', file=sys.stderr, flush=True)
		traceback.print_exc()
		sys.exit(1)
