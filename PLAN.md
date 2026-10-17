# PLAN: Thronlande D2c – Aufräumen nach Claude-Review

Ziel: Claude-Review von D2/D2b (Devlog #45/#46, 17.10.2026) fand keine Spielfehler, aber vier Aufräumpunkte. Optik, Budgets und Größenwerte bleiben **unverändert**; es geht nur um Aufbauzeit und Code-Ordnung.
Branch: `feature/thronlande-d2` (weiterarbeiten, ist gepusht).

**Bestehender Code:** `src/server/LandscapeBuilder.luau` (`rimDetails` mit lokaler Funktion `put`, `details`), `src/server/EnvironmentAssets.luau` (`place`), `src/server/BoardBuilder.luau` (`buildBridges`), `src/shared/Config.luau` (`Config.ENVIRONMENT`, `Config.ISLAND`), Tests `tests/thronlande.test.luau`, `tests/island.test.luau`, `tests/bridges.test.luau`.

**Leitlinien:** Deterministisch pro `mapKey`. Keine neuen Kategorien/Größen/Budgets. Brett, Brückenlogik (außer Schritt 3), UI, Hub, Nutzer-Lighting, `docs/referenz/` nicht anfassen. Keine Credits. Ein Commit pro Schritt. Notizen in **UTF-8**.

## Schritte

- [x] 1. **Randaufbau beschleunigen** – `LandscapeBuilder.rimDetails` / `put`
  - Vorher messen: `scripts/test-run.ps1` gibt „D2b Seed 1/2/3 … ms Stub-Randaufbau“ aus; Werte in Notizen.
  - **Rückbau unvollständiger Gruppen:** Statt `board:GetChildren()` nach `RimGroup` zu durchsuchen, die Assets der aktuellen Gruppe in einer lokalen Liste sammeln und nur diese zerstören.
  - **Vorprüfung vor dem Klonen:** In `put` vor `EnvironmentAssets.place` einen geschätzten Fußabdruck prüfen – Quadrat um (x, z) mit halber Kantenlänge `0.5 * Zielbreite * (1 - sizeVariation) * TILE_SIZE`; Zielbreite = `opts.width` bzw. `Config.ENVIRONMENT.categories[category].width` (Bäume: `ISLAND.tree.crownWidth`). Fußabdruck gegen `occupied` (mit `overlapClearance`) und `LandscapeBuilder.rimFits` prüfen; außerdem Dreiecksbudget mit `rimBudget.estimates[category]` bzw. `Config.ENVIRONMENT.triangles` der bevorzugten Variante, falls bekannt. Nur offensichtlich scheiternde Proben verwerfen; die bestehende Nachprüfung mit echter Bounding-Box bleibt unverändert.
  - Akzeptanz: Alle D2b-Regressionen in `test-run.ps1` grün (Randmaße, Vorderzone, vollständige Gruppen, Mindestdichte ≥ `rimBudget.minimumObjects`, Budgets, Determinismus). Stub-Randaufbau im Mittel der Seeds 1–3 **mindestens 30 % schneller** (vorher/nachher in Notizen). Randobjekte je Seed höchstens ±10 % gegenüber vorher.
  - Wenn Studio erreichbar: ein reguläres `ResumeLevel` und `IslandPropBuildMs` vorher/nachher notieren (nur Play, keine Kamera-Eingriffe, Studio nicht minimieren). Sonst überspringen und in Notizen vermerken.

- [x] 2. **Toten Insel-Code entfernen** – `LandscapeBuilder.details`
  - Nach `if state.island then rimDetails(state, board); return end` sind alle weiteren `state.island`-Zweige unerreichbar: `setmetatable(table.clone(Config.ISLAND) …)`, `(state.island and 0 or s.frontTransition)` → `s.frontTransition`, Zeile `if state.island and not LandscapeBuilder.rimFits(...)`. Entfernen.
  - Akzeptanz: Verhalten bei `Config.ISLAND.enabled = false` (Tal) unverändert; bestehende Tal-/Landschaftstests in `test-run.ps1` und `test-levelgen.ps1` grün.

- [x] 3. **Modellnamen zentral in Config** – `Config.ENVIRONMENT`, `EnvironmentAssets.place`, `LandscapeBuilder.put`, `BoardBuilder.buildBridges`
  - Neu `Config.ENVIRONMENT.rimRock = "rock_50"`; die drei Literale `"rock_50"` in `EnvironmentAssets.luau` (2×) und `LandscapeBuilder.luau` (1×) darauf umstellen.
  - Neu `Config.ENVIRONMENT.bridge.referenceModel = "archbridge_1"`; `BoardBuilder` übergibt `variant = settings.referenceModel` statt des Literals. Den nun doppelten Eintrag `archbridge = "archbridge_1"` aus `Config.ENVIRONMENT.preferred` entfernen (einziger `archbridge`-Platzierer ist `buildBridges`, der immer `variant` setzt).
  - Akzeptanz: `rg '"rock_50"|"archbridge_1"' src` findet nur noch `Config.luau`. `bridges.test.luau` und D2-Regressionen grün.

- [ ] 4. **Doppelten Namen `frontCategories` auflösen** – `Config.ISLAND`, `LandscapeBuilder.put`
  - `Config.ISLAND.frontCategories` (Menge erlaubter flacher Kategorien vorne) in `frontAllowed` umbenennen; `rimGroups.frontCategories` (Liste der vorderen Hauptobjekte) bleibt.
  - `rimGroups`-Block so einrücken/umbrechen, dass sichtbar ist, wo er endet und dass `frontAllowed` direkt in `Config.ISLAND` steht.
  - Akzeptanz: `rg frontCategories src` trifft nur `rimGroups.frontCategories`; Vorderzonen-Regression grün.

- [ ] 5. **Abschluss** – Tests, Doku
  - `scripts/check.ps1`, `test-run.ps1`, `test-levelgen.ps1`, `test-tutorial.ps1`, `test-run-ui.ps1` OK; Rojo-Build.
  - Devlog **#48 „Thronlande D2c – Aufräumen nach Review“** (Ziel · Umsetzung · Entscheidungen · Probleme · Messung vorher/nachher · Teststatus); „Nächste Schritte“: Claude-Review D2/D2b erledigt, Nutzer-/Handytest offen, danach Merge nach `main`.
  - Wiki: `docs/wiki/Thronlande.md` nur anpassen, falls dort Geändertes beschrieben ist.
  - Committen, `git push`, Studio im Edit-Modus, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Rand sieht aus wie nach D2b: vorne flache Deko, Gruppen an Seiten/hinten, Brett frei lesbar
- [ ] Brücken stehen, Figuren gehen darüber, Feldklicks wie vorher
- [ ] Levelstart spürbar nicht langsamer; Handy flüssig

## Nicht anfassen
- Größen, Kategorien, Budgets, Gruppenzahlen in `Config.ISLAND`; Spielregeln, Generator, Brettinhalt, UI, Hub, Lighting des Nutzers, Figuren, `docs/referenz/`, 3D AI Studio (keine Credits)

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**.)

