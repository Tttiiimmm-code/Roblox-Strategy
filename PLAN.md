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

- [x] 3. **Prüfskript Generator** – neue Dateien `tests/levelgen.test.luau`, `scripts/test-levelgen.ps1`
  - Läuft mit `tools/luau/luau.exe` ohne Roblox: kleine Stubs für `Color3`, `Enum`, `Vector2` usw. und ein `require`-Ersatz, der `Config`, `RunConfig`, `MapChunks`, `LevelGen` aus `src/shared` lädt (Ansatz frei, aber **committet** und mit einem Befehl startbar).
  - Prüft für 1 000 Seeds × Tiefe 1–5 × alle Themen: Kartengröße 10×8, nur erlaubte Zeichen, Startfelder passierbar und eindeutig, Gegner auf passierbaren Feldern, Mindestabstand eingehalten, alle Gegner erreichbar, Schwerpunkt-Anteil ungefähr eingehalten, Determinismus (zweimal gleicher Seed → gleiches Ergebnis), Optionen 2–3 ohne doppeltes Thema. Ausgabe: Anzahl Prüfungen, Rückfall-Level-Quote (soll ≈ 0 sein).
  - `scripts/check.ps1` bleibt unverändert; in `AGENTS.md` unter „Befehle“ eine Zeile für das Prüfskript ergänzen.
  - Fertig, wenn: `powershell -ExecutionPolicy Bypass -File scripts/test-levelgen.ps1` → OK, Exit 0.

- [x] 4. **Lauf-Zustand im Profil** – `src/server/ProfileStore.luau`
  - `profile.run = nil | { seed, region, depth (1..), team = { [heroId] = { hp, alive } }, order = { heroId… }, options = { … }, current = optionIndex | nil, earned = { gold, gems }, cleared = Anzahl }`. In `load` übernehmen, in `normalize` prüfen (Typen, Helden im Besitz und bekannt, Indizes gültig; sonst `run = nil`).
  - `profilePayload` (Main) liefert eine Kopie des Laufs an den Client.
  - Fertig, wenn: alte Profile ohne `run` laden unverändert; manipulierter `run` wird verworfen (geprüft, Ergebnis in Notizen).

- [x] 5. **Server-Ablauf** – `src/server/Main.server.luau` (ggf. neues Modul `src/server/RunService.luau`, wenn `Main` sonst zu groß wird)
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

- [x] 6. **Client-Oberfläche** – neues Modul `src/client/RunUI.luau` (über `UIKit`), Anbindung in `MenuUI.luau`/`Main.client.luau`
  - Thronsaal-Menü: Knopf **„Lauf starten“** → Teamwahl (3 aus der Sammlung; Karten wie im Prep-Bildschirm wiederverwenden, wo sinnvoll) → `StartRun`.
  - **Wahl-Bildschirm:** „Grasland – Level x / 5“, Team-Leiste (Name, KP-Balken, Gefallene ausgegraut), 2–3 Options-Karten (Themen-Symbol + Name, Belohnungs-Symbol + Menge), Knopf **„Aufgeben“** mit Bestätigung. Große Touch-Ziele (Handy).
  - Ist `current` gesetzt: statt Wahl ein Knopf **„Level erneut starten“** (`ResumeLevel`) mit kurzem Hinweis, dass das abgebrochene Level von vorne beginnt.
  - **Beim Spielstart mit laufendem Lauf direkt den Wahl-Bildschirm zeigen**, nicht den Hub.
  - Im Kampf: HUD-Hinweis Tiefe/Thema; „Aufgeben“ (mit Bestätigung) im Kampfmenü.
  - Ergebnis nach Lauf-Level: Sieg → Belohnung, geheilte KP → „Weiter“ zum Wahl-Bildschirm. Lauf-Ende (Niederlage/geschafft/aufgegeben) → Zusammenfassung (geschaffte Level, verdientes Gold/Edelsteine) → „Zum Thronsaal“.
  - Lade-Ablauf (`startLoading`/`missionReady`) für Lauf-Level wiederverwenden bzw. verallgemeinern, damit kein halbfertiges Brett zu sehen ist.
  - Fertig, wenn: statische Prüfung der Bildschirmwechsel; Texte auf Deutsch; keine Sterne/Schwierigkeit in Lauf-Bildschirmen.

