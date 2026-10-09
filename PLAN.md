# PLAN: Level-Optik Etappe C5 – Tal-Landschaft aus Terrain, Felshügel statt Würfel, lichterer Wald

Ziel: Ein Optik-Standard wie bei beliebten Roblox-Spielen mit Spielfeld von oben (Tower-Defense-/Anime-Spiele): **natürliche Formen statt Kisten**, das Spielfeld **in eine Landschaft eingebettet** statt von einem Ring aus Einzelobjekten umgeben, **keine sichtbaren Platzhalter**, Ferne geht in Dunst über.
Branch: `feature/level-optik-c` (enthält Phase 3, C1–C4)

**Nutzer-Feedback zum C4-Test (10.10.2026):** Thronsaal normal, keine Warnungen, Schatten ok, Figuren auf Brücken ok, Handy (Samsung S25+) flüssig. **Berge sehen aus wie braune Würfel mit Steinen**, **Wald noch etwas zu dicht**, **Gelände außerhalb muss besser werden: ein Ring aus zufälligen Gegenständen sieht nicht schön aus**, **hintere Bäume sind nur runde Kronen** (Kugel-Platzhalter).

**Nutzerentscheidungen (10.10.2026):**
- **Umgebung: Tal mit Hügeln und Bergen:** Das Spielfeld liegt in einem Wiesental. Ringsum steigen Grashügel mit Gruppen echter Yasu-Bäume an, hinten und an den Seiten felsige Berge, die in Dunst übergehen. Vorne zur Kamera (+Z in Grundausrichtung) flach, damit nichts das Brett verdeckt. Gebaut mit **Roblox-Terrain**. **Keine Kugel-Platzhalter** mehr.
- **Bergfelder: Terrain + Felsmodelle:** Benachbarte `M`-Felder (und `C`-Klippen) werden zu natürlichen Felshügeln aus Terrain geformt, mit größeren Felsmodellen aus dem Paket als Details. Das Feldraster und die Klickflächen bleiben erkennbar.
- **Wald: 1–2 Bäume pro Waldfeld** (statt 2–3), Kronengröße wie in C4 (1,1–1,2 Felder).

**Bestehender Code:**
- `src/server/BoardBuilder.luau`: Terrain wird bisher nur geräumt (`lastTerrainRegion`, `FillBlock(... Air)`, nur bei Größenwechsel). Umgebungsring (C3/C4, `outer`-Platzierung, Kronen-Ersatzteile), Sichtboden-Parts (`groundZoomMargin = 4.2`, bis ~1.075 Studs), Felswände `M`/`C` (C3: Wedge-Facetten), Waldfelder (`decorate` Fall `F`), Klick-Kacheln (`tile.CanQuery = true`).
- `src/shared/Config.luau`: `ENVIRONMENT.forest` (`treesPerForestTile`, `thirdTreeChance`), `ENVIRONMENT.outer`, `ENVIRONMENT.rocks`, `TERRAIN.M` (Höhe 4, begehbar mit Kosten) und `TERRAIN.C` (Höhe 8, unpassierbar), `FEEL.atmosphere.battle` (Atmosphere/ColorCorrection/Bloom vorhanden).
- `src/client/Main.client.luau:614–627`: Klick-Raycast mit **Include**-Filter auf `Board` + `Units`, ignoriert Terrain also bereits. So muss es bleiben.
- `src/client/CameraController.luau`: frei drehbar (`rotateBy`, `yaw`), Zoomgrenzen aus C1.
- `Config.HUB_ORIGIN = (0, 0, 420)`: Der Thronsaal (ca. x −50…50, z 345…495) darf weder von Terrain noch von Umgebungsteilen berührt werden.
- Tests/Messung: `tests/outer.test.luau`, `tests/walls.test.luau`, `tests/environment-metrics.test.luau`, `tests/board.stubs.luau`, `scripts/measure-environment.ps1`.

**Leitlinien:**
- **Spielregeln und Lesbarkeit:** Feldraster, Klickflächen, Bewegungs-Overlays, Figurenhöhe (`Grid.toWorld`/`tileHeight`), Brückenhöhen und Umrisse funktionieren unverändert. Terrain darf Overlays und Figuren auf begehbaren Feldern nicht durchdringen.
- **Leistung:** Terrain statt hunderter Einzelteile. Dazu Teile/Dreiecke vorher/nachher (`measure-environment.ps1`) und die Zahl der Terrain-Schreibaufrufe bzw. das Terrain-Volumen in den Notizen. Die reale Aufbauzeit („Missionsaufbau …“) misst der Nutzer in Studio. Terrain-Aufbau so bündeln, dass er auch auf dem Server zügig bleibt (wenige große `Fill*`-Aufrufe bzw. `WriteVoxels` in Blöcken).
- **Determinismus:** gleiche Karte = gleiche Landschaft (Seed aus Karte/Lauf).
- **Terrain-Aufräumen:** Bei jedem Brettaufbau wird das Terrain des vorherigen Bretts vollständig entfernt (nicht nur bei Größenwechsel), auch Tutorial ↔ Lauf. Der Thronsaal bleibt unberührt.
- Part-Fallback ohne Paket bleibt funktionsfähig (Terrain ist immer verfügbar; nur Modelle fallen weg).
- Alle Werte WIP in `Config`. Ein Commit pro Schritt, alle Prüfskripte grün. Geschmacksfragen: zurückhaltende Variante, über Config umstellbar, in den Notizen nennen.

