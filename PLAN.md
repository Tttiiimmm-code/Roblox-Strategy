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

- [x] 1. **Aufbereiten** – `scripts/cleanup.ps1`
  - Jede GLB mit `-Prop` aufbereiten, Name = Ordnername. Dreieckslimits (WIP): kleine Deko (`grass`, `flowers`, `stones`) ≤ 300, `lantern`, `banner`, `barrels`, `crystal_pedestal` ≤ 1.000, `ruin_column`, `crystal_shrine`, `boulder` ≤ 1.500, `ruin_arch`, `bridge` ≤ 3.000. Textur 512.
  - Kontrollbilder (`_vorne/_seite/_oben`) ansehen: vollständig, aufrecht, keine Bodenplatte/Schattenscheibe (bei allen 12 prüfen; flache Bodeninsel ggf. wie beim Torbogen entfernen), Farben wie Original, **matt**. Ausrichtung mit `-Front` korrigieren.
  - Akzeptanz: 12 `*_clean.fbx`, Bericht je Modell in den Notizen (Dreiecke, Größe).

- [x] 2. **Ein Import für den Nutzer** – neues Blender-Skript + `scripts/studio/thronlande-import.luau`
  - Alle 12 bereinigten Modelle in **eine** Datei `assets/raw/d2/thronlande_pack.fbx` zusammenführen (je Modell ein Objekt, Objektname = Zielname wie `rim_banner_1`, `deco_grass_2` …, Pivot unten Mitte, vorne −Z, nebeneinander mit Abstand).
  - Befehlsleisten-Skript `scripts/studio/thronlande-import.luau` (Muster `umgebung-import.luau`): nimmt das importierte Model aus dem Workspace, macht daraus Ordner `thronlande_pack` mit je einem Model pro Vorlage (Name = Kategorie_Nr, Pivot unten Mitte, verankert, ohne Kollision), damit der Nutzer nur noch **Save to File → `assets/environment/thronlande_pack.rbxm`** machen muss.
  - Anleitung für den Nutzer in `docs/umgebung-assets.md` ergänzen (kurz, ab null erklärt: 3D importieren → FBX wählen → Skript in Befehlsleiste → Save to File).
  - Dann **stoppen**: unter „Offene Fragen“ eintragen „Nutzeraktion: thronlande_pack importieren“, `.handoff/status` = `frage`. Claude führt den Nutzer durch den Import.

- [x] 3. **Kategorien und Größen** – `Config.ENVIRONMENT.categories`, `EnvironmentAssets`
  - Neue `rim_*`-Kategorien mit WIP-Größen (Rand, außerhalb des Bretts): Säule/Schrein/Banner/Laterne ≈ 0,6–1,2 Felder hoch, Torbogen ≈ 1,5 Felder breit, Fässer ≈ 0,6 Felder, Kristallsockel ≈ 0,8 Felder, Felsen (`rock`-Randvariante) wie bisheriger Rand-Fels.
  - `deco_grass`, `deco_flower`, `deco_stone`: neue Modelle als **bevorzugte** Varianten; alte Creator-Store-Varianten nur noch Rückfall, falls neue fehlen.
  - Brücke: Prüfen, welche Kategorie die Brett-Brücken heute nutzen (`bridge`/`archbridge`). Neue Brücke dort einsetzen, **Laufwege, Feldhöhen und Klickbarkeit unverändert** (Figuren stehen auf dem bestehenden Brückenboden; Modell nur Optik, ohne Kollision/Query). Passt die Form nicht ohne Eingriff in Brettlogik, nicht umbauen, sondern unter „Offene Fragen“ notieren.
  - Akzeptanz: Lader findet alle 12 Vorlagen; fehlende Datei → bisherige Optik (kein Fehler).

