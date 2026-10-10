# PLAN: Thronlande D2 – eigene Requisiten (12 Modelle)

Ziel: Der Inselrand wirkt leer und die Umgebung mischt Creator-Store-Modelle verschiedener Stile. D2 bringt **12 eigene, vom Nutzer freigegebene Requisiten** (3D AI Studio, Modell P2) ins Spiel: einheitlicher kantiger Low-Poly-Stil, lila-graues Gestein, warmes Holz, Gold, grüne Kristalle. Der Rand der Insel wird damit gefüllt; Gras, Blumen, Steine und Brücke auf dem Brett bekommen den neuen Stil.
Branch: neu `feature/thronlande-d2` von `feature/thronlande`.
Der gemalte Himmel je Gebiet × Tageszeit ist **nicht** Teil von D2 (eigene Etappe D3).

**Rohdateien (von Claude heruntergeladen, nicht im Git, `assets/raw/` ist ignoriert):** `assets/raw/d2/<name>/<name>.glb`

| Nr | Name (Ordner) | Inhalt | Kategorie im Spiel | Einsatz |
|---|---|---|---|---|
| 1 | `ruin_column` | Säulenruine mit Gras, Goldring | `rim_ruin_column` (neu) | Inselrand |
| 2 | `banner` | blaues Königsbanner mit Goldkrone | `rim_banner` (neu) | Inselrand |
| 3 | `crystal_shrine` | Steinschrein mit grünem Kristall | `rim_crystal_shrine` (neu) | Inselrand |
| 4 | `ruin_arch` | Torbogen-Ruine (Schattenscheibe schon entfernt) | `rim_ruin_arch` (neu) | Inselrand |
| 5 | `lantern` | Laternenpfahl mit Kristalllicht | `rim_lantern` (neu) | Inselrand |
| 6 | `crystal_pedestal` | Kristallsockel (3 Kristalle, Goldband) | `rim_crystal_pedestal` (neu) | Inselrand |
| 7 | `bridge` | Holzbrücke, Goldkappen, Seilgeländer | bestehende Brückenkategorie (`bridge`/`archbridge`, siehe Schritt 3) | Brett-Brücken |
| 8 | `grass` | drei Grasbüschel, ohne Erde | `deco_grass` | Brett + Rand |
| 9 | `flowers` | Blumen mit flachem Erdfleck | `deco_flower` | Brett + Rand |
| 10 | `barrels` | zwei Fässer + Kiste | `rim_barrels` (neu) | Inselrand |
| 11 | `stones` | Steingruppe, ohne Erde | `deco_stone` | Brett + Rand |
| 12 | `boulder` | großer Felsen mit Moos und Erde | `rock` (Rand-Variante) | Inselrand |

**Bestehende Kette (bitte genau so nutzen):** `docs/umgebung-assets.md` („Ein erstes Asset einbinden“), `scripts/cleanup.ps1` (`-Prop`, `-MaxTris`, `-Front`), `scripts/studio/umgebung-import.luau` (Paket-Ordner), `assets/environment/README.md` (Lader: `ServerStorage.EnvironmentModels`, Namensregel `<kategorie>_<nr>`, Pivot unten Mitte, vorne −Z, keine Bodenplatte), `src/server/EnvironmentAssets.luau` (`place`, `variants`), `Config.ENVIRONMENT.categories`, Inselrand-Deko in `LandscapeBuilder.details` (Insel-Zweig, `propCategories`).

**Hinweise zur Maschine:** AMD-Grafiktreiber (`atio6axx.dll`) stürzt bei GPU-Rendering in Blender ab. Stürzt `cleanup.ps1` in Blender ab (Vorschaubilder mit `BLENDER_WORKBENCH`), Vorschau-Rendering auf **Cycles CPU** umstellen (nur Vorschau, keine Änderung der Exportlogik) und notieren. Studio-Fenster nicht minimieren lassen (schwarze Bilder = minimiert). **Keine Credits** in 3D AI Studio ausgeben.

## Schritte

- [ ] 1. **Aufbereiten** – `scripts/cleanup.ps1`
  - Jede GLB mit `-Prop` aufbereiten, Name = Ordnername. Dreieckslimits (WIP): kleine Deko (`grass`, `flowers`, `stones`) ≤ 300, `lantern`, `banner`, `barrels`, `crystal_pedestal` ≤ 1.000, `ruin_column`, `crystal_shrine`, `boulder` ≤ 1.500, `ruin_arch`, `bridge` ≤ 3.000. Textur 512.
  - Kontrollbilder (`_vorne/_seite/_oben`) ansehen: vollständig, aufrecht, keine Bodenplatte/Schattenscheibe (bei allen 12 prüfen; flache Bodeninsel ggf. wie beim Torbogen entfernen), Farben wie Original, **matt**. Ausrichtung mit `-Front` korrigieren.
  - Akzeptanz: 12 `*_clean.fbx`, Bericht je Modell in den Notizen (Dreiecke, Größe).

