# PLAN: Weltkarte + Gebiet Sumpf (Phase 1 von „Weltkarte & Gebiete")

Ziel: Statt einer Missionsliste gibt es einen **Weltkarten-Bildschirm** mit Gebieten, Knoten (Missionen) und Wegen dazwischen – das gibt Spielern ein Gefühl von Fortschritt. Dazu das erste neue Gebiet **Nebelsumpf** mit neuem Gelände (Morast, Tiefer Morast), zwei neuen Karten und einem neuen Gegnertyp (Sumpfhexe). Eis und Vulkan sind auf der Karte schon als „Bald verfügbar" sichtbar.
Branch: `feature/weltkarte` – abzweigen von `feature/chibi-figuren`
Kontext: Nutzerwunsch (Entscheidungen): 2D-Kartenbildschirm; Story-Karten handgebaut + später zufällige Erkundungskarten; Gelände-Hindernisse **innerhalb** der Karten, die Spezial-Einheiten (später Flieger/Teleport) umgehen – **nie** Pflicht für den Fortschritt auf der Weltkarte. Reihenfolge: Weltkarte + Sumpf zuerst.

**Allgemein**
- Daten zentral in `Stages.luau`, `Config.luau`, `UnitData.luau`. Kein neues Profil-Feld nötig (Sterne sind schon nach Stage-ID gespeichert) – `ProfileStore` nicht anfassen.
- UI über `UIKit` (Theme), Handy mitdenken: Knoten ≥ 64 px, Karte per Wischen scrollbar.
- Nur erlaubte Symbole (`★ ◆ ♦ ⚔ ⚠ ⓘ`). Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt.

## Schritte

- [ ] 1. **Gebiete + Kartengraph** – Datei: `src/shared/Stages.luau`
  - Neue Tabelle `Stages.Regions` (Reihenfolge = Anzeige):
    | id | name | color | area (Anteile der Kartenfläche x, y, w, h) | atmosphere | comingSoon |
    |---|---|---|---|---|---|
    | `greenland` | Grünland | (110,170,90) | 0.02, 0.38, 0.42, 0.58 | `battle` | – |
    | `swamp` | Nebelsumpf | (85,115,85) | 0.40, 0.45, 0.30, 0.50 | `swamp` | – |
    | `ice` | Frostgipfel | (175,205,235) | 0.30, 0.02, 0.40, 0.38 | – | true |
    | `volcano` | Glutberg | (175,75,50) | 0.70, 0.30, 0.28, 0.65 | – | true |
  - Jede Mission bekommt `region`, `mapPos = Vector2.new(x, y)` (Anteile 0–1 der Kartenfläche) und `requires = { ids }`:
    - s1 Grenzdorf: greenland, (0.10, 0.80), `{}` · s2 Waldpass: greenland, (0.22, 0.58), `{ "s1" }` · s3 Banditenfestung: greenland, (0.32, 0.82), `{ "s2" }` · s4 Nebelfurt: swamp, (0.48, 0.66), `{ "s2" }` · s5 Hexenhütte: swamp, (0.62, 0.82), `{ "s4" }` → **Verzweigung** nach s2.
  - `Stages.isUnlocked(profile, index, diffId)`: **Signatur bleibt** (Server nutzt sie in `Main.server.luau:546`). Neue Regel: freigeschaltet, wenn `requires` leer ist **oder mindestens eine** gelistete Mission geschafft ist (`isCleared`); Stufen-Regel (`diff.requires`) unverändert.
  - Hilfsfunktion `Stages.getRegion(id)`.
  - Fertig, wenn: s3 und s4 werden beide nach s2 freigeschaltet; s5 nach s4.

