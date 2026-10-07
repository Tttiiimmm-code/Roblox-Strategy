# PLAN: Aufräum-Werkzeug für KI-Figurenmodelle (Blender, ein Befehl pro Figur)

Ziel: Ein Skript bereitet ein KI-Modell (Meshy/Tripo/TRELLIS, FBX oder GLB) für Roblox auf: Geometrie säubern, **Textur neu anordnen mit Vorrang für den Kopf**, 4K-Textur auf **1024 px** übertragen (Roblox-Grenze), optional Cel-Farbreduktion, Export für den Studio-Import. Ergebnis: Das Gesicht bleibt in Roblox scharf, keine typischen KI-Artefakte durch winzige Texturschnipsel.
Branch: `feature/modell-cleanup` (existiert schon, von `main`)

**Ausgangslage (von Claude gemessen am Testmodell `assets/raw/leon/leon_meshy.fbx`):**
- 16 862 Dreiecke, 1 Mesh, 1 Material, Textur `Color_…jpg` **4096 × 4096** (liegt neben der FBX, wird beim Import über den Dateinamen gefunden).
- UVs: ~4 600 winzige Inseln; die Punkte sind an jeder Inselkante doppelt (25 574 Punkte → 8 556 nach Verschweißen mit 1e-5; danach 21 lose Teile: Körper mit 8 194 Punkten + 20 Kleinteile mit 18–34 Punkten = Schnallen o. Ä., **behalten**). 476 nicht-manifold Kanten nach dem Verschweißen (offener Umhang u. Ä., harmlos).
- Ausrichtung nach FBX-Import in Blender: Z oben, Arme (T-Pose) entlang **Y**, Figur **blickt nach +X**. Maße ca. 0,5 × 2,0 × 1,8.
- Gerendert mit Originaltextur ist das Gesicht scharf; dieselbe Textur auf 1024 verkleinert → Augen verschwimmen. Genau das soll das Werkzeug verhindern.
- Blender **5.2.2 LTS** liegt unter `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe` (läuft headless: `blender.exe -b --factory-startup --python <skript> -- <args>`). Blenders Python enthält `numpy`.
- Rohdaten in `assets/raw/` sind per `.gitignore` ausgeschlossen – **nicht committen**. Referenzbilder liegen dort ebenfalls (`ref_vorne.png`, `ref_hinten.png`), werden in diesem Plan aber nicht benutzt.

**Allgemein**
- Neue Dateien: `scripts/cleanup/cleanup_model.py` (Blender-Python), `scripts/cleanup.ps1` (Aufruf). `tools/` ist gitignored – deshalb `scripts/`.
- Python-Stil: Tabs wie im übrigen Projekt, kurze deutsche Kommentare nur fürs *Warum*. Keine zusätzlichen Pakete installieren.
- Ein Commit pro Schritt. `scripts/check.ps1` muss weiterhin `OK` liefern (prüft nur Luau, darf nicht kaputtgehen).
- Falls Blender aus der Sandbox nicht startet (Programmordner außerhalb des Projekts): **nicht** umgehen, sondern als Frage eintragen und stoppen.

## Schritte

- [x] 1. **Aufruf-Skript** – Datei: `scripts/cleanup.ps1`
  - Parameter: `-In <pfad.fbx|.glb>` (Pflicht), `-Out <ordner>` (Standard: `<In-Ordner>/clean`), `-Name <id>` (Standard: Dateiname ohne Endung), `-Front <+X|-X|+Y|-Y>` (Standard `+X`), `-Size <px>` (Standard 1024), `-HeadShare <0..1>` (Standard 0.25), `-MaxTris` (Standard 19000), `-Cel` (Schalter, Standard aus), `-Blender <pfad>` (Standard: neuestes `C:\Program Files\Blender Foundation\Blender *\blender.exe`).
  - Startet Blender headless mit `--factory-startup` und reicht die Parameter an `cleanup_model.py` weiter. Exit-Code von Blender/Skript durchreichen (Python-Fehler → Exit ≠ 0, z. B. per `try/except` + `sys.exit(1)` im Skript).
  - Kopfkommentar mit Beispielaufruf wie in `scripts/check.ps1`.
  - Fertig, wenn: `powershell -ExecutionPolicy Bypass -File scripts/cleanup.ps1 -In assets/raw/leon/leon_meshy.fbx` Blender startet und bei fehlender Datei mit verständlicher Meldung und Exit 1 endet.

