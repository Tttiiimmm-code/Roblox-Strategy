# Charakter-Pipeline: vom Design zum Spielmodell

Ziel: Alle Figuren im Anime-Stil des Leon-Designs (realistische Anime-Proportionen, Cel-Look, Silber/Gold-Rüstung, kräftige Stofffarben). Im Spiel als echte 3D-Modelle (Figurenstil `"mesh"`). Fehlt ein Modell, zeigt das Spiel automatisch die Chibi-Figur – man kann also Figur für Figur austauschen.

## 1. Design-Blatt (Bild)
Pro Figur **zwei Bilder** wie beim Leon-Design:
- **Vorderansicht + Rückansicht in T-Pose**, ganzer Körper, neutraler grauer Hintergrund, keine Schatten am Boden, kein Text.
- Arme waagerecht, Finger gestreckt, Beine leicht auseinander – erleichtert das spätere Rigging.
- **Waffe nicht in der Hand.** Die eigene Waffe der Figur wird separat generiert (`<id>_waffe.rbxm`, siehe Style-Guide Abschnitt 5) und vom Spiel in die Hand gesetzt. Deko-Waffen auf Rücken/Hüfte sind erlaubt.
- Gleicher Stil für alle: Leons Blatt als Stil-Referenz an den Bildgenerator geben und die Prompt-Vorlage aus `docs/stil-guide.md` verwenden.

## 2. Bild → 3D-Modell
Werkzeuge mit **Mehransicht-Eingabe** (Vorder- + Rückbild): z. B. Meshy, Tripo, Rodin.
- Einstellungen: Stil „stylized/anime", **Ziel ≤ 20 000 Dreiecke** (Roblox-Grenze je MeshPart, außerdem wichtig fürs Handy), möglichst **ein** Material. Generator-Textur ruhig in **4K (4096 × 4096)** herunterladen: Das Aufräum-Werkzeug überträgt sie gezielt auf 1024 × 1024 und reserviert mehr Texturfläche für den Kopf.
- Ergebnis als **FBX oder GLB** herunterladen und unter `assets/raw/<id>/` ablegen. Separate Texturdateien neben die FBX legen und ihre Dateinamen unverändert lassen, damit Blender sie findet. Rohdaten und Ergebnisse in diesem Ordner werden nicht committet.

### Aufbereiten mit einem Befehl
Voraussetzung: Blender ist unter `C:\Program Files\Blender Foundation\Blender <Version>\` installiert. PowerShell im Projektordner öffnen, zum Beispiel für Leon:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/cleanup.ps1 -In assets/raw/leon/leon_meshy.fbx -Name leon
```

Das Skript wählt die neueste Blender-Installation und arbeitet ohne geöffnetes Blender-Fenster. Bei anderer Installation `-Blender 'C:\Pfad\blender.exe'` ergänzen. Ohne `-Name` verwendet es den Eingabedateinamen ohne Endung; ohne `-Out` landen alle Ergebnisse im Unterordner `clean` neben der Eingabe.

Es verschweißt doppelte Punkte, entfernt winzige Teile, berechnet Normalen neu und begrenzt die Geometrie standardmäßig auf 19 000 Dreiecke. Es legt neue UVs mit Kopf-Vorrang an und backt die Originalfarben auf die neue Textur. Die Figur steht anschließend mit den Füßen auf Z = 0 und blickt in Blender nach −Y; ihre Größe bleibt erhalten. Ein vorhandenes Rig und Animationen werden verworfen; Avatar Auto Setup folgt erst nach dem Aufräumen.

Vor dem Studio-Import die Dateien unter `assets/raw/leon/clean/` ansehen:

