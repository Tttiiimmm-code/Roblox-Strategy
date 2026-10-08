# PLAN: Roguelike Phase 1 – Lauf-Grundgerüst im Grasland

Ziel: Ein spielbarer Lauf über die 5 Grasland-Level: Lauf starten (3 Helden wählen) → vor jedem Level aus 2–3 zufällig erzeugten Optionen wählen → kämpfen → Teilheilung, Tote bleiben tot → nächste Wahl. Lauf endet, wenn alle Helden tot sind, nach Level 5 (vorläufiges Ende, weitere Gebiete folgen) oder durch Aufgeben. Verlassen und wiederkommen → direkt zurück in den Lauf.
Branch: `feature/lauf-phase1` (existiert, von `docs/roguelike-design`)
Kontext: **`docs/roguelike-design.md` lesen** (Entscheidungen + Phasen). Diese Phase setzt nur Phase 1 um. **Alle Zahlen sind Platzhalter** (Werte WIP) und gehören zentral in `RunConfig`.

**Bestehender Code (Anknüpfungspunkte)**
- `src/server/Main.server.luau`: ein globaler `state` (ein Brett pro Server), `setupStage(stageId, diffId)` baut aus `Stages.get(id)` (`map`, `slots`, `enemies`, `region`) das Brett; `BeginBattle` stellt Helden aus dem Profil auf (`spawnHero`); `checkResult` (Niederlage bisher = Lord tot); `finishBattle` (Sterne/Gold, `writeBackHeroes` übernimmt Level/EP auch gefallener Helden); `handleCommand` mit Befehlen `StartStage`, `Retry`, `ToLobby`, `BeginBattle`, `Act`, `EndTurn`, `Undo`.
- `src/shared/Stages.luau` (Missionen, Regionen), `src/shared/Config.luau` (`TERRAIN` mit `cost.foot`/`cost.horse`), `src/shared/UnitData.luau` (`Enemies`: `brigand`, `soldier`, `javelin`, `archer` …), `src/server/ProfileStore.luau` (`normalize`), Client: `src/client/MenuUI.luau` (Hub-Menü, Weltkarte, Prep, Ergebnis), `src/client/Main.client.luau` (Laden/`startLoading`/`missionReady`, Befehle senden), `src/client/UIKit.luau` (Theme).

**Leitlinien**
- Server ist autoritativ: Client sendet nur Wünsche (`StartRun`, `ChooseLevel`, `ResumeLevel`, `AbandonRun`), Server prüft Besitz, Lauf-Zustand, Index-Grenzen.
- Bestehende Missionen (Weltkarte, Sterne, Schwierigkeit) **bleiben in dieser Phase unverändert spielbar**; Umbau zum Tutorial ist Phase 2. Lauf-Kämpfe dürfen Sterne/Schwierigkeit nicht anfassen.
- Bestehende Kampflogik wiederverwenden (keine Kopien): `setupStage` so umbauen, dass es eine fertige Stage-Tabelle annehmen kann (z. B. `setupBattle(stage, opts)`; `setupStage(id, diff)` ruft das weiterhin auf).
- Profil-Schema nur ergänzen; alte Profile über `normalize` weiterführen; kaputter/unbekannter Lauf-Stand → verwerfen statt abstürzen.
- Ein Commit pro Schritt, `scripts/check.ps1` = `OK` nach jedem Schritt.

## Schritte

