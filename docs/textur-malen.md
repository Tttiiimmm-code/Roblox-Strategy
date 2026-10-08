# Leons Textur selbst bemalen

Du brauchst Blender 5.2 und die bereits aufbereitete Figur. Gemalt wird direkt auf einer 1024 × 1024 großen Bilddatei. Die folgenden Namen beziehen sich auf die englische Oberfläche und Blenders normale Tastenbelegung.

## 1. Mal-Datei erzeugen und öffnen

Öffne PowerShell im Projektordner `C:\Users\Nutzer\Game` und führe aus:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/paint.ps1 -Name leon -Mode Setup
```

Du siehst zum Schluss „Mal-Datei gespeichert“. Benötigt werden `assets/raw/leon/clean/leon_clean.glb`, `leon_tex.png` und die beiden Bilder `assets/raw/leon/ref_vorne.png` / `ref_hinten.png`. Fehlt etwas, nennt der Befehl die Datei; das Modell vorher wie in der [Charakter-Pipeline](charakter-pipeline.md#aufbereiten-mit-einem-befehl) aufbereiten.

Öffne im Explorer `assets/raw/leon/clean/leon_malen.blend` per Doppelklick. Falls Windows kein Programm dafür kennt: Blender starten, **File → Open**, diese Datei wählen. Klicke oben auf den Reiter **Texture Paint**. Links siehst du die Maltextur, rechts Leon. Falls oben links im rechten Fenster **Object Mode** steht, wähle dort **Texture Paint**. Leon ist bereits ausgewählt; das Malbild heißt `leon_tex_bemalt.png`.

Ein erneuter Setup-Befehl bricht ab, sobald die Mal-Datei vorhanden ist. Zum Weiterarbeiten einfach die vorhandene Datei öffnen. Nur zum bewussten Neuerstellen `-Force` ergänzen: Die bisherigen Pinsel-/Dateieinstellungen werden neu eingerichtet; eine vorhandene bemalte PNG bleibt erhalten und wird zusätzlich als `leon_tex_bemalt_<zeitstempel>.png` gesichert.

Für andere Figuren `-Name <id>` verwenden; mit `-Dir 'C:\Pfad\zur\Figur'` einen anderen Eingabeordner wählen. Die Ergebnisse landen immer in dessen Unterordner `clean`. Liegt Blender anderswo, `-Blender 'C:\Pfad\blender.exe'` ergänzen.

## 2. Leon ins Bild holen und die Ansicht bewegen

Bewege den Mauszeiger über das rechte Fenster. Mit **View → Frame Selected** holst du Leon in die Mitte (Ziffernblock-Komma). Jetzt kannst du ihn betrachten:

- **Mittlere Maustaste gedrückt halten und ziehen:** um Leon drehen.
- **Mausrad:** näher heran oder weiter weg.
- **Umschalt + mittlere Maustaste und ziehen:** Bildausschnitt verschieben.
- **View → Viewpoint → Front:** gerade von vorne schauen (Ziffernblock **1**).
- **View → Viewpoint → Back:** gerade von hinten schauen (**Strg + Ziffernblock 1**).

Ohne Ziffernblock oder mittlere Maustaste: **Edit → Preferences → Input** öffnen und **Emulate Numpad** beziehungsweise **Emulate 3 Button Mouse** einschalten. Danach funktionieren **1** / **Strg + 1** auf der oberen Zahlenreihe; **Alt + linke Maustaste** ersetzt die mittlere, **Umschalt + Alt + linke Maustaste** verschiebt die Ansicht. Alternativ bleiben die genannten **View**-Menüs verfügbar. Das Einstellungsfenster danach schließen.

## 3. Scharfe Details mit der Referenz übertragen

Wähle zuerst **Front** und zoome zum Gesicht. Klicke oben im rechten Fenster auf die Pinsel-Auswahl mit dem Namen des aktuellen Pinsels und wähle **Referenz vorne**. Du kannst die Auswahl auch mit **Umschalt + Leertaste** öffnen. Im Auswahlfenster die Bibliothek **Current File** oder **All** wählen und nach `Referenz vorne` suchen. Das ist ein in dieser Datei gespeicherter Pinsel. Wenn du die Pinsel unten als Leiste sehen möchtest, aktiviere **View → Asset Shelf**.

Jetzt erscheint das zugeschnittene Vorderbild als Schablone über dem Modell. Es wird beim Malen auf die sichtbare Oberfläche übertragen. Halte die jeweilige Taste gedrückt und ziehe im rechten Fenster:

- **Rechte Maustaste:** Schablone verschieben.
- **Umschalt + rechte Maustaste:** Schablone größer oder kleiner machen.
- **Strg + rechte Maustaste:** Schablone drehen.

Richte zunächst Augen, Nase und Kinn aufeinander aus. Male mit **linker Maustaste** kurze Striche über die gewünschten Details: erst Augen und Gesicht, dann Wappen und Goldkanten. Du siehst die Linien aus dem Referenzbild auf Leon erscheinen. Die Schablone für jeden Bereich neu ausrichten, wenn die Form des 3D-Modells vom Referenzbild abweicht. Die Pinselfarbe beim Referenzpinsel auf Weiß lassen, damit die Bildfarben richtig übertragen werden.

Für den Rücken: **View → Viewpoint → Back** wählen. Mit dem Mauszeiger rechts **N** drücken, im aufgeklappten Seitenbereich **Tool → Brush Settings → Texture** öffnen. An der kleinen Textur-Auswahl beim Vorschaubild **Referenz hinten** wählen; **Mapping** bleibt **Stencil**. Nun erscheint das Rückenbild; es ist bereits richtig herum und wird nicht gespiegelt. Wieder ausrichten und mit links malen. Für die Vorderseite dort wieder **Referenz vorne** wählen.

Falls die Schablone fehlt: Prüfe in diesem **Texture**-Bereich die Textur **Referenz vorne** bzw. **Referenz hinten** und **Mapping → Stencil**. Beim Pinsel muss **Referenz vorne** aktiv sein. Den Seitenbereich mit **N** schließen, sobald du Platz zum Malen brauchst.

## 4. Flächen mit einer einzigen Farbe malen

Öffne wieder die Pinsel-Auswahl und wähle **Flach malen**. Die Schablone verschwindet. Der Pinsel hat eine harte Kante und malt ohne Bildtextur.

Zeige auf eine saubere Silber- oder Stoffstelle und drücke **Umschalt + X**; falls der Farbaufnahme-Cursor erscheint, mit links auf die Stelle klicken. Die Pinselfarbe übernimmt deren Farbe. Das ist die Pipette in Blender 5.2; alternativ mit **F3** nach **Sample Color** suchen und die Stelle anklicken.

Mit **F**, Mausbewegung und linkem Klick stellst du den Radius ein. Mit **Umschalt + F**, Mausbewegung und linkem Klick die Stärke einstellen; für deckende Flächen oben **Strength = 1.000** wählen. Male mit links über fleckige Rüstungs- oder Stoffflächen. Du siehst eine gleichmäßige Farbe. Für freie Farbwahl oben auf das Farbfeld des Pinsels klicken.

## 5. Rückgängig machen und zweimal speichern

Ein misslungener Strich lässt sich mit **Strg + Z** rückgängig machen; der Mauszeiger bleibt dabei über dem Malfenster.

**Speichere nach dem Malen immer Bild und Blender-Datei:**

1. Maus über das **linke Bildfenster** bewegen. In dessen Bildauswahl muss `leon_tex_bemalt.png` stehen. **Image → Save** klicken oder **Alt + S** drücken. Ein Stern am Bildnamen verschwindet: Die Farben stehen jetzt in der PNG auf der Festplatte.
2. **Strg + S** drücken. Damit speicherst du die Blender-Datei samt Pinsel-Einstellungen.

Der Export liest ausschließlich `leon_tex_bemalt.png` von der Festplatte. Nur **Strg + S** speichert deine Bildänderungen nicht in diese PNG. Ist die Blender-Datei mehr als 60 Sekunden neuer als die PNG, erinnert der Export mit „Bild in Blender gespeichert? (Image → Save)“ daran. Auch ohne diese Meldung beide Speicherschritte ausführen.

## 6. Exportieren und in Studio importieren

Führe in PowerShell im Projektordner aus:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/paint.ps1 -Name leon -Mode Export
```