- [x] 4. **Inselrand füllen** – `LandscapeBuilder.details` (Insel-Zweig), `Config.ISLAND`
  - Rand deterministisch pro `mapKey` mit Gruppen bestücken: z. B. Ruinen-Ecke (Säule + Torbogen + Steine), Lager (Fässer + Laterne), Kristallplatz (Schrein oder Sockel + Gras/Blumen), Banner an 1–2 Rand-Ecken Richtung Kamera nicht verdeckend. Gras/Blumen/Steine locker verteilt; Felsen an der Kante. Mengen als WIP-Werte in `Config.ISLAND` (`rimGroups`, `rimScatter` o. ä.).
  - Regeln: nichts auf dem Brett, nichts über die Kante hinaus, Abstand zu Wasserfällen/Flussmündungen, nichts verdeckt Felder in Normalansicht (hohe Objekte nur an Hinterkante/Seiten). Andere Gebiete (Sumpf/Eis/Vulkan): vorerst dieselben Modelle, Kristallfarbe nicht ändern (Modelle sind Grasland-grün; Gebietsvarianten = spätere Etappe).
  - Teile/Leistung: Meshes zählen nicht ins Insel-Teilebudget (450), aber messen: Anzahl Requisiten, geschätzte Dreiecke, Aufbauzeit.
  - Akzeptanz: Normal- und Übersichtsbild (Grasland, 3 Seeds): Rand wirkt belebt, Brett frei und lesbar.

- [x] 5. **Abschluss** – Tests, Messung, Devlog
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

- **Brückenform passt nicht ohne Eingriff (Codex, 10.10.2026):** Die Brett-Brücken verwenden `archbridge` (`BoardBuilder.buildBridges`). Der bisherige Lader misst den Modellboden per Raycast und setzt daraus die Feld- und Uferhöhen (`Grid.setHeights`); ein direkter Wechsel auf `archbridge_2` würde diese Höhen ändern. In Studio beide tatsächlichen Vorlagen in temporären, anschließend entfernten Models geprüft: neue Längsachse Z vor der Messung auf X gedreht, beide gleichmäßig auf die aktuelle Ein-Feld-Spannweite `(1 + 2 * 0,65) * 8 = 18,4` Studs skaliert, Unterkante auf Y=0. Alte Brücke: Breite **5,178**, Gesamthöhe **4,894** Studs; neue Brücke: Breite **15,128**, Gesamthöhe **9,393** Studs. Neue Optik ragt damit weit in die benachbarten Felder. Boden-Raycasts entlang der Mittellinie bei X = −8 / −4 / 0 / 4 / 8 liefern alt **1,590 / 2,767 / 3,081 / 2,767 / 1,590**, neu **3,208 / 3,165 / 3,077 / 2,805 / 2,560** Studs. Das Höhenprofil unterscheidet sich deutlich (Toleranz `footTolerance = 0,3`); ein vertikaler Versatz allein löst es nicht. Gemäß Schritt 3 keine Brettlogik geändert. **Wie soll Claude die Integration planen: neue Brücke zunächst zurückstellen und D2 ohne Brückentausch fortsetzen, oder eine gezielte geometrische Anpassung der neuen Brücke samt eigener Abnahme vorsehen?** Schritte 3–5 bleiben offen; Arbeit gemäß AGENTS.md gestoppt.
- **Blumenlimit / Formtreue (Codex, 10.10.2026):** `flowers` verliert bei der vorgeschriebenen Aufbereitung mit `-Prop -MaxTris 300` deutlich die Blütenform. Der Farbtreue-Check schlägt fehl (RGB-Abweichung 5,61 / 11,87 / 15,04; Grenze je Kanal 12/255). Vergleichsbilder: `assets/raw/d2/flowers/clean/flowers_vorne_original.png` und `flowers_vorne.png`. Darf das WIP-Dreieckslimit für Blumen erhöht werden, oder soll eine eigene, formschonende Vereinfachung geplant werden? Keine Lockerung der Farbtreue-Prüfung vorgenommen. Schritt 1 ist nicht abgenommen; Arbeit gemäß AGENTS.md gestoppt.
  - **Antwort Claude:** Vergleich angesehen – bei 300 Dreiecken zerfallen die Blüten. Blumen-Limit auf **800** (WIP) anheben; Ziel: Blütenform wie Original erkennbar. Die Farbtreue-Prüfung nicht lockern; liegt sie bei 800 nur knapp über der Grenze und sieht im Kontrollbild richtig aus, Abweichung mit Werten notieren und weitermachen. Den grauen Rand unter dem Erdfleck wie die anderen Bodenscheiben entfernen. Blender-Läufe **nacheinander, nie parallel** (Malloc-/Thread-Fehler kamen von gleichzeitigen Läufen); fehlgeschlagene Modelle (grass, barrels, stones, boulder, banner-Neuaufbereitung) seriell erneut aufbereiten. Notizen bitte in **UTF-8** schreiben (Umlaute kamen wieder als `?` an, von Claude repariert). Danach weiter bis zum geplanten Halt „Nutzeraktion: thronlande_pack importieren“.
