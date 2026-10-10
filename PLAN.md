# PLAN: Schwebende Thronlande – Etappe D1 (Grasland)

Ziel: Jedes Kampflevel ist eine **schwebende Insel über einem Wolkenmeer** statt eines Terrain-Tals. Das ist das wichtigste Wiedererkennungsmerkmal der Welt (Designsystem „Throne Tales“, Komponente MapFrame, entschieden vom Nutzer am 10.10.2026). Erst Grasland, aber so gebaut, dass weitere Gebiete nur Palette/Fraktion/Gefahr ergänzen müssen.
Branch: neu `feature/thronlande` von `feature/ui-designsystem` (enthält C7 und die neue UI).

**Nutzerentscheidungen (10.10.2026):**
- Insel **mittelgroß**: 3–4 Felder Landrand rund ums Brett (Bäume, Felsen, Requisiten, Thronkristalle), dann die Kante. Der Rand bleibt in der Übersicht sichtbar.
- **2–4 kleine Nebeninseln** im Hintergrund (Gebietsfarben, je ein Thronkristall) für Tiefe.
- **Dichte Wolkendecke** unter der Insel: hell, leicht lila zum Horizont, kantige Low-Poly-Wolkenberge, kein Boden sichtbar.
- Canyon-/Tal-Landschaft aus dem Referenzvideo ist verworfen; das Video bleibt nur Maßstab für Helligkeit/Sättigung.

**Farben (Designsystem, WIP in Config):** Erdschicht #9a6a48, Steinschicht #6d6480, Wolken #f4f1ff, Himmel oben #9ddde6 → Horizont #c9a8ff, Schaum #f2fbff, Thronkristall Grasland #7cc242 (Akzent je Gebiet: Sumpf #b46be0, Eis #6fd3ff, Vulkan #ff7a1a), Kristallglanz weiß. In der Welt keine Konturlinien.

**Bestehender Code:** `src/server/LandscapeBuilder.luau` (Terrain-Tal: `prepare`, `surface`, `writeSurface`, `details`, Fernboden-Blöcke, `withoutHub`, Randflüsse `state.rivers`), `src/server/BoardBuilder.luau` (Brett, Terrain-Wasser, Felshügel, Klippenwände `cliffWalls`, `waterfall()`), `src/shared/Config.luau` (`LANDSCAPE`, `WATER.extendRivers`, `FEEL.environmentMargin`, `landscapeMargin`, `CAMERA`, `overviewZoom`), `src/client/CameraController.luau` (Zoom-/Schwenkgrenzen), `src/client/Atmosphere.luau` + `Config.FEEL.atmosphere.battle` (Haze/Farbe). Hub-Terrain bei `HUB_ORIGIN` bleibt unberührt.

**Studio-Prüfung (Pflicht für Schritte 1–6):** echter Ort „Throne Tales“, Rojo verbunden, nur Play-Modus (Terrain-Räumen nie im Edit-Modus!). DataStore aktiv, Spielstand darf sich ändern. Lauf über Remotes oder UI starten, Kamera per Mausrad/WASD, `screen_capture`. Pro Schritt Normalzoom- und Übersichtsbild; vorher/nachher beschreiben. Teile-/Dreieckszahlen und Aufbauzeit vorher/nachher messen.

**Leitlinien:** Alles schaltbar über `Config.ISLAND.enabled` (aus = bisheriges Tal, als Rückfall). Deterministisch pro `mapKey`. Klickbarkeit, Figurenhöhen, Overlays, Brücken, Wasser, Felshügel, Klippenwände und Wasserfälle auf dem Brett bleiben unverändert. Low-Poly: kantige Flächen, keine Roblox-Materialtexturen für neue Inselteile (`SmoothPlastic`), Terrain darf für Oberflächen bleiben, wo es heute schon genutzt wird. Teilebudget für alles Neue (Insel-Unterseite, Kante, Wolken, Nebeninseln, Kristalle) **≤ 450 Teile**, in den Notizen gemessen. Ein Commit pro Schritt. Geschmacksfragen → „Offene Fragen“.