- [x] 1. **Konfiguration** – neue Datei `src/shared/RunConfig.luau`
  - Platzhalter (Kommentar „Werte WIP“): `START_TEAM = 3`, `LEVELS_PER_REGION = 5`, `REGIONS = { "greenland" }` (weitere folgen), `PARTIAL_HEAL = 0.3`, `OPTIONS_MIN = 2`, `OPTIONS_MAX = 3`, Gegnerbudget/-level je Tiefe (z. B. Anzahl 4 + Tiefe, Level 1 + Tiefe), Belohnung je Tiefe (Gold und Edelsteine steigen mit der Tiefe – **kein** Prozentabzug beim Scheitern), Mindestabstand Gegner ↔ Startfelder.
  - **Themen** (Gegnerschwerpunkt) als Daten: z. B. `axe` → `brigand`, `lance` → `soldier`/`javelin`, `bow` → `archer`; je Thema Name, Symbol (Emoji/Text, später Bild), Gegnerarten, Anteil Schwerpunkt (z. B. 0.6). Belohnungsarten in Phase 1: `gold`, `gems`.
  - Fertig, wenn: Modul lädt, keine Lauf-Zahl steht verstreut in anderer Logik.

- [x] 2. **Bausteine + Generator** – neue Dateien `src/shared/MapChunks.luau`, `src/shared/LevelGen.luau`
  - `MapChunks.greenland`: mindestens 10 handgemachte 5×4-Stücke aus `. F M W H B` (Wald-Gruppen, Hügel/Berg, Bach mit Brücke, kleine Festung …). Brett 10×8 = 2×2 Stücke, je Stück zufällig gespiegelt (horizontal/vertikal).
  - `LevelGen.generate(seed, regionId, depth, themeId, teamSize)` → `{ map, slots, enemies, region, theme }` im Format von `Stages.List`-Einträgen. **Rein deterministisch** mit eigenem kleinem PRNG im Modul (kein `Random`/`math.random`, damit es auch im reinen Luau-Test läuft): gleicher Seed → identisches Level.
  - Startzone: untere 2 Reihen; dort `teamSize` passierbare Startfelder (bis 6 vorsehen). Gegner in der oberen Hälfte auf passierbaren Feldern, Mindestabstand (Manhattan) zu allen Startfeldern aus `RunConfig`, Anzahl/Level/Schwerpunkt aus `RunConfig`.
  - **Lösbarkeitsprüfung:** Wegsuche (Bewegungstyp `foot`, Kosten aus `Config.TERRAIN`) – jedes Gegnerfeld ist passierbar und von jedem Startfeld erreichbar; Anteil unpassierbarer Felder ≤ Grenze. Fehlschlag → nächster abgeleiteter Seed, max. z. B. 50 Versuche, danach sicheres Rückfall-Level (offene Ebene).
  - `LevelGen.makeOptions(runSeed, depth, regionId)` → 2–3 Optionen `{ themeId, reward = { kind, amount }, seed }` (deterministisch aus Lauf-Seed + Tiefe; Themen in einer Wahl nicht doppelt).
  - Fertig, wenn: Prüfskript aus Schritt 3 grün.

- [ ] 3. **Prüfskript Generator** – neue Dateien `tests/levelgen.test.luau`, `scripts/test-levelgen.ps1`
  - Läuft mit `tools/luau/luau.exe` ohne Roblox: kleine Stubs für `Color3`, `Enum`, `Vector2` usw. und ein `require`-Ersatz, der `Config`, `RunConfig`, `MapChunks`, `LevelGen` aus `src/shared` lädt (Ansatz frei, aber **committet** und mit einem Befehl startbar).
  - Prüft für 1 000 Seeds × Tiefe 1–5 × alle Themen: Kartengröße 10×8, nur erlaubte Zeichen, Startfelder passierbar und eindeutig, Gegner auf passierbaren Feldern, Mindestabstand eingehalten, alle Gegner erreichbar, Schwerpunkt-Anteil ungefähr eingehalten, Determinismus (zweimal gleicher Seed → gleiches Ergebnis), Optionen 2–3 ohne doppeltes Thema. Ausgabe: Anzahl Prüfungen, Rückfall-Level-Quote (soll ≈ 0 sein).
  - `scripts/check.ps1` bleibt unverändert; in `AGENTS.md` unter „Befehle“ eine Zeile für das Prüfskript ergänzen.
  - Fertig, wenn: `powershell -ExecutionPolicy Bypass -File scripts/test-levelgen.ps1` → OK, Exit 0.