- **Nutzeraktion: thronlande_pack importieren (Codex, 10.10.2026):** Schritte 1 und 2 sind abgeschlossen. `assets/raw/d2/thronlande_pack.fbx` in Studio importieren, das importierte Model auswählen, `scripts/studio/thronlande-import.luau` ausführen und den erzeugten Ordner als `assets/environment/thronlande_pack.rbxm` speichern. Anleitung: `docs/umgebung-assets.md`, Abschnitt „Thronlande D2: zwölf eigene Requisiten in einem Import“. Claude führt den Nutzer durch den Import; Fortsetzung mit Schritt 3 erst danach. Studio-Import noch ungetestet.
  - **Antwort Claude (Nutzeraktion erledigt, 10.10.2026):** Nutzer hat `thronlande_pack.fbx` in Studio importiert (alle 12 MeshParts mit TextureID, keine SurfaceAppearance). Claude hat das Import-Model in `thronlande_import` umbenannt (Namenskonflikt mit dem Paketordner) und das Importskript ausgeführt; Nutzer hat den Ordner als **`assets/environment/thronlande_pack.rbxm`** (136 KB) gespeichert, Workspace danach leer. Weiter mit Schritt 3–5. Hinweise: Die Vorlagen sind ca. 1 Stud groß (Spiel skaliert); `archbridge_2` hat die Längsachse Z (siehe Notiz). Studio-Tests nur, wenn kein Blender-Lauf parallel läuft (GPU-Treiberabstürze beim gleichzeitigen Betrieb); Studio-Fenster nicht minimieren. Notizen in UTF-8. Schritt 1–2-Änderungen (Skripte, cleanup.ps1, Doku) bitte mit committen.
  - **Antwort Claude (Brücke):** Gezielte Anpassung, mit klarem Rückfall:
    1. `archbridge_2` beim Platzieren auf Längsachse X drehen und **nicht gleichmäßig** skalieren: Länge = heutige Spannweite (18,4 Studs), **Breite ≈ alte Brückenbreite** (5,2 Studs, höchstens +15 %), Höhe so, dass die **Deckoberkante an beiden Enden höchstens `footTolerance` (0,3) von der Uferhöhe** abweicht. Die neue Brücke ist flach – ein flaches, gemessenes Höhenprofil auf den Brückenfeldern ist in Ordnung (die Vorgabe „Feldhöhen unverändert“ gilt nur für Ufer/Nachbarfelder, nicht für die Brückenfelder selbst), solange der Übergang Ufer → Brücke ≤ `footTolerance` bleibt, Figuren sichtbar auf dem Deck stehen und Klicks/Wege gleich bleiben.
    2. Nichts ragt in Nachbarfelder (Breite innerhalb des Brückenfelds).
    3. Neue Regression: Profil/Übergänge der Brückenfelder, Nachbarfelder unverändert, Klickfelder/Figurenhöhen.
    4. **Rückfall:** Sieht die gestauchte Brücke im Studio-Bild verzerrt aus oder lässt sich die Toleranz nicht einhalten, bei `archbridge_1` bleiben, Befund + Bild in den Notizen festhalten und D2 ohne Brückentausch fertigstellen (kein erneuter Halt deswegen).
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**.)