- [ ] 2. **Neues Gelände: Morast** – Dateien: `src/shared/Config.luau`, `src/server/BoardBuilder.luau`, `src/client/UI.luau`
  - `Config.TERRAIN.S` = Morast: `name = "Morast"`, `avoid = -15`, `def = 0`, `cost = { foot = 2, horse = 3 }`, `height = -0.2`, `terrainMaterial = Enum.Material.Mud`, `color = (95,85,60)`, `material = Enum.Material.Mud`.
  - `Config.TERRAIN.D` = Tiefer Morast: `name = "Tiefer Morast"`, `avoid = 0`, `def = 0`, `cost = {}` (für Fuß/Pferd unpassierbar – **später** `fly = 1` für Flieger, Kommentar dazu), `height = -0.8`, `terrainMaterial = Enum.Material.Mud`, `color = (60,55,40)`, `material = Enum.Material.Mud`. Optisch dunkler: zusätzlich eine flache, halbtransparente Wasserschicht (Terrain `Water`, 1 Stud) über dem Schlamm.
  - `BoardBuilder.decorate`: `S` → 2–3 Schilfhalme (dünne Zylinder 0.15×1.6, Farbe (110,120,60), leicht geneigt, Position wie bei `F` pseudozufällig aus x/y); `D` → 1–2 abgestorbene Baumstümpfe/Äste (dunkles Holz). Die Terrain-Kalibrierung (Raycast je Zeichen) muss `S`/`D` mitmessen – prüfen, dass sie über alle Zeichen läuft.
  - `UI.luau`: Ausweichen/Verteidigung mit Vorzeichen formatieren (`%+d` statt `+%d`), damit „-15" statt „+-15" erscheint (Terrain-Panel ~Zeile 511 und Info-Panel ~Zeile 499).
  - Fertig, wenn: Morast verlangsamt (Fuß 2, Pferd 3), Ausweichen −15 im Kampf wirksam und korrekt angezeigt; Tiefer Morast ist unbetretbar.

- [ ] 3. **Neuer Gegner: Sumpfhexe** – Datei: `src/shared/UnitData.luau`
  - Klasse `UnitData.Classes.EnemyMage = { name = "Hexe", mov = 5, moveType = "foot", growths = {} }` mit Chibi-Aussehen: Haut S2, Augen (150,60,160), `long` (60,40,70), `wizard` (50,80,50), Outfit (50,80,50) / (40,35,45) / (150,120,60), `robe = true`. Prüfen, ob weitere Stellen eine Klassenliste erwarten (`rg "EnemyArcher" src`) und dort gleich behandeln (z. B. R15-`look`).
  - `UnitData.Enemies.witch = { name = "Sumpfhexe", class = "EnemyMage", weapon = "Fire", stats = { hp = 16, str = 0, mag = 5, skl = 5, spd = 5, lck = 2, def = 1, res = 5 } }`
  - `UnitData.Enemies.morwen = { name = "Morwen", class = "EnemyMage", weapon = "Fire", rarity = 4, ai = "stationary", stats = { hp = 26, str = 0, mag = 8, skl = 7, spd = 6, lck = 4, def = 3, res = 7 } }` (Bosshexe, ★4-Effekte durch `rarity`).
  - Fertig, wenn: beide Gegner erscheinen als Chibi-Hexen und greifen mit Feuer (Reichweite 1–2) an; `EnemyAI` braucht keine Änderung.