- `leon_vorne.png`, `leon_hinten.png`: ganze Figur, Ausrichtung und Farben des Ergebnisses.
- `leon_gesicht.png` neben `leon_gesicht_original_1k.png`: Ergebnis mit Kopf-Vorrang gegenüber der unverändert angeordneten Originaltextur auf 1K; Augen/Iris sollten im Ergebnis schärfer bleiben.
- `leon_vorne_original.png`: zusätzliche Vorderansicht mit der hochauflösenden Originaltextur zum Farbvergleich.
- `leon_bericht.txt`: Geometrie, UV-Inseln, tatsächlicher Kopfanteil, Farbabweichung, Laufzeit und FBX-Re-Import-Kontrolle. Ohne Cel führt eine mittlere Abweichung über 12/255 in einem RGB-Kanal zu einem Fehler; nur bei Exit-Code 0 ist der Lauf erfolgreich.

Falls die Figur falsch herum steht, erneut mit ihrer **ursprünglichen Blickrichtung nach dem Blender-Import** aufrufen: `-Front '+X'` (Standard), `-Front '-X'`, `-Front '+Y'` oder `-Front '-Y'`. Für Leon passt `+X`. Weitere Optionen: `-Size 1024`, `-HeadShare 0.25`, `-MaxTris 19000` und `-Out <ordner>`.

### Optional: Textur selbst bemalen
Augen, Wappen und Goldkanten lassen sich mit den Referenzbildern als Schablone nachmalen; fleckige Flächen mit einer einzigen Farbe glätten. Die [Einsteiger-Anleitung zum Textur-Malen](textur-malen.md) führt durch Mal-Datei, Blender, beide Speicherschritte und Studio-Import.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/paint.ps1 -Name leon -Mode Setup
powershell -ExecutionPolicy Bypass -File scripts/paint.ps1 -Name leon -Mode Export
```

Zwischen beiden Befehlen `assets/raw/leon/clean/leon_malen.blend` öffnen und malen; **Image → Save** speichert `leon_tex_bemalt.png`, **Strg + S** die Blender-Datei. Dann die Prüfbilder `leon_bemalt_vorne.png`, `_hinten.png`, `_gesicht.png` kontrollieren und `leon_bemalt.fbx` importieren. Ein vorhandenes Setup wird nur mit `-Force` neu erstellt; dabei wird die bemalte Textur gesichert und beibehalten.

### Optional: Cel-Farbreduktion
Für eine zweite Variante einen eigenen Namen verwenden, damit beide Ergebnisse vergleichbar bleiben:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/cleanup.ps1 -In assets/raw/leon/leon_meshy.fbx -Name leon_cel -Cel -CelColors 16
```

Zusätzlich entsteht `leon_cel_tex_cel.png`; die Exporte verwenden diese Textur. Die Körperfarben werden auf höchstens `-CelColors` Palettenfarben reduziert. Der Kopfbereich (obere 16 % der Höhe nahe der Körperachse), Hintergrund und Randpixel bleiben erhalten. Körperpixel mit mehr als 40 RGB-Einheiten Abstand zur Palettenfarbe behalten ebenfalls ihre Originalfarbe; ihr Anteil steht im Bericht. Daher darf das gesamte PNG mehr als 16 Farben enthalten. Der Kopf-Vorrang bei der UV-Anordnung bleibt bei den oberen 13 % und standardmäßig 25 % der UV-Fläche. Gesicht einschließlich Kinn im Prüfbild mit der normalen Variante vergleichen. Bei Cel wird die Farbabweichung nur berichtet und führt nicht zum Abbruch.

### In Studio importieren
**Roblox Studio → Avatar → 3D importieren → `assets/raw/leon/clean/leon_clean.fbx`** (für Cel: `leon_cel_clean.fbx`). Die Textur ist eingebettet; `leon_tex.png` bzw. `leon_cel_tex_cel.png` bleibt zusätzlich als separate Datei verfügbar. Auch `<Name>_clean.glb` enthält die Textur für die Weiterbearbeitung. Das Skript kontrolliert die exportierte FBX durch erneuten Import in eine leere Szene auf identische Dreieckszahl, Texturgröße und eingebettete PNG-Daten.

