# PLAN: Visual-Pass 2 – Avatar-Figuren, 3D-Schlachtfeld, Licht/Symbole, Sounds

Ziel: Sichtbarer Qualitätssprung: moderne Roblox-Avatar-Figuren (R15) statt Klötzchen, ein echtes 3D-Schlachtfeld mit Roblox-Terrain (detaillierte Gras-/Fels-/Wasser-Texturen, Höhen), korrekt belichteter Thronsaal ohne Kästchen-Symbole und hörbare Sounds. Spielregeln bleiben unverändert.
Branch: `feature/visual-pass-2` – abzweigen von `feature/game-feel-1` (enthält Game-Feel-Pass + Fixes, vom Nutzer in Studio angespielt)
Kontext: Nutzer-Feedback nach Game-Feel-Pass: „sieht noch ziemlich gleich aus" (Screenshots: Klötzchen-Figuren mit Standard-Smiley, flache Spielfeld-Platten, überbelichteter weißer Saal, Symbole als leere Kästchen ▯, Beschwörungskreis-Schild im Boden). `docs/DEVLOG.md` #10–#11.

**Allgemein**
- Neue Einstellwerte zentral (`Config`, `UnitData`, `Sounds`). Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt.
- Asset-IDs unten stammen aus der offiziellen Roblox-Suche (Creator Store / Katalog, Ersteller **Roblox**, **ProSoundEffects**, **APMOfficial**, **DistrokidOfficial**) und sind freigegeben nutzbar. Keine anderen IDs aus dem Internet einbauen.

## Schritte

- [x] 1. **Symbole ohne Kästchen** – Dateien: `src/client/UI.luau`, `MenuUI.luau`, `CollectionUI.luau`, `UIKit.luau`
  - Gotham kennt viele Unicode-Zeichen nicht. Erlaubt bleiben nur nachweislich angezeigte: `★ ◆ ♦ ⚔ ⚠ ⓘ`. Alle anderen Deko-Zeichen ersetzen/entfernen: `✕`→`X`, `✦`/`♜`/`⚑`/`↶`/`✓`/`♛` entfernen (Text bleibt, z. B. „Rekrutieren", „Kaserne", „Aufgeben", „Zurück", „Dabei", „★ Anführer"), `⟲ n`→`Rückblende n` (Schrift 13), `▸`/`▶`/`▶▶`/`⏩` → „Zug beenden", „1×", „2×", „Gegnerphase überspringen".
  - Fertig, wenn: `rg "[✕✦♜⚑⟲▸▶⏩↶✓♛]" src` liefert nichts.

- [x] 2. **Thronsaal: Licht & Schild** – Dateien: `src/server/HubBuilder.luau`, `src/shared/Config.luau`
  - Überbelichtung: in `HubBuilder.build` `Lighting.Technology = Enum.Technology.Future`, `Lighting.Brightness = 1.2`, `Lighting.ExposureCompensation = -0.35`, `Lighting.GlobalShadows = true`. Marmor-Farben leicht abdunkeln/wärmer (`WHITE` ≈ RGB 225,218,205; `MARBLE` ≈ 205,198,186).
  - `Config.FEEL.atmosphere.hall`: Bloom `Intensity 0.18, Threshold 1.4`, ColorCorrection `Brightness -0.02, Contrast 0.12`; Kerzen-Licht `Brightness 1.2`.
  - Beschwörungskreis-Schild: Der Kreis ist ein um Z gedrehter Zylinder – `label()` daher an einen eigenen unsichtbaren, aufrechten Anker-Part hängen (`Transparency=1`, `CanCollide/CanQuery=false`, 1×1×1, über dem Kreismittelpunkt) statt an `circle`. Gleiches Muster für alle Labels nutzen, deren Anker gedreht ist.
  - Fertig, wenn: Saal nicht mehr weiß ausgebrannt, Schatten sichtbar, Schild über dem Kreis lesbar.

