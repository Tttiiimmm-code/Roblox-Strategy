---
tags: [system]
---
# Bosse und Lager

Roguelike Phase 3 (Devlog #32). Werte in `src/shared/RunConfig.luau` und `UnitData.Enemies`, Fähigkeiten im Servermodul `BossAbilities`, Ablauf in `RunService`.

## Laufabfolge (Grasland)
L1/L2 Wahl → **L3 Miniboss** → L4 Wahl → **Extra-Lager** (verbraucht kein Level) → **L5 Boss**.

## Bosse
| Gegner | Rolle | Besonderheit |
|---|---|---|
| Banditenhauptmann (`brigand_captain`) | Miniboss L3, 2 Leibwachen | Bewegung 3; ruft einmal bei ≤ 40 % KP 1–2 Banditen in Radius 2 |
| Garrick (`chieftain`, Klasse Bandenführer) | Boss L5, Festung + 3 Leibwachen | hält die Festung bis zum ersten Treffer (`hold_until_hurt`); **Kriegsschrei** alle 3 Runden (+3 Stärke, Radius 3, 1 Runde); bei ≤ 50 % KP Verstärkung 2–3 Banditen mit einer Gegnerphase Vorwarnung |

- Bossfall beendet den Kampf sofort, übrige Gegner fliehen.
- Belohnung: Miniboss 2×, Boss 3× Gold. Gebietsboss erhöht den Teamplatz um 1 (Start 3, max. 6).
- Lauf- und beschworene Gegner skalieren mit der Tiefe (`ENEMY_STAT_PER_LEVEL`).

## Lager
- Statt eines Kampfes mit 30 % Chance als Option (`CAMP_CHANCE`), ohne Belohnung.
- Volle Heilung, Team tauschen (`CampSwap`), gefallene Helden wiederbeleben (`CampRevive`: 100 + 25 × Level Gold oder 15 Edelsteine), weiter mit `LeaveCamp`.
- Tote Helden bleiben sonst für den Rest des Laufs tot.

Verwandt: [[Roguelike-Läufe]], [[Remotes und Befehle]], [[Einheiten und Helden]], [[roguelike-design]]
