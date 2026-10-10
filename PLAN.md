# PLAN: Thronlande D2b – Inselrand schmaler und lebendig

Ziel: D2 (Devlog #45) bindet die 12 eigenen Requisiten technisch korrekt ein, optisch wirkt der Rand aber weiter leer. Claude-Review in Studio (10.10.2026, Grasland Level 3, normale Spielkamera):
- **Streu-Deko winzig:** `deco_grass_2`/`deco_flower_4`/`deco_stone_1` am Rand gemessen **0,3–0,7 Studs hoch** (Feld = 8 Studs) – obwohl `ISLAND.rimScatter.height = 0.28` Felder (≈ 2,2 Studs) vorsieht. Die Randgröße wird offenbar von den kleinen Brett-Grenzen der `deco_*`-Kategorien (`Config.ENVIRONMENT`) überschrieben → **Fehler**, beheben.
- **Vorderer Rand komplett leer** (größte sichtbare Fläche), weil hohe Objekte nur hinten/seitlich stehen dürfen und vorne nichts ersatzweise steht.
- Von jeder großen Requisite steht nur **eine**; Gruppen wirken verloren auf der großen Fläche.
Branch: `feature/thronlande-d2` (weiterarbeiten, schon gepusht).

**Nutzerentscheidungen (10.10.2026):**
- **Rand schmaler: 2–3 Felder** (statt 3,4–4).
- **Dicht und lebendig:** viel Gras, Blumen und Steine in **sichtbarer Größe**, **2–3 Gruppen pro Seite**, **vorne flache Deko** (Gras, Blumen, Steine, Fässer, niedrige Felsen), hohe Objekte (Säule, Torbogen, Banner, Laterne, Schrein, Sockel, Bäume) weiter hinten/seitlich.

**Bestehender Code:** `src/shared/Config.luau` (`Config.ISLAND`: `rimTiles`, `rimGroups`, `rimScatter`, `rimPlacement`, `overviewPadding`; `Config.ENVIRONMENT.categories`), `src/server/LandscapeBuilder.luau` (`outline`, `details` Insel-Zweig, Randgruppen/Streuplätze), `src/server/EnvironmentAssets.luau` (`place` – Größenbegrenzung je Kategorie), `src/server/IslandBuilder.luau` (Nebeninseln/Wolken hängen von Insel-/Brettgröße ab), `src/client/CameraController.luau` + `Config.overviewZoom` (Rand in der Übersicht), `tests/thronlande.test.luau`, `tests/island.test.luau`.

**Studio-Prüfung:** echter Ort, nur Play, **keine Kamera-Eingriffe** (Normalzoom + Mausrad), Studio-Fenster nicht minimieren, **kein Blender parallel** (GPU-Treiber). Lauf: `Remotes.Command` `ResumeLevel`, ggf. `LeaveCamp`, dann `ChooseLevel index=1`. Pro Schritt Normal- und Übersichtsbild.

**Leitlinien:** Werte zentral in `Config.ISLAND` (WIP). Deterministisch pro `mapKey`. Brett (Felder, Klicks, Figuren, Brücke), UI, Hub, Nutzer-Lighting, `docs/referenz/` nicht anfassen. Keine Credits. Ein Commit pro Schritt. Notizen in **UTF-8**.

## Schritte

- [x] 1. **Größenfehler Streu-Deko** – `EnvironmentAssets.place`, `LandscapeBuilder.details`
  - Am Rand platzierte `deco_grass`/`deco_flower`/`deco_stone` sollen die **Rand-Größen** aus `ISLAND.rimScatter` erhalten, nicht die Brett-Grenzen. Brett-Deko bleibt in der bisherigen Brettgröße.
  - WIP-Zielgrößen am Rand: Gras ≈ 0,35 Feld hoch, Blumen ≈ 0,3, Steine ≈ 0,25 hoch / 0,5 breit; ±15 % Streuung.
  - Regression: gemessene Bounding-Box der Randdeko entspricht den Randwerten; Brettdeko unverändert.

- [x] 2. **Rand schmaler** – `Config.ISLAND.rimTiles` = `{ min = 2, max = 3 }`
  - Abhängige Werte prüfen und anpassen: Kantenreserve, Randgruppen-Abstände, Übersichtszoom/Schwenkgrenzen, Nebeninsel- und Wolkenabstände, Flussmündungen/Wasserfälle. Nichts darf über die Kante ragen oder in der Luft hängen.
  - Akzeptanz: Übersichtsbild – Insel kompakter, Brett größer im Bild, Kante/Wand/Wasserfälle intakt.

- [x] 3. **Dichte, lebendige Bestückung** – `LandscapeBuilder.details`, `Config.ISLAND`
  - **Zonen:** Vorderer Randstreifen (Kameraseite) nur **flache** Objekte (Höhe ≤ WIP 0,5 Feld: Gras, Blumen, Steine, Fässer, niedriger Fels); hintere und seitliche Streifen alles inkl. hoher Requisiten und Bäume. Nichts darf Brettfelder in Normalansicht verdecken (vorhandene `frontHeight`-Logik nutzen/anpassen).
  - **Gruppen:** 2–3 Gruppen je Seite (hinten/links/rechts), vorne 1–2 flache Gruppen (z. B. Fässer + Steine + Gras). Gruppen bestehen aus Hauptobjekt + 3–6 Begleitern (Gras/Blumen/Steine) eng darum, damit sie als Szene lesbar sind. Jede Rand-Requisite darf mehrfach vorkommen (deterministische Variation über Drehung/Größe).
  - **Streuung:** Gras/Blumen/Steine flächig, deutlich dichter als jetzt (WIP: ~1 Objekt je ¾ Randfeld, Grasbüschel am häufigsten), mit leichter Häufung an Gruppen und Kante.
  - **Leistung:** Obergrenzen als WIP-Werte (z. B. ≤ 140 Randobjekte, geschätzt ≤ 90.000 Dreiecke inkl. Bäume); gleiche Meshes werden wiederverwendet. Messung (Anzahl, Dreiecke, Aufbauzeit) in Notizen.
  - Akzeptanz: Normalbild – vorderer Rand mit sichtbarem Gras/Blumen/Steinen/Fässern, Seiten und Hinterkante mit klaren Gruppen; Brett frei lesbar.

- [x] 4. **Abschluss** – Tests, Messung, Devlog
  - Tests anpassen/ergänzen: Randbreite 2–3, Zonen (vorne nur flach), Größen Randdeko, Mindestanzahl/Obergrenzen, nichts auf Brett/über Kante/in Wasser, Determinismus, vier Gebiete. `scripts/check.ps1`, `test-run.ps1`, `test-levelgen.ps1`, `test-tutorial.ps1`, `test-run-ui.ps1` OK; Rojo-Build.
  - Normal- und Übersichtsbilder für 3 Grasland-Seeds (einer mit Brücke, falls möglich).
  - Devlog **#46 „Thronlande D2b – Rand schmaler und lebendig“**, „Nächste Schritte“ (D3: gemalter Himmel je Gebiet × Tageszeit). Committen, `git push`, Studio im Edit-Modus, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Rand schmaler, dicht und lebendig: vorne Gras/Blumen/Steine/Fässer sichtbar, Gruppen an Seiten/hinten
- [ ] Brett frei lesbar, nichts verdeckt Felder; Klicks/Bewegung wie vorher
- [ ] Handy flüssig, Aufbauzeit okay

## Nicht anfassen
- Spielregeln, Generator, Brett-Inhalt/Brückenlogik, UI, Hub, Lighting-Effekte des Nutzers, `docs/referenz/`, 3D AI Studio (keine Credits), Figuren

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**.)