- [x] 3. **Sounds eintragen** – Datei: `src/shared/Sounds.luau` (Format `"rbxassetid://<id>"`)
  | Platz | ID | Titel (Quelle) |
  |---|---|---|
  | musicHub | 1839906422 | Medieval Castle (APMOfficial) – Alternative 139186694323000 Royal Court Background Music |
  | musicBattle | 1837301451 | Epic Battle Simulator (APMOfficial) – Alternative 136589058650858 Last Judgment |
  | musicVictory | 9041812129 | Born A Winner, 5 s (APMOfficial) |
  | musicDefeat | 9048278630 | Sitting with Sadness – Sting 1, 10 s (APMOfficial) |
  | click | 9119717523 | Switch Click Toggle Button 2 (ProSoundEffects) |
  | open | 9120709477 | Whoosh Fast Short Dull 2 (ProSoundEffects) |
  | close | 9113842150 | Cloth Whooshes Soft 1 (ProSoundEffects) |
  | hit | 9119746592 | Sword Hit 2 (ProSoundEffects) |
  | crit | 9116673678 | Metal Impact Heavy Clunking Hits 1 (ProSoundEffects) |
  | miss | 9119749145 | Sword Swish 102 (ProSoundEffects) |
  | death | 9113480915 | Body Fall Thud 2 (ProSoundEffects) |
  | levelUp | 1836860398 | Winning Spirit, 6 s (APMOfficial) |
  | recruit | 9116394545 | Magic Glows Chiming Hits 1 (ProSoundEffects) |
  | recruitRare | 9116395089 | Magic Glows Chiming Hits 4 (ProSoundEffects) |
  | recruitLegendary | 9116395085 | Magic Glows Chiming Hits 5 (ProSoundEffects) |
  | coin | 127645268874265 | CoinTransfer_01 (Roblox) |
  - `hover`, `phase`, `step` bleiben leer (nichts Passendes Offizielles gefunden).
  - Lautstärken in `Sounds.VOLUME` anpassen: Musik 0.3, click 0.4, hit/miss 0.6, crit 0.8.
  - Fertig, wenn: IDs eingetragen, Kommentar „vom Nutzer in Studio probehören" bleibt stehen.

- [x] 4. **3D-Schlachtfeld mit Roblox-Terrain** – Dateien: `src/shared/Config.luau`, `src/shared/Grid.luau`, `src/server/BoardBuilder.luau`
  - `Config.TERRAIN[...]` je Gelände ergänzen: `height` (Oberkante in Studs) und `terrainMaterial`: Ebene `0` / `Enum.Material.Grass`; Wald `0.4` / `LeafyGrass`; Berg `4` / `Rock`; Wasser `-1.2` / `Water` (darunter `Sand`/`Mud` als Grund); Festung `1` / `Cobblestone`; Brücke `0.2` / `WoodPlanks`.
  - `Grid.tileHeight(x, y)` (aus `terrainAt().height`) und `Grid.toWorld(x, y)` liefert die Höhe als Y (statt 0). Dadurch stehen Einheiten, Overlays, Cursor, Laufwege und Kamera-Fokus automatisch auf der richtigen Höhe – alle Aufrufer von `toWorld` prüfen, dass nichts eine feste Höhe 0 annimmt (`HubBuilder` nutzt eigene Koordinaten).
  - `BoardBuilder.build`: Brett-Bereich (plus `Config.FEEL.environmentMargin`) mit `workspace.Terrain:FillBlock(...)` aufbauen: Grundschicht `Ground`/`Grass` bis Höhe 0, je Feld ein Block in `terrainMaterial` bis `height`; Berge zusätzlich mit 1–2 `FillBall` für unregelmäßige Kuppen (deterministisch aus x,y); Wasser als `Water`-Block über abgesenktem Grund. Vorher nur den Brett-Bereich leeren (`FillBlock` mit `Air`), **nicht** `Terrain:Clear()` auf die ganze Welt.
  - Die bisherigen farbigen Feld-Parts werden zu **unsichtbaren Klickflächen** (`Transparency = 1`, `CanCollide = false`, `CanQuery = true`, Dicke 0,2, Oberkante = Feldhöhe) – Attribute `X/Y` bleiben, damit die Klick-Erkennung in `Main.client.luau` unverändert funktioniert.
  - Dezentes Raster: dünne dunkle Linien (Neon aus, `Transparency 0.75`, `CanQuery=false`) an den Feldkanten auf Feldhöhe, damit Felder lesbar bleiben.
  - Deko: `SurroundingGrass`-Part entfernen (Terrain übernimmt); Waldbäume als 2–3 gestapelte Kugeln/Kegel-Optik, Außenbäume/-felsen beibehalten aber auf Terrainhöhe setzen. Alles Deko `CanQuery=false`.
  - Fertig, wenn: Berge sind erhöht, Wasser ist echtes Roblox-Wasser, Gras/Fels haben Terrain-Texturen; Klicks auf jedes Feld (auch Berg/Wasser-Rand) treffen das richtige Feld; Einheiten stehen sichtbar auf der Oberfläche.