## Notizen (Codex)

### Fortsetzung 10.10.2026 – Schritte 3–5 abgeschlossen

- Claudes Brückenfreigabe umgesetzt. Zwölf Vorlagen vom echten Studio-Import erkannt. Sieben neue Randkategorien und WIP-Größen zentral in Config; Gras/Blumen/Steine bevorzugen eigene Varianten, fehlendes Paket erhält die bisherigen Varianten/Part-Optik. `rock_50` nur mit ausdrücklicher Rand-Auswahl, keine Beimischung in Brettfelsen. Credits/Quelle in `assets/environment/README.md` ergänzt.
- Neue Brücke ausschließlich aus einem achsenparallelen Mesh: Vorlage längs Z beim Platzieren auf X gedreht; Spannweite wie zuvor, Breite 5,2 Studs, Gesamthöhe 4,8 Studs. Alte Brücke zunächst als Messreferenz: Uferhöhen unverändert, neue Deckhöhe auf Ufermitten und tatsächliche Feldübergänge abgestimmt. Nur Brückenfelder erhalten das neue gemessene Profil. Fehlende neue Vorlage, fehlender Decktreffer oder Abweichung über 0,3 Studs → alte Brücke; fehlende alte Referenz → bisherige Part-Brücke. Temporäre Query-Freigabe nur synchron zur Messung; anschließend ohne Collision/Query/Touch.
- Echte Studio-Raycasts: ein/zwei Brückenfelder, beide Achsen. Breite **5,200** Studs; größter Deck-/Uferübergang **0,176** Studs (Grenze 0,3), Figurenposition aus `Grid.toWorld` gegenüber Deck maximal **0,00000012** Studs, Uferänderung **0**. Brückenwege und Feldklickflächen unverändert. Neue Brücken in Seed-1/2-Bildern angesehen; tatsächliche Figurenbewegung über Brücken und Touchklicks weiterhin Nutzerprüfung.
- Deterministische Ruinen-/Lager-/Kristall-/Bannergruppen an Hinterkante/Seiten; 36 lose Gras-/Blumen-/Stein-/Felsplatzierungen. Begrenzte Wiederholungen bei blockierten Gruppenplätzen, danach freier Abschnitt derselben Kante. Ganze Modell-AABB außerhalb Brett/Hub, alle vier Ecken mit Kantenreserve auf Insel, Fluss-/Wasserfallkorridore mit Abstand; niedrige Objekte vorne. Modellüberlappungen mit vorhandenen Landschaftsmodellen vermieden. Kristallfarben nicht geändert. Eigene Meshes zählen nicht ins 450er Inselteilebudget.
- Messung, echte BoardBuilder-Aufbauten (Grasland, Tiefe 1, axe, Teamgröße 4): Seed 1 **48 / 37.553 / 40,85 ms / 249,64 ms**, Seed 2 **49 / 39.052 / 27,42 ms / 180,08 ms**, Seed 3 **49 / 39.052 / 24,03 ms / 201,61 ms** (Requisiten / geschätzte Requisitendreiecke / Requisitenaufbau / gesamter Brettaufbau). Einzelmessungen, kein Handy-/GPU-Benchmark. Alle sieben Randkategorien vorhanden. Dreiecke aus Aufbereitungsberichten; LOD unbekannt.
- Studio-Bilder `D2_final_seed1/2/3_normal/uebersicht`: tatsächliche Play-Geometrie mit Spielneigung 0,75, regulärem Startzoom/Config-Übersichtszoom; UI nur für Diagnose ausgeblendet, ohne Figuren. Screenshots im MCP angesehen, keine lokalen Bilddateien geliefert. Rand bestückt, Brett frei; kleine Streudeko im Übersichtszoom kaum erkennbar. Zusätzlich bestehendes Level über reguläres `ResumeLevel` gestartet, echte Figuren/UI/Standardkamera angesehen: 48 Randrequisiten, Output Brett 242 ms/Figuren 12 ms; dieses Level hat keine Brücke. Nur bekannte Lighting-/Chibi-Hinweise. Abschließend Studio **Edit** bestätigt; sämtliche Diagnoseobjekte/Kameraänderungen durch Stop entfernt.
- Neue `tests/thronlande.test.luau`: zwölf importvermessene Vorlagen, Präferenz/fehlendes Paket, Randfelsen nur am Rand, vier Gebiete × drei Seeds mit Wiederholungen, negative Brett-/Kanten-/Wasser-/Vordersichtproben; Brückenstub mit Erfolg, fehlendem Treffer und ungeeignetem Gefälle, Ufer-/Nachbarhöhen, Wege/Klickbarkeit. Echte Mesh-Raycasts zusätzlich wie oben in Studio; Stub ersetzt keine Spielprüfung.
- **Prüfungen:** check.ps1 **OK: 39 Dateien, Exit 0**; test-run.ps1 **OK** (34.458 Lauf-/Boss-/Lager-, 752.975 Inselprüfungen plus D2, Maximum 450/450); test-levelgen.ps1 **OK** (19.000 Level-, 5.000 Options-, 96 Landschafts-, 2.400 Boss-/Minibossprüfungen); test-tutorial.ps1 **OK: 168**; test-run-ui.ps1 **OK: 280**; Rojo-Build **TacticsGame.rbxlx erfolgreich**, git diff --check ohne Fehler. Nutzer-/Handytests und unabhängiges Claude-Review offen.
- Devlog #45 und nächste Schritte ergänzt. Frühere Schritte 1–2 einschließlich Importpaket werden mit committet; `docs/referenz/` bleibt unverfolgt/unverändert. Keine Credits verwendet. Sandbox-Startfehler weiterhin vorhanden, Projektbefehle gemäß Dauerregel automatisch geprüft außerhalb ausgeführt. Abschluss auf `feature/thronlande-d2`, Übergabesignal nach Commit/Push: `fertig`.

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

