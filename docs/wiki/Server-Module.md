---
tags: [architektur, modul, server]
---
# Server-Module (`src/server`)

| Modul | Aufgabe |
|---|---|
| `Main.server` | Spielzustand, Befehlsprüfung, Phasen, Tutorial, Läufe, Sieg/Niederlage → [[Remotes und Befehle]] |
| `RunService` | Laufdaten und Übergänge (Start, Levelwahl, Abschluss) → [[Roguelike-Läufe]] |
| `ProfileStore` | Profile per DataStore, Migration → [[Profil und Speichern]] |
| `EnemyAI` | bester Angriff in Reichweite, sonst vorrücken |
| `BoardBuilder` | baut das Spielfeld aus Parts |
| `EnvironmentAssets` | geprüfte Umgebungs-Vorlagen → [[umgebung-assets]] |
| `HubBuilder` | Thronsaal → [[Thronsaal-Hub]] |
| `UnitVisuals` | Figuren platzieren, laufen, KP-Anzeige, Tod |

Siehe [[Architektur]].
