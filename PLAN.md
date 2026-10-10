# PLAN: Level-Optik Etappe C7 – helles Spielfeld, Terrain-Wasser, echte Berge/Klippen, sichtbare Wasserfälle (mit Studio-Prüfung)

Ziel: Die Befunde aus Claudes eigenem Studio-Test von C6 beheben. **Neu: Codex prüft jeden Optik-Schritt selbst in Roblox Studio** (Studio-MCP ist für Codex aktiv) mit Bildern statt nur mit Rechentests. Rechentests allein haben in C6 nicht erkannt, dass Terrain-Glättung Wasserfälle verdeckt.
Branch: `feature/level-optik-c` (enthält Phase 3, C1–C6)

**Befunde aus Claudes Studio-Test (10.10.2026, Seed-Lauf + gezielt gebaute Wasserfallkarte):**
1. **Spielfeld viel zu dunkel:** Bodenteile `Ground_*` sind `Material.Grass` mit Farbe ≈ (73,86,64) bzw. (65,77,57). Auf Parts wirkt das Grass-Material deutlich dunkler als dasselbe Material im Terrain (`SetMaterialColor` Grass = (88,115,72)). Das Spielfeld ist fast schwarzgrün und dunkler als die Umgebung; Felder und Raster sind kaum unterscheidbar. Die Client-Beleuchtung ist korrekt (battle-Preset: Brightness 2,2, Exposure 0,1, ColorCorrection Sat 0,18). Im Ort liegen zusätzlich `Lighting.ColorGrading` (ColorGradingEffect) und `Lighting.Bloom`, vom Nutzer in Studio angelegt; nicht anfassen.
2. **Wasserfälle unsichtbar:** Seed 18 (`LevelGen.generate(18, "greenland", 1, "lance", 3, "battle")`, Wasserfall x=12, y=2, dy=1). Die Teile werden gebaut (`WaterfallSource` y≈8,1, `Waterfall` bei z=16), aber die Terrain-Klippe ist eine runde Felskuppe bis ≈11 Studs, die über die Feldkante hinausragt und die Fallfläche vollständig verdeckt. Von der Kamera sieht man nur einen dünnen hellblauen Strich. Smooth Terrain rundet zwischen 4-Stud-Voxeln und ragt über die rechnerische Belegung hinaus.
3. **Bergfelder wirken wie Plattformen mit Trittplatten:** Die grauen Standkappen (4,4×4,4×0,4) sind als eckige Fliesen sichtbar, und der abgesenkte Hügel wirkt nicht mehr wie ein Berg.
4. **Klippen (`C`) sind runde Felskuppen** statt steiler Felswände.
5. **Wasser** ist ein flaches, hellblaues `SmoothPlastic`-Rechteck (Transparenz 0,18) mit harten Kanten, das nicht zum Terrain passt.

**Nutzerentscheidungen:** C5: Bergfelder **Terrain + Felsmodelle**, Umgebung Tal. C6: Spielfeld **Roblox-Materialien passend zum Terrain**, Wasserfälle auf etwa jeder 4.–5. Karte. **Neu (10.10.2026): Wasser auf dem Spielfeld als Terrain-Wasser** (Wellen/Spiegelung; das Raster zeigt die Feldgrenzen; ein Fluss darf über den Spielfeldrand ins Gelände weiterfließen).

**Bestehender Code:** `src/server/BoardBuilder.luau` (Bodenaufbau `Ground_*`, Wasserflächen, Standkappen, Felsmodelle, Ufer, `waterfall()`, Brücken mit Wasserboden unter `B`), `src/server/LandscapeBuilder.luau` (`surface()` für `M`/`C`, `rockFields`, `writeSurface`, Aufräumen, Landschaft), `src/shared/Grid.luau` (`setHeights`/`tileHeight`-Overrides, schon für Brücken genutzt, Server-Snapshot `tileHeights` an den Client), `src/shared/Config.luau` (`TERRAIN`, `LANDSCAPE`, `FEEL`), `src/shared/Stages.luau` (Regionspaletten), Client-Overlays/Auswahlring/`UnitShadow` nutzen `Grid.toWorld`.

