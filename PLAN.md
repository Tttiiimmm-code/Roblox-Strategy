# PLAN: Level-Optik Etappe C2 – Creator-Store-Modelle, dichter Wald, gewölbte Brücken, runde Ufer

Ziel: Die Lauf-Karten sollen wie die **Nutzer-Vorlage** aussehen (gemalte Taktikkarten von oben: dichte Wälder, geschwungene Flüsse mit kleinen Brücken, runde Ufer, belebte Wiesen). C1 hat Größe und Generator geliefert. C2 setzt die **vom Nutzer ausgewählten Creator-Store-Modelle** richtig ein und verbessert die Bodenoptik.
Branch: `feature/level-optik-c` (enthält Phase 3 + C1)

**Modelle (liegen als Paket vor):** `assets/environment/grasland_pack.rbxm` → `ServerStorage.EnvironmentModels.grasland_pack` (Ordner). Inhalt laut Import (Befehlsleiste, `scripts/studio/umgebung-import.luau`):
`tree_1…20`, `bush_1…3`, `deco_root_1…5` (Yasu's Stylized Tree Pack), `rock_1…49` (Stylized Rock Pack), `deco_flower_1…3`, `deco_grass_1`, `deco_fence_1`, `archbridge_1`, Ordner `materials` (5 MaterialVariants, von den Modellen nicht genutzt). Alle Vorlagen sind Models mit Namen `<kategorie>_<nr>`, Vorschaugröße normiert (größte Seite 8 Studs). Credits: `assets/environment/README.md`.

**Aufbau der Modelle (vom Nutzer in Studio ausgelesen):**
- Baum/Busch: Model aus 2 MeshParts: Stamm (`Material=Wood`, SurfaceAppearance `AlphaMode=Overlay`) + Krone (`Material=LeafyGrass`, SurfaceAppearance `AlphaMode=Transparency`). `MeshPart.Color` grau (163,163,163), keine TextureID. Die Kronentexturen sind laut Urheber farblos und zum Umfärben gedacht.
- Fels: einzelner MeshPart mit TextureID, Formen sehr unterschiedlich (z. B. `rock_1` flach 7,5×1,6×8).
- Brücke `archbridge_1`: ein MeshPart mit TextureID, **gewölbt**, Maße ≈ 8,0 lang × 2,1 hoch × 2,3 breit (Länge entlang X der Vorlage – Ausrichtung prüfen).
- Gras: eine UnionOperation (4,7×8×4,8). Zaun: Model aus 10 Unions/Parts, Länge entlang Z. Blumen: Model aus 2 MeshParts (Stängel + Blüten, über `Color` gefärbt).

**Nutzerentscheidungen (09.10.2026):**
- Modelle aus dem Creator Store: siehe oben (Yasu für Bäume + Büsche, Felspaket F2, drei Blumenfarben, Gras, Zaun)
- **Felsen in verschiedenen Größen**: große Größenspanne, kleine Felsen zusätzlich als Deko-Steinchen
- **gewölbte Brücken**: eine Brücke pro Querung, Figuren stehen auf dem Bogen
- **Wald 2–3 Bäume pro Waldfeld**, dazu Busch/Wurzel; **Figuren im Wald mit Umriss**
- **Wiesen-Deko mittel**: etwa jedes zweite Wiesenfeld 1–2 Grasbüschel, ab und zu Blumen/Steinchen, selten Zaun
- **Wasserfälle auf etwa jeder 6.–8. Karte**, auch an Seen statt nur am linken Rand
- **Kronen pro Region umfärben, mit Mischung**: Grasland meist grün mit einigen Herbstbäumen, später Sumpf dunkelgrün, Eis weiß, Vulkan verbrannt
- Bodentexturen malt der Nutzer selbst (`Config.GROUND_TEXTURES`, nicht Teil von C2)

**Bestehender Code:**
- `src/server/EnvironmentAssets.luau`: `variants(category)` (Claude hat in 18698ea Ordner-Pakete + MaterialVariants ergänzt), `place(category, cframe, opts)` skaliert anhand von `Config.ENVIRONMENT.categories[category]` und `sizeVariation`
- `src/server/BoardBuilder.luau`: `decorate(ch, x, y, parent, mapKey)` setzt Eckobjekte; `bridgeAngle`; Bodenaufbau; `waterfall(feature, parent)`
- `src/shared/Config.luau`: `ENVIRONMENT` (Kategorien, `decoChance`, `bushChance`, `edgeInset`, `outer`), `TERRAIN.B.height = 0.2`, `FEEL`
- `src/shared/Grid.luau`: `toWorld`/`tileHeight` (19 Aufrufe von `Grid.toWorld` in `src`)
- `src/shared/LevelGen.luau`: `cliffs(...)` mit Wasserfall nur am linken Flussende, `RunConfig.WATERFALL_CHANCE`
- `src/shared/Stages.luau`: Region mit `treeColor`
- `src/client/UnitAnimator.luau:131` und `TutorialGuide.luau:107` nutzen bereits `Highlight` (Roblox zeigt höchstens ~31 Highlights gleichzeitig)
- `src/client/CameraController.luau`: Kamera schaut aus +Z schräg nach unten (`offset = (0, 1, 0.75)` mit `rotation`)

**Leitlinien:**
- Tutorial-/Story-Karten dürfen von den neuen Modellen profitieren, ihre Karten und Regeln bleiben aber unverändert.
- Ohne Paket (keine Varianten) bleibt die bisherige Part-Deko vollständig funktionsfähig, das ist in den Tests Pflicht.
- **Handy-Leistung:** Nach jedem großen Schritt Teilezahl und geschätzte Dreiecke des Bretts in den Notizen festhalten. Ziel ≤ 300.000 Dreiecke für eine typische 16×12-Karte inklusive Umgebungsrand. Alle Mengen (Bäume pro Feld, Deko-Quote, Schatten) als WIP-Werte in `Config`.
- Determinismus: gleiche Karte = gleiche Deko.
- Ein Commit pro Schritt, alle Prüfskripte grün.

## Schritte

- [x] 0. **Review der Lader-Änderung von Claude** (Commit 18698ea, `EnvironmentAssets.variants`): Ordner-Pakete werden durchsucht, und MaterialVariants landen im MaterialService. Befunde unter Notizen festhalten und kleine Fehler direkt beheben. Ergänze einen Test: Paket-Ordner mit `tree_1`/`tree_2` und ein loses `rock_1` werden erkannt, Namen ohne Muster werden ignoriert.

- [x] 1. **Dichter Wald** – `BoardBuilder.decorate` (Fall `F`), `Config.ENVIRONMENT`
  - Pro Waldfeld **2–3 Bäume** (WIP `treesPerForestTile = {min = 2, max = 3}`). Die Positionen werden deterministisch im Feld gestreut, Kronen dürfen in Nachbarfelder ragen. Baumgröße deutlich größer als bisher (WIP etwa 1,0–1,4 Felder hoch und 0,6–0,9 Felder breit), mit Größenstreuung.
  - Dazu mit WIP-Wahrscheinlichkeit ein Busch (`bush`) oder eine Wurzel (`deco_root`) am Feldrand.
  - Eigene Platzierungsgrößen für Baum/Busch/Wurzel im Wald, damit Eck-Deko und Umgebungsrand (`outer`) ihre eigenen Werte behalten.
  - Fallback ohne Varianten: bisherige Part-Bäume.
  - Fertig, wenn: Waldfelder wirken geschlossen; Teile/Dreiecke vorher/nachher in den Notizen.

- [x] 2. **Umriss für Figuren im Wald** – Client (Figuren-Darstellung, z. B. `UnitAnimator`), `Config`
  - Figuren auf Waldfeldern bekommen einen `Highlight`-Umriss, der durch Bäume sichtbar ist (`DepthMode = AlwaysOnTop`, Füllung unsichtbar oder sehr schwach). Teamfarbe: Spieler blau, Gegner rot (Werte in Config). Dasselbe gilt für Figuren auf Feldern, die von Kronen verdeckt werden: das Feld direkt hinter einem Waldfeld aus Kamerasicht. Wie du diese Felder bestimmst, entscheidest du; nenne die Regel in den Notizen.
  - **Highlight-Budget:** Bestehende Highlights (Auswahl, Tutorial) dürfen nicht verdrängt werden. Begrenze die Wald-Umrisse auf einen Config-Wert (z. B. 20). Ist das Budget voll, haben die Figuren des Spielers Vorrang.
  - Der Umriss folgt Bewegung, Tod und Phasenwechsel: kein Umriss bleibt hängen.
  - Fertig, wenn: Ein Test oder Stub prüft Budget, Vorrang und Aufräumen.

- [x] 3. **Kronenfarbe pro Region** – `Stages`/`Config`, `EnvironmentAssets` oder `BoardBuilder`
  - Pro Region eine gewichtete Farbmischung für Kronen (WIP), zum Beispiel Grasland: meist mittelgrün, etwas hellgrün und etwa 10 % Herbst orange/rot. Für Sumpf, Eis und Vulkan legst du Platzhalterwerte an.
  - Die Farbe gilt nur für Kronen-Teile: MeshParts mit `LeafyGrass` oder mit einer SurfaceAppearance mit `AlphaMode = Transparency`. Der Stamm bleibt unverändert. Setze sie über `SurfaceAppearance.Color` (mit pcall; schlägt das zur Laufzeit fehl, Hinweis in die Notizen und auf `MeshPart.Color` ausweichen). Gilt für Bäume, Büsche und den Umgebungsrand, deterministisch pro Platzierung.
  - Fertig, wenn: Die Farbe ist pro Baum deterministisch und Stämme bleiben unverändert (Test mit Stub-SurfaceAppearance).

- [x] 4. **Felsen in verschiedenen Größen + Deko-Steinchen** – `BoardBuilder.decorate` (Fall `M`, Klippen `C`), `Config`
  - Bergfelder: zum Beispiel ein großer Fels und 1–2 kleinere, Größenspanne als WIP-Wert (etwa 0,5×–1,6× der Grundgröße), freie Drehung.
  - Klippen (`C`): ein paar große Felsen auf der Oberkante, damit die Blöcke weniger glatt wirken. Klickbarkeit bleibt erhalten, weil die Modelle nicht abfragbar sind.
  - `deco_stone`: Gibt es keine eigenen `deco_stone_*`-Varianten, werden Felsvarianten in Deko-Größe genutzt.
  - Fertig, wenn: In einer Testkarte wird eine sichtbare Größenstreuung geprüft (Stub-Maße).

- [x] 5. **Gewölbte Brücken** – `BoardBuilder`, `Grid`, Client-Overlays, `Config`
  - Für jede Querung (zusammenhängende `B`-Felder quer zum Fluss) **ein** `archbridge`-Modell, das von Ufer zu Ufer über die ganze Querung reicht. Ausrichtung je nach Flussrichtung; achte darauf, dass die Längsachse der Vorlage stimmt.
  - Unter der Brücke sieht man Wasser: `B`-Felder zeigen bei vorhandenem Modell Wasserboden statt Holzboden, die Wasserhöhe bleibt wie bei `W`.
  - **Figuren stehen auf dem Bogen:** Höhe pro `B`-Feld (und, falls die Brücke darauf aufliegt, pro Uferfeld), zum Beispiel einmalig beim Aufbau per Raycast auf das Brückenmodell gemessen oder aus einem Profil berechnet. Die Höhe muss Server **und** Client bekannt sein: Figurenposition, Bewegungs-Overlays, Auswahlring, Blob-Schatten (`UnitShadow`), Kampfkamera. Zentral über `Grid` lösen (zum Beispiel eine Höhenkorrektur pro Feld, die `toWorld` berücksichtigt), statt an jeder Stelle einzeln.
  - Akzeptanz: Die Füße stehen höchstens ±0,3 Studs neben dem Brückenboden. Ohne `archbridge`-Variante bleiben bisherige Brücken und Höhen unverändert. Tests für Querungs-Erkennung (1 und 2 Felder breit), Ausrichtung und Höhenkorrektur.

- [x] 6. **Runde Ufer mit Sandstreifen** – `BoardBuilder` (Bodenaufbau), `Config.FEEL`
  - Ufer sollen rund statt rechteckig wirken: an Landfeldern neben Wasser ein schmaler Sand- oder Uferstreifen, an konvexen Ecken abgerundete Übergänge (zum Beispiel Zylinder-Teile), an konkaven Ecken passende Füllstücke. Raster, Klickfelder und Feldfarben bleiben eindeutig erkennbar, Brückenenden bleiben frei.
  - Teilebudget als WIP-Wert; Teilezahl vorher/nachher in den Notizen.

- [x] 7. **Wiesen-Deko mittel** – `BoardBuilder.decorate` (Fall `.`), `Config.ENVIRONMENT`
  - Etwa jedes zweite Wiesenfeld 1–2 Grasbüschel (`deco_grass`), dazu ab und zu Blumen (`deco_flower`, drei Farben) oder Steinchen, selten ein Zaunstück (`deco_fence`). Positionen am Feldrand, die Feldmitte bleibt frei (Zug-Ring/Figur sichtbar). Alle Quoten als WIP-Werte.
  - Start- und Gegnerfelder bleiben gut lesbar, keine Deko auf Feldern mit Figuren beim Start.

- [x] 8. **Wasserfälle auf etwa jeder 6.–8. Karte** – `LevelGen`, `RunConfig`
  - Wasserfälle auch an Seen und an anderen Flussenden, nicht nur links (Klippe am Ufer, Fall ins Wasser). Ziel-Quote 12–17 % der normalen Laufkarten, im Generatortest messen.
  - Die Bedingungen aus C1 bleiben (Lösbarkeit, Startzone, `BoardBuilder.waterfall` prüft `C` → `W`).

- [x] 9. **Prüfskripte + Messung** – Tests für alle Schritte. In den Notizen: Teile und geschätzte Dreiecke je Karte (Mittel/Max über 100 Seeds, mit Stub-Varianten in Originalgröße der Kategorien) und Stub-Aufbauzeit.

- [ ] 10. **Abschluss:** `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-run-ui.ps1` alle OK, dazu Rojo-Build. Devlog **#34** „Level-Optik Etappe C2“ (inklusive Creator-Store-Import und Credits-Hinweis), „Nächste Schritte“ aktualisieren. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Waldfelder dicht mit 2–3 Bäumen, Kronen gemischt gefärbt (meist grün, einige Herbstbäume), Stämme natürlich
- [ ] Figuren im Wald haben einen gut sichtbaren Umriss (blau/rot), der beim Bewegen/Sterben verschwindet; Auswahl- und Tutorial-Markierungen funktionieren weiter
- [ ] Gewölbte Brücken: eine pro Querung, Figuren stehen auf dem Bogen, Bewegungsfelder liegen richtig
- [ ] Ufer wirken rund, mit Sandstreifen; Felsen in verschiedenen Größen; Wiesen mit Gras, Blumen, Steinchen, vereinzelt Zaun
- [ ] Ab und zu ein Wasserfall, auch an Seen
- [ ] Alle Felder lassen sich anklicken/antippen, kein roter Output
- [ ] Handy: flüssig, Ladezeit („Missionsaufbau …“) im Rahmen

## Nicht anfassen
- Spielregeln, Generatorlogik außer Wasserfall-Quote/-Orte, Tutorial-Karten, Lager-/Boss-Logik, Bodentexturen (`GROUND_TEXTURES`-Werte setzt der Nutzer)

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)


