# PLAN: Level-Optik Etappe C6 – Zoomgrenze, Bodenmaterialien, saubere Felshügel, Wurzelfüße, Wasserfälle

Ziel: Feinschliff nach dem Studio-/Handy-Test von C5 (Nutzer, 10.10.2026).
Branch: `feature/level-optik-c` (enthält Phase 3, C1–C5)

**Nutzer-Feedback zum C5-Test:**
- **OK:** Aufbau „Missionsaufbau Lauf: Brett 263 ms, Figuren 16 ms“, PC und Handy flüssig, **Wald gut so**, Thronsaal unverändert.
- **Zoom:** Ganz herausgezoomt sieht man das Ende der Karte. Das Herauszoomen soll nur so weit gehen, wie es sinnvoll ist.
- **Spielfeldboden zu grell:** Er soll zum Terrain außerhalb und zu den Baum-/Grasmodellen passen.
- **Felsen (`M`):** Kleine Steine schweben über dem großen Felsen; Anzahl, Farbe und Detailgrad der kleinen Steine passen nicht zum großen Terrain-Felsen. **Füße von Einheiten clippen** durch die großen Felsen. Auf dem Screenshot verdeckt der Felshügel außerdem einen Teil des gelben Zielfelds daneben.
- **Bäume:** Die **Baumfüße fehlen**; die Stämme werden nach unten dünner, das ergibt keinen Sinn. Claude: Yasu's Paket liefert dafür eigene Wurzelstücke (`deco_root_1…5`, „Root Meshes“), die an den Stammfuß gehören; bisher werden sie nur lose als Deko gesetzt.
- **Wasserfälle:** In 10 getesteten Karten keinen gesehen.

**Nutzerentscheidungen (10.10.2026):**
- **Spielfeldboden: Roblox-Materialien** in denselben Materialien/Farben wie das Terrain drumherum (Gras, Erde, Fels; `Config.LANDSCAPE.palette` bzw. Region in `Stages`). Gedämpft, einheitlich. Eigene Texturen können später über `GROUND_TEXTURES` darüber gelegt werden.
- **Wasserfälle:** Sichtbarkeit mit den Terrain-Klippen prüfen und reparieren, **Häufigkeit auf etwa jede 4.–5. Karte** (20–25 % der normalen Laufkarten).
- Nicht in diesem Plan (folgen separat): **eigener 3D-Lagerplatz** (Lichtung mit Lagerfeuer und Zelten, Helden sitzen ums Feuer). **Notfall-Beschwörung** bleibt bei Phase 4.

**Bestehender Code:** `src/client/CameraController.luau` (`maximumZoom()`, `Config.CAMERA.zoomOverviewMin/zoomOverviewScale`), `src/server/LandscapeBuilder.luau` (`zoomMargin = 4.2`, `sculptDistance`, Fernboden, `surface()` für `M`/`C`, `rockFields`), `src/server/BoardBuilder.luau` (Bodenaufbau mit `TERRAIN[ch].color/material`, Standkappen auf `M`, Felsmodelle an `M`/`C`, Waldfelder, `waterfall()`), `src/shared/Config.luau` (`TERRAIN`, `GROUND_TEXTURES`, `GROUND_FLECKS`, `LANDSCAPE`, `ENVIRONMENT.rocks/forest`), `src/shared/Stages.luau` (Regionspaletten), `src/shared/LevelGen.luau` + `RunConfig.WATERFALL_CHANCE` (aktuell 0,56 bedingt, ergibt 15,6 %), Tests `tests/landscape.test.luau`, `tests/walls.test.luau`, `tests/environment-metrics.test.luau`, `tests/levelgen.test.luau`, Messung `scripts/measure-environment.ps1`.

**Leitlinien:** Klickbarkeit, Figurenmitte, Overlays, Brückenhöhen, Umrisse, Determinismus und Part-Fallback bleiben erhalten. Alle Werte WIP in `Config`. Teile/Dreiecke/Terrain-Volumen vorher/nachher in den Notizen. Ein Commit pro Schritt, alle Prüfskripte grün. Geschmacksfragen: zurückhaltende Variante, über Config umstellbar, in den Notizen nennen.

