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

- [ ] 0. **Review der Lader-Änderung von Claude** (Commit 18698ea, `EnvironmentAssets.variants`): Ordner-Pakete werden durchsucht, und MaterialVariants landen im MaterialService. Befunde unter Notizen festhalten und kleine Fehler direkt beheben. Ergänze einen Test: Paket-Ordner mit `tree_1`/`tree_2` und ein loses `rock_1` werden erkannt, Namen ohne Muster werden ignoriert.

- [ ] 1. **Dichter Wald** – `BoardBuilder.decorate` (Fall `F`), `Config.ENVIRONMENT`
  - Pro Waldfeld **2–3 Bäume** (WIP `treesPerForestTile = {min = 2, max = 3}`). Die Positionen werden deterministisch im Feld gestreut, Kronen dürfen in Nachbarfelder ragen. Baumgröße deutlich größer als bisher (WIP etwa 1,0–1,4 Felder hoch und 0,6–0,9 Felder breit), mit Größenstreuung.
  - Dazu mit WIP-Wahrscheinlichkeit ein Busch (`bush`) oder eine Wurzel (`deco_root`) am Feldrand.
  - Eigene Platzierungsgrößen für Baum/Busch/Wurzel im Wald, damit Eck-Deko und Umgebungsrand (`outer`) ihre eigenen Werte behalten.
  - Fallback ohne Varianten: bisherige Part-Bäume.
  - Fertig, wenn: Waldfelder wirken geschlossen; Teile/Dreiecke vorher/nachher in den Notizen.

- [ ] 2. **Umriss für Figuren im Wald** – Client (Figuren-Darstellung, z. B. `UnitAnimator`), `Config`
  - Figuren auf Waldfeldern bekommen einen `Highlight`-Umriss, der durch Bäume sichtbar ist (`DepthMode = AlwaysOnTop`, Füllung unsichtbar oder sehr schwach). Teamfarbe: Spieler blau, Gegner rot (Werte in Config). Dasselbe gilt für Figuren auf Feldern, die von Kronen verdeckt werden: das Feld direkt hinter einem Waldfeld aus Kamerasicht. Wie du diese Felder bestimmst, entscheidest du; nenne die Regel in den Notizen.
  - **Highlight-Budget:** Bestehende Highlights (Auswahl, Tutorial) dürfen nicht verdrängt werden. Begrenze die Wald-Umrisse auf einen Config-Wert (z. B. 20). Ist das Budget voll, haben die Figuren des Spielers Vorrang.
  - Der Umriss folgt Bewegung, Tod und Phasenwechsel: kein Umriss bleibt hängen.
  - Fertig, wenn: Ein Test oder Stub prüft Budget, Vorrang und Aufräumen.

- [ ] 3. **Kronenfarbe pro Region** – `Stages`/`Config`, `EnvironmentAssets` oder `BoardBuilder`
  - Pro Region eine gewichtete Farbmischung für Kronen (WIP), zum Beispiel Grasland: meist mittelgrün, etwas hellgrün und etwa 10 % Herbst orange/rot. Für Sumpf, Eis und Vulkan legst du Platzhalterwerte an.
  - Die Farbe gilt nur für Kronen-Teile: MeshParts mit `LeafyGrass` oder mit einer SurfaceAppearance mit `AlphaMode = Transparency`. Der Stamm bleibt unverändert. Setze sie über `SurfaceAppearance.Color` (mit pcall; schlägt das zur Laufzeit fehl, Hinweis in die Notizen und auf `MeshPart.Color` ausweichen). Gilt für Bäume, Büsche und den Umgebungsrand, deterministisch pro Platzierung.
  - Fertig, wenn: Die Farbe ist pro Baum deterministisch und Stämme bleiben unverändert (Test mit Stub-SurfaceAppearance).

