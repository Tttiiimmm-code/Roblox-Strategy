# Umgebungs-Assets: vom Bild aufs Brett

Etappe A ersetzt Part-Deko schrittweise durch eigene Modelle. Ohne passende Datei bleibt die bisherige Deko sichtbar. Ein Feld ist **8 × 8 Studs**. Der Lader liegt auf dem Server; Rojo lädt den Ordner `assets/environment/` nach `ServerStorage.EnvironmentModels`.

## Größen und Technik

Alle Modelle: **Textur 512 × 512**, möglichst ein Material, Pivot **unten Mitte**, aufrecht, vorne **−Z** in Studio, keine Bodenplatte, kein Rig erforderlich. Größen werden proportional auf die Grenzen aus `Config.ENVIRONMENT` skaliert; bis zu ±10 % Streuung bleibt innerhalb dieser Grenzen. Bei breiten Modellen kann die erreichte Höhe kleiner sein. Die Tabelle nennt die maximalen Maße einer Platzierung auf dem Brett, nicht die Ausgangsgröße im 3D-Generator.

| Kategorie / Dateiname | Breite × Tiefe höchstens (Felder) | Zielhöhe höchstens (Felder / Studs) | Dreiecke | Verwendung |
|---|---|---|---|---|
| `tree_1.rbxm` | 0,22 × 0,22 | 0,55 / 4,4 | ≤ 1.500 | Zwei Bäume an gegenüberliegenden Waldecken; schmale, klare Krone. |
| `bush_1.rbxm` | 0,20 × 0,20 | 0,16 / 1,28 | ≤ 600 | Gelegentlich dritte Waldecke, zusätzlich Rand. |
| `rock_1.rbxm` | 0,22 × 0,22 | 0,28 / 2,24 | ≤ 1.000 | Drei Felsen an Bergecken; die Höhenstufe liefert der Boden. |
| `fortress_1.rbxm` | 0,20 × 0,20 | 0,38 / 3,04 | ≤ 3.000 | Ein schlankes Turm-/Mauereckelement, viermal pro Festungsfeld. Die Figur steht zwischen den Ecken. |
| `bridge_1.rbxm` | 1,00 × 1,00 | 0,16 / 1,28 | ≤ 3.000 | Geländerpaar längs −Z, Mittelstreifen frei. Keine erhöhte Laufplatte: Figuren stehen auf dem vorhandenen Brückenboden. Drehung aus Nachbarfeldern. |
| `ruins_1.rbxm` | 0,20 × 0,20 | 0,38 / 3,04 | ≤ 3.000 | Ruinenelement vorbereiten; automatische Layout-Verwendung folgt in Etappe B. |
| `deco_stone_1.rbxm`, `deco_flower_1.rbxm` | 0,14 × 0,14 | 0,08 / 0,64 | ≤ 300 | Selten an einer Ecke der Ebene. |
| `deco_grass_1.rbxm` | 0,14 × 0,14 | 0,12 / 0,96 | ≤ 300 | Kleine Grasbüschel am Feldrand. |
| `deco_fence_1.rbxm` | 0,24 × 0,24 | 0,12 / 0,96 | ≤ 500 | Kurzes Zaunsegment an einer Ecke, keine vollständige Feldumzäunung. |

Außerhalb des Bretts nutzt der Lader dieselben Baum-/Fels-/Buschmodelle größer: Baum höchstens 1,4 Felder breit / 2,25 hoch, Fels 0,9 / 0,75, Busch 0,7 / 0,45. Nur große Objekte werfen Schatten. Auf dem Brett stehen Ecken 2,7 Studs vom Feldmittelpunkt entfernt. Proportionen auch von oben prüfen; Zweige und Mauern dürfen den freien Mittelpunkt nicht füllen.

## Asset-Liste Grasland

Selbst erzeugen und abhaken:

- [ ] `tree_1` – kompakter Laubbaum mit schmaler runder Krone
- [ ] `tree_2` – leicht kantigere, asymmetrische Laubkrone
- [ ] `tree_3` – schlanker Baum mit wenigen klaren Kronenstufen
- [ ] `bush_1` – kompakter grüner Busch
- [ ] `bush_2` – niedriger, leicht kantiger Busch
- [ ] `rock_1` – warmer kantiger Fels
- [ ] `rock_2` – flacherer Fels mit anderer Silhouette
- [ ] `fortress_1` – schmaler sandfarbener Turm als Festungsecke
- [ ] `bridge_1` – einfaches hölzernes Geländerpaar, freie Mitte, Länge entlang −Z
- [ ] `ruins_1` – beschädigtes Mauereckelement, für Etappe B