## Schritte

- [x] 1. **Zoomgrenze + kleineres Terrain** – `CameraController`, `Config.CAMERA`, `Config.LANDSCAPE`
  - Bestimme die größte sinnvolle Zoomstufe: Das ganze Brett passt bequem ins Bild (PC 16:9 und Handy quer), aber auch bei allen Kameradrehungen und Brettecken ist **kein Kartenende** zu sehen. Die Grenze leitet sich aus Brettgröße und Landschaftsgröße ab, nicht als freie Zahl. Kleine Bretter (Tutorial) bekommen eine passende kleinere Grenze.
  - Danach die Landschaft (`zoomMargin`, Fernboden, Aufräumbereich) auf das verkleinern, was bei dieser Grenze sichtbar ist, plus Sicherheitsrand. Ziel: kürzerer Aufbau und weniger Terrain zum Übertragen. Der Dunst (`FEEL.atmosphere`) darf so abgestimmt werden, dass der Horizont weich ausläuft.
  - Fertig, wenn: Strahl-/Sichtprüfung (wie C3-Bodentest: vier Ecken, acht Drehungen, 4:3/16:9/21:9, FOV) zeigt bei maximalem Zoom nur Landschaft bzw. Dunst, kein Kartenende; Terrain-Volumen und Aufrufe vorher/nachher in den Notizen.

- [x] 2. **Spielfeldboden aus Roblox-Materialien** – `Config.TERRAIN`, `BoardBuilder` (Bodenaufbau), `Stages`, `Config.LANDSCAPE.palette`
  - Bodenflächen der Felder nutzen Roblox-Materialien passend zum Terrain: Wiese `.` = Grass, Wald `F` = Grass (dunkler) oder LeafyGrass, Weg/Erde = Ground, Fels = Rock/Slate, Sumpf passend. Farben aus derselben Regionspalette wie das Terrain, damit Spielfeld und Umgebung nahtlos wirken. Gedämpft, nicht grell. Die Felder bleiben unterscheidbar (Wald etwas dunkler als Wiese), das Raster bleibt sichtbar.
  - Bodenflecken (`GROUND_FLECKS`) und Sandstreifen farblich an die neue Basis anpassen oder abschalten, wenn sie mit dem Material unruhig wirken (Entscheidung in den Notizen).
  - `GROUND_TEXTURES` mit eigener Bild-ID hat weiterhin Vorrang (spätere Nutzertexturen).
  - Fertig, wenn: Stub prüft Material/Farbe pro Gelände aus der Regionspalette und den Vorrang von `GROUND_TEXTURES`.

- [x] 3. **Saubere Felshügel** – `LandscapeBuilder.surface` (`M`/`C`), `BoardBuilder` (Standkappen, Felsmodelle an `M`/`C`), `Config.LANDSCAPE.rockFields`, `ENVIRONMENT.rocks`
  - **Keine clippenden Füße:** Die *gerenderte* Terrain-Oberfläche auf `M`-Feldern liegt im Standbereich unter der Figuren-/Overlayhöhe. Achtung: Roblox-Smooth-Terrain glättet zwischen 4-Stud-Voxeln und kann dadurch über die Belegungshöhe hinausragen; dafür Sicherheitsabstand einplanen. Alternative: Die Standhöhe der Figur auf `M` an die sichtbare Felsoberfläche anpassen (zentral über `Grid`-Höhen wie bei Brücken). Wähle die robustere Variante und begründe sie.
  - **Nachbarfelder frei:** Der Felshügel bleibt innerhalb der `M`/`C`-Felder (plus höchstens kleinem Überhang unterhalb der Overlayhöhe). Overlays und Zielfelder auf Nachbarfeldern werden nicht verdeckt.
  - **Kleine Steine:** keine schwebenden Steine. Platzierung auf der tatsächlichen Hügeloberfläche (z. B. Höhe aus `LandscapeBuilder.surface`), leicht eingesunken. Deutlich weniger (WIP), und eingefärbt bzw. abgestimmt auf Farbe und Material des Terrain-Felsens (Rock/Slate-Palette). Wirkt ein Paketfels neben dem glatten Terrain zu detailreich, lieber größere, ruhigere Felsen oder gar keine.
  - **Standkappen** auf `M` farblich an den Fels anpassen, damit sie nicht als helle Quadrate auffallen.
  - Fertig, wenn: Stub prüft Terrain-Höhe mit Glättungsreserve unter der Standhöhe, keine Terrainbelegung über Overlayhöhe in Nachbarfeldern, alle Felsdetails auf der Oberfläche (kein Abstand > WIP-Toleranz nach unten), geringere Anzahl. Teile/Dreiecke vorher/nachher.

