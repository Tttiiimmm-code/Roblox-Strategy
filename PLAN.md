# PLAN: Levelwahl-Karten im Designsystem-Stil + Wahrscheinlichkeitsliste schließen

Ziel: Die drei Optionen der Levelwahl sehen aus wie im Designsystem (Komponente „LevelChoice“): eigenständige Karten statt riesiger Jelly-Knöpfe, gut lesbare Belohnung, ein klarer Knopf pro Karte. Außerdem schließt die Wahrscheinlichkeitsliste, wenn die Rekrutierung verlassen wird.
Branch: `feature/ui-designsystem` (weiterarbeiten, Stand nach Devlog #41)

**Befunde aus Claudes Studio-Test (10.10.2026):**
1. `RunUI.luau` `buildChoice` (~Zeile 155–165): Jede Option ist ein `UIKit.button("", …, "default")` in Kartengröße. Die Glanzkuppe des Knopfs wird dadurch zu einem großen blassen Fleck über der oberen Kartenhälfte; die Belohnung („120 Gold“, `THEME.gold` auf `btn-blue` #4a8dff, ohne Kontur) ist kaum lesbar (Kontrast ≈ 1,5 : 1). Das Lager sieht aus wie ein Kampf.
2. Die Wahrscheinlichkeitsliste (`CollectionUI` `buildOdds`, `odds.frame`) bleibt offen, wenn der Spieler die Rekrutierung über eine andere Einrichtung (z. B. Kriegstisch-Prompt) verlässt, und liegt dann über der Teamwahl. `MenuUI.closeLobby` schließt nur die Lobby.

**Ziel-Aussehen je Option (Werte aus `UIKit.THEME`/`METRICS`):**
- Grundfläche: `UIKit.panel` **ohne** Juwel (Ecken 16, Glas-Indigo, Chromrand, ink außen).
- Oben eine Kennzeile im `UIKit.tag`-Stil (Michroma, Versalien, holoCyan): „KAMPF“, „MINIBOSS“, „BOSS“ bzw. „RAST“.
- Darunter Symbol (wie bisher aus `optionText`, Emoji bleiben vorerst – eigenes Icon-Set kommt später) und Titel in FredokaOne weiß mit Kontur (`THEME.title`, 26–28).
- Belohnung/Detail als **Pille**: `panelInset`, 2 px ink-Rand, Ecken voll rund, weiße Schrift; das Belohnungssymbol darf farbig bleiben. Beim Lager stattdessen die Beschreibung in `dim` als normaler Text.
- Unten ein echter Knopf (Höhe 48): Kampf „Wählen“ (`default`), Miniboss/Boss „Kampf!“ (`primary`), Lager „Rasten“ (`active`).
- Die **ganze Karte bleibt antippbar** (große Touchfläche wie bisher), der Knopf ist zusätzlich klickbar; beide lösen `callbacks.onChooseLevel(i)` aus, nur einmal pro Tipp, `lastState.busy` weiter beachten.
- Hover/Druck: Karte darf beim Drücken leicht skalieren (0,97) oder nur der Knopf reagiert – keine Überlappung der Nachbarkarten (bisher `HoverScale = 1`).

## Schritte

- [x] 1. **Levelwahl-Karten** – `RunUI.luau` (`buildChoice`, ggf. kleiner Helfer), ggf. `UIKit` für eine wiederverwendbare `UIKit.pill(...)`
  - Umsetzung wie oben. Layout für 2 und 3 Optionen prüfen; nichts darf abgeschnitten sein (Designgröße 1280×720).
  - Akzeptanz (Studio, echter Lauf): Bild der Levelwahl mit Kampf- und Lageroption; Belohnung klar lesbar, kein großer Glanzfleck, Lager unterscheidbar; ein Tipp auf Karte **und** einer auf den Knopf startet jeweils genau einmal.

- [x] 2. **Wahrscheinlichkeitsliste beim Verlassen schließen** – `CollectionUI.luau`, `MenuUI.luau`
  - Neue Funktion z. B. `CollectionUI.closeOverlays()` (schließt Wahrscheinlichkeitsliste; Ergebnisfenster nur, wenn das ohne Datenverlust geht – sonst offen lassen und in den Notizen begründen). `MenuUI.closeLobby` und jeder Wechsel weg von der Lobby rufen sie auf.
  - Akzeptanz: Studio – Wahrscheinlichkeitsliste öffnen, dann per Kriegstisch-Prompt die Teamwahl öffnen: Liste ist zu.

- [x] 3. **Abschluss**
  - `scripts/check.ps1`, `scripts/test-run-ui.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-levelgen.ps1` OK; Rojo-Build. UI-Regressionen: Option ist Panel ohne Juwel, Knopfstil je Optionsart, Ein-Tipp-eine-Wahl, `closeOverlays` beim Schließen der Lobby.
  - Devlog **#42 „Levelwahl-Karten“**. Committen, pushen, Studio im Edit-Modus lassen, `.handoff/status` = `fertig`.

**Studio-Prüfung:** wie im vorigen Plan (echter Ort, DataStore aktiv, Spielstand darf sich ändern; GUI-Koordinaten ohne 58-px-Topbar; Hub-Prompts per `InputHoldBegin/End`; nur Play-Modus).

## Manueller Test (Nutzer)
- [ ] Levelwahl: drei klar getrennte Karten, Belohnung lesbar, Lager erkennbar, Antippen startet sofort
- [ ] Wahrscheinlichkeitsliste schließt beim Verlassen der Rekrutierung

## Nicht anfassen
- Server, Lauflogik, Optionsinhalte (`RunConfig`), Emoji-Symbole (eigenes Icon-Set kommt später), Welt-Optik, `docs/referenz/`

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Levelwahl als `UIKit.panel(Jewel=false)` mit transparenter Ganzkarten-Klickfläche, Michroma-Kennzeile, Fredoka-Titel und eigenem 48-px-Knopf umgesetzt. Belohnungspille lokal in RunUI: kein zusätzlicher UIKit-Helfer nötig. Nur der Knopf reagiert auf Druck; HoverScale=1 verhindert Überlappungen.
- Gemeinsame Klickbehandlung für Karte/Knopf prüft `lastState.busy` und unterdrückt doppelte Aktivierungen derselben Eingabe. Nächster Tipp bleibt möglich; kein dauerhafter Wahllock.
- `CollectionUI.closeOverlays()` schließt die Wahrscheinlichkeiten. Rufergebnisse bleiben bis „Weiter“ offen, damit eine noch ungelesene Enthüllung nicht verloren geht. `MenuUI.closeLobby()` und die zentrale Sichtbarkeitsprüfung schließen beim Wechsel zu Teamwahl, Kaserne, Laden, eigenem Kampf oder Willkommen.
- Studio fand zunächst eine Überlappung bei 240 Designpixeln Kartenhöhe. Titel/Symbol kompakter angeordnet und Detail über dem Knopf verankert; Geometrieregressionen prüfen 240/296 Pixel mit zwei/drei Optionen.
- Alle fünf Pflichtprüfungen und Rojo-Build erfolgreich: check 38 Dateien; Run-UI 280 Prüfungen; Tutorial 168; Lauf 34458 Lauf-/Boss-/Lager-Stubs und 338242 Brett-/Kameraprüfungen plus Landschaftsregressionen; Generator 19000 Level-/5000 Optionsprüfungen, 96 Landschaftskombinationen und 2400 Boss-/Minibosskarten.
- Studio ausschließlich Play im echten Ort 75433071253639, Rojo-Quellen geprüft, DataStore `saveOk=true`: echte Zwei-/Drei-Optionen, Kampf/Lager und lesbare Gold-/Edelsteinpillen bildgeprüft. Ein Knopfklick startete einen Kampf, ein Klick auf den Lagertitel öffnete das Lager: temporärer serverseitiger Zähler bestätigte jeweils genau einen ChooseLevel-Befehl. Vier echte Testläufe neu gestartet/aufgegeben; vorhandener abgebrochener Lauf ebenfalls beendet. Abschluss ohne aktiven Lauf; Gold/Edelsteine unverändert (1563/3), keine Rufe/Käufe.
- Wahrscheinlichkeitsliste per echtem Klick geöffnet, dann Kriegstisch-Prompt mit InputHoldBegin/End: `oddsVisible=false`, `teamVisible=true`, Bild bestätigt. Keine neuen Output-Fehler, nur bekannte Modell-/Lighting-Hinweise. Probescript nur in Play; nach Stop entfernt. Studio abschließend Edit bestätigt. Keine lokalen Screenshotpfade geliefert.
- Sandbox-Prozessstart weiter defekt; Projektbefehle gemäß Dauerregel automatisch geprüft außerhalb der Sandbox ausgeführt. `docs/referenz/` unberührt. Unabhängiges Claude-Review sowie Nutzer-/Handytests bleiben offen; manuelle Nutzer-Checkboxen deshalb nicht abgehakt.