Du siehst „Export geprüft“ und den Anteil geänderter Pixel. Unter `assets/raw/leon/clean/` entstehen:

- `leon_bemalt_vorne.png`, `leon_bemalt_hinten.png`, `leon_bemalt_gesicht.png`: gespeicherte Farben auf der Figur kontrollieren.
- `leon_bemalt_bericht.txt`: Dreiecke, Bildgröße, geänderte Pixel und Ergebnis des FBX-Re-Imports.
- `leon_bemalt.fbx`, `leon_bemalt.glb`: Modell mit eingebetteter bemalter Textur.

Sind die Änderungen im Prüfbild nicht zu sehen, zurück zu Schritt 5 gehen und das richtige Bild speichern. Bei einer Größenmeldung die PNG wieder in der Größe des Originals speichern (bei Leon 1024 × 1024).

In **Roblox Studio → Avatar → 3D importieren** `leon_bemalt.fbx` auswählen. Du siehst Leon mit der eingebetteten Textur; Farben, Haltung und Blickrichtung kontrollieren. Dann **Avatar Auto Setup** wie in [Abschnitt 3 der Charakter-Pipeline](charakter-pipeline.md#3-rig-skelett-für-roblox) durchführen. Erst das fertige R15-Modell als `assets/characters/leon.rbxm` speichern, wie dort in Abschnitt 4 beschrieben.

## 7. Kleine Schritte und eine Alternative

Beginne mit den Augen. Wenige klare, harte Kanten helfen bei dieser kleinen Textur mehr als weiches Verwischen. Wechsle für die Übergänge zwischen Vorder- und Rückseite zu **Flach malen**, nimm die passende Nachbarfarbe auf und gleiche den Übergang mit kleinen Strichen aus.

Alternativ `leon_tex_bemalt.png` in Krita oder Photopea öffnen und `leon_uv_raster.png` als eigene Ebene darüberlegen: Das Raster zeigt die Grenzen der Modellflächen. Auf der Farbebene malen, vor dem PNG-Export die Rasterebene ausblenden und das Ergebnis in derselben Bildgröße als `leon_tex_bemalt.png` speichern. Danach den Export-Befehl aus Schritt 6 ausführen; nach externer Bearbeitung ein bereits geöffnetes Blender-Bild mit **Image → Reload** neu laden.

Die Mal-Datei und PNGs bleiben zusammen im Ordner `clean`, weil ihre Bildpfade relativ sind. Die automatischen Prüfungen liefen mit Blender 5.2.2; Pinsel-Auswahl, Schablonen-Handhabung und Studio-Import müssen noch vom Nutzer ausprobiert werden. Tasten und Pinseltechnik stehen auch im [Blender-Handbuch](https://docs.blender.org/manual/en/latest/sculpt_paint/texture_paint/editing.html) und unter [Texture & Texture Mask](https://docs.blender.org/manual/en/latest/sculpt_paint/brush/texture.html); die Klickwege oben wurden mit den UI-/Keymap-Dateien der installierten Version abgeglichen.