### Fortsetzung 10.10.2026 – Schritte 1 und 2 abgeschlossen, Halt für Nutzerimport

- Blumenfreigabe umgesetzt: WIP-Limit 800, alle Blender-Läufe ausschließlich nacheinander. Neue Quellen behalten die Original-GLBs bei. Beim Blumenmodell 107 vermessene graue Randflächen entfernt und den noch grau texturierten unteren Saum an der ermittelten Oberkante abgeschnitten; brauner Erdfleck bleibt erhalten. Banner, Schrein, Laterne und Gras wie zuvor ohne zusätzliche Bodenscheiben; alle zwölf Modelle in Vorder-, Seiten- und Draufsicht angesehen.
- Technische Korrekturen innerhalb der Aufbereitung: GLB importiert im Modus `QUATERNION`; Euler-Drehungen waren nachweislich wirkungslos. Vor `-Front` nun ausdrücklich `XYZ` setzen. Banner, Gras, Fässer, Steine, Torbogen und Kristallsockel mit `-Front +X` neu aufbereitet; Blumen mit `-Front -Y`. Die unveränderten übrigen Exporte sind bereits in der gewünschten Frontansicht ausgerichtet. Vorherige Frontangaben dieses Plans sind dadurch überholt.
- Blumen-Decimate erzeugte zwei exakt deckungsgleiche Restflächen, die beide Exportformate beim Re-Import entfernten. Diese Restflächen im Prop-Modus bereits vor UV-Aufbereitung/Export entfernen und im Bericht zählen; die strenge Gleichheit der Export-Dreieckszahlen bleibt bestehen. Keine Lockerung des Farbchecks. Farbvergleich arbeitet jetzt nach Maskierung mit `int16` statt großen vollständigen Float-Arrays; dieselbe RGB-Differenz und Grenze.
- Speicherfehler traten trotz serieller Ausführung erneut auf (`Malloc returns null`, im Vorschau-Rendering und Texturbacken). Option `scripts/cleanup.ps1 -Threads 1` ergänzt und für die erfolgreichen Wiederholungen genutzt; ohne Option bleibt die automatische Threadwahl. Kein `atio6axx.dll`-Fehler beobachtet, kein Wechsel des Vorschau-Renderers nötig. Nur projektlokale Logs gelesen. Sandbox-Startfehler weiter vorhanden; Projektbefehle gemäß Dauerregel automatisch geprüft außerhalb der Sandbox ausgeführt.
- Alle Einzelmodelle: 512×512, matt (Roughness 1, Metallic 0), ohne Cel; vollständige eingebettete PNGs und Dreieckszahlen im tatsächlichen FBX-Re-Import geprüft. Sämtliche Farbchecks innerhalb 12/255 je Kanal. Blumen aktuell **RGB 2,17 / 2,45 / 2,85**, **798 Dreiecke**; fünf Blüten in Kontrollbildern erkennbar. Die Blumenfrage ist damit erledigt. Bei Banner/Fässern/Blumen bleiben vereinfachungsbedingte Texturabweichungen sichtbar; Kontrollbilder für Claudes unabhängiges Review vorhanden.

