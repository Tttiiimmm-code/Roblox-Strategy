# PLAN: Level-Optik Etappe A2 – Klickfix, dunklerer Boden mit Textur

Ziel: Nach dem Studio-Test von Etappe A (Devlog #24): Felder wieder anklickbar, Boden **dunkler/gedämpfter** und **nicht mehr nur flach**, sondern mit dezenter gemalter Textur – vorbereitet für eigene Boden-Texturen des Nutzers.
Branch: `feature/level-optik`

**Nutzer-Rückmeldung (08.10.2026):** Boden „nur flach und viel zu grell, muss dunkler“; Raster ok; Objekte gut sichtbar; Klick auf blaue Bewegungsfelder wird nicht angenommen (keine Fehlermeldung, Auswahl bleibt). Entscheidung Bodenlook: **„Dunkler + Textur“** (gedämpfte Farben, dezente gemalte Gras-/Stein-Textur, später durch eigene Texturen ersetzbar).

## Schritte

- [x] 1. **Review + Commit Klickfix (Claude, uncommittet in `src/server/BoardBuilder.luau`)**
  - Ursache: `Surround`, `Side_*`, `Ground_*` hatten `CanCollide = true`; Roblox ignoriert `CanQuery = false` nur bei `CanCollide = false`. Der Klick-Raycast (`tileFromRay`, Include = Board + Units) traf deshalb die Bodenplatte (bündig mit der Oberkante der unsichtbaren `Tile_x_y`) statt der Kachel mit X/Y-Attributen. Fix: diese drei `deco`-Aufrufe ohne `CanCollide = true`.
  - Prüfen: keine anderen Brett-Teile mit `CanCollide = true` und fehlenden X/Y-Attributen im Raycast-Bereich (auch Fallback-Deko, Wasser, Pfützen, Rand); nichts im Spiel braucht kollidierende Bodenplatten (Figuren sind verankert, Spieler-Avatar steht im Thronsaal). Ergebnis in Notizen, dann committen.
  - Fertig, wenn: Raycast-Stub (wie frühere Prüfhilfen) trifft für jeden Feldmittelpunkt von oben und schräg aus Kamerawinkel die richtige `Tile_x_y`.

- [x] 2. **Gedämpfte Farben** – `src/shared/Config.luau` (`TERRAIN.color`), `src/shared/Stages.luau` (Regionsfarben)
  - Alle Boden- und Randfarben deutlich dunkler und weniger gesättigt (Richtwert: Sättigung −25 bis −35 %, Helligkeit −20 bis −30 %), Geländearten weiterhin klar unterscheidbar (Ebene/Wald/Berg/Festung/Wasser/Morast); Seitenflächen bleiben eine Stufe dunkler. Werte zentral, Kommentar „Werte WIP“.
  - Fertig, wenn: Farbtabelle vorher/nachher in den Notizen.

- [ ] 3. **Textur auf dem Boden** – `src/server/BoardBuilder.luau`, `src/shared/Config.luau`
  - `Config.GROUND_TEXTURES[ch] = { top = "<asset-id>" | nil, side = "<asset-id>" | nil, studsPerTile, transparency }` (leer = keine Bild-ID vorhanden). Ist eine ID gesetzt: `Texture`-Instanzen auf Ober- bzw. Seitenflächen der `Ground_`/`Side_`-Parts (Kachelung über `StudsPerTileU/V`, Farbe/Transparenz so, dass die Geländefarbe sichtbar bleibt).
  - **Ohne Bild-ID (Standard):** prozedurale Auflockerung ohne Assets: je Feld wenige flache, leicht dunklere/hellere unregelmäßige Flecken (deterministisch aus Feld + Kartenkennung, knapp über der Oberfläche, `CanCollide`/`CanQuery`/`CanTouch` = false), Wald-/Gras-Felder zusätzlich vereinzelte kleine Halm-/Steinflecken. Mitte des Feldes nicht überladen (Figur, Zug-Ring, Bewegungsfelder müssen gut lesbar bleiben). Teilezahl im Blick behalten (Handy) – Obergrenze je Feld in Config; Aufbauzeit-Stub vorher/nachher in Notizen.
  - Raster und Overlays bleiben über den Flecken sichtbar (Höhen-Reihenfolge prüfen).
  - Fertig, wenn: ohne IDs Flecken sichtbar und deterministisch; mit Test-ID (Stub) korrekte `Texture`-Instanzen; Klick-Raycast-Prüfung aus Schritt 1 weiterhin grün.

- [ ] 4. **Anleitung eigene Boden-Texturen** – `docs/umgebung-assets.md` (neuer Abschnitt)
  - Für Einsteiger: nahtlose (tileable) stilisierte Textur per Bild-KI erzeugen (Prompt-Vorlage: „seamless tileable stylized anime grass texture, top-down, cel shaded, 2-tone, muted colors, no shadows, 512x512“ + Varianten für Stein/Weg/Morast), auf Nahtlosigkeit prüfen, in Roblox Studio hochladen (**Ansicht → Asset Manager → Importieren**, Bild-ID kopieren), in `Config.GROUND_TEXTURES` eintragen. Roblox-Hinweis: hochgeladene Bilder werden moderiert, erst danach sichtbar.
  - Fertig, wenn: Nutzer kann ohne Rückfrage eine Textur einbinden.

- [ ] 5. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok. Devlog #24 um Nachtrag ergänzen (Klickfix, Farben, Textur; Teststatus ungetestet). Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Figur wählen → blaues Feld anklicken → Bewegung/Menü funktioniert (Story + Lauf, auch auf Wald/Berg/Festung)
- [ ] Boden dunkler, nicht mehr grell, Flecken lockern auf, Geländearten unterscheidbar
- [ ] Raster, Bewegungs-/Angriffsfelder und Zug-Ring gut sichtbar
- [ ] Handy flüssig

## Nicht anfassen
- Generator-Layout (Etappe B), Thronsaal, Spielregeln, Figuren

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden. Befehle außerhalb der Sandbox wie zuvor nur mit Freigabe des Nutzers.)

