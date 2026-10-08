# PLAN: Level-Optik Etappe A – stilisiertes Brett, Raster, Ladeweg für Umgebungs-Assets

Ziel: Das Spielbrett passt optisch zu den Cel-Figuren: **stilisierter Boden** statt realistischem Roblox-Terrain, **dezent sichtbares Raster**, und ein **Ladeweg für Umgebungs-Assets** (Bäume, Büsche, Felsen, Gebäude vom Nutzer generiert; Kleinkram aus Roblox-Paketen). Fehlende Assets → die bisherigen Part-Objekte bleiben (schrittweiser Austausch wie bei den Figuren). Dazu Stil-Guide + Asset-Liste für den Nutzer und ein Objekt-Modus im Aufräum-Werkzeug.
Branch: `feature/level-optik` (existiert, von `main`)
Nutzerentscheidungen (08.10.2026): Boden stilisiert passend zu Cel; Raster dezent sichtbar; Nutzer generiert Bäume, Büsche, Berge/Felsen, Gebäude selbst, Kleinkram (Steine, Blumen, Grasbüschel, Zäune) kommt aus Paketen. Layout der Bausteine ist **Etappe B** (nicht hier).

**Bestehender Code**
- `src/server/BoardBuilder.luau`: `build(regionId)` füllt Roblox-Terrain (`fillTerrain`, `FillBlock`, Höhen-Kalibrierung `sinkCache`, `reuseTerrain`), legt unsichtbare Klick-Kacheln `Tile_x_y` (Attribute X/Y), Rasterlinien `GridLine` (Config.FEEL.gridLineWidth/gridTransparency), Part-Deko je Feld (`decorate`: Bäume bei `F`, Pfützen im Sumpf …) und Umgebung am Rand (`OuterTrunk`/`OuterLeaves`/`OuterRock`).
- `src/shared/Config.luau`: `TERRAIN` (height, color, material, terrainMaterial), `TILE_SIZE = 8`, `FEEL`. `src/shared/Stages.luau`: `Regions` (surroundMaterial, treeColor, grassColor, waterColor).
- Client-Ladeprüfung `missionReady` in `src/client/Main.client.luau` wartet u. a. auf Terrain per Raycast (`terrainParams`) – muss zum neuen Boden passen.
- Vorbild für Asset-Ladeweg: `ReplicatedStorage.CharacterModels` ← `assets/characters` in `default.project.json`, Vorlagenprüfung/Skriptentfernung im `CharacterBuilder` (mesh-Pfad).
- Aufräum-Werkzeug: `scripts/cleanup.ps1` + `scripts/cleanup/cleanup_model.py` (Kopf-Gewichtung, Kopferkennung bricht bei Nicht-Figuren ab).

**Leitlinien**
- Handy-Leistung: wenige Teile, keine Transparenz-Stapel, `CastShadow` nur bei großen Objekten. Ziel: Brettaufbau nicht langsamer als bisher (Ausgabe „Missionsaufbau … Brett x ms“ vergleichen).
- Story-Missionen, Thronsaal und Lauf-Level nutzen denselben Builder – alle müssen weiter funktionieren.
- Ein Commit pro Schritt, `scripts/check.ps1` = `OK`; nach Schritt 2–4 zusätzlich Rojo-Build.

## Schritte

- [x] 1. **Asset-Ordner + Lader** – `default.project.json`, neuer Ordner `assets/environment/` (mit `README.md`), neues Modul `src/server/EnvironmentAssets.luau`
  - `ServerStorage.EnvironmentModels` ← `assets/environment` (nur der Server baut das Brett). Ohne Dateien muss alles bauen.
  - Namensschema `<kategorie>_<nr>.rbxm` (z. B. `tree_1`, `bush_2`, `rock_1`, `fortress_1`, `bridge_1`, `deco_flower_1`). `EnvironmentAssets.variants(kategorie)` liefert alle gültigen Vorlagen (Model/BasePart), `EnvironmentAssets.place(kategorie, cframe, opts)` klont eine deterministisch gewählte Variante (Schlüssel aus Feldposition + Kartenkennung), setzt sie mit Pivot unten Mitte auf den Boden, optional Drehung (beliebig oder 90°-Schritte) und Größenstreuung ±10 %, skaliert auf eine Zielhöhe/-breite in Feldern (Werte zentral in `Config.ENVIRONMENT`).
  - **Sicherheit (Pakete aus dem Creator Store):** Beim Laden alle Skripte (`BaseScript`, `ModuleScript`), Sounds, `ClickDetector`/`ProximityPrompt` und Partikel entfernen; alle Teile `Anchored`, `CanCollide`/`CanQuery`/`CanTouch` = false (Klicks treffen das Feld). Warnung einmal je Datei.
  - Fertig, wenn: ohne Assets kein Fehler; mit einer lokalen Testvorlage (nur lokal, nicht committen) wird sie korrekt platziert, Skripte entfernt (Prüfung mit Stubs wie bei früheren Prüfhilfen, Ergebnis in Notizen).