**Studio-Prüfung (Pflicht für Schritte 1–5) – so hat Claude getestet:**
- `list_roblox_studios` → Ort „Throne Tales“. Rojo muss verbunden sein (prüfen: `ReplicatedStorage.Shared.Config.Source` enthält den aktuellen Stand).
- `start_stop_play(true)`. DataStore ist in Studio gesperrt, daher immer ein frisches Profil. Vom **Client** aus `ReplicatedStorage.Remotes.Command:FireServer`: `{type="TutorialChoice", play=false}`, dann `{type="StartRun", heroes={"leon","starter_mage","starter_knight"}}`, Optionen über `Remotes.GetProfile:InvokeServer().run.options`, dann `{type="ChooseLevel", index=<battle-Option>}`. „Missionsaufbau …“ steht in `get_console_output`.
- Für bestimmte Karten im **Server**-Kontext: `LevelGen.generate(seed, …)`, `Grid.setMap(stage.map)`, `BoardBuilder.build(stage.region or "greenland", stage.features, stage)`. `execute_luau` lädt frische Modulinstanzen, das ist fürs Bauen in Ordnung.
- Kamera: Im Play-Modus wirkt `screen_capture` mit Kameraposition nicht (die Spielkamera überschreibt sie). Stattdessen über `user_mouse_input` scrollen (Zoom) und über `user_keyboard_input` mit W/A/S/D verschieben, dann `screen_capture`.
- **Nur im Play-Modus bauen**, nie im Edit-Modus: Die Landschaft räumt große Terrainbereiche, das würde den Ort verändern. Nach der Prüfung `start_stop_play(false)`.
- In den Notizen pro Schritt beschreiben, was auf den Bildern zu sehen war (vorher/nachher). Wenn möglich die Bilder unter `docs/screenshots/c7/` ablegen.

**Leitlinien:** Klickbarkeit (Client-Raycast Include auf Board/Units, ignoriert Terrain), Figurenmitte, Overlays, Brückenhöhen, Umrisse, Determinismus und Part-Fallback bleiben erhalten. Alle Werte WIP in `Config`. Teile/Dreiecke/Terrain vorher/nachher. Ein Commit pro Schritt, alle Prüfskripte grün. Geschmacksfragen: zurückhaltende Variante, über Config umstellbar, in den Notizen nennen.

## Schritte

- [x] 1. **Helles, passendes Spielfeld** – `Config.TERRAIN`, `Stages`, `BoardBuilder`
  - Die Bodenfarben der Felder so wählen, dass sie im Spiel **gleich hell oder etwas heller als das umgebende Terrain-Gras** wirken; das Material-Abdunkeln auf Parts ausgleichen. Wiese, Wald (etwas dunkler), Erde/Weg und Fels bleiben klar unterscheidbar; Rasterlinien gut sichtbar, aber nicht schwarz. Werte pro Region.
  - Studio: Vergleichsbild Spielfeldrand ↔ Terrain bei Normalzoom; das Spielfeld darf nicht dunkler als die Umgebung wirken.

