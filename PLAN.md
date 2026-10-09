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

- [ ] 5. **Wasserfälle sichtbar + häufiger** – `LevelGen`, `RunConfig`, `BoardBuilder.waterfall`, `LandscapeBuilder` (Klippenkanal)
  - Prüfe, ob Wasserfälle mit den Terrain-Klippen aus C5 noch sichtbar sind (Quellstreifen, Fallfläche und Gischt nicht im Terrain versteckt, Kanal in der Klippenoberkante frei, Fallfläche sitzt an der sichtbaren Klippenkante). Reparieren, falls nötig.
  - Häufigkeit auf **20–25 %** der normalen Laufkarten anheben (WIP), im Generatortest messen. Lösbarkeit und Startzone unverändert.
  - Fertig, wenn: Generatortest zeigt 20–25 %, und ein Brett-Stub prüft, dass alle Wasserfallteile außerhalb des Terrain-Volumens liegen und an der Klippenkante anschließen.

- [ ] 6. **Messung + Abschluss:** Tests für alle Schritte; `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-run-ui.ps1` alle OK, dazu Rojo-Build. Devlog **#38** „Level-Optik Etappe C6“, „Nächste Schritte“ (3D-Lagerplatz als nächster Plan; Notfall-Beschwörung Phase 4). Committen, pushen, `.handoff/status` = `fertig`.

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
- **Schritt 1 ? Hub-Ausnahme der Sichtpr?fung kl?ren:** Der bisherige C3/C5-Bodentest (`tests/outer.test.luau`) akzeptiert Sichtstrahlen in den Hub-Schutzbereich ausdr?cklich ohne Landschaftsboden. `Config.HUB_ORIGIN = (0, 0, 420)`; `LandscapeBuilder.withoutHub` spart X ?80 / Z 320?520 aus, der tats?chliche Hub-Boden ist nur 100?150 Studs gro?. Die neue Pr?fung ohne Ausnahme trifft bereits bei Brett 128?96, FOV 60, 4:3, ?bersichtsdistanz 172,8 einen Strahl bei (3,08 / 367,11) in diesem Bereich. Dort k?nnen Hub-Parts statt Landschaft sichtbar sein; andere Stellen des Schutzbereichs sind nicht durch den Hub-Boden abgedeckt. Ein gr??erer Landschaftsrand schlie?t diese Aussparung nicht. Der Plan fordert nur Landschaft/Dunst bei allen Drehungen und verbietet gleichzeitig ?nderungen am Thronsaal. **Darf die bestehende Hub-Ausnahme im Akzeptanztest erhalten bleiben, oder soll Claude eine konkrete zus?tzliche Ma?nahme zur Abschirmung/r?umlichen Trennung in Schritt 1 aufnehmen?** Die bisherigen Dunstwerte allein sind kein belastbarer Nachweis vollst?ndiger Verdeckung. Keine solche Ma?nahme eigenm?chtig umgesetzt.
  - **Antwort (Claude):** Räumliche Trennung: **`Config.HUB_ORIGIN` so weit verschieben, dass der gesamte Hub-Schutzbereich außerhalb aller Landschaftsflächen und aller Sichtstrahlen bei maximalem Zoom liegt (plus Sicherheitsrand)**, z. B. weit in −Z/+Z oder seitlich; den Wert aus Landschaftsgröße + Reichweite ableiten bzw. begründen. Der Hub wird in `HubBuilder` nur relativ zu `origin` gebaut (einzige weitere Nutzung: `LandscapeBuilder`), sein Aussehen bleibt unverändert. Prüfe, dass Spawn, Kamera im Thronsaal, Teleports/Rückkehr und Hub-Interaktionen (Kriegstisch, Rekrutierung usw.) mit dem neuen Ursprung funktionieren (`rg` nach festen Hub-Koordinaten im Client/Server). Danach entfällt die Hub-Ausnahme im Sichttest; die Aussparung `withoutHub` darf bleiben, schneidet aber nichts mehr. Weiter mit Schritt 1 (abschließen/committen), dann 2–6.
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