- [ ] 2. **Ein Import für den Nutzer** – neues Blender-Skript + `scripts/studio/thronlande-import.luau`
  - Alle 12 bereinigten Modelle in **eine** Datei `assets/raw/d2/thronlande_pack.fbx` zusammenführen (je Modell ein Objekt, Objektname = Zielname wie `rim_banner_1`, `deco_grass_2` …, Pivot unten Mitte, vorne −Z, nebeneinander mit Abstand).
  - Befehlsleisten-Skript `scripts/studio/thronlande-import.luau` (Muster `umgebung-import.luau`): nimmt das importierte Model aus dem Workspace, macht daraus Ordner `thronlande_pack` mit je einem Model pro Vorlage (Name = Kategorie_Nr, Pivot unten Mitte, verankert, ohne Kollision), damit der Nutzer nur noch **Save to File → `assets/environment/thronlande_pack.rbxm`** machen muss.
  - Anleitung für den Nutzer in `docs/umgebung-assets.md` ergänzen (kurz, ab null erklärt: 3D importieren → FBX wählen → Skript in Befehlsleiste → Save to File).
  - Dann **stoppen**: unter „Offene Fragen“ eintragen „Nutzeraktion: thronlande_pack importieren“, `.handoff/status` = `frage`. Claude führt den Nutzer durch den Import.

- [ ] 3. **Kategorien und Größen** – `Config.ENVIRONMENT.categories`, `EnvironmentAssets`
  - Neue `rim_*`-Kategorien mit WIP-Größen (Rand, außerhalb des Bretts): Säule/Schrein/Banner/Laterne ≈ 0,6–1,2 Felder hoch, Torbogen ≈ 1,5 Felder breit, Fässer ≈ 0,6 Felder, Kristallsockel ≈ 0,8 Felder, Felsen (`rock`-Randvariante) wie bisheriger Rand-Fels.
  - `deco_grass`, `deco_flower`, `deco_stone`: neue Modelle als **bevorzugte** Varianten; alte Creator-Store-Varianten nur noch Rückfall, falls neue fehlen.
  - Brücke: Prüfen, welche Kategorie die Brett-Brücken heute nutzen (`bridge`/`archbridge`). Neue Brücke dort einsetzen, **Laufwege, Feldhöhen und Klickbarkeit unverändert** (Figuren stehen auf dem bestehenden Brückenboden; Modell nur Optik, ohne Kollision/Query). Passt die Form nicht ohne Eingriff in Brettlogik, nicht umbauen, sondern unter „Offene Fragen“ notieren.
  - Akzeptanz: Lader findet alle 12 Vorlagen; fehlende Datei → bisherige Optik (kein Fehler).

- [ ] 4. **Inselrand füllen** – `LandscapeBuilder.details` (Insel-Zweig), `Config.ISLAND`
  - Rand deterministisch pro `mapKey` mit Gruppen bestücken: z. B. Ruinen-Ecke (Säule + Torbogen + Steine), Lager (Fässer + Laterne), Kristallplatz (Schrein oder Sockel + Gras/Blumen), Banner an 1–2 Rand-Ecken Richtung Kamera nicht verdeckend. Gras/Blumen/Steine locker verteilt; Felsen an der Kante. Mengen als WIP-Werte in `Config.ISLAND` (`rimGroups`, `rimScatter` o. ä.).
  - Regeln: nichts auf dem Brett, nichts über die Kante hinaus, Abstand zu Wasserfällen/Flussmündungen, nichts verdeckt Felder in Normalansicht (hohe Objekte nur an Hinterkante/Seiten). Andere Gebiete (Sumpf/Eis/Vulkan): vorerst dieselben Modelle, Kristallfarbe nicht ändern (Modelle sind Grasland-grün; Gebietsvarianten = spätere Etappe).
  - Teile/Leistung: Meshes zählen nicht ins Insel-Teilebudget (450), aber messen: Anzahl Requisiten, geschätzte Dreiecke, Aufbauzeit.
  - Akzeptanz: Normal- und Übersichtsbild (Grasland, 3 Seeds): Rand wirkt belebt, Brett frei und lesbar.

- [ ] 5. **Abschluss** – Tests, Messung, Devlog
  - Tests: Lader/Kategorien (alle 12, Rückfall bei fehlenden), Rand-Platzierung (auf Insel, nicht auf Brett, Abstand Kante/Wasser, Determinismus), Brückenfelder unverändert begehbar/klickbar. `scripts/check.ps1`, `test-run.ps1`, `test-levelgen.ps1`, `test-tutorial.ps1`, `test-run-ui.ps1` OK; Rojo-Build.
  - Credits-Hinweis: eigene Modelle in `assets/environment/README.md` (Quelle 3D AI Studio, vom Nutzer erstellt).
  - Devlog **#45 „Thronlande D2 – eigene Requisiten“**, „Nächste Schritte“ (D3: gemalter Himmel je Gebiet × Tageszeit, zufällig pro Level; Gebietsvarianten der Requisiten). Committen, `git push -u origin feature/thronlande-d2` (bei Ablehnung notieren, trotzdem `fertig`). Studio im Edit-Modus, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Inselrand mit Ruinen, Banner, Laternen, Fässern, Kristallen, Gras, Blumen, Steinen belebt; Stil einheitlich und matt
- [ ] Neue Brücke sieht gut aus, Figuren laufen wie vorher darüber, Klicks funktionieren
- [ ] Brett gut lesbar, nichts verdeckt Felder
- [ ] Handy flüssig, Aufbauzeit okay

## Nicht anfassen
- Spielregeln, Generator, Felder/Wasser/Klippen-Logik des Bretts, UI, Hub, Lighting-Effekte des Nutzers (ColorGrading/Bloom), `docs/referenz/`, 3D AI Studio (keine Credits), Figuren

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**.)

## Notizen (Codex)