## Notizen (Codex)
- Schritt 2: HSV-Sättigung × 0,70 und Helligkeit × 0,75, auf ganze RGB-Werte gerundet. Seiten bleiben zusätzlich 22 % dunkler. Weltkarten-/Schwierigkeitsfarben und Objektfarben außerhalb der Bodenpalette bleiben unverändert; Grünland übernimmt Config, Sumpf überschreibt wie bisher.

| Boden/Rand | RGB vorher | RGB nachher |
|---|---|---|
| Ebene | 126/184/92 | 108/138/90 |
| Wald | 72/132/62 | 68/99/62 |
| Berg | 140/122/98 | 105/96/83 |
| Wasser | 60/120/200 | 77/108/150 |
| Morast | 95/85/60 | 71/66/53 |
| Tiefer Morast (auch Sumpf) | 55/95/110 | 54/75/83 |
| Festung | 170/160/150 | 128/122/117 |
| Brücke | 150/110/70 | 113/92/71 |
| Sumpf Grasmaterial | 78/92/52 | 62/69/48 |
| Sumpf Wassermaterial | 52/62/38 | 41/47/34 |
| Sumpf Rand | 92/122/70 | 76/92/64 |
| Sumpf Ebene | 102/142/78 | 86/107/73 |
| Sumpf Wald | 64/104/57 | 57/78/53 |
| Sumpf Wasser | 65/112/130 | 63/88/98 |

- Schritt 1: Claudes vorbereiteten Klickfix geprüft. Sämtliche Brett-Deko einschließlich Boden, Seiten, Rand, Fallbacks, Wasser und Pfützen hat CanCollide/CanQuery/CanTouch = false; importierte Modelle werden ebenfalls bereinigt. Nur Tile_x_y bleibt abfragbar. Figurenwurzeln sind verankert, der Avatar steht im separaten Thronsaal: keine Boden-Kollision erforderlich.
- Raycast-Stub mit Strahl/Quader-Schnitt und Roblox-Kollisionsregel: alle fünf Storykarten, Lauf Seed 12345 und alle acht Geländearten; 5.616 Strahlen senkrecht sowie im echten Kamerawinkel (Offset 0/1/0,75) und 70°, jeweils vier Drehrichtungen, treffen die richtige Kachel. Pflichtcheck OK (32 Dateien). Studio-/Handytest ausstehend.
- Aufbauzeit vor Texturflecken (30 Aufbauten/Karte, lokaler Stub): s1 4,49 ms / 449 Parts; s2 7,50 / 776; s3 6,88 / 681; s4 8,27 / 874; s5 9,81 / 985; Lauf 4,87 / 479. Keine Aussage über Roblox-Rendering/Replikation; tools-Prüfhilfen bleiben ignoriert.
