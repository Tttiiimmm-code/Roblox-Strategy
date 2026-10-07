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

- [ ] 6. **Optional `-Cel`: Farbreduktion** – gleiche Datei
  - Nur mit Schalter. K-Means (numpy) auf die Texturpixel, Farbanzahl Parameter `-CelColors` (Standard 16; in `cleanup.ps1` ergänzen). **Kopf-Inseln ausnehmen** (Maske: Kopf-Flächen in `UV_neu` als Polygone in ein Maskenbild rasterisieren, z. B. per zweitem Emission-Bake mit Flächenattribut 1/0). Hintergrund/Randpixel unverändert lassen.
  - Ergebnis zusätzlich als `<Name>_tex_cel.png`; Export (Schritt 7) nutzt dann diese Textur. Farbtreue-Grenze gilt für `-Cel` **nicht** (nur Bericht).
  - Fertig, wenn: Lauf mit `-Cel` erzeugt Textur mit ≤ `-CelColors` Farben außerhalb der Kopfmaske; Gesicht im Prüfbild unverändert.

- [ ] 7. **Export** – gleiche Datei
  - `<Name>_clean.fbx` (nur Mesh, Textur eingebettet: `path_mode='COPY'`, `embed_textures=True`, Achsen Blender-Standard Forward −Z / Up Y, Scale „FBX Units Scale"), `<Name>_clean.glb` (Textur eingebettet) und `<Name>_tex.png` (bzw. `_tex_cel.png`).
  - Kontrolle: exportierte FBX in leere Szene neu importieren und Dreieckszahl/Texturgröße mit dem Ergebnis vergleichen (Bericht).
  - Fertig, wenn: beide Dateien existieren, Re-Import liefert gleiche Dreieckszahl und eine 1024er-Textur.

- [ ] 8. **Doku** – Dateien: `docs/charakter-pipeline.md`, `assets/characters/README.md`
  - Pipeline Abschnitt 2: Ablage `assets/raw/<id>/`, Aufruf von `scripts/cleanup.ps1` mit Beispiel, was die Prüfbilder zeigen, `-Front` falls die Figur falsch herum steht, `-Cel` optional. Hinweis: Generator-Textur ruhig in 4K herunterladen – das Werkzeug verkleinert gezielt. Satz „Textur 1024 × 1024" im Generator-Abschnitt entsprechend anpassen.
  - Fertig, wenn: Nutzer kann ohne Rückfrage von „FBX heruntergeladen" bis „FBX in Studio importieren" folgen.

- [ ] 9. Abschluss: Werkzeug für Leon mit und ohne `-Cel` laufen lassen (Ausgabe in `assets/raw/leon/clean`, **nicht committen**). `scripts/check.ps1` = `OK`. Devlog-Eintrag #21 „Aufräum-Werkzeug für KI-Modelle" (Teststatus: in Studio ungetestet) und „Nächste Schritte" ergänzen. Committen, pushen, `.handoff/status` = `fertig`.

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
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)

## Notizen (Codex)
-
