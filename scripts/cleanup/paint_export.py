"""Bemalte PNG von der Festplatte mit dem aufbereiteten Modell exportieren."""

from pathlib import Path
import sys
import time
import traceback

import bpy
import numpy as np

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from cleanup_model import export_files, final_material, proof_camera, render_views, triangle_count
from paint_common import arguments, load_clean


def image_pixels(image):
	width, height = image.size
	if width == 0 or height == 0:
		raise ValueError(f'PNG konnte nicht gelesen werden: {image.filepath}')
	pixels = np.empty(width * height * 4, dtype=np.float32)
	image.pixels.foreach_get(pixels)
	return pixels.reshape(height, width, 4)


def main():
	args = arguments()
	started = time.monotonic()
	paint_path = args.output / f'{args.name}_tex_bemalt.png'
	blend_path = args.output / f'{args.name}_malen.blend'
	warning = blend_path.is_file() and blend_path.stat().st_mtime - paint_path.stat().st_mtime > 60
	if warning:
		print('WARNUNG: Bild in Blender gespeichert? (Image → Save). '
			'Die Mal-Datei ist mehr als 60 Sekunden neuer als das Bild; exportiert wird nur die PNG auf der Festplatte.', flush=True)
	# Keine .blend öffnen: nur die gespeicherte PNG ist die Exportquelle.
	obj = load_clean(args)
	painted = bpy.data.images.load(str(paint_path), check_existing=False)
	original = bpy.data.images.load(str(args.output / f'{args.name}_tex.png'), check_existing=False)
	painted.colorspace_settings.name = 'sRGB'
	original.colorspace_settings.name = 'sRGB'
	size = tuple(painted.size)
	if size != tuple(original.size):
		raise ValueError(f'Bemalte Textur hat Größe {size}, Original {tuple(original.size)}. '
			'Bitte in der Größe des Originals malen und als PNG speichern.')
	changed = np.any(image_pixels(painted) != image_pixels(original), axis=2)
	report = {'triangles_after': triangle_count(obj.data), 'texture_size': size,
		'changed_pixels': int(changed.sum()), 'changed_share': float(changed.mean())}
	final_material(obj, painted)
	# Derselbe Kamerarahmen und dieselben Render-Einstellungen wie beim Aufräumen.
	comparison = obj.copy()
	bpy.context.collection.objects.link(comparison)
	camera, center, full_scale, face_center, height = proof_camera(obj)
	render_views(obj, comparison, camera, args.output, f'{args.name}_bemalt', center, full_scale, face_center, height)
	bpy.data.objects.remove(comparison, do_unlink=True)
	export_files(obj, args.output / f'{args.name}_bemalt.fbx', args.output / f'{args.name}_bemalt.glb',
		paint_path, size, report)
	share = f"{100 * report['changed_share']:.4f}".rstrip('0').rstrip('.').replace('.', ',')
	lines = [f'Modell: {args.name}', f'Texturquelle (Festplatte): {paint_path}',
		f"Dreiecke: {report['triangles_after']}", f'Texturgröße: {size}',
		f"Geänderte Pixel: {share} % ({report['changed_pixels']} / {changed.size})",
		f"FBX-Re-Import Dreiecke: {report['export_triangles']}",
		f"FBX-Re-Import Texturgrößen: {report['export_texture_sizes']}",
		f"FBX-Textur eingebettet und PNG identisch: {report['export_embedded']}",
		f'Exportdateien: {args.name}_bemalt.fbx, {args.name}_bemalt.glb',
		f'Laufzeit: {time.monotonic() - started:.2f} s', 'Studio-Test: ungetestet']
	if warning:
		lines.append('WARNUNG: Bild in Blender gespeichert? (Image → Save)')
	(args.output / f'{args.name}_bemalt_bericht.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')
	print(f'Bemalter Export fertig; geänderte Pixel {share} %.', flush=True)


if __name__ == '__main__':
	try:
		main()
	except Exception as error:
		print(f'Bemalter Export fehlgeschlagen: {error}', file=sys.stderr, flush=True)
		traceback.print_exc()
		sys.exit(1)