Kleinkram aus Paketen:

- [ ] `deco_stone_1` – kleine Steine
- [ ] `deco_flower_1` – wenige große stilisierte Blüten
- [ ] `deco_grass_1` – Grasbüschel mit klarer Silhouette
- [ ] `deco_fence_1` – kurzes Holzzaunsegment

Im Creator Store nur Modelle mit wenigen Dreiecken und passender Cel-Formensprache wählen. Quelle/Urheber und Nutzungsbedingungen vor Verwendung prüfen und lokal festhalten. Große Grasflächen, realistische Blatt-Texturen und Effektpakete passen nicht zu dieser Etappe. Nur das benötigte Model oder den MeshPart exportieren, kein ganzes Paket-Verzeichnis. Der Lader entfernt Skripte, Sounds, ClickDetector, ProximityPrompt und Partikeleffekte aus dem Klon, warnt einmal je Datei und deaktiviert Kollisionen, Touch und Abfragen. Die lokale Vorlage wird dabei nicht verändert.

## Prompt-Vorlage

Leons Referenzblatt als Stilreferenz anhängen; dieselben 2-Ton-Schatten und flachen Farben verwenden. Für Meshy je Objekt eine einzelne freie Ansicht verwenden; eine zusätzliche Rückansicht separat erzeugen, statt mehrere Objekte in einem Bild zusammenzustellen.

> *Stylized anime fantasy tactics game environment prop, [OBJEKT], same art style as the attached character reference, 2-tone cel shading, flat colors, clean hard shadows, no outline, simplified low-poly shapes, strong readable silhouette, [REGION-FARBEN], isolated single object, full object visible, neutral grey background, no ground plane, no cast shadow, no text, no character, front three-quarter view. [FORM UND FREIE BEREICHE]*

Beispiel Baum: `[OBJEKT] = compact slender deciduous tree`, `[REGION-FARBEN] = rich grass green foliage, warm brown trunk`, `[FORM UND FREIE BEREICHE] = few large canopy masses, branches contained close to the trunk, narrow footprint`.

Beispiel Brücke: `a pair of low wooden bridge railings`, `warm brown wood`, `railings aligned along the front-to-back axis, wide empty central passage, no deck or floor slab`.

Negativ: *realistic, photo, noisy texture, soft gradient shading, outline, text, watermark, ground plate, base pedestal, particles, character, multiple objects on one sheet*.

## Ein erstes Asset einbinden