- [x] 4. **Wurzelfüße an Bäumen** – `BoardBuilder` (Waldfelder), `LandscapeBuilder.details`, `EnvironmentAssets`, `Config`
  - Jeder Paketbaum (Brett und Landschaft) bekommt ein `deco_root`-Modell am Stammfuß: zentriert auf den Stamm (Wood-MeshPart des Baums), skaliert auf die Stammdicke am unteren Ende, leicht in den Boden eingesunken, zufällig gedreht. So endet der Stamm nicht mehr in einer dünnen Spitze.
  - Die bisherigen losen `deco_root`-Platzierungen als Unterholz entfallen oder werden reduziert, um das Dreieckbudget zu halten.
  - Ohne Paket: keine Änderung am Part-Fallback.
  - Fertig, wenn: Stub prüft: pro Paketbaum genau ein Wurzelfuß, Mittelpunkt innerhalb einer WIP-Toleranz um den Stammfuß, Skalierung relativ zur Stammbreite, deterministisch. Teile/Dreiecke vorher/nachher.

- [x] 5. **Wasserfälle sichtbar + häufiger** – `LevelGen`, `RunConfig`, `BoardBuilder.waterfall`, `LandscapeBuilder` (Klippenkanal)
  - Prüfe, ob Wasserfälle mit den Terrain-Klippen aus C5 noch sichtbar sind (Quellstreifen, Fallfläche und Gischt nicht im Terrain versteckt, Kanal in der Klippenoberkante frei, Fallfläche sitzt an der sichtbaren Klippenkante). Reparieren, falls nötig.
  - Häufigkeit auf **20–25 %** der normalen Laufkarten anheben (WIP), im Generatortest messen. Lösbarkeit und Startzone unverändert.
  - Fertig, wenn: Generatortest zeigt 20–25 %, und ein Brett-Stub prüft, dass alle Wasserfallteile außerhalb des Terrain-Volumens liegen und an der Klippenkante anschließen.

- [x] 6. **Messung + Abschluss:** Tests für alle Schritte; `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-run-ui.ps1` alle OK, dazu Rojo-Build. Devlog **#38** „Level-Optik Etappe C6“, „Nächste Schritte“ (3D-Lagerplatz als nächster Plan; Notfall-Beschwörung Phase 4). Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Maximal herausgezoomt: ganzes Brett im Bild, kein Kartenende, auch beim Drehen
- [ ] Spielfeldboden gedämpft, passt zu Terrain und Modellen; Felder weiterhin unterscheidbar, Raster sichtbar
- [ ] Felshügel: keine clippenden Füße, keine schwebenden Steine, Steine passen farblich, Zielfelder daneben frei
- [ ] Bäume mit Wurzelfuß statt dünner Spitze
- [ ] Wasserfälle tauchen etwa auf jeder 4.–5. Karte auf und sind gut sichtbar
- [ ] „Missionsaufbau …“ gleich schnell oder schneller als 263 ms; Handy flüssig