## Notizen (Codex)

- Schritt 9: Tests für sämtliche C2-Schritte in `test-run.ps1` integriert; zusätzliche Fälle für fremde Highlight-Slots, Kameradrehung, entfernte Figuren, Material-Klonfehler, Skript-/Sound-Bereinigung, vollständigen Brettdeterminismus und den echten Server-Höhensnapshot. Aus dem lokalen Rojo-Export maßhaltige Fixtures aller **83 Paketmodelle / 118 Teile** erzeugt (Originalgrößen, Rotationen, Teileklassen und Kronenmerkmale, ohne Mesh-Geometrie). WIP-Mengen auf das typische Budget abgestimmt: weiterhin 2–3 Bäume/Feld (dritter Baum 10 %), Busch/Wurzel 20 %, weiterhin 1–2 kleine Felsen (zweiter 35 %), Wiesenquote unverändert 50 %. Pflichtcheck/test-run grün.
- Endmessung Schritt 9, gleiche 100 Grünland-Seeds, 16×12, sechs Starts, inklusive Umgebungsrand: mit Original-Paketfixtures **1.762,2 Teile im Mittel / max. 1.971**, Dreiecke geschätzt **296.921 im Mittel / max. 453.272**, **87,87 ms Stub-Aufbau im Mittel**. Ohne Paket **1.936,9 Teile im Mittel / max. 2.350**, **41,77 ms Stub-Aufbau**. Typisches geschätztes Ziel ≤ 300.000 wird im Mittel geprüft; dichte Maximalfälle liegen darüber. Mesh-IDs referenzieren externe Geometrie; die lokale Datei enthält keine brauchbaren Render-Dreieckzahlen (VertexCount/TriangleCount 0). Schätzannahmen aus Schritt 1 unverändert, Zaun mit tatsächlichen 8 Unions/2 Parts genauer. Reale Dreiecke, Asset-Ladezeit, Raycast-Oberfläche und Handy-Bildrate bleiben ausdrücklich ungemessen; kein Studio-/Handy-Ergebnis behauptet.