- [x] 2. **Terrain-Wasser** – `BoardBuilder` (Wasserflächen `W`, Wasser unter `B`), `LandscapeBuilder`, `Config`
  - `W`-Felder (und das Wasser unter Brücken) bestehen aus Roblox-**Terrain-Wasser** in passender Höhe (Wasseroberfläche ≈ bisherige Wasserhöhe). `Terrain.WaterColor`, `WaterTransparency`, `WaterWaveSize/Speed`, `WaterReflectance` pro Region (WIP, ruhig, nicht zu bunt). Ufer und Sandstreifen schließen sauber an.
  - Klick-Kacheln über Wasser bleiben (unsichtbar/abfragbar), damit Felder anklickbar bleiben; das Raster bleibt über dem Wasser sichtbar.
  - Fluss am Spielfeldrand: Das Terrain-Wasser läuft im Gelände ein Stück weiter, bis in den Dunst bzw. zu einer Senke (WIP-Schalter).
  - `D` (Sumpfwasser): entweder ebenfalls Terrain-Wasser oder bisherige Darstellung, in den Notizen begründen (`WaterColor` gilt global).
  - Aufräumen: Beim nächsten Brettaufbau verschwindet altes Wasser vollständig.
  - Studio: Bild eines Flusses mit Brücke und Ufer; Brücken und Figuren darauf sehen weiter richtig aus.

- [x] 3. **Echte Felshügel ohne Trittplatten** – `LandscapeBuilder.surface` (`M`), `BoardBuilder` (Standkappen, Felsmodelle), `Grid`, Server-Snapshot
  - Standkappen entfernen. Der Felshügel darf wieder **sichtbar hoch und natürlich** sein, gerne höher als `TERRAIN.M.height`, mit Felsmodellen am Hang.
  - **Standhöhe pro `M`-Feld = sichtbare Felsoberfläche an der Feldmitte**, beim Aufbau gemessen (Raycast nur gegen Terrain an der Feldmitte, bzw. über einen kleinen Bereich gemittelt) und über `Grid.setHeights` wie bei den Brücken an Server und Client übertragen. So stehen Figuren, Overlays, Auswahlring und `UnitShadow` auf dem Fels, ohne zu clippen und ohne zu schweben. Die Spielwerte von `M` (Kosten, Ausweichen, Verteidigung) bleiben unverändert.
  - Zielfelder auf Nachbarfeldern dürfen nicht verdeckt werden: Der Hügel fällt zur Feldgrenze hin ab bzw. bleibt im Nachbarfeld unter dessen Overlay-Höhe.
  - Studio: Nahaufnahme eines Berg-Clusters mit Figur darauf und markiertem Nachbarfeld. Keine Fliesen, kein Clipping, kein Schweben, Nachbarfeld frei.

- [x] 4. **Steile Klippen** – `LandscapeBuilder.surface` (`C`), `BoardBuilder`, `Config`
  - `C` wirkt wie eine **Felswand**: steile Seiten bis an die Feldkante, unregelmäßige Oberkante. Smooth Terrain rundet; deshalb an den Außenkanten große Felsmodelle aus dem Paket als Wandverkleidung (dicht genug, damit keine runde Kuppe sichtbar bleibt) oder eine andere robuste Lösung (in den Notizen begründen). Klippen bleiben unpassierbar und anklickbar.
  - Studio: Bild einer Klippengruppe aus Normalansicht. Eine Wand ist erkennbar, keine Kuppe.

- [ ] 5. **Wasserfälle sichtbar** – `BoardBuilder.waterfall`, `LandscapeBuilder` (Kanal), `Config.FEEL.waterfall*`
  - Die Fallfläche liegt **vor** der sichtbaren Klippenoberfläche und wird von keinem Terrain verdeckt. Den Kanal in der Klippe so breit und tief räumen, dass auch nach der Terrain-Glättung nichts darüber ragt. Die Fallfläche reicht von der sichtbaren Oberkante bis in das Terrain-Wasser. Die Gischt sitzt auf der Wasseroberfläche. Gerne breiter und auffälliger (WIP), weiterhin ohne teure Partikel.
  - Wenn nötig, die Generatorregel so anpassen, dass Wasserfälle an Klippenkanten entstehen, die zur Kamera (Grundausrichtung +Z) oder zur Seite zeigen und nicht nach hinten weg. Quote weiter 20–25 %.
  - Studio: Seed 18 und mindestens eine weitere Wasserfallkarte aus Normalansicht. Der Fall ist klar sichtbar.