## Notizen (Codex)

- Schritt 1: Eigene Randmaße pro Streukategorie, ±15 % Variation; aufrechte Einzelmeshes werden in Höhe/Breite getrennt angepasst, komplexe Ersatzmodelle weiter proportional begrenzt. Brettpfad unverändert. Studio: reguläres ResumeLevel (Grasland Level 3), D2b_01_groessen_normal/uebersicht, nur Mausrad. Gemessen: Randgras 2,747 Studs, Stein 1,875 Studs. Syntaxcheck OK; gesamte Regression läuft.

- Schritt 2: Rand 2–3 Felder, Gruppenmitte 1,25 Felder, Baumabstand 1,15–1,4; Baumgruppen ebenfalls mit rimFits gegen Kante/Wasser geschützt. Zoom und Wolkenabstand folgen bereits rimTiles.max; Schwenkgrenzen/Nebeninseln sind brettbezogen und bleiben gültig. Fluss-/Fallschale nutzt denselben Umriss. D2b_02_schmal_normal/uebersicht im regulären ResumeLevel, kein Kameraeingriff. 426 Inselteile; Kante/Wand intakt. check.ps1 OK; Schritt-1-test-run.ps1 Exit 0.

- Schritt 3: Deterministische 2–3 Hauptgruppen je Hinter-/Seitenkante und 1–2 flache Vordergruppen, je 3–6 Begleiter; gewichtete flächige Streuung mit Gruppen-/Kantenhäufung. Vordere Maximalhöhe 0,5 Feld, Fässer niedriger skaliert. Gesamte Randobjekte inklusive Bäume/Busch mit gemeinsamer Belegungsprüfung und harten Budgets 140/90.000; Schätzung Baum inklusive Wurzel 2.000, Busch 1.500 gemäß Paket-Fixtures. Reguläres ResumeLevel Seed 1867460066: vor Vorprüfung 119 Objekte/68.491 Dreiecke/627,40 ms; nach Vorprüfung 115/67.291/255,64 ms, sechs Bäume, Gruppen 3/2/2/1. Einzelmessungen, kein Handybenchmark. D2b_03_dicht_normal/uebersicht mit Figuren/UI, nur Mausrad. Syntax OK. Regression meldete fehlende Standardargumente im Random-Stub; Aufrufe explizit auf (0, 1) korrigiert, finaler Lauf in Schritt 4.