- [x] 2. **Stilisierter Boden + Raster** – `src/server/BoardBuilder.luau`, `src/shared/Config.luau`, `src/shared/Stages.luau`
  - Roblox-Terrain für das **Brett** ersetzen durch Parts: je Feld ein Block in der Geländefarbe (`SmoothPlastic`, kräftige flache Farbe; Farbwerte zentral in `Config.TERRAIN`), Höhe = bisherige `height`; Seitenflächen etwas dunkler (eigener schmaler Rand-Part oder zweite Farbstufe), damit Höhenstufen wie im Cel-Stil lesbar sind. Wasser: flacher, leicht transparenter blauer Block unter Ebenenhöhe. Benachbarte Felder gleicher Art und Höhe zu größeren Blöcken zusammenfassen, wo einfach möglich (weniger Teile).
  - Umgebung außerhalb des Bretts: stilisierte Fläche in Regionsfarbe (`Stages.Regions`), leichter Absatz zum Brett. Roblox-Terrain wird für das Brett nicht mehr benutzt; vorhandenes Terrain im Brettbereich beim Aufbau entfernen. Sumpf-Pfützen/Morast als stilisierte Flächen statt Terrain-Wasser. Höhen-Kalibrierung (`sinkCache`) entfällt, wenn nicht mehr nötig.
  - **Raster dezent:** Linien dünn, halbtransparent, Farbe leicht dunkler als der Boden; auf allen Höhen sauber auf der Feldoberkante (nicht versinken, nicht schweben). Werte in `Config.FEEL`.
  - Client-Ladeprüfung (`missionReady`): Terrain-Raycast durch Prüfung der Boden-Parts ersetzen; Kamera/`Grid.toWorld`/Figuren-Bodenhöhe müssen weiter stimmen (Figuren stehen auf der Feldoberfläche, Zug-Ring sichtbar).
  - Thronsaal (`HubBuilder`) nicht anfassen.
  - Fertig, wenn: Story-Mission, Lauf-Level und Sumpf-Mission bauen ohne Terrain auf dem Brett; Aufbauzeit in Notizen (vorher/nachher); keine Figur versinkt oder schwebt (statisch geprüft, Studio-Test durch Nutzer).

- [x] 3. **Assets im Brett verwenden** – `src/server/BoardBuilder.luau`
  - Zuordnung in `Config.ENVIRONMENT`: `F` → `tree` (+ gelegentlich `bush`), `M` → `rock`, `H` → `fortress`, `B` → `bridge` (längs zur Brückenrichtung ausgerichtet), Ebene `.` → selten `deco_*` (Blumen/Steine/Gras, Anteil konfigurierbar, nur am Feldrand, Feldmitte frei für Figuren), Rand-Umgebung → `tree`/`rock`/`bush`.
  - Gibt es für eine Kategorie keine Vorlage → bisherige Part-Deko (gleiches Aussehen, auf dem neuen Boden).
  - Deko darf Figuren und Zug-Ring nicht verdecken: Bäume/Büsche an den Feldecken bzw. klein genug; Höhe begrenzt (`Config.ENVIRONMENT`).
  - Fertig, wenn: mit lokalen Testvorlagen je Kategorie korrekt platziert; ohne Vorlagen identisch zu Schritt 2.

