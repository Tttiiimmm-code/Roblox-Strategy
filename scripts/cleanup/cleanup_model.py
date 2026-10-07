"""KI-Figurenmodelle für Roblox aufbereiten; Aufruf über scripts/cleanup.ps1."""

import argparse
from pathlib import Path
import sys
import traceback


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
	print(f'Aufruf geprüft: {args.input} -> {args.output}', flush=True)


if __name__ == '__main__':
	try:
		main()
	except Exception as error:
		print(f'Aufräumen fehlgeschlagen: {error}', file=sys.stderr, flush=True)
		traceback.print_exc()
		sys.exit(1)
