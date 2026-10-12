# Blender-Grundkurs – schöne Low-Poly-Modelle für Throne Tales

Ziel: Du baust eigene Umgebungsmodelle (Fels, Busch, Baum, Zaun) selbst in Blender, passend zum [Style-Guide](stil-guide.md) und zu den Grenzen aus [umgebung-assets.md](umgebung-assets.md). Keine Vorkenntnisse nötig. Bezieht sich auf **Blender 5.2**, englische Oberfläche, Standard-Tastenbelegung.

Plane pro Lektion 20–40 Minuten. Lieber jeden Tag eine Lektion als alles an einem Abend.

---

## Lektion 0 – Einrichten (5 Min.)

1. Blender starten, Startfenster wegklicken. Den Würfel, die Kamera und das Licht siehst du im großen **3D-Viewport**.
2. **Edit → Preferences**:
   - *Input → Emulate Numpad* einschalten, **falls dein Laptop keinen Ziffernblock hat** (dann gelten die Ziffern oben auf der Tastatur als Numpad; die Auswahlmodi Punkt/Kante/Fläche wählst du im Edit Mode dann über die drei Symbole oben links im Viewport statt mit 1/2/3).
   - *Interface → Line Width* bzw. *Resolution Scale* vergrößern, wenn dir alles zu klein ist.
3. Eine Maus mit Mausrad ist fast Pflicht. Mit Touchpad geht es, ist aber mühsam.

**Goldene Regel:** Tastenkürzel wirken immer in dem Fenster, über dem gerade die **Maus** steht.

---

## Lektion 1 – Bewegen in der 3D-Ansicht

| Aktion | Taste |
|---|---|
| Drehen | Mittlere Maustaste ziehen |
| Verschieben | Umschalt + mittlere Maustaste |
| Zoomen | Mausrad |
| Auf Auswahl zoomen | Numpad **.** |
| Vorne / Seite / Oben | Numpad **1** / **3** / **7** (mit Strg: Rückseite/andere Seite/unten) |
| Ansichts-Kreismenü | **~** (Taste links neben der 1, auf deutschen Tastaturen **^**) |
| Perspektive ↔ orthografisch | Numpad **5** |
| Darstellung (Drahtgitter, Solid, Material) | **Z** (Kreismenü) |

**Übung:** Den Würfel von allen sechs Seiten anschauen, nur mit Tasten. Dann frei drumherum drehen und mit Numpad . wieder zentrieren.

---

## Lektion 2 – Objekte: auswählen, bewegen, drehen, skalieren

| Aktion | Taste |
|---|---|
| Auswählen | Linksklick (Umschalt + Klick = mehrere) |
| Alles / nichts auswählen | **A** / **Alt + A** |
| Verschieben (Grab) | **G** |
| Drehen | **R** |
| Skalieren | **S** |
| Nur auf einer Achse | danach **X**, **Y** oder **Z** drücken (z. B. `G Z` = nur hoch/runter) |
| Exakter Wert | danach Zahl tippen (z. B. `R Z 45` Enter) |
| Abbrechen | Rechtsklick oder **Esc** |
| Neues Objekt | **Umschalt + A** |
| Duplizieren | **Umschalt + D** |
| Löschen | **X** |
| Rückgängig | **Strg + Z** |
| Seitenleiste mit Zahlenwerten | **N** |

**Übung:** Würfel löschen. Mit Umschalt + A → Mesh → Cylinder einen Zylinder anlegen, mit `S Z 3` in die Höhe ziehen, mit `G X 2` zur Seite schieben, mit Umschalt + D kopieren und daneben stellen.

---

## Lektion 3 – Edit Mode: die Form wirklich bauen

Ein Objekt besteht aus **Punkten (Vertices)**, **Kanten (Edges)** und **Flächen (Faces)**. Mit **Tab** wechselst du zwischen *Object Mode* (ganze Objekte) und *Edit Mode* (Punkte/Kanten/Flächen).

| Aktion | Taste |
|---|---|
| Punkt- / Kanten- / Flächenmodus | **1** / **2** / **3** (im Edit Mode) |
| Ring/Schleife auswählen | **Alt + Klick** auf eine Kante |
| Extrudieren (herausziehen) | **E** |
| Fläche nach innen einsetzen (Inset) | **I** |
| Schleifenschnitt (Loop Cut) | **Strg + R**, Mausrad = Anzahl, Klick, dann schieben |
| Abschrägen (Bevel) | **Strg + B** |
| Punkte verschmelzen | **M** |
| Durch Röntgenblick auswählen | **Alt + Z** |
| Proportionales Bearbeiten (weiche Verformung) | **O**, beim Ziehen Mausrad = Radius |
| Verbundenes Teil auswählen | **L** (Maus darüber) |

