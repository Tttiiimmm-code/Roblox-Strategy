# PLAN: UI-Umstellung auf das Designsystem „Throne Tales“ (Y2K-Fantasy)

Ziel: Die gesamte Oberfläche bekommt den Look des Designsystems – Glas-Indigo-Fenster mit Chromrand und Kronjuwel, Jelly-Knöpfe mit 3D-Kante, runde Konturschriften, Chrom-Titel, Heldenkarten mit Signaturfarbe und Holo-Rahmen für ★5. Das Spielverhalten ändert sich nicht.
Branch: `feature/ui-designsystem` (abgezweigt von `feature/level-optik-c`, Stand `b44961a`)
Designsystem (nur zur Info, für Codex nicht nötig): https://claude.ai/artifact/GsncXyUBtQh3UymyBhtbfD – alle benötigten Werte stehen unten.

**Warum zentral:** Fast alle Bildschirme (`UI`, `MenuUI`, `CollectionUI`, `RunUI`, `BattleScene`, `Hub`, `TutorialGuide`) bauen über `src/client/UIKit.luau` (`THEME`, `BUTTON_STYLES`, `panel`, `button`, `bar`, `heroCard`, `rarityStars`, `label`). Deshalb zuerst UIKit umbauen, dann nur gezielte Stellen in den Bildschirmen.

**Werte (alle in `UIKit.THEME` als `Color3`, Namen frei wählbar, aber alte Schlüssel weiter gültig lassen):**

| Rolle | Wert | Verwendung |
|---|---|---|
| ink | #141a33 | einzige Konturfarbe: Textkontur, äußerer Fensterrand, Knopfrand, Kartenrand |
| backdrop | #0b0a26 | Abdunklung hinter modalen Fenstern (Transparenz 0,35) |
| panelTop / panelBottom | #3b3fd1 / #1a1660 | Fensterverlauf (ersetzt `top`/`bottom`) |
| panelInset | #110e45 | vertiefte Flächen, Balkenspur (ersetzt `barBg`) |
| panelLine | #7f86ff | 1-px-Lichtkante oben innen |
| text / dim | #ffffff / #d2d9f5 | Haupttext / Nebentext |
| chromeLight / chromeMid / chromeDark | #f4f7ff / #b9c2d6 / #5f6884 | Chromverlauf: hell → mittel → harter Knick dunkel (bei 0,50) → hell |
| holoCyan / holoLilac / holoPink / holoLime | #3ef0ff / #b58cff / #ff5fd2 / #c6ff4a | Holo-Verlauf (nur Beschwörung und ★5), Kennzeilen in holoCyan |
| holoShade | #7a4fd6 | 3D-Kante unter dem Holo-Knopf |
| gold / goldShade | #ffc93c / #c98a12 | Hauptaktion, Gold-Chrom-Titel, Münzen |
| gem | #6ee8ff | Edelstein-Symbol ♦ (wie bisher) |
| starEmpty | #4a5068 | leere Sterne (wie bisher) |
| good / bad / warn, player / enemy, HP-Farben, Seltenheitsfarben | **unverändert** | |

**Knopfstile (`BUTTON_STYLES`: Füllung, 3D-Kante):** default #4a8dff / #2a5fc4 · primary = gold #ffc93c / #c98a12 · danger #ff4d4d / #c22d36 · active #3fd15a / #23963a · muted #6a71c9 / #454b9a (WIP, noch nicht im Designsystem) · disabled #8a90a6 ohne Kante, Schrift 0,4 transparent · **neu `holo`**: Verlauf holoCyan → holoLilac → holoPink → gold, Kante holoShade.

**Schriften:** Display `Enum.Font.LuckiestGuy` (große Titel, Schadenszahlen) · UI `Enum.Font.FredokaOne` (Knöpfe, Namen, Überschriften, Balkenzahlen – ersetzt `title` und `bold`) · Text `Enum.Font.GothamMedium` (bleibt) · Tech `Enum.Font.Michroma` (kurze Kennzeilen in Versalien). Falls ein Enum-Wert fehlt: `Font.fromName` bzw. `FontFace` verwenden und in den Notizen nennen.

**Maße:** Ecken klein 6 / Knopf+Karte 12 / Fenster 16 / Banner 24 · Knopf mindestens 48 hoch (Designgröße 1280×720), Hauptaktion 64 · 3D-Kante 5 px, beim Drücken 1 px · Textkontur 1,5 px (≤ 16), 2 px (17–28), 3 px (≥ 32) · Fensterrand: 3 px Chrom innen + 3 px ink außen · Kartenrahmen 4 px + ink außen · harter Fallschatten 8 px nach unten, ink, Transparenz ≈ 0,55 (kein Weichzeichner).