## Nicht anfassen
- Spielregeln, Generator (außer Wasserfall), Brücken, Ufer-Logik, Wiesen-Deko-Mengen, Umrisse, UI, Lager-/Boss-Logik, Thronsaal

## Offene Fragen
- **Schritt 1 – beantwortete Hub-Frage:** Die Sichtstrahlen trafen die bisher ausgesparte Hub-Schutzfläche bei Z = 420, deren Boden nicht den gesamten Schutzbereich abdeckt. Darf die Testausnahme bestehen bleiben, oder braucht es eine räumliche Trennung?
  - **Antwort (Claude):** Räumliche Trennung: **`Config.HUB_ORIGIN` so weit verschieben, dass der gesamte Hub-Schutzbereich außerhalb aller Landschaftsflächen und aller Sichtstrahlen bei maximalem Zoom liegt (plus Sicherheitsrand)**, z. B. weit in −Z/+Z oder seitlich; den Wert aus Landschaftsgröße + Reichweite ableiten bzw. begründen. Der Hub wird in `HubBuilder` nur relativ zu `origin` gebaut (einzige weitere Nutzung: `LandscapeBuilder`), sein Aussehen bleibt unverändert. Prüfe, dass Spawn, Kamera im Thronsaal, Teleports/Rückkehr und Hub-Interaktionen (Kriegstisch, Rekrutierung usw.) mit dem neuen Ursprung funktionieren (`rg` nach festen Hub-Koordinaten im Client/Server). Danach entfällt die Hub-Ausnahme im Sichttest; die Aussparung `withoutHub` darf bleiben, schneidet aber nichts mehr. Weiter mit Schritt 1 (abschließen/committen), dann 2–6.
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

### Zwischenstand Schritt 1 vor der Claude-Antwort (10.10.2026)
- Gemeinsames Übersichts-/Sichtstrahlmodell und verkleinerter Nahbereich bereits uncommittet vorbereitet. Pflichtcheck grün; neue Sichtprüfung scheiterte an der alten Hub-Aussparung. Gemäß Stoppregel Frage eingetragen, Schritte 2–6 noch nicht begonnen. Die Antwort oben und der Auftrag autorisierten anschließend die Fortsetzung.

### Abschluss Schritt 1 (10.10.2026)
- Hub-Ursprung aus maximalem aktuellem Brett (16×12), Sicht-/Landschaftsrand, Hub-Halbtiefe und 2 Feldern Sicherheitsrand abgeleitet. Prüfung gegen Lauf- und feste Kartenmaße; Sichttest ohne Hub-Ausnahme grün. `rg`: HubBuilder verwendet ausschließlich `origin`/`at`, Spawn ebenfalls; Client-Prompts/Thron referenzieren Instanzen, Kamera kehrt zum Humanoid zurück, kein koordinatenbasierter Teleport nötig. Aussehen unverändert; Studio-Rückkehr/Interaktionen noch ungetestet.
- 100 Seeds: Teile/Dreiecke unverändert 1657,3 / 273495 im Mittel. Terrain-Aufrufe vorher 31,96 → 17,99 (Max 32 → 18), Air 7,96 → 1,99, WriteVoxels 16 → 12; Schreibvoxels 247327 → 123878 (Max 258048 → 134144); Festvolumen 44611829 → 33962873 Studs³ (Max 44707799 → 34068729). Stub-Zeit 224,80 ms bei parallelem Testlauf: keine belastbare Studio-Zeitmessung.
- `check.ps1` OK (38 Dateien), `test-run.ps1` OK einschließlich Sicht-/Bretteckenprüfung. Minimale Server-/Generator-Vektor-Stubs um XYZ-Felder ergänzt, damit Config-Geometrie beim Laden berechnet werden kann.

