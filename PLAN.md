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

- [ ] 1. **Zoomgrenze + kleineres Terrain** – `CameraController`, `Config.CAMERA`, `Config.LANDSCAPE`
  - Bestimme die größte sinnvolle Zoomstufe: Das ganze Brett passt bequem ins Bild (PC 16:9 und Handy quer), aber auch bei allen Kameradrehungen und Brettecken ist **kein Kartenende** zu sehen. Die Grenze leitet sich aus Brettgröße und Landschaftsgröße ab, nicht als freie Zahl. Kleine Bretter (Tutorial) bekommen eine passende kleinere Grenze.
  - Danach die Landschaft (`zoomMargin`, Fernboden, Aufräumbereich) auf das verkleinern, was bei dieser Grenze sichtbar ist, plus Sicherheitsrand. Ziel: kürzerer Aufbau und weniger Terrain zum Übertragen. Der Dunst (`FEEL.atmosphere`) darf so abgestimmt werden, dass der Horizont weich ausläuft.
  - Fertig, wenn: Strahl-/Sichtprüfung (wie C3-Bodentest: vier Ecken, acht Drehungen, 4:3/16:9/21:9, FOV) zeigt bei maximalem Zoom nur Landschaft bzw. Dunst, kein Kartenende; Terrain-Volumen und Aufrufe vorher/nachher in den Notizen.

- [ ] 2. **Spielfeldboden aus Roblox-Materialien** – `Config.TERRAIN`, `BoardBuilder` (Bodenaufbau), `Stages`, `Config.LANDSCAPE.palette`
  - Bodenflächen der Felder nutzen Roblox-Materialien passend zum Terrain: Wiese `.` = Grass, Wald `F` = Grass (dunkler) oder LeafyGrass, Weg/Erde = Ground, Fels = Rock/Slate, Sumpf passend. Farben aus derselben Regionspalette wie das Terrain, damit Spielfeld und Umgebung nahtlos wirken. Gedämpft, nicht grell. Die Felder bleiben unterscheidbar (Wald etwas dunkler als Wiese), das Raster bleibt sichtbar.
  - Bodenflecken (`GROUND_FLECKS`) und Sandstreifen farblich an die neue Basis anpassen oder abschalten, wenn sie mit dem Material unruhig wirken (Entscheidung in den Notizen).
  - `GROUND_TEXTURES` mit eigener Bild-ID hat weiterhin Vorrang (spätere Nutzertexturen).
  - Fertig, wenn: Stub prüft Material/Farbe pro Gelände aus der Regionspalette und den Vorrang von `GROUND_TEXTURES`.

- [ ] 3. **Saubere Felshügel** – `LandscapeBuilder.surface` (`M`/`C`), `BoardBuilder` (Standkappen, Felsmodelle an `M`/`C`), `Config.LANDSCAPE.rockFields`, `ENVIRONMENT.rocks`
  - **Keine clippenden Füße:** Die *gerenderte* Terrain-Oberfläche auf `M`-Feldern liegt im Standbereich unter der Figuren-/Overlayhöhe. Achtung: Roblox-Smooth-Terrain glättet zwischen 4-Stud-Voxeln und kann dadurch über die Belegungshöhe hinausragen; dafür Sicherheitsabstand einplanen. Alternative: Die Standhöhe der Figur auf `M` an die sichtbare Felsoberfläche anpassen (zentral über `Grid`-Höhen wie bei Brücken). Wähle die robustere Variante und begründe sie.
  - **Nachbarfelder frei:** Der Felshügel bleibt innerhalb der `M`/`C`-Felder (plus höchstens kleinem Überhang unterhalb der Overlayhöhe). Overlays und Zielfelder auf Nachbarfeldern werden nicht verdeckt.
  - **Kleine Steine:** keine schwebenden Steine. Platzierung auf der tatsächlichen Hügeloberfläche (z. B. Höhe aus `LandscapeBuilder.surface`), leicht eingesunken. Deutlich weniger (WIP), und eingefärbt bzw. abgestimmt auf Farbe und Material des Terrain-Felsens (Rock/Slate-Palette). Wirkt ein Paketfels neben dem glatten Terrain zu detailreich, lieber größere, ruhigere Felsen oder gar keine.
  - **Standkappen** auf `M` farblich an den Fels anpassen, damit sie nicht als helle Quadrate auffallen.
  - Fertig, wenn: Stub prüft Terrain-Höhe mit Glättungsreserve unter der Standhöhe, keine Terrainbelegung über Overlayhöhe in Nachbarfeldern, alle Felsdetails auf der Oberfläche (kein Abstand > WIP-Toleranz nach unten), geringere Anzahl. Teile/Dreiecke vorher/nachher.

- [ ] 4. **Wurzelfüße an Bäumen** – `BoardBuilder` (Waldfelder), `LandscapeBuilder.details`, `EnvironmentAssets`, `Config`
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
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)