## Schritte

- [x] 1. **Wald lichter** – `Config.ENVIRONMENT.forest`, `BoardBuilder.decorate` (Fall `F`)
  - 1–2 Bäume pro Waldfeld (WIP z. B. `treesPerForestTile = {min = 1, max = 2}`, Anteil mit 2 Bäumen als WIP-Wert), dritter Baum entfällt. Kronengröße aus C4 bleibt. Bei einem Baum steht er leicht außermittig, damit die Figurenmitte sichtbarer ist.
  - Fertig, wenn: Stub prüft 1–2 Bäume pro Feld und Determinismus; Teile/Dreiecke vorher/nachher.

- [x] 2. **Tal-Landschaft aus Terrain** – neues Modul, z. B. `src/server/LandscapeBuilder.luau`, aufgerufen aus `BoardBuilder.build`; `Config.LANDSCAPE` (WIP), Farben/Materialien pro Region in `Stages`
  - **Ersetzt** den Umgebungsring aus C3/C4 (Bäume/Büsche/Felsen in Ringform) und **alle Kronen-Ersatzteile**. Der Sichtboden aus Parts wird durch Terrain ersetzt oder nur noch dort genutzt, wo Terrain nicht hinreicht (in den Notizen begründen).
  - Form: Direkt ums Brett ein flacher Wiesenrand (etwa 1–2 Felder, Höhe wie Brettboden). Danach steigen **Grashügel** an, unregelmäßig mit Mulden und Kuppen statt eines gleichmäßigen Walls. **Hinten und an den Seiten** gehen sie in **felsige Berge** über (Rock/Slate oben, Grass/Ground an den Hängen, WIP-Materialien). **Vorne** (+Z in Grundausrichtung) bleibt es flach bis leicht abfallend, sodass aus Start- und Normalansicht nichts das Brett verdeckt. Die Höhen nehmen mit der Entfernung zu, damit die Berge den Horizont bilden. Ganz außen geht die Landschaft in den vorhandenen Atmosphere-Dunst über; beim maximalen Zoom ist kein harter Rand und keine leere Fläche zu sehen.
  - **Echte Yasu-Bäume in Gruppen** auf Hügeln und Hangfüßen (Cluster mit Lücken, keine Reihen), dazu einige Felsmodelle und Büsche als Details. Es gibt keine Kugel-/Kronen-Platzhalter mehr. Die Baumzahl der Landschaft ist als WIP-Wert begrenzt, mit Terrain als Hauptträger der Form.
  - Wasser: Fließt ein Fluss am Brettrand hinaus, darf er im Terrain sichtbar weiterlaufen (Terrain-Wasser), optional als WIP-Schalter. Wasserflächen auf dem Brett bleiben wie sie sind.
  - Kamera frei drehbar: Lösung für die flache Vorderseite wie in C4 (Grundausrichtung) beibehalten oder verbessern; in den Notizen nennen.
  - Fertig, wenn: Stub/Test prüft, dass kein Terrain oder Objekt Brettfelder überdeckt (Terrain-Oberfläche im Brettbereich unter Feldhöhe bzw. geräumt), die Vorderseite unter einer WIP-Höchsthöhe bleibt, hinten/seitlich höher ist, der Thronsaal-Bereich frei bleibt und dass alles deterministisch und vollständig aufgeräumt wird (zweiter Aufbau mit anderer Karte hinterlässt kein altes Terrain). Teile/Dreiecke vorher/nachher.