- [x] 4. **Objekt-Modus im Aufräum-Werkzeug** – `scripts/cleanup.ps1`, `scripts/cleanup/cleanup_model.py`
  - Schalter `-Prop`: keine Kopferkennung/Kopf-Gewichtung (gleichmäßige UV-Verteilung), Standard `-MaxTris 3000`, `-Size 512`, keine T-Pose-Annahmen; Ausrichtung weiter über `-Front`. Prüfbilder vorne/Seite/oben statt Gesicht; Farbtreue-Check bleibt. Figuren-Modus unverändert (Regression: Leon-Lauf wie in Devlog #21, gleiche Zahlen).
  - Fertig, wenn: Leon-Regression ok; ein Nicht-Figuren-Modell (lokal, z. B. per Blender-Skript aus Primitiven erzeugt) läuft mit `-Prop` durch.

- [x] 5. **Stil-Guide Umgebung + Asset-Liste** – `docs/stil-guide.md` (neuer Abschnitt „Umgebung“), `docs/umgebung-assets.md` (neu), Verweis in `docs/charakter-pipeline.md`
  - Stil: gleiche Cel-Regeln wie Figuren (2 Töne, flache Farben, keine Konturlinie), leicht vereinfachte Formen, kräftige Silhouetten, Farben je Region (Grasland zuerst; Sumpf/Eis/Vulkan als Ausblick laut Fraktionstabelle).
  - Technik je Kategorie (Tabelle): Größe in Feldern (1 Feld = 8 Studs), Zielhöhe, Dreiecke (z. B. Baum ≤ 1 500, Busch ≤ 600, Fels ≤ 1 000, Gebäude ≤ 3 000), Textur 512, Pivot unten Mitte, keine Bodenplatte unter dem Objekt.
  - **Asset-Liste Grasland** zum Abhaken: selbst generieren (z. B. 3 Bäume, 2 Büsche, 2 Felsen, 1 Festung, 1 Brücke, 1 Ruine) mit Prompt-Vorlage (wie Figuren-Prompt, angepasst); aus Paketen (Steine, Blumen, Grasbüschel, Zäune) mit Hinweisen: nur Low-Poly/Cel-passend, Lizenz/Creator Store, Skripte werden entfernt, Dateiname `deco_*`.
  - Ablauf: Bild → Meshy → `cleanup.ps1 -Prop` → Studio importieren → als `assets/environment/<name>.rbxm` speichern → Rojo lädt automatisch.
  - Fertig, wenn: Nutzer kann ohne Rückfrage ein erstes Asset erstellen und einbinden.

- [ ] 6. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok, Aufbauzeiten in Notizen. Devlog **#24** „Level-Optik Etappe A“ (Teststatus ungetestet), „Nächste Schritte“ (Etappe B: Bausteine/Layout). Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Story-Mission, Lauf-Level und Sumpf-Mission: Boden stilisiert, Raster dezent, Höhen (Wald/Berg/Festung) lesbar, Wasser erkennbar
- [ ] Figuren stehen auf dem Boden, Zug-Ring sichtbar, Klicks auf Felder funktionieren, Kamera wie gewohnt
- [ ] Ohne eigene Assets: Bäume/Felsen wie bisher (Klötze) auf neuem Boden
- [ ] Ein erstes eigenes Asset (z. B. `tree_1.rbxm`) ablegen → erscheint auf Waldfeldern
- [ ] Handy: flüssig, Raster erkennbar
- [ ] Kein roter Fehler im Output

## Nicht anfassen
- Spielregeln, Generator-Layout (`LevelGen`, `MapChunks` – Etappe B), Thronsaal (`HubBuilder`), Figuren-Code
- Rohdaten in `assets/raw/`

## Offene Fragen
- Codex (08.10.2026): Die normale Befehlsausführung scheitert bereits beim Prozessstart mit `helper_unknown_error: setup refresh had errors`; auch der Pflichtaufruf `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` startet nicht. Ein freigegebener Git-Leseaufruf außerhalb der Sandbox funktioniert: Branch `feature/level-optik`, Arbeitsverzeichnis sauber. Darf die Umsetzung einschließlich Prüfungen und Rojo-Builds außerhalb der Sandbox erfolgen, oder soll zuerst die Sandbox repariert werden? Gemäß AGENTS.md gestoppt; keine Umsetzungsschritte begonnen, keine Checks bestanden.
  - **Antwort (Nutzer, 08.10.2026):** Ja – Befehle für diesen Plan (Prüfungen, Rojo-Build, Blender, Luau-Prüfhilfen, Git) dürfen außerhalb der Sandbox laufen, **jeweils mit Freigabe des Nutzers im Terminal** (normale Freigabeabfrage nutzen, nichts dauerhaft freigeben, was nicht schon freigegeben ist). Keine destruktiven Befehle. Bitte mit Schritt 1 beginnen.
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – **Design-/Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden)