- [ ] 4. **Zwei Sumpf-Karten** – Datei: `src/shared/Stages.luau` (Format wie s2/s3)
  - **s4 „Nebelfurt"** · baseGold 180 · turnGoal 9 · Beschreibung: „Im Nebelsumpf verschwinden Händler spurlos. Folge den Furten – und bleib nicht im Morast stecken."
    ```
    "..SS.F..SSD.",
    ".SSDS...SDD.",
    "..S..H...S..",
    "F...SS.F....",
    "..D.SS..SS.F",
    ".SSD...S..S.",
    "..S..F..SD..",
    "F....SS.....",
    "........F...",
    ```
    slots: (5,9) (6,9) (7,9) (4,8) · enemies (level 3): brigand (7,2), brigand (2,3), archer (6,3), javelin (11,3), witch (12,1) · hardEnemies (level 3): brigand (1,5), archer (8,4)
  - **s5 „Hexenhütte"** · baseGold 260 · turnGoal 11 · Beschreibung: „Morwen, die Moorhexe, lenkt die Banditen aus ihrer Hütte im Sumpf. Brich ihren Bann!"
    ```
    "SSD..H..DSSS",
    "SD...F...DSS",
    "S..SS..SS..S",
    "..SDDS.SDD..",
    "F..SS...S..F",
    "...........S",
    ".SS..F..SS..",
    "..S.....DS..",
    ".F...SS...F.",
    "....S....S..",
    ```
    slots: (6,10) (7,10) (8,10) (4,10) (5,9) · enemies (level 4): morwen (6,1) level 6, brigand (4,2), brigand (8,2), archer (7,3), javelin (2,5), soldier (11,6), witch (11,4) · hardEnemies (level 4): brigand (1,6), archer (12,5)
  - Vor dem Commit prüfen: alle Zeilen gleich lang, kein Slot/Gegner auf `W`/`D`, jeder Gegner per Fuß von den Slots erreichbar (per Hand oder kleinem lokalem Skript – Ergebnis in den Notizen).
  - Fertig, wenn: beide Karten spielbar, Sieg möglich, Sterne werden gespeichert.

- [ ] 5. **Sumpf-Atmosphäre** – Dateien: `src/shared/Config.luau`, `src/client/Main.client.luau` (~Zeile 649)
  - `Config.FEEL.atmosphere.swamp` = Kopie von `battle` mit: haze Density 0.38, Color (170,195,160), Decay (110,130,100), Haze 1.2; color TintColor (225,240,220), Saturation 0.05; lighting Brightness 1.8, ExposureCompensation 0.
  - Statt `Atmosphere.set(isMine() and "battle" or "hall")`: im Kampf das Preset der Region der aktuellen Mission (`Stages.getRegion(Stages.get(<stageId>).region).atmosphere`, Rückfall `"battle"`). Feldnamen der aktuellen Mission im State per `rg "stageId" src` prüfen.
  - Fertig, wenn: Sumpfkarten sind neblig-grün, Grünland-Karten unverändert.