- [x] 5. **Avatar-Figuren (R15)** – Dateien: `src/shared/UnitData.luau`, `src/shared/CharacterBuilder.luau`, `src/server/UnitVisuals.luau`, `src/server/HubBuilder.luau`, Client-Stellen mit `"Root"`
  - **Aussehen-Daten** in `UnitData`: je Klasse `look = { hat = <id>, face = <id oder nil> }`, je Held optional `hairAccessory = <id>`. Startwerte (offizielle Roblox-Katalog-Accessoires):
    - Lord: Krone 3756500192 (Crown of the Golden Serpent); Kavalier: Helm 98450287 (Knights of the Splintered Skies: Helmet); Soldat: 8796225 (Black Knight Helmet); Bogenschütze (beide Teams): Kapuze 102623080 (Brown Riding Hood); Magier: 13121508 (Frumpled Wizard Hat of Old Coots); Kämpfer/Bandit: Bandana 74221074 (Renegade Bandana, Gesichts-Accessoire); Bandenführer: 108829551 (Crimson Studded Viking).
    - Haare (Heldinnen): Mira 1513252656 (Red Action Ponytail), Selina 376527350 (Black Ponytail), Aurelia/Ida 398673196 (Blonde Action Ponytail), Greta 1708329071 (Black Action Ponytail); übrige ohne Haar-Accessoire oder 12819292 (Long Brown Hair) für Leon.
  - **Bauen (nur Server):** In `CharacterBuilder.build` eine `HumanoidDescription` füllen (Accessoires, `BodyColors`: Haut + Torso/Arme in Team- bzw. `Royal`-Farbe) und `Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)` aufrufen. `HumanoidRootPart` verankern (`Anchored = true`), alle Teile `CanCollide = false`, `Massless = true`; `Humanoid.DisplayDistanceType = None`, `HealthDisplayType = AlwaysOff`, `EvaluateStateMachine = false`. `model.PrimaryPart = HumanoidRootPart`; Attribute `TopY`/`HeadY` aus der echten Kopfposition setzen.
  - **Behalten (an R15-Teile hängen):** Waffen (`RightHand`, bei Bogen/Buch `LeftHand`), Seltenheits-Effekte (Schnalle `LowerTorso`, Kragen/Wappen `UpperTorso`, Umhang per Motor6D `CapeJoint` an `UpperTorso`, Waffenglühen, Aura am `HumanoidRootPart`), farbiger Wappenrock über `UpperTorso` in Team-/Royal-Farbe für Lesbarkeit. Kavalier: bestehendes Pferd an `HumanoidRootPart` schweißen, Reiter per Sitz-Pose (Hüften gebeugt) erhöht.
  - **Client-Porträts:** `CreateHumanoidModelFromDescription` geht nur auf dem Server → Server legt beim Start für jeden Helden eine Vorlage in `ReplicatedStorage.HeroTemplates` ab (Name = Helden-ID); `UIKit.heroPortrait` klont diese statt lokal zu bauen.
  - **`"Root"`-Zugriffe umstellen:** überall `model:FindFirstChild("Root")` / `a.Root` → `model.PrimaryPart` (u. a. `UnitAnimator.luau`, `Main.client.luau` `floatText`, `UIKit.portrait`, Hub-NPC-Erkennung in `UnitAnimator.idle`). `rg '"Root"|\.Root\b' src` muss danach nur noch bewusst gewollte Treffer zeigen.
  - **Animation:** `UnitAnimator` Gelenknamen-Zuordnung für R15: `RootJoint`→`Root` (in `LowerTorso`), `Neck`, `RightShoulder`, `LeftShoulder`, `RightHip`, `LeftHip` (Namen bei R15 gleich bis auf Root). Achsen prüfen (R15-C0 sind meist achsparallel → bestehende Winkel funktionieren). Zusätzlich Standard-Roblox-Animationen über `Humanoid.Animator`: Idle `rbxassetid://507766388`, Laufen `rbxassetid://507777826` (öffentliche Roblox-Animationen) – Laufen abspielen solange Attribut `Moving`, sonst Idle; eigene C0-Posen für Angriffe bleiben obendrauf.
  - Thronsaal-NPCs (`HubBuilder.npc`) nutzen denselben Baukasten (Team `Royal`).
  - Fertig, wenn: alle Einheiten und NPCs sind R15-Avatare mit Hut/Haar, Waffe in der Hand, Seltenheits-Effekten; Laufen/Idle animiert; Angriffe, Treffer-Reaktion, Auswahl-Ring, Porträts (Info, Aufstellung, Kaserne, Rekrutierung) funktionieren.