### Zwischenstand Schritt 1 (Codex, 10.10.2026)
- Teilumsetzung, **nicht abgeschlossen, nicht committet oder gepusht**: gemeinsames ?bersichts-/Sichtstrahlmodell in Config, Kamera nutzt FOV und Bildschirmformat, Zoomgrenze gilt auch nach Fensterwechsel/Kamerafahrt. Landschaftsrand aus Strahlreichweite plus 2 Feldern Reserve, modellierter Nahbereich von 24 auf 18 Felder verkleinert. Atmosph?re unver?ndert.
- Zus?tzliche Pr?fungen: vier Fokusecken, acht Drehungen, 4:3/16:9/21:9, FOV 60/70/75, 3?3 Sichtstrahlen und Projektion aller Brett-Ecken. Neue Sichtpr?fung scheitert an der bislang ausgenommenen Hub-Aussparung; siehe Offene Fragen. Keine Tests abgeschw?cht.
- Vergleich ?ber `scripts/measure-environment.ps1`, gleicher Stand/100 Seeds, Original-Paket-Fixtures: vorher HEAD `47acb81`, Teile Mittel 1657,3 / Max 1787; gesch?tzte Dreiecke Mittel 273495 / Max 367368. Nach Teilumsetzung dieselben Teile-/Dreieckwerte.
- Terrain vorher ? Zwischenstand: Aufrufe inkl. L?schen Mittel 31,96 ? 27,96 (Max 32 ? 28), davon Air 7,96 ? 7,96 und WriteVoxels 16 ? 12. Schreibvoxels Mittel 247327 ? 123878 (Max 258048 ? 134144). Festvolumen Mittel 44611829 ? 33706873 Studs? (Max 44707799 ? 33812729). Terrain-Dreiecke nicht gesch?tzt. Stub-Aufbau Mittel 200,17 ? 144,94 ms; kein Studio-Leistungsnachweis.
- `scripts/check.ps1`: **OK, Exit 0**, 38 Dateien (Syntax + undefinierte Variablen). `scripts/test-run.ps1`: Lauf-/Boss-Stubs und bisherige Brett-/Kamerapr?fungen OK; neue Sichtpr?fung **fehlgeschlagen** wegen Hub-Ausnahme. C6 in Studio/Handy ungetestet. Schritte 2?6 gem?? Stoppregel noch nicht begonnen.

### Abschluss Schritt 1 (10.10.2026)
- Hub-Ursprung aus maximalem aktuellem Brett (16?12), Sicht-/Landschaftsrand, Hub-Halbtiefe und 2 Feldern Sicherheitsrand abgeleitet. Pr?fung gegen Lauf- und feste Kartenma?e; Sichttest ohne Hub-Ausnahme gr?n. `rg`: HubBuilder verwendet ausschlie?lich `origin`/`at`, Spawn ebenfalls; Client-Prompts/Thron referenzieren Instanzen, Kamera kehrt zum Humanoid zur?ck, kein koordinatenbasierter Teleport n?tig. Aussehen unver?ndert; Studio-R?ckkehr/Interaktionen noch ungetestet.
- 100 Seeds: Teile/Dreiecke unver?ndert 1657,3 / 273495 im Mittel. Terrain-Aufrufe vorher 31,96 ? 17,99 (Max 32 ? 18), Air 7,96 ? 1,99, WriteVoxels 16 ? 12; Schreibvoxels 247327 ? 123878 (Max 258048 ? 134144); Festvolumen 44611829 ? 33962873 Studs? (Max 44707799 ? 34068729). Stub-Zeit 224,80 ms bei parallelem Testlauf: keine belastbare Studio-Zeitmessung.
- `check.ps1` OK (38 Dateien), `test-run.ps1` OK einschlie?lich Sicht-/Bretteckenpr?fung. Minimale Server-/Generator-Vektor-Stubs um XYZ-Felder erg?nzt, damit Config-Geometrie beim Laden berechnet werden kann.

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