## Notizen (Codex)

- Baseline Schritt 1 (test-run.ps1, Exit 0): Seeds 1/2/3 = 361,96 / 368,91 / 235,86 ms Stub-Randaufbau (Mittel 322,24 ms), 100 / 116 / 122 Randobjekte, 57.409 / 63.690 / 72.582 geschätzte Dreiecke.
- Studio-Messung übersprungen: MCP meldet keine verbundene Studio-Instanz. Keine Kamera-/Studio-Eingriffe.
- Sandbox-Setupfehler: nicht-destruktive Projektbefehle gemäß Dauerregel außerhalb der Sandbox ausgeführt.
- Schritt 1 nachher (test-run.ps1 Exit 0, alle D2b-Regressionen grün): Seeds 1/2/3 = 109,97 / 80,25 / 68,20 ms (Mittel 86,14 ms, 73,27 % schneller). Randobjekte 91 / 107 / 114 (-9,00 / -7,76 / -6,56 %), Dreiecke 53.521 / 61.002 / 68.489. Mindestdichte/Budgets/Determinismus erfüllt; check.ps1 OK (39 Dateien).
- Schritt 2: ausschließlich nach der Insel-Frührückkehr unerreichbare Zweige entfernt; Tal-Ausdruck auf s.frontTransition vereinfacht. Tal-/Generatorregressionen werden im Abschluss erneut ausgeführt.
- Schritt 3: Randfels und Referenzbrücke zentral in Config.ENVIRONMENT; doppeltes preferred.archbridge entfernt. Literalsuche in src trifft nur Config.luau.
