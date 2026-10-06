#!/usr/bin/env bash
# Wartet auf das Codex-Signal (.handoff/status). Meldet "STILL", wenn das neueste
# Codex-Sitzungsprotokoll zu lange unverändert ist – Codex wartet dann vermutlich
# auf eine Freigabe im Terminal, die Claude nicht sehen kann.
cd "$(dirname "$0")/.." || exit 1
limit=${1:-180}
started=$(date +%s)
while [ ! -f .handoff/status ]; do
	sleep 20
	log=$(ls -t "$HOME"/.codex/sessions/*/*/*/*.jsonl 2>/dev/null | head -1)
	if [ -n "$log" ]; then
		# Alte Protokolle (vor Start des Wartens) zählen erst ab jetzt – Codex braucht Zeit zum Hochfahren
		changed=$(stat -c %Y "$log")
		[ "$changed" -lt "$started" ] && changed=$started
		age=$(( $(date +%s) - changed ))
		if [ "$age" -ge "$limit" ] && [ ! -f .handoff/status ]; then
			echo "STILL (Protokoll seit ${age}s unverändert)"
			exit 0
		fi
	fi
done
cat .handoff/status