- [x] 7. **Doku + Abschluss** – `docs/roguelike-design.md` (Phase 1 als umgesetzt markieren, Platzhalterwerte nennen), Hinweis für den Nutzer: **Servergröße 1** in den Roblox-Spieleinstellungen (nicht per Code setzbar). `scripts/check.ps1` = `OK`, `scripts/test-levelgen.ps1` = OK, `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler. Devlog-Eintrag **#23** „Roguelike Phase 1“ (#23, weil #21/#22 auf einem anderen Branch liegen), „Nächste Schritte“ ergänzen. Committen, pushen, `.handoff/status` = `fertig`.

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
- Abschluss: check.ps1 OK (31 Dateien), test-levelgen.ps1 OK (15.000 Level/5.000 Optionen, Rückfall 0 %), Rojo-Build erfolgreich. Designstand und Devlog #23 aktualisiert. Servergröße 1 vom Nutzer einzustellen; Studio-/Handy-Tests und Claude-Review offen. Ein Commit je Planschritt auf feature/lauf-phase1.
- Schritt 6: Bildschirmwechsel statisch nachvollzogen und mit RunUI-Stubs ausgeführt: Hub → Teamwahl → Wahl/Resume → Ladeoverlay → Kampf → Zwischen-/Endergebnis → Wahl bzw. Hub. Laufbildschirme zeigen keine Missionssterne/Schwierigkeit; Touch-Ziele vergrößert, tote Teammitglieder grau, Leon ohne Pflichtplatz. Die echten Main-Befehle zusätzlich mit Roblox-Stubs ausgeführt: ungültige Wünsche/Besitz, feste Wahl/Resume, Profilkopie, Sieg ohne Lord, Belohnungen ohne Sterne, Aufgeben/Niederlage sowie unveränderte Story-Lordregel – OK.
- Ladefehler: ToLobby führt bei einem Lauf intern zurück zur Laufwahl mit festgehaltener Wahl/KP, nicht zum Hub-Zugang. Das Ladeoverlay prüft zusätzlich den RunSeed des Bretts; Kamera und Grid nutzen die serverseitige Karte. Studio-/Handy-Darstellung ist noch ungetestet.
- Schritt 5: Befehlsgrenzen statisch nachvollzogen: Start nur in Lobby, exakte eigene Teams ohne Doppelungen, endliche Optionsindizes, feste Wahl, Resume nur außerhalb aktiver Kämpfe; StartStage/Retry/Recruit und Undo während des Laufs gesperrt. Aufgeben wartet laufende Aktionen ab; Besitzerprüfung bleibt aktiv. RunService mit echten Shared-Modulen geprüft (Start/Fehleingaben, Verschmelzungs-KP, Wiederaufnahme, Heilung/Tote, fünf Siege, Niederlage/Aufgeben) – OK. Laufwahl/Abschluss speichern geordnet und vor dem nächsten Übergang; Speicherung bleibt bei fehlendem Studio-API-Zugriff wie bisher nur im Speicher. Review durch Claude und Studio-Tests stehen aus.
- Schritt 3: 15.000 Level- und 5.000 Optionsprüfungen grün; Rückfallquote 0 %. Teamgrößen 1–6 und erzwungener Rückfall geprüft.
- Schritt 4: Echter ProfileStore.load mit DataStore-Stubs geprüft: altes Profil ohne Lauf, gültiger und gewählter Lauf sowie 16 defekte/manipulierte Stände (Seed, Tiefe, Gebiet, Team/Besitz, KP, Optionen/Belohnung, Index einschließlich NaN, Ertrag) – OK; ungültige Läufe werden verworfen.

### Review Todesspeicherung

- **P2 – Resume erzeugt nach einem Tod andere Gegner statt desselben Levels.** Die Änderung in `Main.server.luau:431–433` verkleinert die lebende Mannschaft bereits während des Levels. `RunService.stage:48–49` übergibt beim Resume deshalb eine andere Teamgröße an `LevelGen.generate`; die Startfelder bestimmen dort die zulässigen Gegnerfelder und den weiteren Zufallsverbrauch (`LevelGen.luau:88–105`). Reproduktion mit echten Modulen: Laufseed `2`, erste Option (Optionsseed `1671405102`), drei Starthelden; ersten Helden als gefallen speichern, dann dieselbe Option mit zwei Lebenden erzeugen. Karte identisch, aber Gegner 1 wechselt von `javelin (3,4)` zu `soldier (7,4)`. Das verletzt die feste Wiederaufnahme aus Schritt 5. Empfehlung: die Generierung für das gewählte Level an eine unveränderliche Teamgröße binden und beim Aufstellen nur die lebenden Helden einsetzen.
- **P3 – Frisch Gefallene fehlen im Siegesergebnis.** Durch das vorgezogene `alive = false` überspringt `RunService.finish:74–79` jetzt auch Helden, die erst im gerade beendeten Level gefallen sind. Für sie entsteht kein `info.healed[id]`; `RunUI.luau:172–177` zeigt daher die bisherige Zeile „Name: gefallen“ nicht mehr. Mit echtem `RunService.finish` reproduziert: Tod bleibt korrekt gespeichert, aber der Ergebnis-Eintrag fehlt. Empfehlung: Todesanzeige unabhängig von der Heilung erzeugen; bereits in früheren Leveln Gefallene dabei getrennt behandeln.
- **Weitere Prüfpunkte ohne Befund:** Die tatsächliche `battle`-Todesbehandlung wurde mit Roblox-Stubs für einen eigenen Angriff mit tödlichem Gegenangriff und einen Gegnerangriff ausgeführt: `alive = false, hp = 0`, Einheit entfernt. `RunService.finish` belebt Tote beim Sieg nicht wieder und entfernt den Lauf bei Niederlage. Tod des letzten Helden mit tatsächlichem `checkResult` nachvollzogen/ausgeführt: Niederlage, Lauf gelöscht. `RunService.stage` stellt ausschließlich Lebende auf. Echter `ProfileStore.load` mit DataStore-Stubs: einzelner konsistent Toter bleibt tot, alle tot sowie widersprüchliches alive/KP-Paar verwerfen den Lauf.
- **Verlassen/Aufgeben/Undo (statisch):** `PlayerRemoving:838` wartet die gesamte laufende Aktion bzw. Gegnerphase und eine vorgemerkte Aufgabe ab; erst danach werden Brett und Profil freigegeben. Ein direkt nach dem Tod verlassender Spieler wird daher mit der Todesmarkierung gespeichert. `abandonRun:606–620` wartet ebenfalls, übernimmt EP und entfernt/speichert den Lauf. `ToLobby` lässt die Todesmarkierung und die feste Wahl bestehen. Undo bleibt durch `not state.run` serverseitig gesperrt.
- **Parallele Saves:** `ProfileStore.write:147–159` serialisiert Schreibzugriffe pro Spieler. Wartende Aufrufe lesen das aktuelle Profil erst nach Erhalt der Sperre; die Reihenfolge wartender Aufrufe muss deshalb nicht FIFO sein. Coroutine-/DataStore-Stubs mit älterem laufendem Save, Todessave, synchronem Laufabschluss und `release`: keine überlappenden SetAsync-Aufrufe, am Ende `run = nil`, kein Überschreiben des Laufendes durch einen alten Lauf. Die Profilidentitätsprüfung verwirft wartende Saves nach Freigabe. Persistenz bleibt wie bisher bei deaktiviertem API-Zugriff oder fehlgeschlagenem SetAsync ohne Wiederholung eingeschränkt; die Prüfungen simulieren erfolgreiche DataStore-Aufrufe.
- **Teststatus:** `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` → **OK: 31 Dateien**, Exit **0**. Gezielte Luau-Reproduktionen mit echten Modulen und Roblox-/DataStore-Stubs wie oben; Roblox Studio und Handy **ungetestet**. Ausschließlich Review/Dokumentation: die uncommittete Änderung in `Main.server.luau` bleibt unverändert und wird nicht mitcommittet.

### Review Klickfix + Wurfspeer

- **P3 – Ladefehler gibt die Eingabe bis zur Abbruchantwort wieder frei.** In `Main.client.luau:81–95` wird auch bei `failed = true` zunächst `loadingMission = nil` gesetzt, `ToLobby` nur asynchron gesendet und anschließend `resetSelection()` aufgerufen. Ist der letzte Snapshot noch ein eigener, nicht beschäftigter Spielerzug ohne Ergebnis (z. B. Lauf-Level mit unvollständig repliziertem Brett bis zum Lade-Timeout), setzt `canControl()` den Modus auf `Idle`; Auswahl und „Zug beenden“ sind bis zum Lobby-Snapshot wieder bedienbar. Mit den echten Ladeende-/Auswahlfunktionen und einem ToLobby-Stub ohne unmittelbare Serverantwort reproduziert: `Idle`, HUD sichtbar, Tools steuerbar. Der Server prüft die Befehle weiterhin; kein nachgewiesener Schaden am Spielstand. Empfehlung: nach fehlgeschlagenem Laden die Eingabe bis zur Abbruchantwort gesperrt halten und sie nur bei erfolgreichem Ladeende direkt freigeben.
- **Klickfix sonst ohne Befund:** Die Vorwärtsdeklaration `local resetSelection` (Zeile 60) wird durch `function resetSelection()` (Zeile 355) korrekt dem lokalen Binding zugewiesen; Initialisierung, Event-Anbindung und der erste GetState-Aufruf erfolgen danach. Erfolgreiches Lauf-Ladeende setzt ohne weiteren Snapshot `Busy → Idle`. Story-Prep bleibt `Busy`, Ergebnis/Server-Busy/Gegnerphase bleiben gesperrt, ein Ladefehler in der Lobby ebenfalls. Zurücksetzen entfernt Auswahl, Aktionsmenü, Kampfvorschau und Bewegungsvorschau; die getrennten Prep-/Ergebnisfenster von MenuUI bleiben erhalten. Bei einer noch laufenden BattleScene bleibt das HUD verborgen; InputBegan sperrt neue Eingaben, vorhandene Gesten werden beim Szenenstart blockiert/gelöscht. Der Reset stoppt keine Szene und verändert keinen Kampfzustand. Acht Ladeende-Szenarien mit echten Funktionen und UI-/Roblox-Stubs ausgeführt; tatsächliche Darstellung in Studio ungetestet.
- **Wurfspeer ohne Befund:** `farMight = -3` und `farHit = -20` greifen ab Manhattan-Abstand 2 symmetrisch für Angriff und Gegenangriff; verwendet wird das geplante Angriffsfeld, nicht die ursprüngliche Position. Fehlende Waffenfelder fallen auf 0 zurück. Schadensuntergrenze und Trefferbegrenzung bleiben bestehen. `Combat.resolve` verwendet direkt `Combat.forecast`; Client-Vorschau/Kampfszene und `EnemyAI.scoreAttack` beziehen ihre Werte daraus. 294 Kombinationen (alle sieben Waffen gegeneinander, Abstand 1/2, Ebene/Wald/Festung) gegen den HEAD-Stand verglichen und jeweils mit vier kontrollierten RNG-Werten aufgelöst: nur Wurfspeer aus Abstand 2 schwächer, Bögen/Magie/Nahkampf unverändert, Treffer und Schaden entsprechen der Vorschau. Gezielte KI-Zielwahl mit echtem EnemyAI zusätzlich geprüft.
- **Gefahrenanzeige:** `redrawDanger` (Main.client:284–305) verwendet `Grid.ranges` und zeigt ausschließlich erreichbare/angreifbare Felder, keine Schadens-/Trefferwerte. Sie bleibt korrekt unverändert, da minRange/maxRange des Wurfspeers weiterhin 1/2 sind. Reichweite 1 und 2 mit echtem Grid geprüft; eine numerische Gefahrenberechnung existiert hier nicht.
- **Teststatus und Umfang:** `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` → **OK: 31 Dateien**, Exit **0**. Gezielte Luau-Prüfungen wie oben erfolgreich; Roblox Studio/Handy **ungetestet**. Nur PLAN.md wird committet; die drei uncommitteten Codeänderungen bleiben unverändert. Der normale Terminal-Executor scheiterte beim Prozessaufbau (`helper_unknown_error`); Lesen, Luau und der identische PowerShell-Check wurden über den verfügbaren Node-Prozesszugriff ausgeführt.