- [x] 6. `scripts/check.ps1` ausführen – fertig, wenn: `OK` / Exit 0
- [x] 7. Spieldatei bauen (`tools/rojo.exe build default.project.json -o TacticsGame.rbxlx`) – fertig, wenn: Build ohne Fehler
- [x] 8. Devlog-Eintrag #12 „Visual-Pass 2" (Teststatus „ungetestet", verwendete Asset-IDs auflisten), „Nächste Schritte" aktualisieren; Branch pushen – fertig, wenn: Eintrag vorhanden, Branch auf GitHub

## Manueller Test in Studio (Nutzer)
- [ ] Keine Kästchen-Symbole mehr; Saal nicht überbelichtet, Schatten sichtbar; Beschwörungskreis-Schild lesbar
- [ ] Musik im Saal/Kampf hörbar, Klick/Treffer/Krit/Verfehlt/Tod/Level-Up/Rekrutierung klingen passend (sonst Alternativ-ID nennen)
- [ ] Schlachtfeld: Berge erhöht, echtes Wasser, Terrain-Texturen; jedes Feld anklickbar; Einheiten stehen auf der Oberfläche, Laufen über Höhen wirkt flüssig
- [ ] Figuren: Avatare mit Kopfbedeckung/Haaren, Waffe in der Hand, Seltenheits-Aura bei ★5; Angriffe/Treffer animiert
- [ ] Porträts in Info-Panel, Aufstellung, Kaserne, Rekrutierung zeigen die Avatare
- [ ] Handy: Bildrate ok
- [ ] Output-Fenster ohne rote Zeilen

## Nicht anfassen
- Spielregeln/Formeln/KI: `Combat.luau`, Bewegungslogik in `Grid.luau` (nur `toWorld`/`tileHeight` ergänzen), `EnemyAI.luau`
- Balancing/Inhalte: `Stages.luau`, `Recruit.luau`, Helden-Werte in `UnitData.luau` (nur Aussehen-Felder ergänzen)
- Speicherformat: `ProfileStore.luau`
- Server-Kampf-Timing (`Config.IMPACT_TIME`, `Config.STRIKE_TIME`) und Befehls-Validierung in `Main.server.luau`

## Offene Fragen
- Falls `CreateHumanoidModelFromDescription` Accessoires nicht lädt (z. B. in Studio ohne veröffentlichten Ort): Figur ohne Accessoires bauen, Warnung loggen, nicht abbrechen – und hier notieren.
- Wenn einzelne Asset-IDs nicht laden: in den Notizen auflisten, nicht durch eigene Suche ersetzen.

## Notizen (Codex)
- Lighting.Technology ist veraltet: aktuelle Entsprechung LightingStyle.Realistic und PrioritizeLightingQuality im HubBuilder verwendet (Roblox-Dokumentation). Alle Saal-Labels nutzen eigene aufrechte Anker.
- Avatar-Bau nutzt die aktuelle Async-Variante CreateHumanoidModelFromDescriptionAsync. Bei Fehlern wird ohne Accessoires erneut aufgebaut; unvollständig geladene Accessoires werden mit ihren vorgegebenen IDs protokolliert. Keine Asset-Ladefehler bestätigt, da Studio-Test aussteht.
- R15 benötigt einen GroundOffset zwischen Root und Fußboden. Platzierung, Laufweg, Saal-NPCs, Bewegungsvorschau, Staub und Auswahlring berücksichtigen ihn. Kamerafokus behält die Gelände-Höhe.
- Porträts klonen die serverseitigen HeroTemplates in einen WorldModel im ViewportFrame. Der verbliebene Name Root bezeichnet nur das R15-Gelenk bzw. den UI-Root.
- Sämtliche Asset-IDs stammen unverändert aus dem Plan. Hörprobe, Accessoires, Animationen, Terrain-Oberflächen/Klicks und Handy-Bildrate sind noch ungetestet.
