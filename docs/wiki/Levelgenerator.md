---
tags: [system]
---
# Levelgenerator

`src/shared/LevelGen.luau` mit Kartenstücken aus `MapChunks.luau`, Werte in `RunConfig`.

- **Deterministisch:** Seed pro Lauf und Level, eigener Zufallsgenerator → wiederholbar und nicht manipulierbar.
- **Bausteine:** sechs 8 × 4 große Kartenstücke ergeben ein 16 × 12-Brett; sie werden kombiniert und gespiegelt, Rand-Kennungen sorgen für nahtlose Übergänge.
- **Landschaft:** geschwungene Flüsse (40 %, 1–2 Felder breit, 2–3 Brücken), Seen (30 %) mit Inseln, Teiche, Klippen (40 %) und Wasserfälle.
- **Lösbarkeit:** alle Gegner erreichbar, Mindestabstand 4 zum Start, höchstens 32 % blockiert; sonst bis zu 50 neue Versuche, danach Rückfallkarte.
- **Aufstellung:** Start in der Mitte der unteren zwei Reihen, Gegner in der oberen Hälfte; Anzahl min(12, 6 + Tiefe), Gegnerlevel steigt mit der Tiefe.
- **Boss-/Minibosskarten:** Bosskarte mit Festung, drei Leibwachen und vier Verstärkungsfeldern (nach Seed gespiegelt); Minibosskarte mit zwei Leibwachen → [[Bosse und Lager]].

Die 3D-Darstellung (Insel, Rand, Wasser, Deko) baut der Server aus dem fertigen Brett → [[Thronlande]].

## Prüfen
`powershell -ExecutionPolicy Bypass -File scripts/test-levelgen.ps1` – Tausende Level-, Options- und Bossprüfungen ohne Roblox (`tests/levelgen.test.luau`).

Verwandt: [[Roguelike-Läufe]], [[umgebung-assets]]
