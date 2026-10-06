# Charakter-Pipeline: vom Design zum Spielmodell

Ziel: Alle Figuren im Anime-Stil des Leon-Designs (realistische Anime-Proportionen, Cel-Look, Silber/Gold-Rüstung, kräftige Stofffarben). Im Spiel als echte 3D-Modelle (Figurenstil `"mesh"`). Fehlt ein Modell, zeigt das Spiel automatisch die Chibi-Figur – man kann also Figur für Figur austauschen.

## 1. Design-Blatt (Bild)
Pro Figur **zwei Bilder** wie beim Leon-Design:
- **Vorderansicht + Rückansicht in T-Pose**, ganzer Körper, neutraler grauer Hintergrund, keine Schatten am Boden, kein Text.
- Arme waagerecht, Finger gestreckt, Beine leicht auseinander – erleichtert das spätere Rigging.
- **Waffe nicht in der Hand.** Waffen in der Hand fügt das Spiel selbst hinzu (sie wechseln mit der Ausrüstung). Schwerter/Bögen/Bücher dürfen als Deko auf dem Rücken oder an der Hüfte sein.
- Gleicher Stil für alle: Leons Blatt als Stil-Referenz an den Bildgenerator geben und die Prompt-Vorlage aus `docs/stil-guide.md` verwenden.

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
