# PLAN: Textur selbst bemalen – fertige Mal-Datei, Export-Befehl, Einsteiger-Anleitung

Ziel: Der Nutzer (**keine Blender-Erfahrung**) kann die aufbereitete Textur einer Figur selbst schärfen und nachmalen: Mal-Datei per Befehl erzeugen → in Blender öffnen und malen (Referenzbild als Schablone, flache Farben) → per Befehl als FBX für Studio exportieren. Anleitung Schritt für Schritt in einfachen Worten.
Branch: `feature/modell-cleanup` (weiterarbeiten, baut auf dem Aufräum-Werkzeug aus Devlog #21 auf)

**Ausgangslage**
- `scripts/cleanup.ps1` + `scripts/cleanup/cleanup_model.py` erzeugen pro Figur unter `assets/raw/<id>/clean/`: `<Name>_clean.glb` / `.fbx` (ein Mesh, UV-Ebene `UV_neu`, Blick nach Blender −Y, Füße auf Z = 0), `<Name>_tex.png` (1024²). Für Leon vorhanden (`-Name leon`).
- Referenzbilder des Nutzers: `assets/raw/leon/ref_vorne.png`, `ref_hinten.png` (1482 × 1036, T-Pose, einfarbig grauer Hintergrund ca. RGB 100–115, scharfe Anime-Linien). Vorne = Figur blickt zum Betrachter; hinten = Rückansicht (nicht gespiegelt).
- Blender 5.2.2 LTS, headless wie bisher (`--factory-startup`). Brushes sind seit Blender 4.3 **Assets** – die Python-API dafür in 5.2 vorab prüfen (siehe Schritt 2).
- Roblox zeigt höchstens 1024 px → gemalt wird direkt auf der 1024er-Textur.
- `assets/raw/` bleibt gitignored, nichts daraus committen.

**Allgemein**
- Neue Dateien: `scripts/paint.ps1`, `scripts/cleanup/paint_setup.py`, `scripts/cleanup/paint_export.py`, `docs/textur-malen.md`. Stil wie `scripts/cleanup.ps1` / `cleanup_model.py` (Tabs, deutsche Kurzkommentare, Exit-Codes durchreichen).
- Export-Einstellungen **nicht duplizieren**: die FBX/GLB-Exportlogik aus `cleanup_model.export_model` in eine kleine gemeinsame Funktion auslagern (z. B. `export_files(obj, fbx_path, glb_path, texture_path, size, report)`), die beide Skripte nutzen. `cleanup.ps1` muss danach für Leon unverändert dieselben Ergebnisse liefern (Bericht: gleiche Dreiecke, Re-Import-Prüfung bestanden).
- Ein Commit pro Schritt, `scripts/check.ps1` = `OK`.

## Schritte

- [x] 1. **Aufruf-Skript** – Datei: `scripts/paint.ps1`
  - `-Name <id>` (Pflicht), `-Dir <ordner>` (Standard `assets/raw/<Name>`; Mal-Dateien liegen in `<Dir>/clean`), `-Mode Setup|Export` (Pflicht), `-Force` (Setup: vorhandene Mal-Datei überschreiben), `-Blender` (Suche wie in `cleanup.ps1` – gleiche Logik).
  - `Setup` startet `paint_setup.py`, `Export` startet `paint_export.py`. Fehlende Eingaben (`<Name>_clean.glb`, `<Name>_tex.png`, Referenzbilder) → verständliche Meldung, Exit 1.
  - Kopfkommentar mit beiden Beispielaufrufen.
  - Fertig, wenn: beide Modi starten Blender bzw. melden fehlende Dateien sauber.

- [x] 2. **Mal-Datei erzeugen** – Datei: `scripts/cleanup/paint_setup.py`
  - Existiert `<Name>_malen.blend` schon und kein `-Force` → abbrechen mit Hinweis (bemalte Arbeit nie überschreiben). `<Name>_tex_bemalt.png` nur anlegen, wenn nicht vorhanden (Kopie von `<Name>_tex.png`); bei `-Force` vorher Sicherung `<Name>_tex_bemalt_<zeitstempel>.png`.
  - `<Name>_clean.glb` importieren; Material: Principled mit Bildtextur `<Name>_tex_bemalt.png` (externe Datei, **nicht** packen, relativer Pfad) über `UV_neu`. Objekt aktiv/ausgewählt.
  - **Referenzen zuschneiden:** `ref_vorne.png` / `ref_hinten.png` auf die Figur zuschneiden (Hintergrund = Pixel nahe der Eckfarbe, Toleranz z. B. 30; Rand 2 %), als `<Name>_ref_vorne_zuschnitt.png` / `_hinten_zuschnitt.png` in `clean/` speichern. Erleichtert das Ausrichten der Schablone.
  - **Pinsel** (Blender-5.2-API prüfen, Brush-Assets): zwei Pinsel anlegen und in der Datei speichern – „Referenz vorne“ (Bildtextur = Zuschnitt vorne, Mapping `STENCIL`, harte Kante, Stärke 1, Radius ca. 40 px) und „Flach malen“ (keine Textur, harte Kante/konstanter Abfall, Stärke 1, Radius ca. 15 px). Zusätzlich die Bildtextur „Referenz hinten“ anlegen (zum Umschalten im Pinsel). Wenn sich Pinsel in 5.2 per Python nicht zuverlässig anlegen/speichern lassen: nur die Bildtexturen anlegen, in den Notizen festhalten und die Pinsel-Einrichtung in der Anleitung (Schritt 4) mit Klickpfad beschreiben.
  - Malmodus-Einstellungen soweit per Daten möglich: Mal-Bild = `<Name>_tex_bemalt.png` (Canvas/Image-Modus), Ansicht-Shading auf Textur, X-Spiegelung aus. UI-Zustand (Arbeitsbereich „Texture Paint“) lässt sich headless nicht setzen – Anleitung übernimmt das.
  - **Texturraster:** `uv.export_layout` → `<Name>_uv_raster.png` (1024², Linien halbtransparent) für Bildprogramme.
  - Datei als `<Name>_malen.blend` speichern (relative Pfade, `bpy.ops.file.make_paths_relative()`).
  - Fertig, wenn: für Leon `leon_malen.blend`, `leon_tex_bemalt.png`, beide Zuschnitte und `leon_uv_raster.png` existieren; erneuter Aufruf ohne `-Force` bricht ab und verändert nichts; Datei headless erneut öffnen → Objekt, Material mit externem Bild und Referenztexturen vorhanden (in Notizen festhalten, ob die Pinsel gespeichert sind).

- [ ] 3. **Export der bemalten Textur** – Datei: `scripts/cleanup/paint_export.py`
  - Liest `<Name>_tex_bemalt.png` **von der Festplatte** (nicht aus der .blend – ungespeicherte Malerei wäre sonst still verloren) und `<Name>_clean.glb`. Bildgröße ≠ Größe von `<Name>_tex.png` → Fehler mit Hinweis.
  - Warnung (kein Abbruch), wenn `<Name>_malen.blend` um > 60 s neuer ist als `<Name>_tex_bemalt.png`: „Bild in Blender gespeichert? (Image → Save)“.
  - Material wie `final_material` mit dem bemalten Bild; Export über die gemeinsame Funktion → `<Name>_bemalt.fbx` / `<Name>_bemalt.glb` inkl. Re-Import-Prüfung.
  - Prüfbilder `<Name>_bemalt_vorne.png`, `_hinten.png`, `_gesicht.png` (Kamera/Einstellungen wie in `proof_images`, gemeinsame Hilfsfunktion statt Kopie) und Bericht `<Name>_bemalt_bericht.txt` (Dreiecke, Texturgröße, Re-Import, Anteil geänderter Pixel gegenüber `<Name>_tex.png`).
  - Fertig, wenn: Testlauf mit unveränderter Kopie → Export ok, „geänderte Pixel 0 %“; Testlauf mit künstlich bemalter Kopie (lokal, z. B. farbiges Rechteck per Skript – danach Originalkopie wiederherstellen) → Änderung im Bericht und im Prüfbild sichtbar.

- [ ] 4. **Einsteiger-Anleitung** – neue Datei `docs/textur-malen.md`, Verweis in `docs/charakter-pipeline.md` (Abschnitt 2, nach „Aufbereiten“) und `assets/characters/README.md`
  - Zielgruppe: noch nie Blender benutzt. Kurze nummerierte Schritte, je Schritt *was klicken/drücken* und *was man dann sieht*. Begriffe wie in der englischen Blender-5.2-Oberfläche (Englisch fett, z. B. „Reiter **Texture Paint** oben“).
  - Inhalt:
    1. Mal-Datei erzeugen (`paint.ps1 -Mode Setup`), `leon_malen.blend` per Doppelklick öffnen, oben Reiter **Texture Paint** wählen.
    2. Bewegen: mittlere Maustaste drehen, Mausrad zoomen, Umschalt + mittlere Maustaste verschieben; Vorder-/Rückansicht über **View → Viewpoint → Front/Back** (Ziffernblock 1 / Strg + 1). Für Laptops ohne Ziffernblock/Mittelklick: „Emulate 3 Button Mouse“/„Emulate Numpad“ (Pfad in den Einstellungen nennen).
    3. **Mit Referenz malen (Schablone):** Pinsel „Referenz vorne“ wählen (bzw. Einrichtung per Klickpfad, falls Schritt 2 keine Pinsel speichern konnte), Vorderansicht; Schablone verschieben mit **rechter Maustaste**, skalieren mit **Umschalt + rechte Maustaste**, drehen mit **Strg + rechte Maustaste**, bis die Umrisse deckungsgleich sind; dann über Gesicht, Augen, Wappen, Goldkanten malen. Rückseite: Bildtextur auf „Referenz hinten“ umstellen, Rückansicht.
    4. **Flach malen:** Pinsel „Flach malen“, Farbe mit **S** (Pipette) vom Modell aufnehmen, Größe **F**, Stärke **Umschalt + F**; für Silber-/Stoffflächen ohne KI-Flecken.
    5. Rückgängig **Strg + Z**. **Speichern in zwei Schritten:** Bild speichern (**Image → Save** im linken Bildfenster bzw. **Alt + S**) *und* Datei speichern (**Strg + S**) – der Export liest das Bild.
    6. Export (`paint.ps1 -Mode Export`), Prüfbilder ansehen, `leon_bemalt.fbx` in Studio importieren (wie in der Pipeline beschrieben).
    7. Tipps: Übergänge vorne/hinten mit „Flach malen“ glätten; Augen zuerst; lieber wenige harte Kanten als weiches Verwischen; Alternativweg mit Krita/Photopea und `leon_uv_raster.png` als Ebene (3 Sätze).
  - Pfade/Tasten müssen zu dem passen, was Schritt 2 tatsächlich einrichtet; bei Unsicherheit über Blender-5.2-Menünamen den sicher existierenden Weg beschreiben und in den Notizen vermerken, was der Nutzer bestätigen soll.
  - Fertig, wenn: Anleitung deckt Setup → Malen → Speichern → Export → Studio ohne Lücke ab.

- [ ] 5. Abschluss: `cleanup.ps1` für Leon erneut (Regression durch Auslagerung der Exportfunktion), `paint.ps1 -Mode Setup` und `-Mode Export` für Leon (danach unveränderte `leon_tex_bemalt.png` hinterlassen). `scripts/check.ps1` = `OK`. Devlog #22 „Textur selbst bemalen“ (Teststatus: vom Nutzer ungetestet), „Nächste Schritte“ ergänzen. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/paint.ps1 -Name leon -Mode Setup` → `leon_malen.blend` öffnen, Reiter **Texture Paint**: Leon ist sichtbar und farbig
- [ ] Pinsel „Referenz vorne“: Schablone lässt sich über das Modell legen und ausrichten; ein Strich übers Gesicht überträgt scharfe Linien aus dem Referenzbild
- [ ] Pinsel „Flach malen“ + Pipette funktionieren; Rückgängig geht
- [ ] Bild speichern + Datei speichern, dann `paint.ps1 -Name leon -Mode Export` → `leon_bemalt_gesicht.png` zeigt die Änderungen
- [ ] `leon_bemalt.fbx` in Studio importieren: bemalte Textur sichtbar
- [ ] Anleitung verständlich? Unklare Stellen notieren

## Nicht anfassen
- Spielcode in `src/`, `default.project.json`, `assets/characters/leon.rbxm`
- Verhalten/Ergebnisse von `cleanup.ps1` (außer der reinen Auslagerung der Exportfunktion)
- Rohdaten in `assets/raw/` nicht committen

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)

## Notizen (Codex)
-
