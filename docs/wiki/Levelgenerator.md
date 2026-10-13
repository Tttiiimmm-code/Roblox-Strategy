---
tags: [system]
---
# Levelgenerator

`src/shared/LevelGen.luau` mit Kartenstücken aus `MapChunks.luau`, Werte in `RunConfig`.

- **Deterministisch:** Seed pro Lauf und Level, eigener Zufallsgenerator → wiederholbar und nicht manipulierbar.
- **Bausteine:** 5 × 4 große Kartenstücke werden kombiniert und gespiegelt; Rand-Kennungen sorgen für nahtlose Übergänge.
- **Flüsse:** 40 % Chance, 1–2 Felder breit, 1–2 Brücken.
- **Lösbarkeit:** alle Gegner erreichbar, Mindestabstand 4 zum Start, höchstens 25 % blockiert; sonst bis zu 50 neue Versuche, danach Rückfallkarte.
- **Gegner:** 4 + 1 je Tiefe, Gegnerlevel steigt mit der Tiefe.

## Prüfen
`powershell -ExecutionPolicy Bypass -File scripts/test-levelgen.ps1` – Tausende Levelprüfungen ohne Roblox (`tests/levelgen.test.luau`).

Verwandt: [[Roguelike-Läufe]], [[umgebung-assets]]