- [ ] 6. **Abschluss:** Tests anpassen bzw. ergänzen (Rechentests bleiben). `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-run-ui.ps1` alle OK, dazu Rojo-Build. Devlog **#39** „Level-Optik Etappe C7“ inklusive Studio-Prüfweg. Committen, pushen, Studio im Edit-Modus lassen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Spielfeld hell und passend zur Umgebung, Felder und Raster gut erkennbar
- [ ] Flüsse/Seen aus Terrain-Wasser mit Wellen; Brücken, Ufer und Figuren sehen richtig aus; Fluss läuft am Rand ins Gelände weiter
- [ ] Bergfelder sind echte Felshügel, Figuren stehen sauber darauf, keine Fliesen, Nachbarfelder frei
- [ ] Klippen sind Felswände; Wasserfälle klar sichtbar (etwa jede 4.–5. Karte)
- [ ] Aufbauzeit („Missionsaufbau …“) im Rahmen, Handy flüssig

## Nicht anfassen
- Spielregeln, Generator (außer Wasserfall-Ausrichtung), Brückenlogik, Wiesen-Deko, Umrisse, UI, Lager-/Boss-Logik, Thronsaal, die vom Nutzer angelegten Lighting-Effekte (`ColorGrading`, `Bloom`), den Edit-Ort (nur im Play-Modus testen)

## Offene Fragen
- Blocker vom 10.10.2026 durch Studio-Neustart und Fortsetzungsauftrag behoben.
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1: Regionale Part-Aufhellung (Gras 0,4; Sumpf/Vulkan 0,42; Eis 0,12; Erde 0,2), regionale Farb-Overrides vor Terrainpalette; Rasterabdunklung 0,22. Studio-Bilder C7_Schritt1_Ausgangsansicht/Nachher: gleiche Laufkarte und Kamera; vorher dunkelgr?nes, schwer lesbares Brett, nachher heller als das angrenzende Terrain mit sichtbarem Raster und dunklerem Wald. Lighting-Effekte unver?ndert. check.ps1 und test-run.ps1 OK. Bildtest durch Codex, Nutzer-/Handytest offen.

- Schritt 2: W und Wasser unter B als Terrain-Voxel; regionale Wasserfarbe/Transparenz/Reflexion/Wellen in Config/Stages. Randfluss zentral abschaltbar, zehn Felder bis zur auslaufenden Senke. D bleibt bei der bisherigen Mud-/Pfuetzen-Darstellung, da WaterColor global gilt und D optisch schlammig bleiben soll. Studio C7_Schritt2_Terrainwasser/Bruecken_Ufer: statt blauem Rechteck bewegte Wasserstruktur/Spiegelung, beide Bruecken frei, Ufer anschliessend, Fluss laeuft beidseitig ins Tal. Figurenpositionen unveraendert; weitere gezielte Bruecken-Figurenprobe folgt im Abschluss. Kartenwechsel/Fortsetzungsschalter und Wasser unter Bruecken automatisch geprueft.