### Schritt 2
- Roblox-Materialien und gemeinsame Regionspalette für Wiese/Wald, Morast, Fels und Festung; Wald 10 % dunkler. Bestehende Regionsmaterialien (Snow/Ground) bleiben wirksam. Brückenholz und Wasserfarbe erhalten.
- Zurückhaltende WIP-Variante: prozedurale Bodenflecken per `GROUND_FLECKS.enabled = false` abgeschaltet, um Materialdetails ruhig zu halten. Sandfarbe gedämpft und Material Ground; Ufergeometrie unverändert. Eigene `GROUND_TEXTURES` bleiben sichtbar und unterdrücken auch bei eingeschalteten Flecken deren Erzeugung.
- `check.ps1` und `test-run.ps1` OK. Neue Prüfung aller vier Regionen/Geländearten und Texturvorrang. 100 gleiche Paket-Seeds nach Schritt 2: Teile Mittel 1303,4 / Max 1401; Dreiecke Mittel 270569 / Max 364224 (vorher 1657,3 / 1787 und 273495 / 367368). Studio ungetestet.

### Schritt 3
- Robustere Variante: Spiel-/Overlayhöhen unverändert, M-Terrain mit 2 Studs Glättungsreserve (halber Voxel) plus 0,15 Studs Abstand abgesenkt. Rock-Standkappen reichen bis zur Basis, damit kein Luftspalt unter der Figurenplattform bleibt; gleiche regionale Felsfarbe.
- Zurückhaltende WIP-Details: ein kleiner Fels auf M, 0–1 auf C, keine kleinen Begleiter. Gedrehte Bounding-Box innerhalb des Felds und außerhalb der M-Figurenmitte. 9 Terrain-Raycast-Auflagen je Detail; niedrigste Auflage minus 0,2 Studs Einsinken. Bei fehlender Auflage Detail weglassen. Felsmaterial/Farbe aus Palette; Paket-Oberflächentextur entfernt, damit der Fels zum Terrain passt.
- Stub prüft Reserve, Standhöhen, fehlende Belegung in Nachbarfeldern, eingefasste Detailboxen, Auflage, Farbe und geringere Anzahl. Reales Smooth-Terrain-Meshing wird nicht simuliert; Studio-Prüfung bleibt offen.
- `check.ps1` und `test-run.ps1` OK. 100 Paket-Seeds Schritt 2 → 3: Teile Mittel 1303,4 → 1270,2 (Max 1401 → 1394), Dreiecke 270569 → 243945 (Max 364224 → 349824). Terrain-Dreiecke nicht enthalten.

### Schritt 4
- Jeder echte Paketbaum bekommt automatisch im gemeinsamen Asset-Platzierer einen `deco_root`-Fuß als Kindmodell. Stammwahl über höchstes Wood-MeshPart, Fußzentrum aus dessen unterer lokaler Mitte, Breite exakt 1,1× Stammbreite (Bounding-Box als verfügbare Näherung), 0,12 Studs Einsinken, deterministische freie Drehung. Brett und Landschaft nutzen dieselbe Funktion; Part-Fallback unverändert.
- Lose Unterholz-Wurzeln entfernt, dort nur noch bestehende Büsche. Wurzeltextur aus Paket beibehalten. Terrain-Bäume behalten ihr bisheriges zusätzliches Einsinken von 0,8 Studs. Das tatsächliche schmale Mesh-Ende lässt sich aus Roblox-Bounds nicht exakt messen; Breitenfaktor ist zentral WIP und in Studio zu beurteilen.
- `check.ps1` und `test-run.ps1` OK; Original-Fixtures prüfen genau einen Fuß pro Brett-/Landschaftsbaum, Position, relative Skalierung, Einsinken, Determinismus und Klickfreiheit. Neuer Test nach seiner Fixture-Hilfsfunktion eingeordnet.
- 100 Paket-Seeds Schritt 3 → 4: Teile Mittel 1270,2 → 1381,0 (Max 1394 → 1576), geschätzte Dreiecke 243945 → 302125 (Max 349824 → 460324). Typisches Budget 350000 eingehalten, Maximalwert gestiegen. Insgesamt gegen C5 weniger Parts, aber mehr Modelldreiecke durch die Pflichtwurzel pro Baum. Keine Terrain-Dreiecke enthalten; Studio/Handy offen.