**Studio-Prüfung (Pflicht für Schritte 2–6), wie in C7:** `list_roblox_studios` → Ort „Throne Tales“, Rojo verbunden (`ReplicatedStorage.Shared.Config.Source` aktuell). `start_stop_play(true)`, frisches Profil; Bildschirme über `Remotes.Command` aufrufen (Hub/Menü, Sammlung/Rekrutierung, Kaserne, Laufwahl, Kampf mit Kampfvorschau und Level-Up). `screen_capture` je Bildschirm vorher (Schritt 1) und nachher; in den Notizen beschreiben, was zu sehen ist. Zusätzlich eine Aufnahme in Handygröße (Studio-Gerätesimulation, z. B. 844×390), wenn über MCP möglich – sonst in den Notizen sagen, dass es fehlt. Danach `start_stop_play(false)`. Nichts im Edit-Modus bauen.

**Leitlinien:** Server bleibt unberührt. Alle Werte zentral in `UIKit` (THEME/BUTTON_STYLES/neue Konstanten), keine Farbwerte verstreut. Bestehende Aufrufer müssen ohne Änderung weiterlaufen: `UIKit.button` liefert weiter einen `TextButton`, dessen `.Text` man setzen kann; `setButtonStyle`, `GetAttribute("Style")`, `HoverScale`, Größen in Layouts bleiben. Klick-/Touchflächen dürfen nicht kleiner werden. Animationen aus `Config.FEEL` unverändert. Lesbarkeit vor Effekt: Weiße Schrift auf hellen Flächen (gold, grün, cyan) nur mit ink-Kontur. Ein Commit pro Schritt. Geschmacksfragen nicht selbst entscheiden → „Offene Fragen“.

## Schritte

- [x] 1. **Vorher-Bilder** – nur Studio
  - Vor jeder Codeänderung je ein Bild von: Hub-Menü, Rekrutierung (Banner + Ergebnis), Kaserne, Laufwahl/Levelwahl, Kampf (Einheiten-Info, Kampfvorschau, Schadenszahl), Level-Up-Fenster. Liste in den Notizen.

- [x] 2. **Theme, Schriften, Konturschrift** – `UIKit.luau` (THEME, `label`, `fitText`), `Main.client.luau` (Schwebezahlen, ca. Zeile 878)
  - THEME auf die Werte oben umstellen; alte Schlüssel (`top`, `bottom`, `barBg`, `goldDark`, `title`, `bold`, `body`) bleiben als Verweise auf die neuen Werte, damit alle Module laufen. `THEME.title` und `THEME.bold` → FredokaOne; neu `THEME.display` (LuckiestGuy) und `THEME.tech` (Michroma). `DIM_HEX`/`GOLD_HEX` anpassen.
  - `UIKit.label`: Für UI-/Display-Schrift automatisch eine **Textkontur in ink** (UIStroke mit `ApplyStrokeMode.Contextual`, Dicke nach Textgröße wie oben). Fließtext (GothamMedium) ohne Kontur. Abschaltbar über ein Prop (z. B. `Outline = false`).
  - Schwebende Schadens-/Heilzahlen: LuckiestGuy mit ink-Kontur statt GothamBlack/TextStroke.
  - Akzeptanz: alle Bildschirme öffnen ohne Fehler im Output; Texte haben die neuen Schriften; Kontur sichtbar und nicht matschig bei 12–14 px.

- [ ] 3. **Fenster mit Chromrand, Glas und Kronjuwel** – `UIKit.panel`
  - Verlauf panelTop → panelBottom; innen 3-px-Chromrand (UIStroke mit UIGradient chromeLight → chromeMid → chromeDark bei 0,50 → chromeLight, senkrecht), außen 3 px ink (z. B. Chromrand am inneren `Background`, ink-Rand am äußeren Frame, sodass beide sichtbar sind); Ecken 16.
  - Glas: 1-px-Lichtkante panelLine oben innen und eine weiche weiße Spiegelung im oberen Drittel (Transparenz ≈ 0,86 → 1).
  - **Kronjuwel** (Erkennungszeichen): kleine Raute (um 45° gedrehtes Quadrat, ca. 16 px, Ecken 3) oben mittig auf der Fensterkante, Verlauf gem → holoLilac, ink-Rand, dünner Chromring, kleines weißes Glanzlicht. Prop zum Abschalten für kleine Info-Fenster (z. B. `Jewel = false`); Standard an.
  - Harter Fallschatten 8 px unter dem Fenster; bei `Animated` (CanvasGroup, schneidet ab) darf er entfallen oder außerhalb liegen – Lösung in den Notizen.
  - Modale Abdunklungen, die heute schwarz/dunkel sind, auf backdrop (0,35) umstellen, soweit sie über UIKit laufen.
  - Akzeptanz: Studio-Bild Hub und Lager/Laufwahl: Chromrand mit hellem Knick erkennbar, ink-Außenrand, Juwel mittig oben, Inhalt nicht verdeckt.