- Schritt 3 (in Arbeit, **nicht abgehakt, nicht committet**): Standplatten entfernt; Terrain-Felshuegel mit Randabfall; gemessene M-Mittenhoehen werden unter Erhalt der Brueckenhoehen in Grid gespeichert. Server-Snapshot und Client nutzen bereits diese Hoehen, daher dort keine Codeaenderung erforderlich. Raycast startet oberhalb der moeglichen Felsoberkante. Erste Studio-Fixture: 16x12, M-Cluster bei (7-9,6-7)/(8,8), Leon-Modell auf (8,7), echter UnitShadow, Overlay auf Berg und Nachbarfeld (9,8). Bild C7_Schritt3_Bergfigur_Nachbar zeigte Huegel ohne Fliesen und Figur auf dem Fels; der Nachbaroverlay wurde am Rand noch verdeckt. Reale Terrain-Raycasts bestaetigten den Ueberhang. Reines starkes Absenken machte die Raender zwar frei, haette einzelne M-Felder zu tief gemacht; daher nicht uebernommen. Aktueller Ansatz: Bergkante -2, Gipfel 8 plus 1,5 Rauheit; begrenzte Randbelegung (0,5) auch in der Voxel-Schicht direkt unter Nullhoehe. **Dieser letzte Ansatz ist wegen Studio-Ausfall noch nicht bildgeprueft.** Keine Aussage, dass das Nachbarfeld bereits frei ist.
- Pruefstand beim Stopp: `check.ps1` OK (38 Dateien, Exit 0), `test-run.ps1` OK (Exit 0) einschliesslich Terrain-Wasser/Berge/Wasserfaelle. Wasserfall-Regressionspruefung unterscheidet jetzt erlaubten Kontakt mit Terrain-Wasser von Festterrain; diese Korrektur liegt zusammen mit Schritt 3 noch uncommittet vor. Die Rechentests simulieren den Terrain-Mesher weiterhin nicht. Vollstaendige Abschlusspruefungen, Vergleichsmessung, Devlog #39, Push und finale Edit-Modus-Bestaetigung stehen aus.
- Lokale Schritt-Commits: `357c02a` (Schritt 1), `f0b70f4` (Schritt 2). Unabhaengige unversionierte Dateien unter `docs/referenz/` waehrend der Arbeit erschienen; nicht angefasst oder gestaged. Screenshots wurden ueber Studio-MCP betrachtet; das Werkzeug lieferte keine lokalen Bildpfade, daher bisher keine Dateien unter docs/screenshots/c7/.

- Schritt 3 abgeschlossen: Randabstand berücksichtigt diagonale Nachbarn; verringerte obere Randdichte plus freie Randbelegung direkt unter Null vermeiden den real gemessenen Mesher-Überhang. Studio-Probe nach Neustart: Clusterhöhen ca. 5,5–9 Studs, Figurenfeld 6,75 Studs, äußerer Ausläufer 2,9 Studs. Bilder C7_Schritt3_Nahaufnahme/Bergfigur_Freier_Nachbar: sichtbarer Fels ohne Standplatten, Leon auf der gemessenen Oberfläche, blauer Nachbaroverlay vollständig frei. Terrain-Raycasts in allen flachen Feldern um den Cluster: kein Treffer über Bodenhöhe (Maximum -3,05). Vorher am Nachbarfeld bis 3,53 Studs Überhang. Probe: 1643 Brettnachkommen ohne zwei Testoverlays, 129024 Voxel; Volumenmessung enthält die Umgebung. Nachbarschaft nicht allein über den Mesher-Stub beurteilt. Probe-Module nur im Play-Modus mit task.wait pro Terrainblock; nach der Probe Play beendet. check.ps1 und test-run.ps1 OK; Nutzer-/Handytest offen.
- Schritt 4: Robuste Alternative zur dichten Paketverkleidung: abgesenkter Terrainkern plus senkrechter Slate-Kern und zwei günstige Wedge-Grate pro äußerer Feldseite, deterministische unregelmäßige Oberkante. Begründung: Paketfelsen sind rund und würden viele Meshes benötigen; die Wandlösung verdeckt den Mesher zuverlässig, bleibt innerhalb der C-Felder und funktioniert auch ohne Paket. Config.LANDSCAPE.cliffWalls schaltet sie zurück auf Terrain um. Quellkante des Wasserfalls bleibt frei. Studio C7_Schritt4_Vorher_Kuppen/Nachher_Waende bei gleicher Kamera: vorher runde Kuppe, nachher klar senkrechte Felswand und kantige Oberkante. Acht C-Felder: vorher 1664 Brettnachkommen / 126720 Voxel, nachher 1696 / 123648; +32 einfache Teile, +288 geschätzte Dreiecke, geringerer Terrainkern. Aufbau der Probe 0,55 s. check.ps1/test-run.ps1 OK. Studio nach Test im Edit-Modus; Nutzer-/Handytest offen.