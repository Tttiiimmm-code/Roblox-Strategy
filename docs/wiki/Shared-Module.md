---
tags: [architektur, modul]
---
# Shared-Module (`src/shared`)

| Modul | Aufgabe |
|---|---|
| `Config` | Gelände, Farben, Timings, UI-Skalierung, Kamera, Umgebung, Insel (`Config.ISLAND`) → [[Thronlande]] |
| `UnitData` | Waffen, Klassen, Seltenheiten, Helden, Gegner und Bossfähigkeiten → [[Einheiten und Helden]] |
| `Stages` | Tutorial-Missionen und Gebiete (Farben, Wasser) |
| `Tutorial` | Schritt-Daten und Prüfungen der Tutorial-Wünsche → [[Tutorial]] |
| `Recruit` | Raten, Pity, Kosten, Verschmelzen → [[Rekrutierung]] |
| `RunConfig` | Lauf-Werte: Brettmaße, Optionen, Bosse, Lager, Belohnungen → [[Roguelike-Läufe]] |
| `LevelGen` | deterministischer Levelgenerator → [[Levelgenerator]] |
| `MapChunks` | 8 × 4-Kartenstücke mit Rand-Kennungen |
| `Grid` | Gelände, Reichweiten, Dijkstra-Wegfindung, Standhöhen |
| `Combat` | Kampfformeln (GBA-FE-Stil) → [[Kampfsystem]] |
| `CharacterBuilder` | R15-Modelle mit Waffen und Seltenheits-Deko |
| `ChibiBuilder` | eigene Teile-Figuren (Brett, Porträts) |
| `UnitShadow` | feste Bodenschatten |
| `Sounds` | Asset-IDs und Lautstärken |

Siehe [[Architektur]].