- [ ] 4. **Felsen in verschiedenen Größen + Deko-Steinchen** – `BoardBuilder.decorate` (Fall `M`, Klippen `C`), `Config`
  - Bergfelder: zum Beispiel ein großer Fels und 1–2 kleinere, Größenspanne als WIP-Wert (etwa 0,5×–1,6× der Grundgröße), freie Drehung.
  - Klippen (`C`): ein paar große Felsen auf der Oberkante, damit die Blöcke weniger glatt wirken. Klickbarkeit bleibt erhalten, weil die Modelle nicht abfragbar sind.
  - `deco_stone`: Gibt es keine eigenen `deco_stone_*`-Varianten, werden Felsvarianten in Deko-Größe genutzt.
  - Fertig, wenn: In einer Testkarte wird eine sichtbare Größenstreuung geprüft (Stub-Maße).

- [ ] 5. **Gewölbte Brücken** – `BoardBuilder`, `Grid`, Client-Overlays, `Config`
  - Für jede Querung (zusammenhängende `B`-Felder quer zum Fluss) **ein** `archbridge`-Modell, das von Ufer zu Ufer über die ganze Querung reicht. Ausrichtung je nach Flussrichtung; achte darauf, dass die Längsachse der Vorlage stimmt.
  - Unter der Brücke sieht man Wasser: `B`-Felder zeigen bei vorhandenem Modell Wasserboden statt Holzboden, die Wasserhöhe bleibt wie bei `W`.
  - **Figuren stehen auf dem Bogen:** Höhe pro `B`-Feld (und, falls die Brücke darauf aufliegt, pro Uferfeld), zum Beispiel einmalig beim Aufbau per Raycast auf das Brückenmodell gemessen oder aus einem Profil berechnet. Die Höhe muss Server **und** Client bekannt sein: Figurenposition, Bewegungs-Overlays, Auswahlring, Blob-Schatten (`UnitShadow`), Kampfkamera. Zentral über `Grid` lösen (zum Beispiel eine Höhenkorrektur pro Feld, die `toWorld` berücksichtigt), statt an jeder Stelle einzeln.
  - Akzeptanz: Die Füße stehen höchstens ±0,3 Studs neben dem Brückenboden. Ohne `archbridge`-Variante bleiben bisherige Brücken und Höhen unverändert. Tests für Querungs-Erkennung (1 und 2 Felder breit), Ausrichtung und Höhenkorrektur.

- [ ] 6. **Runde Ufer mit Sandstreifen** – `BoardBuilder` (Bodenaufbau), `Config.FEEL`
  - Ufer sollen rund statt rechteckig wirken: an Landfeldern neben Wasser ein schmaler Sand- oder Uferstreifen, an konvexen Ecken abgerundete Übergänge (zum Beispiel Zylinder-Teile), an konkaven Ecken passende Füllstücke. Raster, Klickfelder und Feldfarben bleiben eindeutig erkennbar, Brückenenden bleiben frei.
  - Teilebudget als WIP-Wert; Teilezahl vorher/nachher in den Notizen.

- [ ] 7. **Wiesen-Deko mittel** – `BoardBuilder.decorate` (Fall `.`), `Config.ENVIRONMENT`
  - Etwa jedes zweite Wiesenfeld 1–2 Grasbüschel (`deco_grass`), dazu ab und zu Blumen (`deco_flower`, drei Farben) oder Steinchen, selten ein Zaunstück (`deco_fence`). Positionen am Feldrand, die Feldmitte bleibt frei (Zug-Ring/Figur sichtbar). Alle Quoten als WIP-Werte.
  - Start- und Gegnerfelder bleiben gut lesbar, keine Deko auf Feldern mit Figuren beim Start.

- [ ] 8. **Wasserfälle auf etwa jeder 6.–8. Karte** – `LevelGen`, `RunConfig`
  - Wasserfälle auch an Seen und an anderen Flussenden, nicht nur links (Klippe am Ufer, Fall ins Wasser). Ziel-Quote 12–17 % der normalen Laufkarten, im Generatortest messen.
  - Die Bedingungen aus C1 bleiben (Lösbarkeit, Startzone, `BoardBuilder.waterfall` prüft `C` → `W`).

- [ ] 9. **Prüfskripte + Messung** – Tests für alle Schritte. In den Notizen: Teile und geschätzte Dreiecke je Karte (Mittel/Max über 100 Seeds, mit Stub-Varianten in Originalgröße der Kategorien) und Stub-Aufbauzeit.

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