Diese vier Werkzeuge reichen für 90 % aller Spielmodelle: **Extrudieren, Inset, Loop Cut, Bevel.**

**Übung „Kiste":** Würfel, Tab, Flächenmodus (3), obere Fläche wählen, `I` für einen Rand, dann `E` und leicht nach unten ziehen → Kiste mit Deckelrand. Mit Strg + R zwei Schnitte quer legen, die mittleren Flächen rundherum (Alt + Klick) wählen, `E` und `S` leicht vergrößern → Metallband.

---

## Was macht ein Modell „schön"? (bevor wir bauen)

Das ist wichtiger als jedes Werkzeug:

1. **Silhouette zuerst.** Das Spiel wird von schräg oben auf kleine Figuren und Felder geschaut. Ein Modell muss als schwarze Umrissform erkennbar sein. Teste es mit **Z → Solid** und dunkler Ansicht oder einfach durch Herauszoomen, bis es so klein ist wie im Spiel.
2. **Übertreiben.** Dickere Stämme, größere Kronen, kräftigere Kanten. Realistische Proportionen wirken im Spiel dünn und langweilig.
3. **Groß – mittel – klein.** Eine große Hauptform, zwei, drei mittlere Teile, wenige kleine Details. Nie alles gleich groß.
4. **Kanten leicht abschrägen.** Ein winziger Bevel fängt Licht ein und lässt das Modell „fertig" wirken.
5. **Leichte Unregelmäßigkeit.** Nichts kerzengerade: Punkte ein wenig verdrehen, Krone etwas schief. Aber: Königreich-Objekte (Festung, Zaun) bleiben ordentlich und symmetrisch, Banditen/Sumpf dürfen schief und organisch sein (Style-Guide, Abschnitt 3).
6. **Wenige, flache Farben.** 3–5 Farben pro Modell, jede mit **einem** dunkleren Schattenton – das ist unser 2-Ton-Cel-Look.
7. **Wenige Dreiecke.** Low-Poly heißt: jede Fläche hat einen Grund. Grenzen siehe Tabelle in umgebung-assets.md (Fels ≤ 1.000, Busch ≤ 600, Baum ≤ 1.500). Anzeige: Rechtsklick auf die Statusleiste unten → *Scene Statistics*.

---

## Lektion 4 – Projekt Fels (`rock_1`)

1. Neue Datei (Datei → New → General), Würfel löschen.
2. Umschalt + A → Mesh → **Ico Sphere**. Unten links erscheint ein Feld für die Einstellungen: *Subdivisions* = **2**.
3. `S Z 0.6` – flacher machen. `S X 1.3` – etwas breiter.
4. Tab, Punktmodus (1). **O** einschalten. Einzelne Punkte wählen und mit **G** herausziehen/eindrücken. Ziel: kantiger, eher breiter als hoher Brocken mit einer flachen Oberseite.
5. Für Zufall: alles wählen (**A**), **Mesh → Transform → Randomize**, Wert ca. 0.1.
6. Unterseite flach machen: Ansicht von vorne (Numpad 1), mit **B** (Rahmenauswahl) die unteren Punkte wählen, `S Z 0` (alle auf eine Höhe), dann `G Z` bis zur Bodenlinie.
7. Tab zurück. Rechtsklick → **Shade Flat** – Low-Poly-Felsen sehen facettiert am besten aus.
8. Kleine Variante: zwei kleinere Steine (Umschalt + D, verkleinern, drehen) an den großen lehnen. Alle drei wählen, **Strg + J** = zu einem Objekt verbinden.

**Schön-Check:** Ist eine klare Hauptform erkennbar? Sieht er von oben (Numpad 7) nicht wie ein Kreis aus?

---

## Lektion 5 – Projekt Busch (`bush_1`)

1. Ico Sphere mit *Subdivisions* **1** (sehr kantig).
2. Drei bis fünf Kopien, unterschiedlich groß, ineinandergeschoben → wolkige Form. Die größte in die Mitte, die kleinen nach außen und leicht nach unten.
3. Jede Kugel ein wenig mit `S Z 0.8` stauchen und zufällig drehen.
4. Alle wählen, **Strg + J**.
5. Prüfen: Dreiecke ≤ 600, Breite deutlich größer als Höhe.

---

## Lektion 6 – Projekt Baum (`tree_1`)

**Stamm**
1. Cylinder mit *Vertices* = **6** (unten links einstellen). Schmal machen (`S X`/`S Y` 0.3), Höhe passend (`S Z`).
2. Tab, obere Fläche wählen, ein paar Mal **E** und etwas nach oben ziehen, jedes Mal leicht `S` kleiner und mit `G` zur Seite → leicht gebogener, nach oben dünner Stamm.
3. Untere Fläche: `E`, dann `S 1.4` → verbreiterter Fuß (Wurzelansatz).
4. Optional ein Ast: eine seitliche Fläche wählen, `E` herausziehen, verkleinern.