- Schritt 8: Wasserfall-Klippen können an jedem geeigneten W-Ufer entstehen, auch an Seen und in allen vier Richtungen; Startzone, reservierte Brückenufer und bestehende Gewässer bleiben geschützt. Normale Klippenquote/andere Generatorregeln unverändert. Bedingte WIP-Wasserfallchance 0,56 ergibt in 1.000 normalen Grünlandkarten **15,60 %** (Ziel 12–17 %); See-Wasserfälle und alle Richtungen im Test nachgewiesen. 19.000 Level-/5.000 Optionsprüfungen, 96 erzwungene Landschaftskombinationen und 2.400 Boss-/Minibosskarten grün, kein ungewollter Fallback. Brett-/Lauftest ebenfalls grün; endgültige Messung mit 0,56 folgt in Schritt 9.

- Schritt 7: Etwa 50 % der unbesetzten Wiesenfelder bekommen 1–2 Grasbüschel, zusätzlich gelegentlich Blumen/Steinchen und selten Zaun. Alle Quoten in Config; deterministische Eckpositionen mit freier Feldmitte. Server gibt die tatsächlichen Slots/Gegner des Levels an BoardBuilder weiter; dort keine Wiesen-Deko oder Bodenflecken. Ohne Modelle Part-Gras als Ersatz. Stub prüft Dichte/Kategorien/Feldmitte/Starts/Determinismus/Fallback, check/test-run grün. Messung: Mittel 1.839,0 / max. 2.116 Teile; geschätzt Mittel 353.083 / max. 584.448 Dreiecke; Stub-Aufbau 95,14 ms. WIP-Mengen werden in Schritt 9 innerhalb der gewünschten Bereiche auf das typische Dreieckbudget abgestimmt.