- [ ] 4. **Jelly-Knöpfe mit 3D-Kante** – `UIKit.button`, `setButtonStyle`, `BUTTON_STYLES`
  - Füllung aus Stil, Ecken 12, ink-Rand 3 px, **3D-Kante** 5 px in der Kantenfarbe unter dem Knopf, **Glanzkuppe** (weiße Ellipse/Verlauf in der oberen Hälfte, 0,35–0,5 deckend → 0), Schrift FredokaOne weiß mit ink-Kontur.
  - Drücken: Knopf senkt sich auf 1 px Kante (zusätzlich zur bestehenden Skalierung 0,94). Hover wie bisher.
  - Stile wie oben inkl. neuem `holo` (Verlauf), `disabled` ohne Kante. `setButtonStyle` setzt Füllung und Kante.
  - Wichtig: `.Text`, Layout-Größe, Klickfläche und alle bestehenden Aufrufer bleiben gültig. Die Kante darf Layout-Abstände nicht zerstören (in den Notizen sagen, wie gelöst – z. B. Kante als Kind unterhalb der Knopfkante).
  - Mindesthöhe 48 für normale Knöpfe dort sicherstellen, wo Knöpfe heute niedriger sind, ohne Layouts zu sprengen; Abweichungen auflisten.
  - Akzeptanz: Studio-Bild mit default, primary, danger, active, muted, disabled; Text auf Gold/Grün gut lesbar.

- [ ] 5. **Balken, Sterne, Heldenkarten** – `UIKit.bar`, `rarityStars`, `heroCard`
  - Balken: Pillenform (Ecken voll rund), Spur panelInset, Rand 2 px ink, Füllung mit Glanzkuppe; Zahl FredokaOne mit Kontur.
  - Sterne: volle Sterne in Seltenheitsfarbe, leere starEmpty (wie bisher), wenn möglich mit ink-Kontur.
  - Heldenkarte: Hintergrund-Verlauf aus der **Signaturfarbe des Helden** (`UnitData.Heroes[id].chibi.outfit.primary`, sonst Seltenheitsfarbe) oben nach panelBottom unten; Rahmen 4 px in Seltenheitsfarbe + ink außen; Ecken 12; Name FredokaOne in Seltenheitsfarbe mit dicker ink-Kontur, Klasse GothamMedium dim.
  - **★5-Holo-Rahmen**: Rahmen als Verlauf rarity5 → #fff3b0 → holoPink → holoCyan (UIGradient am UIStroke), dazu ein schwacher Schein um die Karte; ★4 einfacher Rahmen (optional ein langsamer Glanzstreifen, nur wenn günstig – sonst weglassen und notieren). `Config.FEEL.rarityEffects` betrifft nur 3D-Effekte, nicht diesen Rahmen.
  - Abzeichen „NEU“ o. ä. als Pille holoPink mit ink-Rand.
  - Akzeptanz: Studio-Bild Kaserne mit ★1–★5 nebeneinander; jede Karte zeigt ihre Signaturfarbe, ★5 Holo-Rahmen.