- [ ] 6. **Weltkarten-Bildschirm** – Datei: `src/client/MenuUI.luau` (`buildLobby` Missionsteil ~Zeile 116–146, `updateLobby` ~Zeile 204–232)
  - Reiter heißt „⚔  Weltkarte". Die linke Missionsliste (300 px) wird ersetzt durch eine **Karte** links (Breite `0.6`); die Detail-Ansicht rechts bleibt inhaltlich gleich (Breite `0.4`, gleicher Code für Stufen, Regeln, Ziele, Belohnung, Start – Layout ggf. enger).
  - Karte = `ScrollingFrame` (Scrollen in X und Y, `CanvasSize` 1200×720 px, dünne Scrollbalken, Touch-Wischen). Darauf:
    - **Gebiete:** je Region ein Frame an `area` (Anteile der Canvas), `UICorner` 40, Region-Farbe mit `UIGradient` (oben heller), Transparenz 0.2, Name in `THEME.title` oben links. `comingSoon`: entsättigt (grau, Transparenz 0.45) + Schriftzug „Bald verfügbar".
    - **Wege:** für jede Kante `requires → Mission` ein Frame (8 px dick) zwischen den Knotenmittelpunkten (Länge = Abstand, `Rotation` = Winkel, `AnchorPoint` 0.5/0.5 in der Mitte). Farbe: Gold, wenn die Ausgangsmission geschafft ist, sonst dunkel/halbtransparent. Unter den Knoten (niedrigerer `ZIndex`).
    - **Knoten:** runder Button 72 px (`UICorner` voll, `UIStroke` 3 px). Zustände: *gesperrt* = grau, nicht anklickbar, Name „???"; *offen* = Region-Farbe, Rand pulsiert (TweenService, Transparenz 0↔0.6, Endlosschleife – beim Neuaufbau alte Tweens abbrechen, nicht bei jedem `update` neue starten); *geschafft* = goldener Rand, im Knoten die Missionsnummer. Darunter Name (Titel-Schrift) und Sterne-Zeile wie bisher (L/N/S + `UIKit.goalStars`). *Ausgewählt* = zusätzlicher heller Ring.
    - Tippen auf einen offenen/geschafften Knoten setzt `selectedIndex` (wie bisher) → Detail-Ansicht aktualisiert.
    - Beim ersten Öffnen: Standardauswahl = erste freigeschaltete, noch **nicht** geschaffte Mission (sonst die letzte freigeschaltete); `CanvasPosition` so setzen, dass dieser Knoten sichtbar ist.
  - Gesperrt-Texte ohne Emoji: Knoten „???", Start-Knopf „Zuerst auf %s schaffen", Warte-Text ohne „⏳" („%s kämpft gerade – bitte warten"); alle übrigen „🔒"/„⏳" in `src` ebenso ersetzen (`rg "🔒|⏳" src`).
  - Fertig, wenn: Weltkarte zeigt 4 Gebiete (2 aktiv, 2 „Bald verfügbar"), 5 Knoten, Wege inkl. Verzweigung nach s2; Auswahl und Missionsstart funktionieren am PC und per Touch.

- [ ] 7. `scripts/check.ps1` = `OK`; `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [ ] 8. Devlog-Eintrag #15 „Weltkarte + Nebelsumpf" (Teststatus „ungetestet"), Ausblick unten unter „Nächste Schritte" übernehmen, Branch pushen, dann `.handoff/status` = `fertig`.

## Manueller Test in Studio (Nutzer)
- [ ] Missionen-Reiter heißt „Weltkarte"; Gebiete Grünland + Nebelsumpf farbig, Frostgipfel + Glutberg grau „Bald verfügbar"
- [ ] Wege zwischen den Knoten; nach Sieg in Waldpass sind **Banditenfestung und Nebelfurt** beide offen; Hexenhütte erst nach Nebelfurt
- [ ] Offene Knoten pulsieren, geschaffte haben Goldrand + Sterne; Karte lässt sich wischen/scrollen (auch Handy)
- [ ] Nebelfurt/Hexenhütte: Morast verlangsamt (weniger blaue Felder), Terrain-Panel zeigt „Ausweichen -15"; Tiefer Morast nicht betretbar; Schilf sichtbar; grünlicher Nebel
- [ ] Hexen greifen mit Feuer an; Morwen bleibt in ihrer Hütte (stationär), hat ★4-Leuchten
- [ ] Alte Spielstände: bisherige Sterne/Freischaltungen bleiben erhalten
- [ ] Output ohne rote Zeilen

## Nicht anfassen
- `ProfileStore.luau` (kein Schema-Wechsel), `Combat.luau`-Formeln, `EnemyAI.luau`, `Recruit.luau`
- Bestehende Karten s1–s3 (Inhalt), Helden-Werte, Befehls-Validierung im Server (außer dass `isUnlocked` neue Regeln hat)

## Ausblick (NICHT umsetzen – nur in den Devlog)
- **Phase 2 – Zufall:** pro Versuch ein Server-Seed → Varianten der Story-Karten (Gegner-Positionen aus Pools, Geländeflecken, Wetter); zufällig erzeugte **Erkundungskarten** je Gebiet (Grinden von Gold/EP/Edelsteinen) als eigene Knotenart auf der Weltkarte.
- **Phase 3 – Flieger + Frostgipfel:** Bewegungstyp `fly` (ignoriert Gelände inkl. Tiefer Morast/Lava, anfällig für Bögen), Pegasus-Heldin (Gratis-Grundversion über Story + seltenere über Rekrutierung); Eis (Ausweichen −10, Pferde langsam), Schneewehen.
- **Phase 4 – Teleport + Glutberg:** Magier-Fähigkeit Teleport (z. B. 1× pro Kampf), Lava (unpassierbar außer Fliegen, Schaden am Rand), Asche.
- Grundsatz: Spezial-Fähigkeiten bieten Abkürzungen, Bonusziele und bessere Sterne – **nie** Pflicht für den Weltkarten-Fortschritt.

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)

## Notizen (Codex)
