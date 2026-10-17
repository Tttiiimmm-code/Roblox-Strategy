---
tags: [architektur, server]
---
# Remotes und Befehle

Angelegt in `src/server/Main.server.luau` im Ordner `ReplicatedStorage.Remotes`.

| Remote | Art | Richtung | Zweck |
|---|---|---|---|
| `Command` | RemoteEvent | Client → Server | Wünsche `{ type = "...", ... }` |
| `StateUpdate` | RemoteEvent | Server → Client | Brett-/Spielzustand |
| `BattleEvent` | RemoteEvent | Server → Client | Kampfabläufe für Animationen |
| `ProfileUpdate` | RemoteEvent | Server → Client | Gold, Edelsteine, Helden |
| `GetState` | RemoteFunction | Client → Server | aktuellen Zustand abfragen |
| `GetProfile` | RemoteFunction | Client → Server | Profil abfragen |

## Befehlstypen (`Command.type`)
| Typ | Bereich |
|---|---|
| `Act` | Einheit bewegen + Warten/Angriff |
| `Undo` | Zug zurücknehmen |
| `EndTurn` | Spielerphase beenden |
| `SetSpeed`, `SetBattleScenes` | Einstellungen |
| `Recruit` | Rekrutierung → [[Rekrutierung]] |
| `StartRun`, `ChooseLevel`, `ResumeLevel`, `AbandonRun`, `ToLobby` | [[Roguelike-Läufe]] |
| `CampSwap`, `CampRevive`, `LeaveCamp` | Lager → [[Bosse und Lager]] |
| `StartTutorial`, `TutorialChoice`, `TutorialStep` | [[Tutorial]] |

> [!warning] Regel
> Nie einem Client-Wert vertrauen – jeder Befehl wird serverseitig vollständig geprüft. Neue Befehle nach dem Muster von `Recruit` in `Main.server.luau` anlegen.