- [ ] 3. **Felshügel statt Würfel** – `BoardBuilder` (Bodenaufbau `M`/`C`, Felswände aus C3), `LandscapeBuilder` bzw. eigener Helfer, `Config`
  - Zusammenhängende `M`-Gruppen werden zu einem **organischen Felshügel aus Terrain** geformt (Rock/Slate, Grass an flachen Stellen, WIP). Die Hügelform greift über Feldgrenzen weich ineinander. **Auf jedem `M`-Feld** bleibt um die Feldmitte eine **ebene Standfläche in Feldhöhe** (`TERRAIN.M.height`), damit Figur, Overlay und Auswahlring richtig sitzen; Terrain ragt dort nicht über die Overlays.
  - `C`-Klippen werden als steilere, höhere Felsformation aus Terrain gebaut (unpassierbar, Oberkante unregelmäßig). Die Wasserfälle (`BoardBuilder.waterfall`) setzen an der neuen Oberkante richtig an.
  - Die braunen Kistenkörper und die Wedge-Facetten aus C3 entfallen für `M`/`C`, oder sie werden vollständig vom Terrain verdeckt (dann nicht mehr sichtbar und ohne CastShadow). Die Klick-Kacheln bleiben (Raycast ignoriert Terrain).
  - **Größere Felsmodelle** aus dem Paket als Details auf und an den Hügeln (mehrere Größen, nur am Rand und an den Hängen, nicht auf der Standfläche).
  - Feldraster und Feldgrenzen bleiben auf `M` erkennbar (z. B. Rasterlinien über der Standfläche). In den Notizen beschreiben, wie.
  - Fertig, wenn: Stub prüft ebene Standflächen auf allen `M`-Feldern (Terrain-Oberfläche an der Feldmitte ≈ Feldhöhe, keine Überdeckung der Overlay-Höhe), Klippen unpassierbar und höher, Felsmodelle nicht auf Standflächen, Klickbarkeit erhalten, Wasserfall-Anschluss korrekt. Teile/Dreiecke vorher/nachher.

- [ ] 4. **Messung + Prüfskripte** – Tests für alle Schritte. In den Notizen: Teile, geschätzte Dreiecke, Terrain-Volumen/Schreibaufrufe und Stub-Aufbauzeit vorher/nachher (100 Seeds, Paket-Fixtures). Tutorial-Karten bauen weiterhin fehlerfrei; ihre Umgebung nutzt dieselbe Landschaft.

- [ ] 5. **Abschluss:** `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-run-ui.ps1` alle OK, dazu Rojo-Build. Devlog **#37** „Level-Optik Etappe C5“ (inklusive Optik-Standard: natürliche Formen, eingebettete Karte, keine Platzhalter), „Nächste Schritte“ aktualisieren. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Spielfeld liegt in einem Wiesental: Grashügel mit Baumgruppen, hinten/seitlich felsige Berge im Dunst; vorne flach, nichts verdeckt das Brett; keine Kugel-Platzhalter, kein Ring aus Einzelobjekten
- [ ] Ganz herausgezoomt und beim Drehen kein harter Rand / keine leere Fläche
- [ ] Bergfelder sind natürliche Felshügel mit Felsen; Figuren stehen sauber auf Bergfeldern, Bewegungsfelder sind sichtbar und anklickbar
- [ ] Klippen als Felsformation, Wasserfälle setzen richtig an
- [ ] Wald luftiger (1–2 Bäume pro Feld)
- [ ] Thronsaal unverändert; Tutorial-Missionen sehen ordentlich aus
- [ ] Aufbauzeit („Missionsaufbau …“) im Rahmen, Handy weiterhin flüssig

## Nicht anfassen
- Spielregeln, Generator, Brücken, Ufer, Wiesen-Deko, Umrisse, UI, Lager-/Boss-Logik

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1: 35 % zweite B?ume, ein Baum 0,22 Felder au?ermittig; C4-Kronenma?e erhalten. Paket-/Fallback-Stubs pr?fen jedes Waldfeld und Determinismus. Fallback mit kantiger Tannensilhouette statt Kugelkronen. Ausgangsstand `ad26c63`: 1.989,5/2.128 Teile, 343.195/495.996 gesch?tzte Dreiecke, 101,43/126,15 ms Stub-Aufbau (Mittel/Max; 100 Seeds).
- Schritt 1 nachher: 1.908,0/2.072 Teile, 282.045/368.996 gesch?tzte Dreiecke, 95,27/126,74 ms Stub-Aufbau; Syntaxcheck gr?n.
- Schritt 2: Terrain-Tal mit 1,5 Feldern flachem Rand, ansteigenden Grash?geln und Fels-/Schieferkuppen hinten/seitlich. 12 lockere Cluster mit maximal 32 echten Paketb?umen; ohne Paket tr?gt Terrain die Umgebung, keine Kronen-Ersatzteile. Sichtboden-Parts und Ringkonfiguration entfernt. Fernboden bis zum bisherigen Zoomrand in gro?en Terrain-Bl?cken; detaillierte Nahlandschaft in 32?32-Voxelbl?cken. Hub-Schutz ?80/?100 Studs wird vor jedem Schreib-/L?schaufruf geometrisch ausgespart. Jeder Aufbau l?scht die alten und neuen Fl?chen, auch bei gleicher Gr??e. Vorderseite bleibt wie C4 in Grundausrichtung +Z, Kamera unver?ndert frei drehbar. Optionale Flussfortsetzung vorerst ausgelassen. Material/Farben pro Region in Stages. Nachher: 1.863,7/2.020 Teile, 279.952/370.596 gesch?tzte Modelldreiecke, 200,47/217,45 ms Stub-Aufbau (inklusive Terrain-Stubs; reale Roblox-Zeit offen). Tests pr?fen Schreibdaten und Hub-Sentinel, keine gerenderte Terrain-Oberfl?che.