- Schritt 6: Schmale Sandstreifen mit verkürzten Tangenten, runde Sand-/Landkappen an konvexen Ecken, Füllscheiben an konkaven Ecken. Konvexe Boden-Kappen werden optisch durch eine wasserfarbige Maske gerundet; Geländehöhen/Regeln/Klickraster unverändert. WIP-Budget maximal 12 zusätzliche Parts je Feld, abschaltbar; Brückenenden und gemessene Ufer bleiben frei. Stub prüft Formen, Klickbarkeit, Budget und Abschaltung; check/test-run grün. Vorher Mittel 1.747,3 / max. 2.062 Teile, danach Mittel 1.797,5 / max. 2.129; Dreiecke geschätzt Mittel 330.337 / max. 568.430; Stub-Aufbau 108,53 ms. Darstellung der optischen Rundung in Studio noch ungetestet.

- Schritt 5: `Grid.bridgeCrossings` erkennt zusammenhängende B-Querungen und ihre Längsachse. Originalpaket geprüft: `archbridge_1` ist 8,0 × 2,1277 × 2,2514 Studs, X-Längsachse ohne Rotation. Je Querung ein proportional skaliertes Modell mit 0,65 Feldern Uferüberstand; Wasserboden unter B-Feldern. Synchroner Include-Raycast entlang der Mitte misst Brücken- und bedeckte Uferfelder; danach alle Modelle wieder nicht abfragbar. Ist ein B-Feld nicht messbar, sichere bisherige Part-Brücke statt einer geratenen Fußhöhe. Absolute Feldhöhen zentral in Grid; Server-Snapshot überträgt sie vor Client-Markierungen/Tutorial. Damit profitieren Figuren, Overlays, Ringe, UnitShadow und Kampfkamera. Stub prüft 1/2 Felder, beide Achsen, Spannweite, Wasser, Ufer, Höhenübertragung und beide Fallbacks; check/test-run grün. ±0,3 Studs gegenüber Stub-Raycast bestätigt; reale Kollisionsoberfläche/Fußstellung bleibt Studio-Test. Messung: Mittel 1.747,3 / max. 2.062 Teile, geschätzt Mittel 326.872 / max. 568.430 Dreiecke, Aufbau 78,46 ms.

