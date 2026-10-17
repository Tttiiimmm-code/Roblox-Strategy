---
tags: [architektur, modul, server]
---
# Server-Module (`src/server`)

| Modul | Aufgabe |
|---|---|
| `Main.server` | Spielzustand, Befehlsprüfung, Phasen, Tutorial, Läufe, Sieg/Niederlage → [[Remotes und Befehle]] |
| `RunService` | Laufdaten und Übergänge (Start, Levelwahl, Lager, Abschluss) → [[Roguelike-Läufe]] |
| `BossAbilities` | Boss-/Minibossfähigkeiten aus Gegnerdaten (Verstärkung, Kriegsschrei) → [[Bosse und Lager]] |
| `ProfileStore` | Profile per DataStore, Migration → [[Profil und Speichern]] |
| `EnemyAI` | bester Angriff in Reichweite, sonst vorrücken; `stationary`/`hold_until_hurt` |
| `BoardBuilder` | baut das Spielfeld (Felder, Wasser, Brücken, Deko, Höhen) |
| `LandscapeBuilder` | Landschaft um das Brett: Inselumriss bzw. Terrain-Tal → [[Thronlande]] |
| `IslandBuilder` | Inselwand, Kristalle, Wolkenmeer, Nebeninseln → [[Thronlande]] |
| `EnvironmentAssets` | geprüfte Umgebungs-Vorlagen (Grasland-/Thronlande-Paket) → [[umgebung-assets]] |
| `HubBuilder` | Thronsaal → [[Thronsaal-Hub]] |
| `UnitVisuals` | Figuren platzieren, laufen, KP-Anzeige, Tod |

Siehe [[Architektur]].
