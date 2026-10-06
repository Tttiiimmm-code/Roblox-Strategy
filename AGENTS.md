# AGENTS.md – gemeinsame Projektregeln (Claude + Codex)

## Projekt
- **Zweck:** Rundenbasiertes Taktikspiel im Stil von Fire Emblem für Roblox – Thronsaal-Hub, Missionen mit Schwierigkeitsstufen/Sternen, Helden mit Seltenheiten, Rekrutierung (Gacha) und Kaserne.
- **Stack:** Luau (Roblox), Projektstruktur mit **Rojo 7.4.4** (`default.project.json`), Roblox Studio zum Testen.
- **Stand:** Grundgerüst – nichts ist final, Werte/Layouts/Texte dürfen sich ändern. Historie: `docs/DEVLOG.md`.
- **Sprache:** Kommentare, UI-Texte, Commits und Doku auf **Deutsch**.

### Verzeichnisse
| Pfad | Landet in Roblox | Inhalt |
|---|---|---|
| `src/shared/` | ReplicatedStorage.Shared | Daten & Logik für Server **und** Client (Config, UnitData, Stages, Recruit, Grid, Combat, CharacterBuilder) |
| `src/server/` | ServerScriptService.Server | `Main.server.luau` (Spielzustand, Befehle), Builder für Brett/Thronsaal, KI, ProfileStore (DataStore) |
| `src/client/` | StarterPlayerScripts.Client | `Main.client.luau` (Eingabe), UI-Module, Kamera, Animationen, Hub |
| `docs/` | – | `DEVLOG.md` (Entwicklungstagebuch), Recherche |
| `tools/` | – | `rojo.exe`, `luau/` (Compiler/Analyzer) – nicht im Git |
| `scripts/` | – | Hilfsskripte (`check.ps1`) |

### Befehle (PowerShell, im Projektordner)
- **Prüfen (Pflicht vor jedem Abschluss):** `powershell -ExecutionPolicy Bypass -File scripts/check.ps1`
  → Syntax aller `.luau` + undefinierte Variablen. Muss mit `OK` / Exit 0 enden.
- **Spieldatei bauen:** `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx`
- **Live-Sync für Studio:** `tools/rojo.exe serve default.project.json` (Port 34872; in Studio als Adresse **`127.0.0.1`** eintragen, nicht `localhost`)
- **Automatische Tests:** gibt es noch keine. Spielverhalten wird **manuell in Roblox Studio** vom Nutzer getestet (siehe unten).

## Arbeitsteilung
| Rolle | Wer | Aufgabe |
|---|---|---|
| Planer/Reviewer | Claude | Architektur, `PLAN.md` schreiben, schwierige Bugs, Review von Codex-Arbeit |
| Umsetzer | Codex | Schritte aus `PLAN.md` umsetzen, `check.ps1` ausführen, Fehler beheben |
| Tester | Nutzer | Spielt in Roblox Studio (Rojo Connect → Play) bzw. auf dem Handy, meldet Ergebnis |

Regel: Wer den Code geschrieben hat, reviewt ihn nicht selbst.

## Übergabe über PLAN.md
- Claude schreibt Aufgaben als nummerierte Schritte in `PLAN.md` (Ziel, betroffene Dateien, prüfbares Akzeptanzkriterium).
- Codex arbeitet die Schritte der Reihe nach ab, hakt sie ab (`[x]`) und notiert unter „Notizen (Codex)" Abweichungen.
- Nichts umsetzen, was nicht in `PLAN.md` steht. Bei Unklarheit: Frage unter „Offene Fragen" eintragen und **stoppen**.
- Ist ein Plan fertig, kommt der nächste Plan in dieselbe Datei (alter Plan wird durch den Devlog-Eintrag dokumentiert).
- **Signal an Claude (Pflicht für Codex):** Als allerletzte Aktion eines Durchgangs die Datei `.handoff/status` schreiben (Ordner ggf. anlegen, nicht committen):
  - `fertig` – alle Schritte abgehakt, Check grün, committet. **Nicht pushen** (braucht Netzwerk-Freigabe) – Claude pusht nach dem Review.