| Modell | Vorlage im Paket | Dreiecke | FBX-Größe (Bytes) | Größe Blender X × Y × Z |
|---|---|---:|---:|---|
| ruin_column | `rim_ruin_column_1` | 1500 | 312332 | 0,666 × 0,668 × 1,000 |
| banner | `rim_banner_1` | 998 | 321276 | 0,511 × 0,091 × 1,000 |
| crystal_shrine | `rim_crystal_shrine_1` | 1500 | 320380 | 0,593 × 0,594 × 1,000 |
| ruin_arch | `rim_ruin_arch_1` | 2999 | 435660 | 0,936 × 0,406 × 0,522 |
| lantern | `rim_lantern_1` | 998 | 297068 | 0,530 × 0,326 × 1,000 |
| crystal_pedestal | `rim_crystal_pedestal_1` | 999 | 298764 | 0,747 × 0,642 × 1,000 |
| bridge | `archbridge_2` | 3000 | 335916 | 0,822 × 1,000 × 0,510 |
| grass | `deco_grass_2` | 299 | 220652 | 1,000 × 0,216 × 0,705 |
| flowers | `deco_flower_4` | 798 | 329788 | 0,977 × 0,925 × 0,657 |
| barrels | `rim_barrels_1` | 1000 | 277564 | 0,985 × 0,925 × 0,675 |
| stones | `deco_stone_1` | 300 | 165308 | 0,999 × 0,916 × 0,388 |
| boulder | `rock_50` | 1499 | 342732 | 0,981 × 1,000 × 0,871 |

