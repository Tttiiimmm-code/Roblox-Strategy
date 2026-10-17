---
tags: [architektur, modul, client]
---
# Client-Module (`src/client`)

| Modul | Aufgabe |
|---|---|
| `Main.client` | Eingabe (Maus/Touch), Reichweiten, Bewegungs- und Kampfvorschau |
| `UIKit` | gemeinsame UI-Bausteine und Designsystem (Glas, Chrom, Jelly-Knöpfe, Schriften), Skalierung → [[Oberfläche und Handy]] |
| `UI` | Kampf-HUD: Phase, Hinweise, Aktionsmenü, Level-Up |
| `MenuUI` | Thronsaal-Menü, Sammlung, Tutorial-Ergebnis |
| `RunUI` | Teamwahl, Levelwahl-Karten, Lager, Lauf-Ergebnis → [[Roguelike-Läufe]] |
| `CollectionUI` | Rekrutierung und Kaserne → [[Rekrutierung]] |
| `TutorialGuide` | Eingabefilter und Markierungen → [[Tutorial]] |
| `Hub` | Einrichtungen, Thron-Schnellmenü → [[Thronsaal-Hub]] |
| `CameraController` | WASD/Ziehen, Q/E/Zwei-Finger drehen, Zoom/Pinch, Zoomgrenze aus Brett-/Inselgröße |
| `ForestOutlines` | Wald-Umrisse (Highlights) im gemeinsamen Highlight-Budget |
| `UnitAnimator` | Idle, Laufen, Angriffe je Waffe, Treffer |
| `BattleScene` | eigene Kampfkulisse |
| `Atmosphere` | Licht-/Effekt-Presets aus `Config.FEEL` |
| `SoundPlayer` | Klänge abspielen |

Siehe [[Architektur]].