- **Keine Rückfragen im Terminal:** Claude sieht das Codex-Fenster nicht. Unklarheiten/Entscheidungen immer unter „Offene Fragen" in `PLAN.md` eintragen, `.handoff/status` = `frage` schreiben und stoppen. Befehle, die eine Freigabe außerhalb der Sandbox bräuchten (Netzwerk, Dateien außerhalb des Projekts, `git push`, destruktive Git-Befehle), nicht ausführen, sondern ebenfalls als Frage eintragen.
  - `frage` – Frage unter „Offene Fragen" eingetragen, Arbeit gestoppt.
  Claude wartet auf diese Datei und startet danach automatisch Review bzw. Antwort.

## Regeln für beide
- Kleine, fokussierte Änderungen; keine Refactorings nebenbei.
- Vor dem Abschluss: `scripts/check.ps1` laufen lassen, Ergebnis kurz melden. Ein grüner Check ersetzt **nicht** den Test in Studio – Teststatus ehrlich angeben („ungetestet" vs. „vom Nutzer bestätigt").
- **Devlog-Pflicht:** Nach jedem abgeschlossenen Plan einen nummerierten Eintrag in `docs/DEVLOG.md` anhängen (Ziel · Umsetzung · Entscheidungen · Probleme · Teststatus) und „Nächste Schritte" aktualisieren.
- Nur gezielt lesen: erst `rg`/`grep`, dann die konkreten Dateien – nicht das ganze Repo einlesen.
- Logs/Ausgaben kürzen (`| Select-Object -Last 50`, `rg`), nie komplett ausgeben.
- Keine Secrets (Passwörter, API-Keys, Cookies, Roblox-Zugangsdaten) in Code oder Commits.
- Commits: kurze Nachricht auf Deutsch, Präfix `feat:`, `fix:`, `test:`, `refactor:`, `docs:`. Arbeit auf Feature-Branches, nicht direkt auf `main`.

## Code-Stil & Architektur (Luau/Roblox)
- **Server ist autoritativ:** Der Client schickt nur Wünsche über `Remotes.Command` (`{ type = "...", ... }`); der Server prüft alles (Besitz, Reichweite, Phase, Kosten). Nie einem Client-Wert vertrauen.
- **Werte zentral:** Balancing-Zahlen gehören in Konfigurationsmodule (`Config`, `UnitData`, `Stages`, `Recruit`), nicht verstreut in Logik.
- **Shared vs. Client/Server:** Reine Daten/Formeln in `src/shared`; UI nur in `src/client`; DataStore/Spielzustand nur in `src/server`.
- `require` relativ: `require(script.Parent.X)` innerhalb eines Ordners, `ReplicatedStorage:WaitForChild("Shared")` von außen.
- Einrückung mit Tabs, `local` für alles, keine globalen Variablen, Funktionen vor ihrer Verwendung definieren (Analyzer meldet sonst „Unknown global").
- Kommentare kurz und auf Deutsch, nur wo das *Warum* nicht offensichtlich ist.
- UI über `client/UIKit.luau` bauen (Theme: blaue Fenster, Goldrand); Designgröße 1280×720, Handy-Bedienung (Touch, große Buttons) mitdenken – 72 % der Roblox-Spieler sind mobil.
- **Profil-Schema (DataStore) ändern:** fehlende Felder in `ProfileStore.normalize` ergänzen, alte Profile dürfen nicht kaputtgehen.
- **Zufallsitems gegen Robux/kaufbare Währung:** alle Wahrscheinlichkeiten müssen vor dem Kauf sichtbar sein (Roblox-Regel) – siehe `Recruit.odds()` und `CollectionUI`.

## Manueller Test (Nutzer)
1. `tools/rojo.exe serve default.project.json` läuft
2. Roblox Studio → Plugins → Rojo → Adresse `127.0.0.1`, Port `34872` → Connect
3. Play (F5); Fehler stehen in Ansicht → Output (rote Zeilen)
4. Handy: Studio → Datei → Auf Roblox veröffentlichen (privat) → Roblox-App → Profil → Kreationen