- `scripts/cleanup/thronlande_pack.py` ausgeführt: **12 getrennte Mesh-Objekte**, Namen wie Tabelle, in einem 4×3-Raster mit Abstand. Ergebnis **`assets/raw/d2/thronlande_pack.fbx`**, **3506764 Bytes**, **15890 Dreiecke insgesamt**. Paket-Re-Import: alle Namen/Objektzahlen, Einzel-Limits, Geometriegrößen, Pivots unten Mitte, eingebettete 512-Pixel-Texturen und matte Materialien erfolgreich. Bericht `assets/raw/d2/thronlande_pack_bericht.json`; Rohdateien/Paket bleiben wie geplant außerhalb des Git.
- `scripts/studio/thronlande-import.luau` fertig: Edit-Modus und genau ein ausgewähltes Workspace-Model erforderlich; alle zwölf MeshPart-Namen vor Änderungen prüfen. Danach Ordner mit zwölf Models, verankert, ohne Collision/Query/Touch, Pivot unten Mitte. Quelle zur Sichtprüfung erhalten; Fehler beim Aufbau entfernen nur den neuen Ordner. Vorlagennamen zusätzlich automatisch gegen Paketbericht abgeglichen. Kurze Importanleitung ab null in `docs/umgebung-assets.md` ergänzt.
- Brücke im FBX-Paket mit Eingang nach −Z und Längsachse Z. Bestehender `archbridge`-Lader bemisst die Länge über X; in Schritt 3 nach Nutzerimport prüfen und nur die Optik passend ausrichten. Keine Brettlogik geändert.
- **Prüfungen:** `scripts/check.ps1` **OK: 39 Dateien, Exit 0**. Studio-Importskript separat kompiliert/auf unbekannte Nicht-Roblox-Globals geprüft, OK. Python- und PowerShell-Syntax geprüft, OK. Alle zwölf Einzelberichte gegen Paket-Re-Import und Studio-Namen geprüft, OK. Kontrollbilder aller zwölf Modelle angesehen. **Studio-Import, Spiel- und Handytests ungetestet**; unabhängiges Review steht bei Claude aus.
- **Geplanter Halt nach Schritt 2:** Nutzeraktion unter „Offene Fragen“ eingetragen. Schritte 3–5 bleiben offen; Kategorien, Randplatzierung und Abschlussprüfungen folgen nach dem Import. Kein abgeschlossener Gesamtplan, daher noch kein Devlog #45, Commit oder Push. `docs/referenz/` unberührt. Übergabesignal `.handoff/status` = `frage`.

### Fortsetzung 10.10.2026 – Halt in Schritt 3 wegen Brückenform

- Nutzerimport und Freigabe von Schritt 1–2 gelesen; `assets/environment/thronlande_pack.rbxm` vorhanden. Branch weiterhin `feature/thronlande-d2`. Bisherige Änderungen für Schritt 1–2 und `docs/referenz/` unverändert erhalten.
- Kategorien, Randplatzierung und Brückenpfad gezielt geprüft. Brückenvergleich mit den tatsächlichen Studio-Vorlagen durchgeführt (keine Blender-Läufe). Ausschließlich temporäre Klone für die Diagnose verwendet und wieder entfernt; Vorlagen, Spielskripte und Brettlogik unverändert. Studio weiterhin im Edit-Modus.
- Eine erste direkte Skalierung der importierten Models war wegen vorhandener Model-Skala/Pivotausrichtung nicht mit dem Lader vergleichbar und wurde verworfen. Die oben dokumentierte abschließende Messung verwendet frische Model-Hüllen mit Weltpivot in Identitätsausrichtung, die originale Geometrie, korrekte X-Ausrichtung und identische Spannweite.
- Brückenform und Bodenprofil erfüllen die Vorgabe „Feldhöhen unverändert, Modell nur Optik“ beim einfachen Austausch nicht. Konkreter Befund und Planungsfrage unter „Offene Fragen“. Keine eigenständige Designentscheidung und keine Änderung der Brettlogik vorgenommen.
- **Prüfung:** `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` **OK: 39 Dateien, Exit 0**. Keine Spiel-/Handytests oder D2-Abnahmebilder; keine Änderungen an Spielcode. Gesamtplan nicht abgeschlossen, deshalb noch kein Devlog #45, Commit oder Push. Weitere Abschlussprüfungen folgen nach Klärung und Umsetzung.
- Sandbox weiterhin mit `helper_unknown_error: setup refresh had errors` defekt; nicht-destruktive Projektbefehle gemäß Dauerregel über automatische Prüfung ausgeführt. Übergabesignal `.handoff/status` = `frage`.