- Schritt 4: Ein großer Fels plus 1–2 kleine je Bergfeld, freie Drehung und getrennte WIP-Größen; 1–2 Felsen je Klippenoberkante. `deco_stone` nutzt bei fehlender eigener Kategorie Felsvarianten in Steinchengröße. Größenstreuung/Klickbarkeit/Ersatz im Stub geprüft; check/test-run grün. Messung nach Schritt 4: 1.748,8 Teile im Mittel / max. 2.062, geschätzt 324.891 Dreiecke im Mittel / max. 568.430, Stub-Aufbau 74,03 ms (100 Seeds). Part-Fallback bleibt aktiv; neue Klippenfelsen erhöhen dessen Teilezahl leicht auf Mittel 1.852,9.

- Schritt 3: Gewichtete regionale Kronenpaletten zentral in Config und über Stages weitergegeben; Grünland 90 % Grün / 10 % Herbst, Platzhalter für Sumpf/Eis/Vulkan. Nur LeafyGrass-MeshParts bzw. transparente SurfaceAppearances gefärbt; Stämme unverändert. `SurfaceAppearance.Color` per pcall, bei fehlender Laufzeitunterstützung einmalige Warnung und `MeshPart.Color`. Stub erzwingt den Fehlerzweig und prüft Determinismus/Stämme/Herbstquote; check/test-run grün. Roblox dokumentiert Laufzeit-Tinting unter https://create.roblox.com/docs/art/modeling/surface-appearance. Das vom Nutzer exportierte Paket wird mit diesem Schritt aufgenommen; Rojo-Import bestätigt. Brett-Geometriebudget unverändert. Laufzeit-Farbersatz nur im Stub ausgelöst, Studio noch ungetestet.

