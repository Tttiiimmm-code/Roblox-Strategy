---
tags: [workflow, test]
---
# Test in Studio

1. `tools/rojo.exe serve default.project.json` starten.
2. Roblox Studio → Plugins → Rojo → Adresse **`127.0.0.1`** (nicht `localhost`), Port `34872` → Connect.
3. Play (F5); Fehler stehen unter Ansicht → Output (rote Zeilen).
4. Handy: Datei → Auf Roblox veröffentlichen (privat) → Roblox-App → Profil → Kreationen.

## Automatische Prüfungen
| Befehl | Prüft |
|---|---|
| `scripts/check.ps1` | Syntax und undefinierte Variablen aller `.luau` |
| `scripts/test-levelgen.ps1` | [[Levelgenerator]] |
| `scripts/test-tutorial.ps1` | [[Tutorial]] |
| `scripts/test-run.ps1` | Läufe, [[Bosse und Lager]], Brett und [[Thronlande]] |
| `scripts/test-run-ui.ps1` | Levelwahl-Oberfläche |
| `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` | Spieldatei bauen |

Offene Prüfpunkte stehen im aktuellen [[PLAN]] und in [[Roadmap]].