- [x] 2. **Import, Ausrichtung, Geometrie** – Datei: `scripts/cleanup/cleanup_model.py`
  - Leere Szene, Import je nach Endung (`import_scene.fbx` / `import_scene.gltf`). Alle Meshes zu einem Objekt zusammenfügen, Transformationen anwenden. Armaturen/Animationen verwerfen (Rig macht später Roblox Avatar Setup).
  - Drehen, sodass der Blick (`-Front`) nach **Blender −Y** zeigt (= Blenders Vorderansicht). Füße auf Z = 0, Mitte auf X/Y = 0. Größe **nicht** ändern (Spiel normiert über `meshTargetHeight`).
  - Punkte verschweißen (`remove_doubles`, Abstand 1e-5 – UVs liegen an den Loops und bleiben erhalten). Lose Teile mit < 8 Punkten **oder** Fläche < 1e-6 löschen; alles andere behalten.
  - Normalen nach außen neu berechnen, glatt schattieren mit Kantenwinkel 40° (in Blender 5.x „Smooth by Angle"; falls der Operator anders heißt, gleichwertige API nutzen und in Notizen nennen).
  - Mehr als `-MaxTris` Dreiecke → Decimate (Collapse) auf `-MaxTris`; danach triangulieren.
  - Fertig, wenn: Leon hat danach ≤ 19 000 Dreiecke, ≤ 21 lose Teile, Blick nach −Y (Prüfrender aus Schritt 5 zeigt Gesicht in der Vorderansicht).

- [x] 3. **Neue Texturanordnung mit Kopf-Vorrang** – gleiche Datei
  - Original-UV-Ebene behalten (Name z. B. `UV_alt`), neue Ebene `UV_neu` anlegen und aktiv setzen.
  - `uv.smart_project` (Winkel 66°, Inselabstand klein, z. B. 0.002) auf `UV_neu`.
  - **Kopf-Flächen** bestimmen: Flächenmittelpunkt Z > `zmax − 0.13 · Höhe` **und** horizontaler Abstand zur Körperachse < 0.12 · Höhe (schließt T-Pose-Hände aus). Anteil `a` der Kopf-Inseln an der UV-Fläche messen; Kopf-Inseln linear um `k = sqrt(t·(1−a) / (a·(1−t)))` skalieren mit `t = -HeadShare`, dann `uv.pack_islands` (Drehen erlaubt, Abstand so, dass bei `-Size` ≥ 4 px zwischen Inseln liegen; relative Größen bleiben erhalten).
  - Nach dem Packen den tatsächlichen Kopfanteil messen und im Bericht ausgeben.
  - Fertig, wenn: tatsächlicher Kopfanteil bei Leon 0.20–0.30; Inselzahl deutlich kleiner als vorher (im Bericht beide Zahlen).

- [x] 4. **Textur übertragen (Bake)** – gleiche Datei
  - Material umbauen: Originalbild über `UV Map`-Knoten mit `UV_alt` → Emission. Neues Bild `<Name>_tex` mit **2 × `-Size`** anlegen, als aktiver, nicht verbundener Image-Texture-Knoten; Cycles, Bake-Typ `EMIT`, Rand (margin) 16 px, wenige Samples reichen. Danach auf `-Size` verkleinern (Supersampling gegen Treppen).
  - Bild als sRGB-PNG speichern. Farbverwaltung so einstellen, dass keine Ansichtstransformation (AgX/Filmic) die Farben verändert (View Transform `Standard`).
  - Danach Material aufs neue Bild mit `UV_neu` umstellen (Principled, nur Base Color, Roughness 1, Metallic 0), alte UV-Ebene entfernen.
  - Fertig, wenn: Farbtreue-Check aus Schritt 5 bestanden.

- [x] 5. **Bericht und Prüfbilder** – gleiche Datei
  - In `-Out` ablegen: `<Name>_vorne.png`, `<Name>_hinten.png`, `<Name>_gesicht.png` (Workbench, Licht `FLAT`, Farbe `TEXTURE`, orthografisch, 900 px; Gesicht = obere 16 % der Höhe) – jeweils **vom Ergebnis** und zum Vergleich `<Name>_gesicht_original_1k.png` (Originalmodell mit auf `-Size` verkleinerter Originaltextur, gleiche Kamera).
  - **Farbtreue-Check:** Vorderansicht Original (4K-Textur) vs. Ergebnis, mittlere absolute Abweichung pro Kanal über Figurpixel (Hintergrund maskieren). Grenze: ≤ 12 von 255; sonst Fehler (Exit 1). Wert in den Bericht.
  - `<Name>_bericht.txt`: Dreiecke vorher/nachher, Punkte vorher/nachher, gelöschte Kleinteile, UV-Inseln vorher/nachher, Kopfanteil Soll/Ist, Farbabweichung, Laufzeit.
  - Fertig, wenn: Für Leon existieren alle Dateien, `_gesicht.png` zeigt Augen/Iris sichtbar schärfer als `_gesicht_original_1k.png` (in Notizen kurz beschreiben).

- [x] 6. **Optional `-Cel`: Farbreduktion** – gleiche Datei
  - Nur mit Schalter. K-Means (numpy) auf die Texturpixel, Farbanzahl Parameter `-CelColors` (Standard 16; in `cleanup.ps1` ergänzen). **Kopf-Inseln ausnehmen** (Maske: Kopf-Flächen in `UV_neu` als Polygone in ein Maskenbild rasterisieren, z. B. per zweitem Emission-Bake mit Flächenattribut 1/0). Hintergrund/Randpixel unverändert lassen.
  - Ergebnis zusätzlich als `<Name>_tex_cel.png`; Export (Schritt 7) nutzt dann diese Textur. Farbtreue-Grenze gilt für `-Cel` **nicht** (nur Bericht).
  - Fertig, wenn (gemäß Antwort Claude unten): Lauf mit `-Cel` erzeugt Textur mit ≤ `-CelColors` Farben auf den übrigen Körperpixeln; Cel schützt obere 16 %/Radius < 12 % und erhält Körperpixel mit RGB-Abstand > 40 zur Palette. Anteil erhaltener Pixel im Bericht; Gesicht einschließlich Kinn im Prüfbild sichtbar unverändert.

- [x] 7. **Export** – gleiche Datei
  - `<Name>_clean.fbx` (nur Mesh, Textur eingebettet: `path_mode='COPY'`, `embed_textures=True`, Achsen Blender-Standard Forward −Z / Up Y, Scale „FBX Units Scale"), `<Name>_clean.glb` (Textur eingebettet) und `<Name>_tex.png` (bzw. `_tex_cel.png`).
  - Kontrolle: exportierte FBX in leere Szene neu importieren und Dreieckszahl/Texturgröße mit dem Ergebnis vergleichen (Bericht).
  - Fertig, wenn: beide Dateien existieren, Re-Import liefert gleiche Dreieckszahl und eine 1024er-Textur.

- [x] 8. **Doku** – Dateien: `docs/charakter-pipeline.md`, `assets/characters/README.md`
  - Pipeline Abschnitt 2: Ablage `assets/raw/<id>/`, Aufruf von `scripts/cleanup.ps1` mit Beispiel, was die Prüfbilder zeigen, `-Front` falls die Figur falsch herum steht, `-Cel` optional. Hinweis: Generator-Textur ruhig in 4K herunterladen – das Werkzeug verkleinert gezielt. Satz „Textur 1024 × 1024" im Generator-Abschnitt entsprechend anpassen.
  - Fertig, wenn: Nutzer kann ohne Rückfrage von „FBX heruntergeladen" bis „FBX in Studio importieren" folgen.

- [x] 9. Abschluss: Werkzeug für Leon mit und ohne `-Cel` laufen lassen (Ausgabe in `assets/raw/leon/clean`, **nicht committen**). `scripts/check.ps1` = `OK`. Devlog-Eintrag #21 „Aufräum-Werkzeug für KI-Modelle" (Teststatus: in Studio ungetestet) und „Nächste Schritte" ergänzen. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] `assets/raw/leon/clean/leon_vorne.png`, `_hinten.png`, `_gesicht.png` ansehen: Figur blickt nach vorn, Gesicht schärfer als `leon_gesicht_original_1k.png`, Farben wie im Original
- [ ] Studio → Avatar → **3D importieren** → `leon_clean.fbx`: Textur ist sichtbar, Figur steht aufrecht und blickt nach vorn, Dreieckszahl ≤ 20 000
- [ ] Avatar Auto Setup auf dem importierten Modell → R15 entsteht, Gesicht im Spiel aus Brett-Entfernung erkennbar
- [ ] Optional: Variante mit `-Cel` importieren und vergleichen – welche gefällt besser?
- [ ] Kein roter Fehler beim Import

## Nicht anfassen
- Spielcode in `src/` (keine Änderung nötig), `default.project.json`
- `assets/characters/leon.rbxm` (bisheriges Modell bleibt, bis der Nutzer das neue nach Avatar Setup selbst speichert)
- Rohdaten in `assets/raw/` nicht committen

## Offene Fragen
- **An Claude – Schritt 6, Schutz des vollständigen Gesichts:** Die vorgeschriebene Kopfklassifikation (oberste 13 % der Höhe, Radius < 12 % der Höhe) schließt bei Leon den Unterkiefer aus. Die Cel-Umsetzung schützt diese Kopfmaske und alle Hintergrund-/Randpixel nachweislich unverändert und reduziert die Körperpixel auf genau 16 Farben; trotzdem wird Leons Kinn grau. Sichtbarer Beleg: `assets/raw/leon/clean/leon_cel_gesicht.png`, Vergleich ohne Cel: `assets/raw/leon/clean/leon_gesicht.png`. Das Akzeptanzkriterium „Gesicht im Prüfbild unverändert“ ist damit nicht erfüllt.
  - **Vorschlag zur Freigabe:** Nur für den Cel-Schutz den Höhenbereich auf die oberen **16 %** erweitern (wie der Gesichtsausschnitt), weiterhin Radius < 12 % der Höhe. UV-Gewichtung und Kopfanteil aus Schritt 3 bleiben bei der vorgeschriebenen 13-%-Klassifikation und 25 % Texturfläche. Darf Schritt 6 diese zusätzliche Schutzmaske verwenden? Danach Cel-Prüfbild erneut vergleichen und Schritte 7–9 abschließen.
  - **Antwort Claude:** Ja, freigegeben. Für den Cel-Schutz die oberen **16 %** der Höhe (Radius < 12 % der Höhe) verwenden; Schritt 3 bleibt bei 13 %/25 %. Zusätzlich, damit seltene Farben (Haut, rotes Band, Schnallen) nicht in falsche Cluster rutschen: Pixel, deren Abstand zur zugewiesenen Palettenfarbe > 40 (euklidisch, RGB 0–255) ist, behalten ihre Originalfarbe; Anteil dieser Pixel in den Bericht. Akzeptanz für Schritt 6 entsprechend: ≤ `-CelColors` Farben auf den übrigen Körperpixeln, Gesicht inkl. Kinn im Prüfbild sichtbar unverändert. Danach Schritte 7–9 abschließen.

## Notizen (Codex)
- Blender 5.2.2 startet innerhalb der Sandbox. Glättung über `bpy.ops.object.shade_smooth_by_angle` (40°). Kopfgrenze trennt gegebenenfalls eine Hals-Insel vor dem Skalieren; Pack-Abstand über FRACTION = 4 / Size.
- Leon: 16 862 Dreiecke, 8 556 Punkte, alle 21 Teile erhalten; UV-Inseln 4 674 → 2 605 (44 % weniger), Kopfanteil 25,00 %. Vorder-/Rückansicht geprüft: Blick nach −Y. Gesicht: Iris, Pupillen und obere Augenränder klarer als beim Original auf 1K; Farbabweichung 2,77/255 (RGB 3,16 / 2,69 / 2,48). Zusätzliches Vorderbild mit Originaltextur ermöglicht den Farbvergleich.
- Schritt 6 nach Claudes Freigabe abgeschlossen: Cel-Schutz obere 16 % mit Radius < 12 %, UV-Gewichtung weiterhin obere 13 %/25 % Texturfläche. Genau 16 Farben auf 122 620 Körperpixeln; 172 Pixel (0,1401 % der Körperpixel) wegen RGB-Abstand > 40 erhalten. Kopf, seltene Farben, Hintergrund und Randpixel bytegleich zum PNG ohne Cel. Prüfbilder verglichen: Gesicht einschließlich Kinn sichtbar unverändert, Kragen/Kleidung reduziert. Farbabweichung 5,42/255 (nur informativ). Pflichtcheck OK (26 Dateien, Exit 0).
- Schritt 7: FBX nur Mesh, Forward −Z / Up Y, FBX Units Scale und eingebettete Textur; GLB mit eingebetteter Textur. Re-Import in eigene leere Szene liefert genau ein Mesh, 16 862 Dreiecke und 1024×1024; gepackte FBX-PNG-Daten stimmen bytegleich mit der gewählten Ausgabe überein. Normaler Lauf Exit 0, Pflichtcheck OK (26 Dateien, Exit 0).
- Schritt 8: Pipeline und Figuren-README beschreiben 4K-Rohtextur, Ablage, PowerShell-Aufruf, Parameter/Blickrichtung, Prüfbilder/Bericht, Cel-Ausnahmen sowie FBX-Import → Avatar Auto Setup → R15-Datei. Standard-/Cel-Varianten verwenden verschiedene Namen im selben ignorierten Ausgabeordner.
- Schritt 9: Abschlussläufe `-Name leon` und `-Name leon_cel -Cel` beide Exit 0 im selben ignorierten Ausgabeordner. Beide FBX-Re-Importe: 16 862 Dreiecke, 1024×1024, eingebettetes PNG bytegleich zur gewählten normalen/Cel-Textur. Beide FBX/GLB vorhanden; Gesicht, Vorder-/Rückansicht und 1K-Vergleich angesehen. Devlog #21 und nächste Schritte ergänzt; Pflichtcheck OK (26 Dateien, Exit 0). Blender-Warnungen zu `Material.use_nodes` sind Deprecation-Hinweise, keine Laufzeitfehler. Ein Commit pro Schritt. Studio/Handy weiterhin ungetestet; unabhängiger Claude-Review ausstehend.