## Notizen (Codex)
- Schritt 5: Umgebungsabschnitt im Stil-Guide, Größen-/Dreieckstabelle passend zu Config, Grasland-Checkliste, Prompt-Vorlage, Hinweise für Paketquellen/Bereinigung und vollständiger tree_1-Ablauf ergänzt; Charakter-Pipeline verweist auf -Prop. Brücken ohne erhöhte Laufplatte, Festung als Eckelement, Ruine erst Etappe B ausdrücklich erklärt. Pflichtcheck OK (32 Dateien).
- Schritt 4: -Prop/--prop ergänzt, Standard 3000 Dreiecke/512 px, gleichmäßige UVs ohne Kopferkennung/-Gewichtung; Prüfbilder vorne/Seite/oben. Blender 5.2: lokaler flacher Testfels aus UV-Sphäre unter tools/ (3968 → 3000 Dreiecke, 512×512, Farbabweichung 0,0594/255, FBX-Re-Import und eingebettetes PNG identisch), alle drei Prüfbilder angesehen. Leon normal und Cel wie Devlog #21: 16862 Dreiecke, 25574 → 8556 Punkte, 21 Teile, 4674 → 2605 UV-Inseln, 25 % Kopf; Farbabweichung 2,7728/5,4210. Berichte (außer Laufzeit), Texturpixel und Vorder-/Rück-/Gesichts-Prüfbilder exakt identisch zu den bestehenden Referenzen. Rohdaten und vorhandene Ergebnisse unverändert, Testausgaben nur tools/. Pflichtcheck OK (32 Dateien), Rojo-Build OK.
- Schritt 3: Feld-/Rand-Zuordnung, seltene Rand-Deko und Brückenrichtung angebunden. Lokale Model/MeshPart-Vorlagen für tree/bush/rock/fortress/bridge und vier deco-Kategorien: Platzierung, freie Feldmitte, Bodenhöhe, Rand und Determinismus OK; beide Brückenrichtungen geprüft. Ohne Vorlagen Part-Signatur identisch zu Schritt 2. Lader begrenzt zusätzlich die gedrehte Breite (45° getestet); äußere Optionen werden kopiert, Config bleibt unverändert. Pflichtcheck OK (32 Dateien), Rojo-Build OK. Festungsvorlage dient als Eckelement; Brückenvorlage braucht freie Mitte ohne erhöhte Laufplatte (Doku folgt in Schritt 5). Studio/Handy ungetestet.
- Schritt 2: SmoothPlastic-Flächen mit dunkleren Seiten, flache Wasserflächen, vier Randflächen; einfache Rechteckzusammenfassung (Story s2: 51/108, Sumpf s4: 57/108, Lauf Seed 12345: 29/80). Stubs prüfen jeden Feldmittelpunkt auf genau eine Fläche mit Oberkante = Grid.toWorld, Rasterhöhe und Klickattribute. Echte missionReady mit fehlendem Boden, falscher Karte, fehlenden Einheiten und Lauf-Seed getestet. Pflichtcheck OK (32 Dateien); Rojo-Build OK. Beispielzeiten im Luau-Stub (vorher/nachher): Story 7,89/6,24 ms, Sumpf 5,84/8,59 ms, Lauf 3,71/3,29 ms; diese schwankenden Stub-Zeiten simulieren keine Terrain-Voxel, Roblox-Replikation oder Rendering. Reale „Missionsaufbau … Brett“-Zeiten vorher/nachher muss der Nutzer in Studio vergleichen; Leistungsziel dort noch unbestätigt. HubBuilder und Grid unverändert.
- Schritt 1: ServerStorage-Ladeweg und Größenkonfiguration angelegt. Lokale Luau-Stubs mit Model/MeshPart und zwölf unerwünschten Skript-/Effekt-/Interaktionsklassen: leerer Ordner, ungültige Vorlage, Bereinigung, Warnung einmal, deterministische Größe, Maximalmaße, Pivot unten Mitte und Klickdurchlass OK. Originalvorlage unverändert; Testvorlagen/Runner nur unter ignoriertem tools/. Pflichtcheck: OK, 32 Dateien, Exit 0.
-
