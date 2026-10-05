# PLAN: Terrain-Fix + Chibi-Figuren (Prototyp zum Vergleich)

Ziel: (a) Raster, Bewegungsfelder und Figuren liegen wieder sichtbar **auf** dem Terrain. (b) Ein eigener, niedlicher **Chibi-Stil** aus Teilen (großer Kopf, Gesicht mit Augen, individuelle Frisuren/Outfits je Held), damit der Nutzer ihn mit den R15-Avataren vergleichen kann. Umschaltbar per Config; R15-Code bleibt erhalten (später evtl. KI-generierte 3D-Modelle).
Branch: `feature/chibi-figuren` – abzweigen von `feature/visual-pass-2`
Kontext: Nutzer-Test nach Visual-Pass 2 (`docs/DEVLOG.md` #12–#13), Screenshots:
- Bewegungs-/Angriffsfelder nur über Wasser sichtbar → Terrain-Oberfläche liegt höher als `Grid.toWorld` (4-Stud-Voxel + Glättung), Grashalme verdecken zusätzlich; Figuren stecken im Boden.
- Alle Kavaliere (Mira, Kai, Siegfried) ohne Modell, Aurelia ohne Kopf (R15-Pfad; Ursache offen, Nutzer liefert Output – **nicht** Teil dieses Plans).
- Nutzer: Figuren „nicht schön genug, damit Leute dafür Geld ausgeben oder grinden".

**Allgemein**
- Neue Werte zentral (`Config.CHIBI`, `UnitData`). Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt.
- Alter Block-Baukasten als Vorlage: `git show 5e4a469:src/shared/CharacterBuilder.luau` (Motoren, Waffen, Pferd, Seltenheits-Effekte). Wiederverwenden statt neu erfinden.

## Schritte

- [x] 1. **Terrain-Oberfläche kalibrieren** – Dateien: `src/server/BoardBuilder.luau`, `src/shared/Config.luau`
  - Terrain-Füllung (Schleife ab `for y = 1, Grid.height()` mit `FillBlock`) in lokale Funktion `fillTerrain(sinkByChar)` auslagern: Oberkante jedes Feldes bei `center.Y - (sinkByChar[ch] or 0)` statt `center.Y`; Grundschichten (Ground/Grass, auch außerhalb des Bretts) um den Wert für `"."` absenken.
  - Ablauf in `BoardBuilder.build`: `fillTerrain({})` → je Terrain-Zeichen (außer `W`) **ein** Feld per `workspace:Raycast(center + Vector3.new(0, 20, 0), Vector3.new(0, -40, 0), params)` messen (`RaycastParams`: `FilterType = Include`, `FilterDescendantsInstances = { workspace.Terrain }`) → `sink[ch] = treffer.Y - center.Y + Config.FEEL.terrainSurfaceMargin` (nur wenn > 0) → Bereich mit Air leeren → `fillTerrain(sink)`. Einmal `print("Terrain-Kalibrierung: ...")` mit den Werten je Zeichen.
  - `Config.FEEL.terrainSurfaceMargin = 0.15` (Abstand, damit Rasterlinien/Felder sichtbar über der Oberfläche liegen).
  - Grashalme aus: `pcall(function() workspace.Terrain.Decoration = false end)`.
  - Rasterlinien bei `+0.08` statt `+0.04` über `Grid.toWorld`.
  - Fertig, wenn: Messung + zweite Füllung umgesetzt, Output-Zeile mit Kalibrierwerten. Akzeptanz im Studio-Test: alle blauen/roten Felder und Rasterlinien sichtbar, Füße auf der Oberfläche.

- [x] 2. **Stil-Schalter** – Dateien: `src/shared/Config.luau`, `src/shared/CharacterBuilder.luau`
  - `Config.CHARACTER_STYLE = "chibi"` (Werte `"chibi"` | `"avatar"`).
  - `CharacterBuilder.build(unit)`: bei `"chibi"` → `require(script.Parent.ChibiBuilder).build(unit)` zurückgeben; sonst bisheriger R15-Pfad unverändert (das `assert(IsServer)` gilt nur im Avatar-Pfad).
  - `HeroTemplates` (Server) und `UIKit.heroPortrait` bleiben unverändert – sie funktionieren mit beiden Stilen.
  - Fertig, wenn: Umschalten in Config wechselt alle Figuren (Kampf, Saal-NPCs, Porträts).

- [x] 3. **Aussehen-Daten je Held/Gegner** – Datei: `src/shared/UnitData.luau` (nur Aussehen-Felder ergänzen, Werte nicht anfassen)
  - Feld `chibi = { skin, eyes, hairStyle, hairColor, headgear, headgearColor, outfit = { primary, secondary, trim }, robe, beard, scale }` je Held in `UnitData.Heroes` und als Klassen-Standard `UnitData.Classes.<Klasse>.chibi` für Gegner/NPCs. Held ohne eigenes Feld → Klassen-Standard.
  - Hautfarben: `S1 = (236,196,164)`, `S2 = (205,150,110)`, `S3 = (150,100,70)`. Frisuren: `spiky`, `short`, `long`, `ponytail`, `bun`, `none`. Kopfbedeckungen: `crown`, `tiara`, `helmet`, `headband`, `wizard`, `hood`, `bandana`, `kettle`, `horned` oder `nil`. Gold = (232,188,74), Metall = (185,192,204).

    | Held | Haut | Augen | Frisur / Farbe | Kopf (Farbe) | Outfit primary / secondary / trim | Extra |
    |---|---|---|---|---|---|---|
    | leon ★5 | S1 | (60,110,200) | spiky (90,58,36) | crown (Gold) | (40,70,160) / (235,235,240) / Gold | – |
    | aurelia ★5 | S1 | (150,90,210) | long (240,240,250) | tiara (Gold) | (245,245,250) / (220,190,110) / Gold | robe |
    | siegfried ★5 | S1 | (60,150,90) | short (230,200,120) | helmet (Metall, Federbusch Gold) | (190,195,205) / (150,25,35) / Gold | – |
    | mira ★4 | S2 | (60,140,120) | ponytail (200,60,50) | headband (Metall) | (40,140,140) / (190,195,205) / (230,230,235) | – |
    | selina ★4 | S1 | (230,180,60) | long (35,30,40) | wizard (110,60,160) | (110,60,160) / (40,35,50) / Gold | robe |
    | tobi ★3 | S2 | (110,80,50) | short (100,70,45) | hood (70,120,60) | (70,120,60) / (120,90,60) / (60,45,35) | – |
    | greta ★3 | S1 | (90,100,160) | bun (120,130,170) | wizard (40,50,100) | (40,50,100) / (235,225,200) / (200,170,90) | robe |
    | bruno ★2 | S3 | (70,50,40) | spiky (30,25,25) | bandana (170,40,40) | (120,85,55) / (170,40,40) / (60,45,35) | – |
    | kai ★2 | S1 | (80,100,140) | short (70,50,35) | helmet (Metall, Federbusch Teamfarbe) | (60,90,150) / (150,155,165) / (200,200,210) | – |
    | finn ★1 | S1 | (80,130,70) | spiky (190,80,40) | bandana (70,130,70) | (200,180,140) / (70,130,70) / (110,80,55) | – |
    | ida ★1 | S2 | (110,80,50) | ponytail (235,205,120) | headband (80,130,70) | (130,100,70) / (80,130,70) / (70,50,35) | – |

    Klassen-Standard (Gegner/NPC): Brigand = S2, short (30,25,25), bandana (110,25,30), Outfit (110,25,30)/(90,70,50)/(50,40,30) · Soldier = S1, short (90,60,40), kettle (Metall), Outfit (150,155,165)/(120,30,35)/(80,80,90) · EnemyArcher = S2, short (90,60,40), hood (110,25,30), Outfit (110,25,30)/(90,70,50)/(50,40,30) · Chieftain = S3, none, horned (Metall), beard, scale 1.2, Outfit (40,35,35)/(130,25,30)/(170,140,80) · Lord/Cavalier/Archer/Mage/Fighter = Werte von leon/kai/tobi/greta/finn.
  - Fertig, wenn: jeder Held und jede Gegnerklasse hat ein auflösbares `chibi`-Aussehen.

- [ ] 4. **ChibiBuilder** – neue Datei `src/shared/ChibiBuilder.luau` (läuft auf Server **und** Client, keine Netz-Assets)
  - Gerüst wie alter Baukasten (`5e4a469`), aber **R15-kompatible Namen**, damit `UnitAnimator`/`UIKit` ohne Änderung laufen:
    - Wurzel `HumanoidRootPart` (unsichtbar, verankert, am Boden, `PrimaryPart`); Rumpf `UpperTorso`; Kopf `Head`; Hände `RightHand`/`LeftHand`.
    - Motor6D-Namen: `Root` (HumanoidRootPart→UpperTorso), `Neck`, `RightShoulder`, `LeftShoulder`, `RightHip`, `LeftHip`, `CapeJoint`.
    - Attribute: `GroundOffset = 0`, `Mounted`, `HeadY`, `TopY`.
  - Proportionen in `Config.CHIBI` (Startwerte, Studs): Beine 0.7×1.0×0.7 (Hüfte y 1.0, untere 0.35 als Stiefel in `trim`), Rumpf 1.7×1.5×1.1 (y 1.0–2.5) mit Gürtel, Arme 0.55×1.1×0.55 (Schulter x ±1.15, y 2.35) + Hand-Kugel Ø0.6 (Haut), **Kopf = Kugel Ø2.6** (Mitte y 3.7, Hals-Gelenk y 2.5). Gesamt-Skalierung `scale` (Chieftain 1.2).
  - **Gesicht** (Vorderseite = −Z, an der Kopfkugel anliegend): 2 Augen (0.38×0.6×0.1, Farbe `eyes`, x ±0.48, y 3.6) mit Neon-Glanzpunkt (0.14×0.14, weiß, oben innen), kleiner Mund (0.3×0.06, dunkel, y 3.15), Wangenröte (0.3×0.12, rosa, Transparenz 0.4, x ±0.75, y 3.35). Chieftain: schräge Augenbrauen. `beard` = Block unter dem Kinn in dunkler Haarfarbe.
  - **Haare** (`hairColor`; außer `none` immer Haar-Kappe = Kugel Ø2.75 bei (0, 3.85, 0.15), Gesicht bleibt frei): `spiky` + 5 schräge Zacken oben/hinten · `short` nur Kappe · `long` + Rückenplatte 2.2×2.2×0.5 bei (0, 3.2, 0.9) · `ponytail` + Kugel Ø0.9 hinten (0, 4.2, 1.4) + Zopf 0.6×1.6×0.6 nach unten · `bun` + Kugel Ø1.0 oben hinten.
  - **Kopfbedeckungen** (`headgearColor`): crown (Ring + 5 Zacken) · tiara (schmaler Reif + Neon-Edelstein in Seltenheitsfarbe) · helmet (Kugelschale Ø2.85 über der Kappe, Gesicht frei, Federbusch) · headband (Band um die Stirn) · wizard (Krempe Ø3.4 + 3 gestapelte, kleiner werdende Zylinder, Spitze leicht geneigt) · hood (Kugel Ø2.95 nach hinten versetzt, Gesicht frei) · bandana (Stirnband + Knoten hinten) · kettle (Krempe + Halbkugel) · horned (Kappe + 2 Hörner).
  - **Outfit:** Rumpf `primary`, Arme/Beine `secondary`, Gürtel/Stiefel/Säume `trim`. `robe = true` → Rock 1.8×0.9×1.2 unter dem Rumpf in `primary`. Team-Lesbarkeit: Schulterstücke + Brust-Schärpe in Teamfarbe (`"team"`, Attribut `Tint`); Outfit-Teile ebenfalls `Tint` (werden grau, wenn die Einheit fertig ist). Haut, Gesicht, Haare ohne `Tint`.
  - **Aus dem alten Baukasten übernehmen** (an neue Maße angepasst): Waffen an `RightHand` (Bogen/Buch an `LeftHand`), Pferd für Kavalier (Reiter erhöht, Hüften gebeugt, `Mounted = true`), Seltenheits-Effekte (Schnalle, Kragen, Waffenglühen + Funken, Umhang mit Saum, Wappen, Aura-Ring + Partikel), Umhang für Lord.
  - Alle Teile: `CanCollide/CanTouch = false`, `Massless = true`; Material SmoothPlastic (Metall-Teile Metal, Stoffe Fabric).
  - Fertig, wenn: `ChibiBuilder.build(unit)` liefert für jeden Helden/Gegner/NPC ein Modell ohne Fehler; Laufen, Atmen, Angriffe und Treffer laufen über die bestehenden Motor-Namen.

- [ ] 5. **Abgeschnittener Knopftext** – Datei: `src/client/UI.luau` (`tools.undo`)
  - „Rückblende N" passt nicht in den Werkzeugknopf: `TextScaled = true` plus `UITextSizeConstraint` (MaxTextSize 13).
  - Fertig, wenn: Text vollständig lesbar.

- [ ] 6. `scripts/check.ps1` = `OK`; `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [ ] 7. Devlog-Eintrag #14 „Terrain-Fix + Chibi-Prototyp" (Teststatus „ungetestet"), „Nächste Schritte" um den Ausblick unten ergänzen, Branch pushen, dann `.handoff/status` = `fertig`.

## Manueller Test in Studio (Nutzer)
- [ ] Kampf: blaue/rote Felder und Rasterlinien überall sichtbar (Wiese, Wald, Berg); Figuren stehen mit den Füßen auf dem Boden; Output-Zeile „Terrain-Kalibrierung: …" vorhanden
- [ ] Chibi-Figuren: großer Kopf mit Augen; jede/r Held/in am Haar/Hut/Outfit sofort unterscheidbar; Gegner klar erkennbar
- [ ] Kavaliere (Mira, Kai, Siegfried) sitzen auf dem Pferd; Aurelia vollständig
- [ ] Laufen, Atmen, Angriff, Treffer, Tod animiert; ★4/★5 mit Leuchten/Umhang/Aura
- [ ] Porträts in Info-Panel, Kaserne, Rekrutierung zeigen die Chibi-Figuren
- [ ] Vergleich: `Config.CHARACTER_STYLE = "avatar"` → R15-Avatare wie vorher
- [ ] Output ohne rote Zeilen

## Nicht anfassen
- Spielregeln/Formeln/KI (`Combat.luau`, Bewegungslogik in `Grid.luau`, `EnemyAI.luau`), `Stages.luau`, `Recruit.luau`, `ProfileStore.luau`, Helden-**Werte** in `UnitData.luau`
- R15-Avatar-Pfad in `CharacterBuilder.luau` (nur den Stil-Schalter davorsetzen)
- Asset-IDs (Sounds, Accessoires, Animationen)

## Ausblick (NICHT umsetzen – nur in den Devlog unter „Nächste Schritte")
Vom Nutzer gewünscht, je eigener Plan nach dem Stil-Entscheid:
1. Ausrüstung/Items: Waffen und Gegenstände zum Ausrüsten der Einheiten (am Modell sichtbar).
2. Beschwörungs-Show: animierte Rekrutierung (Lichtsäule in Seltenheitsfarbe, Kamerafahrt, Pose).
3. Helden-Showcase: großes drehbares Modell in der Kaserne.
4. Eigene Angriffs-Effekte für ★4/★5.
5. Skins / Ausrüstungs-Stufen (Aussehen wächst mit Verschmelzen/Level; kaufbare Skins).
6. Option: KI-generierte 3D-Modelle (Nutzer prüft Tools) als dritter Stil `"mesh"` im selben Schalter.

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)
- Schritt 4 verlangt individuelle Outfitfarben sowie `Tint` für das Ergrauen fertiger Einheiten. `UnitVisuals.update` (`src/server/UnitVisuals.luau`, ab Zeile 157) setzt jedoch jedes Teil mit `Tint` auch bei aktiven Einheiten auf Teamfarbe; dadurch gehen `primary`, `secondary` und `trim` verloren. Darf der Plan um eine gezielte Anpassung dieser Funktion ergänzt werden: Chibi-Outfitteile speichern ihre ursprüngliche Farbe als Attribut, aktive Einheiten erhalten diese Farbe zurück, fertige Einheiten weiterhin `Config.DONE_COLOR`; Teamteile und der Avatar-Pfad behalten das bisherige Verhalten?
  - **Antwort Claude: Ja, genau so.** Ergänzung zu Schritt 4 (Datei zusätzlich `src/server/UnitVisuals.luau`, nur `UnitVisuals.update`): ChibiBuilder setzt an Outfit-Teilen Attribut `BaseColor` (Color3). In `update`: Teil mit `Tint` → fertig = `Config.DONE_COLOR`, aktiv = `p:GetAttribute("BaseColor") or Teamfarbe`. Teamteile (ohne `BaseColor`) und Avatar-Pfad unverändert. Weiter umsetzen.

## Notizen (Codex)
- Branch `feature/chibi-figuren` von `feature/visual-pass-2` angelegt. Vor den Umsetzungsschritten wegen des Farbkonflikts angehalten; noch keine Codeänderungen.
