# Charakter-Pipeline: vom Design zum Spielmodell

Ziel: Alle Figuren im Anime-Stil des Leon-Designs (realistische Anime-Proportionen, Cel-Look, Silber/Gold-Rüstung, kräftige Stofffarben). Im Spiel als echte 3D-Modelle (Figurenstil `"mesh"`). Fehlt ein Modell, zeigt das Spiel automatisch die Chibi-Figur – man kann also Figur für Figur austauschen.

## 1. Design-Blatt (Bild)
Pro Figur **zwei Bilder** wie beim Leon-Design:
- **Vorderansicht + Rückansicht in T-Pose**, ganzer Körper, neutraler grauer Hintergrund, keine Schatten am Boden, kein Text.
- Arme waagerecht, Finger gestreckt, Beine leicht auseinander – erleichtert das spätere Rigging.
- **Waffe nicht in der Hand.** Waffen in der Hand fügt das Spiel selbst hinzu (sie wechseln mit der Ausrüstung). Schwerter/Bögen/Bücher dürfen als Deko auf dem Rücken oder an der Hüfte sein.
- Gleicher Stil für alle: Leons Blatt als Stil-Referenz an den Bildgenerator geben und denselben Prompt-Rahmen verwenden (siehe Abschnitt 5).

## 2. Bild → 3D-Modell
Werkzeuge mit **Mehransicht-Eingabe** (Vorder- + Rückbild): z. B. Meshy, Tripo, Rodin.
- Einstellungen: Stil „stylized/anime", **Ziel ≤ 20 000 Dreiecke** (Roblox-Grenze je MeshPart, außerdem wichtig fürs Handy), Textur **1024 × 1024**, möglichst **ein** Material.
- Ergebnis als **FBX** (oder GLB → in Blender als FBX exportieren) herunterladen.
- In Blender prüfen/aufräumen: Blickrichtung nach vorne, schwebende Einzelteile entfernen, Löcher schließen. Die Größe stellt man beim Import in Studio ein (Ziel: Körperhöhe ca. 5–6 Studs).

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

## 5. Design-Briefings (gleicher Stil wie Leon)
Prompt-Rahmen für den Bildgenerator (jede Figur einsetzen):
> *Anime fantasy RPG character reference sheet, full body, T-pose, front view and back view, neutral grey background, clean cel shading, high detail armor and cloth, same art style as the reference image, no weapon in hands, [BESCHREIBUNG]*

| ID | Klasse / ★ | Beschreibung (Kurzfassung für den Prompt) | Farben |
|---|---|---|---|
| leon | Fürst ★5 | **fertig** – blondes Stachelhaar, blaue Augen, Silber-Gold-Rüstung, blauer Schal/Umhang, blauer Wappenrock mit Gold-Raute, Schwert auf dem Rücken | Blau, Silber, Gold, Schwarz, Rot (Schärpe) |
| aurelia | Magierin ★5 | junge Erzmagierin, langes silberweißes Haar, violette Augen, goldenes Diadem, weiß-goldene Robe mit hohem Kragen und Sternenstickerei, schwebende Lichtrunen als Schmuck, Zauberbuch am Gürtel | Weiß, Gold, Violett |
| siegfried | Kavalier ★5 | erfahrener Ritter, kurzes blondes Haar, grüne Augen, schwere Plattenrüstung mit goldenen Zierkanten, roter Umhang, Helm mit goldenem Federbusch unter dem Arm/auf dem Rücken, Lanze auf dem Rücken | Silber, Karmesinrot, Gold |
| mira | Kavalierin ★4 | lebhafte Reiterin, roter hoher Pferdeschwanz, türkisfarbener Waffenrock über leichter Rüstung, Metall-Stirnband, Reithandschuhe | Türkis, Silber, Weiß |
| selina | Magierin ★4 | geheimnisvolle Hexenmagierin, langes schwarzes Haar, goldene Augen, breiter violetter Zaubererhut, violett-schwarze Robe mit goldenen Mondmotiven | Violett, Schwarz, Gold |
| tobi | Bogenschütze ★3 | junger Jäger, kurzes braunes Haar, grüne Kapuze, Lederweste, Köcher auf dem Rücken, Armschutz | Waldgrün, Braun, Leder |
| greta | Magierin ★3 | ruhige Gelehrte, blaugraues Haar im Dutt, Brille, navyblaue Robe mit cremefarbenem Kragen, Schriftrollen am Gürtel | Navy, Creme, Messing |
| bruno | Kämpfer ★2 | kräftiger Axtkämpfer, schwarzes Stachelhaar, dunklere Haut, rotes Bandana, ärmelloses Lederwams, Gürtel mit Wurfbeilen (Deko) | Braun, Rot, Leder |
| kai | Kavalier ★2 | junger Knappe, dunkelbraunes Haar, schlichter Helm, blau-grauer Waffenrock, einfache Kettenrüstung | Blau, Grau |
| finn | Kämpfer ★1 | Bauernjunge mit Axt, orange Stachelhaare, grünes Bandana, beiges Hemd, geflickte Hose | Beige, Grün |
| ida | Bogenschützin ★1 | Dorf-Jägerin, blonder Pferdeschwanz, grünes Stirnband, braune Lederkleidung, kleiner Köcher | Braun, Grün |
| Brigand | Gegner | Bandit, dunkelrotes Bandana, zerrissene rot-braune Lederkleidung, Narben | Dunkelrot, Braun |
| Soldier | Gegner | Soldat des Grafen, Eisenhut (Kettle Hat), graue Rüstung mit rotem Waffenrock | Grau, Rot |
| EnemyArcher | Gegner | Banditen-Schütze, rote Kapuze, Lederkleidung | Dunkelrot, Braun |
| EnemyMage | Gegner | Sumpfhexe, langes dunkelviolettes Haar, moosgrüner Hexenhut, zerfranste Robe | Moosgrün, Violett |
| Chieftain | Boss | Banditenanführer Garrick, Hörnerhelm, Bart, schwarze Pelzrüstung mit rotem Umhang | Schwarz, Rot, Messing |

Seltenheit sichtbar machen: ★4/★5 mit mehr Gold, aufwendigeren Umhängen und Schmuck; ★1/★2 schlichter. Die Leuchteffekte (Aura, Funken) fügt das Spiel selbst hinzu.

## 6. Leistung (Handy)
- ≤ 20 000 Dreiecke und eine 1024er-Textur je Figur; auf dem Brett stehen bis zu ~14 Figuren gleichzeitig.
- Lieber ein Mesh als viele Einzelteile; keine transparenten Haar-Karten (teuer und flackern).