## Schritte

- [x] 1. **Vorher-Bilder und Messung** – nur Studio
  - Ein Grasland-Kampflevel mit Fluss: Normalzoom, Übersichtszoom, Aufbauzeit, Brett-Nachkommen, Terrain-Voxel.

- [ ] 2. **Inselgrundriss und Oberseite** – `Config.ISLAND` (neu), `LandscapeBuilder`
  - Statt Tal und Fernboden: eine Inseloberseite, die das Brett um **3–4 Felder** (WIP `rimTiles`) umschließt. Umriss organisch-kantig (pro Seite unregelmäßige Polygonkante, deterministisch), keine perfekte Rechteckform.
  - Außerhalb der Insel ist Luft: kein Terrain-Tal, kein Fernboden mehr. Aufräumen beim nächsten Aufbau wie bisher vollständig.
  - Der Rand trägt die bisherige Deko-Logik (`details`: Bäume, Felsen, Büsche) in angepasster Dichte; dazu 1–3 Requisiten-Plätze (vorerst vorhandene Paketmodelle).
  - Akzeptanz: Übersichtsbild zeigt Brett + Landrand + Kante, dahinter nur Himmel.

- [ ] 3. **Inselkante und Unterseite** – neues Modul z. B. `src/server/IslandBuilder.luau`
  - Senkrechte, kantige Kante aus Teilen entlang des Umrisses (wie `cliffWalls`: verdeckt Terrain-Rundung), oben **Erdschicht** (#9a6a48, etwa eine Feldbreite tief), darunter **Steinschicht** (#6d6480), die sich in 2–3 Stufen nach unten zu einer Spitze verjüngt (umgedrehter, facettierter Kegel; Gesamttiefe WIP ≈ 4–5 Felder).
  - **2–4 Thronkristalle** ragen aus der Unterseite: Rauten-Oktaeder (z. B. zwei gegeneinander gesetzte Pyramiden aus Wedges oder ein passendes Paketmodell), `Neon` in der Gebietsakzentfarbe, harte weiße Glanzfacette. Keine teuren Partikel.
  - Akzeptanz: Bild schräg von unten/seitlich (Übersicht, Kamera geneigt): Schichten und Kristalle klar erkennbar, keine Lücken zwischen Kante und Oberseite.

- [ ] 4. **Flüsse stürzen über die Kante** – `LandscapeBuilder` (Randflüsse), `BoardBuilder.waterfall` wiederverwenden
  - Randflüsse (`state.rivers`) laufen bis zur Inselkante und stürzen dort als **Wasserfall** ins Wolkenmeer (Fallfläche ≥ Erd- + Steinschicht, Gischt-/Nebelfläche unten in den Wolken). Brett-Wasserfälle aus C7 bleiben wie sie sind.
  - Akzeptanz: Bild eines Randflusses mit Fall über die Kante.

- [ ] 5. **Wolkenmeer, Himmel, Nebeninseln** – `IslandBuilder`, `Config.FEEL.atmosphere.battle` (Haze), ggf. `Atmosphere.luau`
  - Dichte Wolkendecke deutlich unter der Insel (WIP-Höhe): große helle Grundfläche (#f4f1ff) plus kantige Low-Poly-Wolkenberge, zum Horizont leicht lila (über Haze/Atmosphere oder Farbverlauf der Wolkenteile). Kein Boden darunter sichtbar, auch nicht beim Herauszoomen.
  - Himmel: Haze/Atmosphere so einstellen, dass oben hell-cyan und zum Horizont lila (#c9a8ff) wirkt. Die vom Nutzer angelegten `ColorGrading`/`Bloom` nicht anfassen.
  - **2–4 Nebeninseln** in Abstand (außerhalb des Schwenkbereichs), klein, gleiche Bauweise in vereinfachter Form (Oberseite in Gebietsfarbe, Erd-/Steinkegel, ein Kristall), deterministisch platziert, leichtes Schweben optional (nur wenn günstig, client-seitig).
  - Akzeptanz: Übersichtsbild mit Wolken, Himmelsverlauf und mindestens zwei Nebeninseln; Normalzoom wirkt nicht leer.

- [ ] 6. **Kamera und Lesbarkeit** – `CameraController`, `Config.CAMERA`, `Config.landscapeMargin`/`overviewZoom`
  - Übersichtszoom zeigt die ganze Insel mit etwas Himmel; Schwenken darf nicht so weit, dass nur Wolken im Bild sind. Normalzoom und Klickbarkeit unverändert.
  - Taktische Lesbarkeit: Brett hebt sich weiter klar vom Landrand ab (Randfelder dürfen nicht wie spielbare Felder wirken – z. B. etwas tiefer, Raster nur auf dem Brett).
  - Akzeptanz: Bilder Normal- und Übersichtszoom; drei Proben mit verschiedenen Seeds (mit/ohne Fluss).

- [ ] 7. **Abschluss** – Tests, Messung, Devlog
  - Landschaftsregressionen in `scripts/test-run.ps1`/Tests auf Insel umstellen bzw. ergänzen (Rückfall `ISLAND.enabled = false` weiter geprüft): Insel umschließt Brett, kein Terrain außerhalb der Insel, Randfluss endet in Wasserfall, Teilebudget, Determinismus.
  - `scripts/check.ps1`, `test-run.ps1`, `test-levelgen.ps1`, `test-tutorial.ps1`, `test-run-ui.ps1` OK; Rojo-Build.
  - Messung vorher/nachher: Teile, geschätzte Dreiecke, Terrain-Voxel, Aufbauzeit.
  - Devlog **#43 „Schwebende Thronlande D1“**, „Nächste Schritte“ (D2: Thronkristalle/Banner auf der Insel, weitere Gebiete). Committen, `git push -u origin feature/thronlande` (Ziel ist das eigene Repository des Nutzers `Tttiiimmm-code/Roblox-Strategy`; lehnt die automatische Freigabeprüfung den Push ab, **nicht** als Frage stoppen, sondern in den Notizen vermerken – Claude pusht dann), Studio im Edit-Modus, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Kampflevel schwebt als Insel über Wolken, Rand mit Bäumen, Kante mit Erd-/Steinschicht und Kristallen
- [ ] Flüsse stürzen über die Kante; Nebeninseln im Hintergrund
- [ ] Brett gut lesbar, Klicks/Bewegung wie vorher
- [ ] Handy flüssig, Aufbauzeit okay

## Nicht anfassen
- Spielregeln, Generator, Brett-Inhalt (Felder, Wasser, Hügel, Klippen, Brücken), UI, Thronsaal/Hub-Terrain, Lighting-Effekte des Nutzers, `docs/referenz/`

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1: Studio Throne Tales (75433071253639), Play mit aktivem DataStore; vorhandenen Lauf per ChooseLevel gestartet. Reproduzierbare Landschaftsprobe danach direkt mit echtem BoardBuilder und Generator-Seed 1 (Grasland, Fluss/Lake), ohne Profilmanipulation. MCP-require verwendet eigenen Modulzustand: daher Grid explizit mit Generator-Karte gesetzt; Figuren des laufenden Kampfes sind nicht Teil dieser Geometrieprobe. Bilder D1_01_vorher_fluss_normal/uebersicht aufgenommen. Vorher: 1.447 BaseParts, 2.532 Nachkommen, 118.528 geschriebene Terrain-Voxel, Terrainvolumen 33.832.189 Studs³, Aufbau 0,338 s. Dreiecke geschätzt 460.976 (Mesh/Union je pauschal 1.000; keine exakte GPU-Messung). Tal/Fernboden füllt den gesamten Hintergrund.