- Schritt 4: Vollständige Gruppen werden nur mit mindestens drei Begleitern übernommen; sonst gesamte Szene an derselben Kante verlegen. Zusätzliche Kategorienprüfung verhindert niedrige Seitenbüsche vorne. Mindestdichte im Regressionstest 90 Randobjekte, vorne mindestens 12; harte Obergrenzen inklusive Bäume/Busch. Gemischte Begleiter aus Gras/Blumen/Steinen; Streugras am häufigsten. Alle vier Gebietspaletten × drei Seeds mit Maßen, Zonen, Gruppen, Brett-/Kanten-/Wasserfreiheit und Determinismus geprüft. Der Generator unterstützt aktuell nur Grasland (RunConfig.REGIONS), daher andere Gebiete bewusst auf generierter Graslandgeometrie mit ihren eigenen Paletten; Generator unverändert.
- Finale echte Studio-Messungen (Grasland Seeds 1/2/3, Tiefe 1, axe, Teamgröße 4): 118/117/121 Randobjekte inklusive Bäume/Busch; 63.788/65.691/69.585 geschätzte Dreiecke; Randaufbau 368,87/366,96/276,93 ms, Brett insgesamt 592,06/552,59/461,40 ms. 3/2/0 Brücken. Echte Welt-Bounding-Boxes für alle drei Seeds geprüft: Maße, vollständige Gruppen, Bodenauflage, Brett/Kante/Wasser, Vorderzone und Budgets OK; 45/40/37 Vorderobjekte. Einmalige Messungen, keine GPU-/Handy-Bildrate.
- Studio-Bilder: pro Schritt D2b_01/02/03_*_normal/uebersicht; final reguläres ResumeLevel mit Figuren/UI Seed 1867460066 (126 Objekte, 70.582 Dreiecke, 271,99 ms Randaufbau), D2b_final_lauf_normal/uebersicht. Zusätzlich D2b_seed1/2/3_normal/uebersicht als temporäre BoardBuilder-Geometrievorschauen im Play-Modus. In diesen Vorschauen gehören Figuren/UI weiterhin zum ursprünglichen Lauf; keine gespielten Seed-Level und keine Bewegungsprüfung. Keine Kamera-Position/Neigung gesetzt, nur regulärer Startzoom/Mausrad; Studio nicht minimiert, kein Blender/keine Credits. Screenshots im MCP angesehen, keine lokalen Bilddateien. Output nur bekannte Lighting-/Chibi-Hinweise. Studio Edit bestätigt.
- Abschlussprüfungen: check.ps1 OK (39 Dateien), test-run.ps1 OK (34.458 Lauf-/Boss-/Lagerprüfungen, 677.787 Inselprüfungen, Maximum 450/450 Inselteile, D2b-Regressionssuite), test-levelgen.ps1 OK (19.000 Level-, 5.000 Options-, 96 Landschafts-, 2.400 Boss-/Minibossprüfungen), test-tutorial.ps1 OK (168), test-run-ui.ps1 OK (280); alle Exit 0. Rojo-Build und git diff --check OK. Devlog #46 ergänzt, D3 als nächster Entwicklungsplan beibehalten. Unabhängiges Claude-Review sowie Nutzer-/Handytests bleiben offen.