- [ ] 4. **Lauf-Zustand im Profil** – `src/server/ProfileStore.luau`
  - `profile.run = nil | { seed, region, depth (1..), team = { [heroId] = { hp, alive } }, order = { heroId… }, options = { … }, current = optionIndex | nil, earned = { gold, gems }, cleared = Anzahl }`. In `load` übernehmen, in `normalize` prüfen (Typen, Helden im Besitz und bekannt, Indizes gültig; sonst `run = nil`).
  - `profilePayload` (Main) liefert eine Kopie des Laufs an den Client.
  - Fertig, wenn: alte Profile ohne `run` laden unverändert; manipulierter `run` wird verworfen (geprüft, Ergebnis in Notizen).

- [ ] 5. **Server-Ablauf** – `src/server/Main.server.luau` (ggf. neues Modul `src/server/RunService.luau`, wenn `Main` sonst zu groß wird)
  - `StartRun { heroes }`: nur ohne laufenden Lauf und außerhalb eines Kampfes; genau `START_TEAM` eigene, verschiedene Helden (Leon frei wählbar, keine Pflicht). Seed serverseitig, `depth = 1`, HP = volle Max-KP des Helden (inkl. Verschmelzungs-KP wie `spawnHero`), Optionen erzeugen, speichern.
  - `ChooseLevel { index }`: gültige Option → `current` setzen und speichern (**Wahl ist ab jetzt fest**), Level per `LevelGen.generate` bauen, lebende Lauf-Helden mit ihren gespeicherten HP automatisch auf die Startfelder stellen (kein Prep-Bildschirm), Phase `Player`.
  - `ResumeLevel`: Lauf mit gesetztem `current` → dasselbe Level von vorne (gleicher Seed, HP-Stand vor dem Level).
  - Im Lauf-Kampf: **Niederlage = keine eigene Einheit mehr übrig** (Lord-Regel nur für Story-Missionen); `Undo` im Lauf deaktiviert (Rückblende kommt in Phase 4 als Item); `Retry`/`StartStage` während eines Laufs abgelehnt.
  - **Sieg:** `writeBackHeroes` (EP/Level bleiben, auch für Gefallene), gefallene Helden `alive = false`, Überlebende HP übernehmen, dann Teilheilung `PARTIAL_HEAL`; Belohnung der Option sofort ins Profil (`gold`/`gems`, `earned` mitzählen); `cleared += 1`, `depth += 1`, `current = nil`, neue Optionen; speichern. Nach `LEVELS_PER_REGION` × Anzahl `REGIONS` Leveln → Lauf geschafft (vorläufiges Ende): `run = nil`, Ergebnis mit Zusammenfassung.
  - **Niederlage:** Lauf endet (`run = nil`), verdiente Belohnungen bleiben, EP zurückschreiben, speichern, Ergebnis mit Zusammenfassung.
  - `AbandonRun`: jederzeit (auch mitten im Kampf; eine laufende Gegnerphase erst abwarten wie in `PlayerRemoving`) → Lauf endet wie Niederlage, zurück in die Lobby.
  - **Spieler verlässt mitten im Level:** Kampf abbrechen wie bisher; `run.current` bleibt gesetzt, HP-Stand bleibt der vor dem Level → beim nächsten Mal `ResumeLevel`.
  - `snapshot()` um Laufinfos fürs HUD ergänzen (z. B. `run = { depth, region, themeId, totalLevels }` während eines Lauf-Kampfs).
  - Fertig, wenn: statische Durchsicht aller Befehle inkl. Ablehnung ungültiger Wünsche; Ergebnis in Notizen.