**Krone**
5. Zwei bis drei Ico Spheres (*Subdivisions* 1–2) als Kronenklumpen auf den Stamm setzen, oben schmaler, unten breiter. Die Krone im Style-Guide soll **schmal und klar** sein – also eher hoch-oval als breit.
6. Ganzen Baum zu einem Objekt verbinden (Strg + J), Shade Flat.

**Schön-Check:** Von oben (Numpad 7) darf die Krone die Feldmitte nicht zudecken; das Modell steht in einer Feldecke.

---

## Lektion 7 – Projekt Zaun (`deco_fence_1`) mit Modifiern

Modifier sind „nicht-zerstörende" Werkzeuge: Blender rechnet sie live drauf, du kannst die Grundform weiter ändern. Zu finden im rechten Bereich unter dem **Schraubenschlüssel**.

1. Ein Pfosten aus einem Würfel (`S X 0.15`, `S Y 0.15`, `S Z 1`), oben im Edit Mode die obere Fläche mit `S 0.5` spitz zulaufen lassen.
2. Modifier **Array**: *Count* 3, *Relative Offset X* ca. 3 → drei Pfosten in einer Reihe.
3. Quer-Latte: zweiter Würfel, flach und lang, über die Pfosten legen, Umschalt + D für eine zweite Latte.
4. Modifier **Bevel** auf die Teile: *Amount* sehr klein (0.02), *Segments* 1 → weiche Kanten mit nur wenigen Dreiecken mehr.
5. Fertig? Modifier anwenden: Maus über den Modifier → **Strg + A**. Erst dann exportieren.

Weitere nützliche Modifier: **Mirror** (symmetrische Hälfte – ideal für Festungstürme), **Solidify** (dünnen Flächen Dicke geben), **Decimate** (Dreiecke reduzieren, wenn das Limit überschritten ist).

---

## Lektion 8 – Farbe: die Paletten-Textur (der Cel-Trick)

Roblox braucht für unsere Modelle **eine Textur 512 × 512 und möglichst ein Material**. Der einfachste Weg zum sauberen Cel-Look ist eine **Farbpalette**: ein Bild aus einfarbigen Kästchen, und jede Fläche des Modells wird auf ein Kästchen gelegt.

**Palette anlegen (einmalig, z. B. in Krita oder Photopea):**
- 512 × 512 px, Raster aus 8 × 8 Kästchen à 64 px.
- Je Spalte eine Farbe, **oben der helle Ton, darunter der Schattenton** (gleiche Farbe, dunkler und leicht kühler/blauer).
- Farben aus dem Style-Guide: Steingrau, Moosgrün, Rindenbraun, Laubgrün, Leder-Braun, Messing, Königsblau/Gold usw.
- Als `palette.png` speichern und für alle Umgebungsmodelle wiederverwenden – dann passen sie automatisch zusammen.

**In Blender zuweisen:**
1. Oben auf den Reiter **Shading** wechseln. Modell auswählen, im Material-Bereich **New** klicken.
2. Im Node-Editor unten: Umschalt + A → *Texture* → **Image Texture**, Bild öffnen (`palette.png`), den gelben *Color*-Ausgang mit *Base Color* des Principled BSDF verbinden. Beim Image-Texture-Node die Interpolation von *Linear* auf **Closest** stellen (sonst verschwimmen die Kästchenränder).
3. Oben auf den Reiter **UV Editing** wechseln. Links das UV-Fenster, dort `palette.png` als Bild wählen.
4. Rechts im Edit Mode die Flächen wählen, die z. B. „Rinde hell" werden sollen. Links erscheinen ihre UVs. Mit **S** stark verkleinern (`S 0.01`) und mit **G** mitten in das richtige Kästchen schieben.
5. Für den Schatten: die Flächen auf der Unterseite und der Schattenseite (z. B. alles, was nach unten oder hinten zeigt) in das dunklere Kästchen legen. **Das ist das gemalte Licht des Cel-Shadings.** Licht kommt im Spiel grob von oben – Oberseiten hell, Unterseiten dunkel.
6. Mit **Z → Material Preview** im rechten Fenster das Ergebnis prüfen.

Tipp: Wer feinere Details will (Augen, Wappen), malt sie direkt auf die Textur – siehe [textur-malen.md](textur-malen.md).

---

## Lektion 9 – Export nach Roblox Studio

Die Vorgaben stehen in umgebung-assets.md; in Blender bedeutet das:

1. **Aufrecht und vorne:** Modell steht auf dem Boden (Z = 0), Vorderseite schaut nach **−Y** (Numpad 1 zeigt die Vorderseite). Der FBX-Export dreht das automatisch so, dass in Studio vorne **−Z** ist.
2. **Pivot unten Mitte:** Modell mittig über den Ursprung schieben. Umschalt + S → *Cursor to World Origin*, dann **Object → Set Origin → Origin to 3D Cursor**.
3. **Transformationen anwenden:** Strg + A → **All Transforms**. Sonst ist das Modell in Studio verdreht oder verzerrt.
4. **Aufräumen:** Tab, alles wählen, **M → By Distance** (doppelte Punkte), **Umschalt + N** (Normalen nach außen). Mit Overlays → *Face Orientation* prüfen: alles muss **blau** sein, rot = Fläche zeigt nach innen.
5. **Prüfen:** Dreiecke laut Scene Statistics unter dem Limit, ein Material, Textur 512 × 512.
6. **File → Export → FBX:** *Limit to Selected Objects* an, *Path Mode* = **Copy** und das kleine Symbol daneben (*Embed Textures*) an. Rest Standard. Speichern unter `assets/raw/<name>/`.
7. **Größe** ist zweitrangig: das Spiel skaliert Umgebungsmodelle selbst auf die Grenzen aus `Config.ENVIRONMENT`. Nur die **Proportionen** müssen stimmen.
8. In Studio: **Import 3D** → FBX wählen, Textur und Ausrichtung prüfen, als `assets/environment/<name>.rbxm` speichern (wie in umgebung-assets.md beschrieben).

Optional kannst du das Modell zusätzlich durch das Prüfwerkzeug schicken (`scripts/cleanup.ps1 ... -Prop`, siehe umgebung-assets.md); es erzeugt Prüfbilder von vorne/Seite/oben.

---

## Häufige Fehler

| Problem | Ursache / Lösung |
|---|---|
| Flächen in Studio unsichtbar oder schwarz | Normalen falsch → Edit Mode, alles wählen, **Umschalt + N** |
| Modell liegt auf der Seite oder ist verzerrt | Transformationen nicht angewendet → **Strg + A → All Transforms** vor dem Export |
| Textur fehlt in Studio | Beim FBX-Export *Path Mode: Copy* + *Embed Textures* vergessen |
| Farbkanten verschwommen | Image Texture auf **Closest** stellen, UVs mittig im Kästchen statt am Rand |
| Taste macht etwas anderes als erwartet | Maus steht über dem falschen Fenster, oder falscher Modus (Object/Edit) |
| Alles kaputt | **Strg + Z** mehrmals; regelmäßig mit **Strg + S** speichern |
| Modell „verschwindet" | Versehentlich ausgeblendet (**H**) → **Alt + H** holt alles zurück |

---

## Spickzettel

```
Ansicht   Mitteltaste drehen · Umschalt+Mitte schieben · Rad zoomen · Num . fokussieren
          Num 1/3/7 vorne/seite/oben · Num 5 ortho · Z Darstellung
Objekt    G/R/S + X/Y/Z + Zahl · Umschalt+A neu · Umschalt+D kopieren · Strg+J verbinden
          Strg+A anwenden · Tab Edit Mode · H/Alt+H aus-/einblenden
Edit      1/2/3 Punkt/Kante/Fläche · E extrudieren · I inset · Strg+R loop cut
          Strg+B bevel · M merge · L verbunden · O proportional · Umschalt+N Normalen
Suchen    F3 – findet jeden Befehl per Name, wenn du die Taste vergessen hast
```

---

## Übungsplan

| Tag | Aufgabe |
|---|---|
| 1 | Lektionen 0–2, zehnmal zwischen allen Ansichten wechseln |
| 2 | Lektion 3, drei verschiedene Kisten/Fässer bauen |
| 3 | Fels (Lektion 4) – drei Varianten, die beste behalten |
| 4 | Busch + Baum (Lektionen 5–6) |
| 5 | Palette anlegen und alle bisherigen Modelle einfärben (Lektion 8) |
| 6 | Zaun mit Modifiern, dann erster Export nach Studio (Lektion 9) |
| danach | Festungsturm mit Mirror-Modifier, Ruine (= Festungsturm, kaputt gemacht), Fraktionsvarianten |

**Wie du besser wirst:** Bei jedem Modell erst 2–3 Referenzbilder suchen (z. B. „low poly stylized rock" oder Bilder aus dem eigenen Stil-Blatt), daneben legen (Umschalt + A → *Image → Reference*) und die Formen abschauen. Kopieren ist beim Lernen erlaubt und der schnellste Weg.

Weiterführend: [offizielles Blender-Handbuch](https://docs.blender.org/manual/en/latest/) und die kostenlose Reihe *Blender Fundamentals* auf dem YouTube-Kanal von Blender.