Im Studio Textur, aufrechte Haltung, Blickrichtung und Dreieckszahl prüfen, dann mit Abschnitt 3 fortfahren. Zielhöhe ca. 5–6 Studs; das Spiel normiert die Figur später über `meshTargetHeight`. Das Aufräum-Werkzeug wurde mit Leon in Blender geprüft; der Studio-Import und Avatar Auto Setup müssen noch manuell getestet werden.

## 3. Rig (Skelett) für Roblox
Einfachster Weg: **Roblox Studio → Avatar → Avatar Auto Setup** (Mesh importieren, Auto Setup erzeugt R15-Rig, Gelenke und Skinning automatisch). Alternative: Blender-Rig mit R15-Knochennamen.

Das Modell muss am Ende ein **R15-Rig** sein:
- `Humanoid`, `HumanoidRootPart` und die R15-Teile: `Head`, `UpperTorso`, `LowerTorso`, `LeftUpperArm`, `LeftLowerArm`, `LeftHand`, `RightUpperArm`, `RightLowerArm`, `RightHand`, `LeftUpperLeg`, `LeftLowerLeg`, `LeftFoot`, `RightUpperLeg`, `RightLowerLeg`, `RightFoot`
- Gelenke (Motor6D) mit Standardnamen (`Root`, `Neck`, `RightShoulder`, `LeftShoulder`, `RightHip`, `LeftHip` …) – das macht Auto Setup automatisch.
- Höhe ca. 5–6 Studs, Füße auf Höhe des Bodens, Blick entlang −Z (Studio-Standard „vorne").
- Keine Skripte im Modell.

Kurz prüfen: In Studio ein Standard-Animationsskript testweise drauf (oder „Play" mit dem Modell als StarterCharacter) – läuft und winkt es sauber, passt das Rig.

## 4. Ins Spiel bringen
1. Modell in Studio auswählen → Rechtsklick → **Save to File…** → als `assets/characters/<id>.rbxm` im Projektordner speichern.
   - `<id>` = Helden-ID (`leon`, `aurelia`, `siegfried`, `mira`, `selina`, `tobi`, `greta`, `bruno`, `kai`, `finn`, `ida`) bzw. für Gegner der Klassenname (`Brigand`, `Soldier`, `EnemyArcher`, `EnemyMage`, `Chieftain`).
2. Rojo synchronisiert den Ordner automatisch nach `ReplicatedStorage.CharacterModels`.
3. In `src/shared/Config.luau` `CHARACTER_STYLE = "mesh"` setzen (bzw. lassen). Figuren mit Modell erscheinen im neuen Stil, alle anderen weiter als Chibi.
4. Kavaliere: Pferd baut das Spiel weiterhin selbst dazu (Reiter wird draufgesetzt). Ein eigenes Pferdemodell kann später als `assets/characters/horse.rbxm` folgen.

## 5. Design-Vorschläge (optional – Designs entwirft und generiert der Nutzer selbst)
Verbindliche Regeln (Proportionen 1 : 7, Cel-Shading 2-Ton, Gesicht wie Leon, 1 Haupt- + 1 Akzentfarbe, Fraktionsformen, Seltenheitsstufen) und die Prompt-Vorlage stehen im **Style-Guide**. Seltenheit = Rang (★1–2 einfache Leute, ★3 Profis, ★4 Anführer, ★5 einzeln geplante Legenden). Farben sind Vorschläge und dürfen sich wiederholen. Die Liste unten sind die **aktuellen** Figuren – weitere kommen nach diesem Schema dazu.

| ID | Klasse / ★ | Hauptfarbe / Akzent | Beschreibung (für `[BESCHREIBUNG]`) |
|---|---|---|---|
| leon | Fürst ★5 | Königsblau / Gold | **fertig** – blondes Stachelhaar, blaue Augen, Silber-Gold-Rüstung, blauer Schal/Umhang, Wappenrock mit Gold-Raute, Schwert auf dem Rücken |
| aurelia | Magierin ★5 | Weiß / Gold | *Entwurf – ★5 wird einzeln geplant:* junge Erzmagierin, langes silberweißes Haar, violette Augen, goldenes Diadem, weiße Robe mit hohem Kragen, Sternen-Goldstickerei und Rauten-Emblem, Zauberbuch an der Hüfte |
| siegfried | Kavalier ★5 | Smaragdgrün / Gold | *Entwurf – ★5 wird einzeln geplant:* erfahrener Ritter, kurzes blondes Haar, grüne Augen, volle Plattenrüstung mit Gold-Ornamenten, smaragdgrüner Umhang, Helm mit goldenem Federbusch am Gürtel, Lanze auf dem Rücken |
| mira | Kavalierin ★4 | Türkis / Weiß | Anführerin der Grenzreiter (Rangabzeichen am Umhang), lebhaft, roter hoher Pferdeschwanz, volle leichte Rüstung mit Goldkanten, türkisfarbener Umhang und Waffenrock, Metall-Stirnband, Reithandschuhe |
| selina | Magierin ★4 | Violett / Gold | Zaubermeisterin mit Meisterstab-Emblem, geheimnisvoll, langes schwarzes Haar, goldene Augen, breiter violetter Zaubererhut, aufwendige violette Robe mit Goldmond-Motiven und Umhang |
| tobi | Bogenschütze ★3 | Olivgrün / Ocker | junger Jäger, kurzes braunes Haar, olivgrüne Kapuze mit Goldsaum, Lederweste, ein Armschutz aus Stahl, Köcher auf dem Rücken |
| greta | Magierin ★3 | Senfgelb / Navy | ruhige Gelehrte, blaugraues Haar im Dutt, Brille, senfgelbe Robe mit Goldsaum und navyblauem Kragen, Schriftrollen am Gürtel, eine Brosche |
| bruno | Kämpfer ★2 | Kupferorange / Dunkelbraun | kräftiger Axtkämpfer, schwarzes Stachelhaar, dunklere Haut, kupferfarbenes Stirntuch, ärmelloses Lederwams, schlicht |
| kai | Kavalier ★2 | Stahlgrau / Hellblau | Knappe (einfache Leute), dunkelbraunes Haar, schlichter stahlgrauer Waffenrock, einfache Kettenhaube, wenig Metall |
| finn | Kämpfer ★1 | Sandbeige / Hellgrün | Bauernjunge, orange Stachelhaare, hellgrünes Bandana, beiges Hemd, geflickte Hose, schlicht |
| ida | Bogenschützin ★1 | Altrosa / Braun | Dorf-Jägerin, blonder Pferdeschwanz, altrosa Tunika, braunes Stirnband, Lederkleidung, kleiner Köcher |
| Brigand | Bandit | Dunkelrot / Braun | gezackt, geflickt, Fell-Kragen, dunkelrotes Bandana, Narben |
| Soldier | Soldat (Graf) | Stahlgrau / Rot | Eisenhut, graue Rüstung mit rotem Waffenrock, ordentlicher als Banditen |
| EnemyArcher | Bandit | Dunkelrot / Ocker | rote Kapuze, Lederkleidung, ausgefranste Säume |
| EnemyMage | Sumpf | Moosgrün / Violett | Sumpfhexe, langes dunkelviolettes Haar, moosgrüner Hut mit Federn, zerfranste Robe, Knochenschmuck |
| Chieftain | Bandit (Boss) | Schwarz / Rot | Garrick, Hörnerhelm, Bart, schwarze Pelzrüstung, roter Umhang, massiger (bis 1 : 7,5) |

## 6. Leistung (Handy)
- ≤ 20 000 Dreiecke und eine 1024er-Textur je Figur; auf dem Brett stehen bis zu ~14 Figuren gleichzeitig.
- Lieber ein Mesh als viele Einzelteile; keine transparenten Haar-Karten (teuer und flackern).