### Schritt 5
- Quellstreifen um 0,05 Studs über Klippensollhöhe, bis zur Außenseite der Fallfläche verlängert. Fall beginnt an Quelloberkante, innere Seite direkt an der Klippenkante (vorher 0,06 Studs Spalt). Kanal inklusive einer Voxelreserve auch in benachbarten C-Feldern stromaufwärts/seitlich flach; Gischt vollständig im Wasserfeld.
- `WATERFALL_CHANCE` bedingt von 0,56 auf 0,8. Generatormessung 1000 normale Laufkarten: **21,60 %**, Ziel 20–25 % erfüllt, alle vier Richtungen, Seen und andere Ufer vorhanden. 19000 Level-/5000 Optionsprüfungen, 96 Kombinationen und 2400 Boss-/Minibosskarten OK; keine regulären Rückfälle. Startzone und Lösbarkeitsprüfungen unverändert.
- `check.ps1` und `test-run.ps1` OK. Zusätzliche Wasserfall-Stubs in allen vier Richtungen, mit/ohne Paket: Quelle oberhalb Terrain, Fall-/Gischt-Innenvolumen außerhalb Terrain, bündige Quelle/Fall/Klippe. Volumenprüfung mit offener Box (0,0001 Studs vom Rand), damit erlaubter Grenzflächenkontakt bei negativer Richtung nicht als Durchdringung gilt; Anschluss separat exakt geprüft.

### Schritt 6 – Abschluss
- Texturvorrang aus Schritt 2 auch auf M-Standkappen ergänzt (Top/Seiten); eigener Bergtextur-Stub grün. Kodierungsfehler in den historischen Schritt-1-Notizen korrigiert, beantwortete Frage erhalten.
- Finale Prüfungen: `check.ps1` **OK, 38 Dateien, Exit 0**; `test-levelgen.ps1` **OK, 19000 Level-, 5000 Optionsprüfungen, 96 Landschaftskombinationen, 2400 Boss-/Minibosskarten**, keine regulären Rückfälle, Wasserfallquote 21,60 %. `test-run.ps1` **OK, 34458 Lauf-/Boss-/Lager-Stubs, 341244 Brett-/Kameraprüfungen** plus Material-/Fels-/Wurzel-/Wasserfall-/Landschaftsregressionen. `test-tutorial.ps1` **168**, `test-run-ui.ps1` **116 Prüfungen**, beide OK. Rojo-Build `TacticsGame.rbxlx` erfolgreich, alle Exit 0. Automatische Formatprüfung ohne Fehler.
- Finale Messung, 100 identische Seeds und Original-Paket-Fixtures (`47acb81` → C6): Teile Mittel **1657,3 → 1381,2**, Max 1787 → 1576; Modelldreiecke geschätzt Mittel **273495 → 302111**, Max 367368 → 460324. Terrain-Aufrufe Mittel **31,96 → 17,99**, Max 32 → 18; Air 7,96 → 1,99, WriteVoxels 16 → 12; Schreibvoxels **247327 → 123945**, Max 258048 → 134144; Festvolumen **44611829 → 33960719 Studs³**, Max 44707799 → 34065017. Terrain-Dreiecke nicht geschätzt.
- Derselbe Vergleichslauf: Stub-Aufbau Mittel 298,16 → 183,49 ms, Max 461,07 → 387,31 ms. Lauf teilweise parallel zur Brettprüfung; reine Vergleichswerte, kein Studio-Leistungsnachweis und nicht mit den vom Nutzer gemeldeten 263 ms vergleichbar.
- Devlog #38 und Nächste Schritte aktualisiert: eigener 3D-Lagerplatz als nächster Entwicklungsplan, Notfall-Beschwörung in Phase 4. **C6 in Studio/Handy ungetestet; Claude-Review ausstehend.** Deshalb alle manuellen Checkboxen offen. Ein Commit pro Schritt, Abschluss auf `feature/level-optik-c`.