- [ ] 6. **Client-Oberfläche** – neues Modul `src/client/RunUI.luau` (über `UIKit`), Anbindung in `MenuUI.luau`/`Main.client.luau`
  - Thronsaal-Menü: Knopf **„Lauf starten“** → Teamwahl (3 aus der Sammlung; Karten wie im Prep-Bildschirm wiederverwenden, wo sinnvoll) → `StartRun`.
  - **Wahl-Bildschirm:** „Grasland – Level x / 5“, Team-Leiste (Name, KP-Balken, Gefallene ausgegraut), 2–3 Options-Karten (Themen-Symbol + Name, Belohnungs-Symbol + Menge), Knopf **„Aufgeben“** mit Bestätigung. Große Touch-Ziele (Handy).
  - Ist `current` gesetzt: statt Wahl ein Knopf **„Level erneut starten“** (`ResumeLevel`) mit kurzem Hinweis, dass das abgebrochene Level von vorne beginnt.
  - **Beim Spielstart mit laufendem Lauf direkt den Wahl-Bildschirm zeigen**, nicht den Hub.
  - Im Kampf: HUD-Hinweis Tiefe/Thema; „Aufgeben“ (mit Bestätigung) im Kampfmenü.
  - Ergebnis nach Lauf-Level: Sieg → Belohnung, geheilte KP → „Weiter“ zum Wahl-Bildschirm. Lauf-Ende (Niederlage/geschafft/aufgegeben) → Zusammenfassung (geschaffte Level, verdientes Gold/Edelsteine) → „Zum Thronsaal“.
  - Lade-Ablauf (`startLoading`/`missionReady`) für Lauf-Level wiederverwenden bzw. verallgemeinern, damit kein halbfertiges Brett zu sehen ist.
  - Fertig, wenn: statische Prüfung der Bildschirmwechsel; Texte auf Deutsch; keine Sterne/Schwierigkeit in Lauf-Bildschirmen.

- [ ] 7. **Doku + Abschluss** – `docs/roguelike-design.md` (Phase 1 als umgesetzt markieren, Platzhalterwerte nennen), Hinweis für den Nutzer: **Servergröße 1** in den Roblox-Spieleinstellungen (nicht per Code setzbar). `scripts/check.ps1` = `OK`, `scripts/test-levelgen.ps1` = OK, `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler. Devlog-Eintrag **#23** „Roguelike Phase 1“ (#23, weil #21/#22 auf einem anderen Branch liegen), „Nächste Schritte“ ergänzen. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Thronsaal → „Lauf starten“ → 3 Helden wählen → Wahl-Bildschirm zeigt 2–3 Optionen mit Symbolen
- [ ] Option wählen → Brett passt zum Thema (z. B. viele Bogenschützen), Helden stehen unten, keine Gegner direkt daneben
- [ ] Level gewinnen → Belohnung, KP teilweise geheilt, gefallener Held ausgegraut → neue Optionen
- [ ] Mitten im Level Spiel beenden, neu starten → direkt im Lauf, „Level erneut starten“ startet dasselbe Level von vorne
- [ ] „Aufgeben“ (im Wahl-Bildschirm und im Kampf) → Zusammenfassung → Thronsaal, Gold/Edelsteine behalten
- [ ] Alle Helden sterben → Lauf vorbei, Zusammenfassung
- [ ] 5 Level geschafft → „Lauf geschafft“
- [ ] Bisherige Missionen über die Weltkarte funktionieren weiter
- [ ] Kein roter Fehler im Output; auf dem Handy bedienbar

## Nicht anfassen
- Bestehende Missionen, Sterne, Schwierigkeitsstufen, Weltkarte (Phase 2)
- Kampfregeln (`Combat`), KI, Brettaufbau außer dem Umbau `setupStage` → Stage-Tabelle
- Rekrutierung, Kaserne, Figuren-/Mesh-Code

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist – **Designfragen nicht selbst entscheiden**, der Nutzer will gefragt werden)

## Notizen (Codex)
-