1. Einen Baum als `tree_1` nach der Vorlage erzeugen und mit [Stil-Guide, Umgebung](stil-guide.md#9-umgebung) vergleichen.
2. Bild in Meshy zu einem Objekt umwandeln, mit Textur als FBX oder GLB herunterladen. Rohdatei unter `assets/raw/tree_1/` ablegen; separate Texturdateien neben die FBX legen. Die Ausgangstextur darf größer als 512 sein.
3. Im Projektordner aufbereiten (Blender installiert):

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/cleanup.ps1 -In assets/raw/tree_1/tree_1_meshy.glb -Name tree_1 -Prop -MaxTris 1500
   ```

   Dateiname/Endung an die eigene Eingabe anpassen. `-Prop` verwendet standardmäßig 512 px und 3.000 Dreiecke, die Tabelle setzt engere Grenzen für kleine Objekte. Für Busch `-MaxTris 600`, Fels `-MaxTris 1000`; Figuren weiterhin ohne `-Prop`. `-Front '+X'` ist der Standard; bei falscher Ausrichtung die ursprüngliche Vorderachse nach Blender-Import mit `-Front '-X'`, `'+Y'` oder `'-Y'` angeben. Explizites `-Size`/`-MaxTris` überschreibt den Modus-Standard. Kopferkennung und `-HeadShare` werden im Objekt-Modus übersprungen.
4. Unter `assets/raw/tree_1/clean/` die Bilder `tree_1_vorne.png`, `_seite.png`, `_oben.png` ansehen: vollständiges Objekt, aufrechte Haltung, Farben und freie Bereiche. `tree_1_vorne_original.png` ist der Farbvergleich. Bericht prüfen: Dreiecke innerhalb des Tabellenlimits, Textur 512×512, Farbtreue und FBX-Re-Import erfolgreich, Exit-Code 0. Optional `-Cel` mit eigenem Namen erzeugt eine Farbpalette für das ganze Objekt; keine Gesichtsausnahme.
5. `tree_1_clean.fbx` in Studio über **3D importieren** importieren. Textur und Ausrichtung prüfen. MeshPart oder zusammengehörige Teile zu einem Model gruppieren, **Wurzel `tree_1` nennen** und Pivot unten Mitte setzen. Keine Scripts/Rigs/Bodenplatte ergänzen.
6. Dieses eine Model auswählen → Rechtsklick → **Save to File…** → `assets/environment/tree_1.rbxm`. Dateiname und Wurzelname gleich halten; keine zusätzliche Ordnerhülle speichern. Weitere Varianten heißen `tree_2.rbxm`, `tree_3.rbxm` usw.; Kategorien und Nummern wie oben, Kleinbuchstaben, Nummer ab 1.
7. Rojo mit `tools/rojo.exe serve default.project.json` starten, in Studio an **127.0.0.1:34872** verbinden. In `ServerStorage.EnvironmentModels` prüfen, dass `tree_1` ein Model/MeshPart ist. Play → Mission mit Wald starten: Vorlagen werden beim Brettaufbau übernommen; eine bereits gebaute Mission für neue Dateien neu starten.
8. Von oben und aus Brett-Entfernung prüfen: Figur und Zug-Ring sichtbar, Feldklicks funktionieren, kein roter Output, flüssig auf dem Handy. Fehlende andere Kategorien bleiben Part-Deko. Bei Fehlern Dateiname, Kategorie und Output-Meldung melden.

Die Auswahl hängt deterministisch von Karteninhalt, Gebiet und Feldposition ab. Ein unverändertes Brett mit denselben Vorlagen erhält dieselben Varianten, Drehungen und Größen. Anordnung größerer Gebäude und Bausteine ist **Etappe B**.

## Eigene Boden-Texturen einbinden

Der Boden ist zunächst mit gedämpften Farben und kleinen prozeduralen Flecken versehen. Du kannst die Oberseite jeder Geländeart durch ein eigenes Bild ersetzen und unabhängig davon ein Bild für die Seiten eintragen. Dafür brauchst du kein 3D-Modell und kein Blender.

### 1. Nahtloses Bild erzeugen

Diese Vorlage in einer Bild-KI verwenden; als quadratisches PNG mit 512×512 Pixeln speichern:

> seamless tileable stylized anime grass texture, top-down, cel shaded, 2-tone, muted colors, no shadows, 512x512, subtle painted irregular patches, flat lighting, no perspective, no objects, no grid, no text

Varianten: `grass texture` durch `weathered stone texture` (Berg/Festung), `packed earth path texture` (Weglook), `mud texture with subtle wet patches` (Morast) oder `wood plank texture` (Brücke) ersetzen. Keine Bäume, Gebäude, großen Halme, Perspektive oder eingebrannten Schlagschatten ins Bild malen. Wenige große, dezente Farbflächen passen zum Figurenstil; viele winzige Details flimmern auf dem Handy. Eine eher helle, entsättigte Vorlage eignet sich zum Einfärben mit der Bodenfarbe; ein bereits sehr dunkles Bild wird durch diese Einfärbung noch dunkler.

„Seamless“ im Prompt garantiert keine Nahtlosigkeit: Das Bild vor dem Hochladen in einem Bildeditor viermal als 2×2-Muster nebeneinander legen. An den mittleren Kanten dürfen keine hellen Linien, Farbwechsel oder abgeschnittenen Flecken auffallen. Alternativ das Bild um 256 Pixel horizontal und vertikal mit umlaufendem Versatz verschieben, die nun mittigen Nähte korrigieren und das 2×2-Muster erneut prüfen. PNG in voller Größe speichern.

### 2. Bild in Roblox hochladen

1. Das eigene Spiel in Roblox Studio öffnen. **Fenster → Asset Manager** (oder auf der Start-Registerkarte) wählen. In älteren Studio-Versionen heißt der Weg **Ansicht → Asset Manager**. Den Button **Importieren / Asset-Import** im Asset Manager anklicken.
2. Die PNG auswählen und den Upload abschließen. In das Inventar des Nutzers bzw. der Gruppe hochladen, der das Spiel gehört.
3. Roblox moderiert hochgeladene Bilder. Das Bild erscheint erst nach Freigabe; bei einem ausstehenden oder abgelehnten Upload bleibt die Textur unsichtbar. Im Asset Manager bei Bedarf die Ansicht aktualisieren und nach dem Bildnamen bzw. Asset-Typ **Bild** filtern.
4. Beim freigegebenen **Bild** Rechtsklick → **Asset-ID kopieren**. Die Bild-ID verwenden, nicht die ID eines separaten Decal-Objekts. Die Ziffernfolge für den nächsten Schritt bereithalten.

Der aktuelle Menüweg, Import, Moderation und Kopieren der ID sind im [Roblox Asset Manager](https://create.roblox.com/docs/projects/assets/manager) beschrieben.

### 3. ID in Config eintragen

In `src/shared/Config.luau` den vorhandenen Abschnitt `Config.GROUND_TEXTURES` suchen. Den vorhandenen Eintrag für die Ebene ändern; **keinen zweiten Eintrag hinzufügen**:

```luau
["."] = { top = "rbxassetid://DEINE_BILD_ID", side = nil, studsPerTile = 8, transparency = 0.65 },
```

`DEINE_BILD_ID` durch die kopierten Ziffern ersetzen. Auch `top = "123456789"` ist möglich; diese Beispielnummer nicht als echte Textur verwenden. Für ein eigenes Seitenbild bei `side` dessen Bild-ID in Anführungszeichen einsetzen.

| Zeichen | Boden |
|---|---|
| `.` | Ebene / Gras |
| `F` | Wald |
| `M` | Berg / Fels |
| `H` | Festung / Stein |
| `B` | Brücke / Holz |
| `W` | Wasser |
| `S` | Morast |
| `D` | Tiefer Morast |

Es gibt noch keinen eigenen Weg-Geländetyp. Eine Wegtextur lässt sich zum Ausprobieren bei `.` eintragen und gilt dann für alle Ebenenfelder. Wald und Ebene benötigen jeweils ihre eigene `top`-Zuordnung; dieselbe Bild-ID darf in beiden stehen. Die Zuordnung gilt in allen Gebieten, die Farbe wird passend zum Gebiet eingefärbt.

- `top`: Bild auf der Oberseite. `nil` oder `""` aktiviert wieder die prozeduralen Flecken. Mit gesetzter Bild-ID entfallen diese Flecken, auch solange Roblox das Bild noch nicht anzeigt.
- `side`: Bild auf den vier Seitenflächen einschließlich des dünnen Oberseitenrandes. `nil` oder `""` lässt die Seiten einfarbig und dunkler. Nur ein Seitenbild verändert die prozeduralen Oberseitenflecken nicht.
- `studsPerTile`: Wiederholung in beiden Bildrichtungen. `8` entspricht einer Bildwiederholung je Feldbreite; `4` wiederholt das Bild häufiger, `16` vergrößert das Muster. Einen Wert größer als 0 verwenden. Große Bodenrechtecke wiederholen das Bild, statt es über die ganze Fläche zu strecken.
- `transparency`: `0` zeigt das eingefärbte Bild vollständig, `1` macht es unsichtbar. Mit `0.65` bleibt die Bodenfarbe deutlich sichtbar. Für stärkere Flecken z. B. `0.5` ausprobieren. Raster und Zuganzeigen liegen darüber.

Die Bedeutung von Einfärbung, Transparenz und Kachelung erklärt die [Roblox-Anleitung zu Texturen](https://create.roblox.com/docs/parts/textures-decals).

### 4. Im Spiel prüfen

Datei speichern, Rojo verbinden (**127.0.0.1:34872**) und die Mission neu starten: Der Boden wird beim Kartenaufbau erzeugt. In `Workspace.Board.Ground.Ground_…` findet sich bei gesetzter `top`-ID ein `Texture`-Objekt; die Seitenbilder sitzen zusätzlich in `Side_…`. Keine Bilddatei in `assets/environment` ablegen: Roblox lädt sie über ihre Asset-ID.

Story, Lauf und Sumpf ansehen: keine störenden Bildnähte, Gelände gut unterscheidbar, Figur und Zug-Ring sichtbar, blaue Felder anklickbar. Danach auf dem Handy prüfen. Falls das Bild fehlt: Upload-/Moderationsstatus, Bild-ID, Eigentümer/Zugriff und rote Output-Meldungen kontrollieren; `top = nil` stellt bis zur Klärung die Flecken wieder her. Die begrenzte Anzahl und Gestaltung der Standardflecken steht unter `Config.GROUND_FLECKS` (Werte WIP).
