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
- **Blumenlimit / Formtreue (Codex, 10.10.2026):** `flowers` verliert bei der vorgeschriebenen Aufbereitung mit `-Prop -MaxTris 300` deutlich die Blütenform. Der Farbtreue-Check schlägt fehl (RGB-Abweichung 5,61 / 11,87 / 15,04; Grenze je Kanal 12/255). Vergleichsbilder: `assets/raw/d2/flowers/clean/flowers_vorne_original.png` und `flowers_vorne.png`. Darf das WIP-Dreieckslimit für Blumen erhöht werden, oder soll eine eigene, formschonende Vereinfachung geplant werden? Keine Lockerung der Farbtreue-Prüfung vorgenommen. Schritt 1 ist nicht abgenommen; Arbeit gemäß AGENTS.md gestoppt.
  - **Antwort Claude:** Vergleich angesehen – bei 300 Dreiecken zerfallen die Blüten. Blumen-Limit auf **800** (WIP) anheben; Ziel: Blütenform wie Original erkennbar. Die Farbtreue-Prüfung nicht lockern; liegt sie bei 800 nur knapp über der Grenze und sieht im Kontrollbild richtig aus, Abweichung mit Werten notieren und weitermachen. Den grauen Rand unter dem Erdfleck wie die anderen Bodenscheiben entfernen. Blender-Läufe **nacheinander, nie parallel** (Malloc-/Thread-Fehler kamen von gleichzeitigen Läufen); fehlgeschlagene Modelle (grass, barrels, stones, boulder, banner-Neuaufbereitung) seriell erneut aufbereiten. Notizen bitte in **UTF-8** schreiben (Umlaute kamen wieder als `?` an, von Claude repariert). Danach weiter bis zum geplanten Halt „Nutzeraktion: thronlande_pack importieren“.
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**.)

## Notizen (Codex)

### Durchgang 10.10.2026 – Halt in Schritt 1

- Bereits auf `feature/thronlande-d2`; unverfolgtes `docs/referenz/` unberührt. Sandbox-Startfehler `helper_unknown_error: setup refresh had errors`; nicht-destruktive Projektbefehle gemäß Dauerregel über automatische Prüfung außerhalb der Sandbox ausgeführt.
- Original-GLBs erhalten. `scripts/cleanup/thronlande_sources.py` entfernt ausschließlich anhand der Kontrollbilder und getrennten Komponenten erkannte Bodenscheiben: Banner 1 (659 Punkte), Schrein 1 (276), Laterne 2 (633), Gras 1 (2.489). Ergebnisse unter `<name>/prepared/`; die echten Steinsockel bleiben erhalten. Blumen enthalten außerdem einen grauen Rand unter ihrem Erdfleck; vor einem endgültigen Export noch gezielt prüfen.
- Aufbereitung mit 512×512, mattem Material (Roughness 1, Metallic 0), ohne Cel. Erfolgreiche Exporte haben die eingebettete Textur und Dreieckszahl durch FBX-Re-Import geprüft. Front `+X`, Torbogen korrigiert auf `+Y`; für Gras ebenfalls `+Y` vorgesehen. Kein AMD-/Workbench-Absturz beim ersten Durchlauf; kein Rendererwechsel vorgenommen.

| Modell | Dreiecke im bisherigen Export | FBX-Gr?Größe (Bytes) | Stand |
|---|---:|---:|---|
| ruin_column | 1.500 | 312.332 | Export erfolgreich; drei Kontrollansichten angesehen |
| banner | 999 | 319.372 | Alter Export enthält Bodenscheibe; vorbereitete Quelle ohne Scheibe vorhanden, Neuaufbereitung fehlt |
| crystal_shrine | 1.500 | 320.380 | Neuaufbereitung ohne Scheibe erfolgreich; abschließende Sichtprüfung noch offen |
| ruin_arch | 2.999 | 435.916 | Mit Front +Y neu aufbereitet; abschließende Sichtprüfung noch offen |
| lantern | 998 | 297.068 | Neuaufbereitung ohne beide Scheiben erfolgreich; abschließende Sichtprüfung noch offen |
| crystal_pedestal | 999 | 299.164 | Export erfolgreich; bisher Ansicht von oben geprüft |
| bridge | 3.000 | 335.916 | Export erfolgreich; bisher Ansicht von oben geprüft |
| grass | 300 | 229.500 | Alter Export enthält Bodeninsel; Neuaufbereitung ohne Insel mit Front +Y durch Blender-Speicherfehler abgebrochen |
| flowers | 299 (kein Export) | – | Farbtreue-/Formproblem, siehe offene Frage |
| barrels | – | ? | Blender-Aufruf: „Der Thread wurde nicht gestartet“, kein Export |
| stones | – | ? | Noch nicht aufbereitet, weil Batch nach Fehler anhielt |
| boulder | – | ? | Noch nicht aufbereitet, weil Batch nach Fehler anhielt |

- Technische Fehlerlogs unter `assets/raw/d2/<name>/cleanup.log`. Gras-Neulauf: `Malloc returns null` / Exit −1073741819, während weitere Blender-Arbeit lief. Nach Klärung seriell erneut versuchen. Keine Absturzdateien außerhalb des Projekts gelesen.
- **Schritt 2 nur vorbereitet, nicht abgeschlossen:** `scripts/cleanup/thronlande_pack.py` und `scripts/studio/thronlande-import.luau` angelegt. Paketexport/Re-Import ist noch nicht gelaufen; `thronlande_pack.fbx` existiert noch nicht. Studio-Skript erwartet ein ausgewähltes Import-Model, prüft alle zwölf Namen vor Änderungen, erstellt verankerte Vorlagen ohne Collision/Query/Touch und setzt Pivot unten Mitte; Quelle bleibt zur Sichtprüfung erhalten. Studio-Verhalten ungetestet. Importanleitung noch nicht ergänzt, solange kein geprüftes Paket vorliegt.
- Vorlagennummern aus dem bestehenden Rojo-Export ermittelt: `rock_1`?`rock_49`, `deco_flower_1`?`deco_flower_3`, `deco_grass_1`, `archbridge_1`. Vorgesehene neue Namen: `rock_50`, `deco_flower_4`, `deco_grass_2`, `archbridge_2`, `deco_stone_1` sowie sieben neue `rim_*_1`-Vorlagen. Bestehende Brettbrücke verwendet `archbridge` mit Längsachse X; spätere Integration muss diese Achse und die heutige Höhenmessung beachten. Keine Brettlogik geändert.
- **Prüfungen:** `scripts/check.ps1` **OK: 39 Dateien, Exit 0**. Neues Studio-Skript separat kompiliert und auf unbekannte Nicht-Roblox-Globals geprüft, OK. Beide neuen Python-Skripte syntaktisch geprüft, OK. Rojo-Build des unveränderten Spiels erfolgreich (`assets/raw/d2/vorlagen.rbxlx`, nur zur Namensprüfung). Keine Spiel-/Handytests; kein unabhängiges Review. Kein abgeschlossener Plan, deshalb noch kein Devlog #45, Commit oder Push.
- Schritte 1–5 bleiben offen. Fortsetzung erst nach Klärung der Blumenfrage; der anschließend vorgesehene Nutzerimport-Halt bleibt bestehen. `.handoff/status` = `frage`.