- [ ] 6. **Titel, Kennzeilen, Beschwörung** – neue Helfer in `UIKit` + gezielte Stellen
  - `UIKit.chromeTitle(props, parent)`: TextLabel in LuckiestGuy, Text mit Chromverlauf (UIGradient auf dem TextLabel, Hintergrund transparent), 3 px ink-Kontur; Variante `Gold = true` (Verlauf #fff6d0 → gold → goldShade bei 0,52 → gold → #fff6d0).
  - `UIKit.tag(props, parent)`: Michroma, Versalien, holoCyan, klein (12–16).
  - Große Titel umstellen (heute `THEME.title` mit TextSize ≥ 30): `MenuUI.luau` 72, 137, 240, 277 · `CollectionUI.luau` 69 (Bannertitel → Gold-Chrom), 157, 215 · `RunUI.luau` 36, 146 · `UI.luau` 382 („Level Up!“ → Gold-Chrom), 421, 448 · `BattleScene.luau` 39, 53. Zeilennummern Stand `b44961a`.
  - Rekrutierung (`CollectionUI`): Zehnerruf-Knopf im Stil `holo` statt `primary`; Einzelruf `default`; Edelstein-Anzeige als Pille (panelInset, ink-Rand, Ecken voll rund). **Wahrscheinlichkeiten bleiben unverändert sichtbar** (Roblox-Regel).
  - Akzeptanz: Studio-Bilder Hub-Titel, Rekrutierungsbanner, Ergebnis „Neue Verbündete“, Level-Up.

- [ ] 7. **Abschluss** – Tests, Devlog
  - `scripts/check.ps1`, `scripts/test-run-ui.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-levelgen.ps1` alle OK; Rojo-Build. UI-Tests anpassen, falls sie Farben/Fonts prüfen (Regeln nicht abschwächen, nur neue Werte).
  - Devlog **#40 „UI-Umstellung Designsystem“** (Ziel · Umsetzung · Entscheidungen · Probleme · Teststatus) und „Nächste Schritte“ aktualisieren (nächste Etappen: Schwebende Thronlande, Thronkristalle/Banner).
  - Committen, pushen (erster Push des neuen Branches: `git push -u origin feature/ui-designsystem`), Studio im Edit-Modus lassen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Hub, Rekrutierung, Kaserne, Laufwahl, Kampf, Level-Up: neuer Look überall, nichts abgeschnitten oder überlappend
- [ ] Fenster haben Chromrand und Kronjuwel; Knöpfe wirken „drückbar“ (Kante, Senken beim Tippen)
- [ ] Texte gut lesbar, auch klein und auf goldenen/grünen Knöpfen
- [ ] Heldenkarten zeigen ihre eigene Farbe; ★5-Karten haben den Holo-Rahmen
- [ ] Handy: alle Knöpfe gut mit dem Daumen treffbar, Bildwiederholrate unverändert flüssig

## Nicht anfassen
- Server, Spielregeln, Generator, Brett/Welt-Optik (Terrain, Klippen, Wasser – kommt mit „Schwebende Thronlande“ in einem eigenen Plan), Kamera, Sounds, Profil-Schema, Wahrscheinlichkeitsanzeige, die vom Nutzer angelegten Lighting-Effekte, `docs/referenz/`

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1 (10.10.2026): Studio 70aa44d0 (AutoRecovery-Datei, PlaceId 0); Config.Source entspricht lokal bis auf abschließenden Zeilenumbruch, Rojo 7.7.1 verbunden. Frisches Speicherprofil. Vorher-Aufnahmen im MCP: Willkommen, Hub/Thronmenü, Rekrutierungsbanner, echtes Einzelruf-Ergebnis, Kaserne mit allen Helden (Client-Profilprobe), Laufteam, Levelwahl, Kampf/Einheiteninfo, Kampfvorschau, Level-Up (Darstellungsprobe). Bisher Blau-Gold, Fondamento-Titel, flache Knöpfe; schmale Kartenrahmen. Die flüchtigen BattleEvent-Schadenszahlen waren in den ersten Aufnahmen nicht sichtbar. Ergänzende Aufnahme UI_Vorher_Schadenszahl_Fixture: stehende 7 am Avatar mit exakt den bisherigen floatText-Schriftwerten (GothamBlack/TextStroke); reine Darstellungsfixture. Keine Server-Spielwerte geändert. Aufnahmen im MCP betrachtet, keine lokalen Bildpfade geliefert. Play beendet; Edit-Modus. Handyaufnahme folgt beim Abschluss, soweit MCP-Gerätesimulation möglich.

- Schritt 2: THEME-Farben/Verweise und RichText-Hexwerte umgestellt. FredokaOne, LuckiestGuy und Michroma sind in Studio als Enum vorhanden. label/outline verfolgen Font, TextSize und TextTransparency; Outline=false deaktiviert die Kontur. Schwebezahlen verwenden LuckiestGuy und denselben ink-UIStroke, der mit ausblendet. check.ps1 OK (38 Dateien). Studio-Bilder Willkommen, Rekrutierung, Kaserne, Laufwahl und Kampf/Level-Up: neue runde Schrift und klare Konturen auch bei kleinen Namen/Kennwerten; Fließtext ohne Kontur. Output ohne neue Fehler, bekannte Mesh-Rückfälle/Lighting-Hinweis. Play beendet. Vorher-Schadenszahl tatsächlich in UI_Vorher_Schadensschrift_Standbild sichtbar: ScreenGui-Standbild der ursprünglichen floatText-TextLabel-Werte auf dem Kampfbrett; Billboard-Proben waren in screen_capture unsichtbar.