- Fortsetzung: Nutzer hat `grasland_pack.rbxm` bereitgestellt; offene Frage entfernt. Rojo liest einen Paketordner mit 20 Bäumen, 3 Büschen, 5 Wurzeln, 49 Felsen, 3 Blumen, Gras, Zaun und gewölbter Brücke ein.
- Schritt 2: Waldumrisse zentral in `ForestOutlines`; maximal 20, Gesamtbudget 31 mit mindestens 8 reservierten Slots, zusätzliche fremde Highlights werden berücksichtigt. Spieler vor Gegnern, stabile Reihenfolge nach UnitId. Verdeckung: auf Wald oder direkt hinter Wald entlang der dominanten horizontalen Blickachse; dreht sich mit der Kamera. Bewegung anhand der aktuellen Root-Position, Tod anhand Hp/Todesanimation, Aufräumen bei Kampfende. Stub für Budget/Vorrang/Kameranachbar/Bewegung/Tod/Kampfende und test-run/check grün. Teile-/Dreieckzahl des Bretts unverändert, Umrisse sind keine Meshes.

- Schritt 1: Mit Baumvarianten deterministisch 2–3 größere Bäume je Waldfeld und optional Busch/Wurzel. Eigene Waldgrößen in Config; Eck- und Randgrößen unverändert. Ohne Varianten weiterhin die ursprünglichen zwei Part-Bäume. Stub prüft Baumanzahl; alle bisherigen Brett-/Laufprüfungen grün. Darstellung in Studio/auf Handy ungetestet.
- Messung Schritt 1, jeweils 100 Grünland-Seeds, 16×12 inklusive Rand, mit maßhaltigen Kategorie-Stubs: vorher 1.682,4 Teile im Mittel / max. 1.923, geschätzt 279.005 Dreiecke im Mittel / max. 457.530, Stub-Aufbau 69,07 ms; danach 1.755,9 Teile im Mittel / max. 2.068, geschätzt 330.515 Dreiecke im Mittel / max. 574.030, Stub-Aufbau 84,79 ms. Annahmen je Modell: Baum/Busch 1.500, Fels 800, Wurzel 500, Gras 300, Blume 350, Zaun 2.000 Dreiecke; primitive Teile separat geschätzt. Keine gemessenen Mesh-Dreieckzahlen, da das reale Paket fehlt. Die Schätzung überschreitet das Ziel; reale Dreiecke und Handy-Leistung müssen vor einer Leistungsfreigabe geprüft werden. Aufbauzeiten sind Stub-Zeiten ohne Roblox/Rendering/Asset-Download.

- Schritt 0: Review von Claude-Commit 18698ea: Ordner-Pakete und lose Modelle korrekt, Namensfilter ignoriert unpassende Namen. Nicht klonbare MaterialVariants abgesichert. Neuer Lader-Stub grün; test-run grün. Ausgangswert ohne Paket, 100 Seeds: 1.848,6 Teile im Mittel, max. 2.305; Stub-Aufbau 61,65 ms im Mittel. Dreieckschätzung folgt mit den Kategorie-Stubs in Schritt 1/9.
