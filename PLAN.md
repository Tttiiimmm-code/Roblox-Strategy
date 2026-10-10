# PLAN: UI-Korrekturen nach Studio-Test (Designsystem-Umstellung, Teil 2)

Ziel: Die Fehler beheben, die Claude am 10.10.2026 beim eigenen Studio-Test im echten Ort „Throne Tales“ (PlaceId 75433071253639) gefunden hat. Danach darf der Nutzer veröffentlichen.
Branch: `feature/ui-designsystem` (weiterarbeiten, Stand nach Devlog #40)

**Befunde aus Claudes Studio-Test (Play-Modus, echter Ablauf):**
1. **Überlagerte Fenster ohne Hintergrund:** „Neue Verbündete“ (`CollectionUI` ~Zeile 211, Panel `Animated`, ZIndex 31) und „Wahrscheinlichkeiten“ (`CollectionUI` ~Zeile 153) zeigen Titel, Karten und Knöpfe, aber keinen Fensterhintergrund – man liest das Rekrutierungsfenster dahinter. Gemessen: `Background` existiert, Transparenz 0,04, `GroupTransparency` 0, aber `Background.ZIndex = 0`. Alle ScreenGuis außer `BattleScene` laufen mit `ZIndexBehavior.Global` (Standard dieses Orts), dadurch wird der Hintergrund unter der Abdunklung (ZIndex 30) und dem Rekrutierungsfenster gezeichnet. Bei den Wahrscheinlichkeiten kritisch (Roblox-Regel: gut lesbar).
2. **Geländefenster wächst:** `GelaendeKasten` (`UI.luau` ~Zeile 101, `AutomaticSize = Y`) ist 620 px statt ca. 78 px hoch und verdeckt die rechte Bildschirmseite. Ursache: der neue `Shadow` (um 8 px nach unten versetzt) zählt für `AutomaticSize` mit.
3. **Zu viele Kronjuwelen:** Im Kampf bis zu fünf gleichzeitig (Phasenbanner, Einheiten-Info, Geländefenster, Aktionsmenü, Kampfvorschau), dazu auf den Helden-Feldern im Laufbildschirm. Laut Designsystem gehört das Juwel nur auf **große** Fenster. Außerdem überlappt die Kampfvorschau (`UI.luau` `buildForecast`, Position y = 92) das Phasenbanner, sodass zwei Juwelen aufeinander sitzen.
4. **Reste im alten Stil:** Beschwörungsbanner-Hintergrund noch Braun-Gold (`THEME.bannerTop/bannerBottom`, Goldrand 2 px); KP-Balken der Kampfszene (`BattleScene.luau` `buildSide`, ~Zeile 45) noch eckig mit goldDark-Rand; Level-Abzeichen der Kaserne (`CollectionUI` ~Zeile 358–363) in Pink wie „NEU“; Kartenrahmen der Kaserne werden nach Auswahl 3 px statt 4 px (`CollectionUI` ~Zeile 333).
5. **Kontur bei geschrumpftem Text:** `UIKit.outline` richtet die Dicke nach `TextSize`, nicht nach der tatsächlich angezeigten Größe (`TextScaled`/`fitText`). Kleine, herunterskalierte Texte können „zulaufen“.

**Studio-Prüfung (Pflicht ab Schritt 1):** wie im vorigen Plan. Achtung: Der Ort ist jetzt der echte, veröffentlichte Ort; DataStore-Zugriff ist in Studio **aktiv**. Der Nutzer erlaubt, seinen Spielstand fürs Testen zu verändern (10.10.2026). Trotzdem keine Profil-Massenänderungen, keine Robux-/Kaufabläufe. Klicks über `user_mouse_input` verwenden GUI-Koordinaten (ohne die 58-px-Topbar des Screenshots); ProximityPrompts im Hub lassen sich per `InputHoldBegin/End` auslösen. Nur im Play-Modus testen; danach `start_stop_play(false)`.

**Leitlinien:** Nur Client-UI. Alle Werte zentral in `UIKit`. Bestehende Aufrufer bleiben gültig. Ein Commit pro Schritt. Geschmacksfragen → „Offene Fragen“.

## Schritte

- [x] 1. **Fensterhintergrund in der richtigen Ebene** – `UIKit.panel`
  - Alle Deko-Teile des Fensters (`Background`, `Shadow`, `Glass`, `InnerLight`, `OuterBorder`, `CrownJewel`) liegen in derselben Ebene wie das Fenster selbst (`ZIndex = f.ZIndex`) und folgen späteren `ZIndex`-Änderungen. Sie müssen trotzdem **unter** dem Fensterinhalt liegen – auch dann, wenn Inhalte ihren Standard-ZIndex 1 behalten oder genau den ZIndex des Fensters haben. Lösung frei (z. B. Inhalt-ZIndex beim Hinzufügen auf mindestens `f.ZIndex` anheben, oder Deko konsequent in eigener Ebene), in den Notizen begründen.
  - Funktioniert in Global- **und** Sibling-ScreenGuis (`BattleScene`).
  - Akzeptanz (Studio, je ein Bild): „Neue Verbündete“ nach einem echten Einzelruf, „Wahrscheinlichkeiten“, Level-Up-Fenster, Laufergebnis/Lauf-Fenster, Ladebildschirm. Hintergrund deckend, nichts vom Fenster dahinter lesbar, alle Inhalte sichtbar.

- [x] 2. **Kein Wachsen bei `AutomaticSize`** – `UIKit.panel`, ggf. `UI.luau` (`GelaendeKasten`)
  - Schatten und andere Deko dürfen die automatische Größe nicht beeinflussen (z. B. bei `AutomaticSize` keinen versetzten Schatten als direktes Kind, oder Schatten so anlegen, dass er nicht mitzählt).
  - Akzeptanz: `GelaendeKasten.AbsoluteSize.Y` passt zum Inhalt (Richtwert ≤ 100 px bei drei Zeilen) und bleibt nach mehrmaligem Ein-/Ausblenden gleich (in den Notizen Messwerte nennen). Bild: Kampf mit ausgewähltem Feld.

- [x] 3. **Kronjuwel nur auf großen Fenstern, Vorschau ohne Überlappung** – `UIKit.panel` und Aufrufer
  - Standard umdrehen: `Jewel` ist **aus**, außer ausdrücklich `Jewel = true`. Einschalten nur für große, eigenständige Fenster: Willkommen/Lobby-Hauptfenster und Lager-Dialog (`MenuUI`, `RunUI` `RunWindow` und Dialog), Rekrutierung/Kaserne-Hauptfenster, „Neue Verbündete“, „Wahrscheinlichkeiten“, Level-Up, Ladebildschirm-Karte. **Kein** Juwel auf: Phasenbanner, Einheiten-Info, Geländefenster, Aktionsmenü, Kampfvorschau, Toast, Pillen, Helden-Feldern im Lauf, Kampfszenen-Fenstern. Liste der tatsächlich gesetzten Stellen in den Notizen.
  - Kampfvorschau so weit nach unten setzen, dass sie das Phasenbanner nicht berührt (mindestens 8 px Abstand inklusive Rand).
  - Akzeptanz: Kampfbild mit Auswahl + Aktionsmenü + Kampfvorschau: höchstens ein Juwel sichtbar, keine Überlappung.

- [x] 4. **Reste angleichen** – `UIKit.THEME`, `CollectionUI`, `BattleScene`
  - Beschwörungsbanner: Verlauf `holoShade` (#7a4fd6) oben → `panelBottom` unten statt Braun-Gold; Rand wie Fenster (Chrom 3 px + ink außen) statt Gold 2 px; Ecken 24 bleiben. Gold-Chrom-Titel bleibt.
  - Kampfszene-KP-Balken: Spur `panelInset`, Rand 2 px ink, Ecken 6; KP-Trennlinien bleiben.
  - Kaserne-Level-Abzeichen: `panelInset` mit ink-Rand und weißer Schrift; Pink (`holoPink`) bleibt allein „NEU!“ vorbehalten.
  - Kaserne-Auswahl: nicht gewählte Karten behalten 4 px (`METRICS.cardBorder`), gewählte 6 px.
  - Akzeptanz: Bilder Rekrutierung, Kaserne mit gewählter Karte, Kampfszene.

- [x] 5. **Kontur nach angezeigter Größe** – `UIKit.outline`
  - Dicke nach der tatsächlich dargestellten Textgröße (`TextBounds`/`AbsoluteSize` bzw. aktuelle Größe bei `TextScaled`), mit denselben Stufen (≤ 16 → 1,5; 17–28 → 2; ≥ 32 → 3); bei sehr kleinem Text (< 12) höchstens 1 px. Günstig halten (kein Aktualisieren pro Frame).
  - Akzeptanz: Bild eines herunterskalierten Knopftexts (z. B. „Gegnerphase überspringen“) und der Pillenzahlen; Buchstaben offen und lesbar.

- [x] 6. **Abschluss** – Tests, Devlog
  - `scripts/check.ps1`, `scripts/test-run-ui.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-levelgen.ps1` alle OK; Rojo-Build. UI-Regressionen für Schritt 1–3 ergänzen (Deko-ZIndex folgt Fenster-ZIndex; Juwel standardmäßig aus; `AutomaticSize` ohne versetzten Schatten).
  - Devlog **#41 „UI-Korrekturen nach Studio-Test“**.
  - Committen, pushen, Studio im Edit-Modus lassen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Beschwörung: Ergebnisfenster und Wahrscheinlichkeiten mit deckendem Hintergrund, gut lesbar
- [ ] Kampf: Geländefenster rechts klein, nur ein Kronjuwel im Bild, Vorschau überlappt nichts
- [ ] Beschwörungsbanner lila statt braun; Kaserne-Abzeichen und Rahmen stimmig
- [ ] Handy: kleine Texte mit Kontur gut lesbar
- [ ] Danach: Datei → Auf Roblox veröffentlichen

## Nicht anfassen
- Server, Spielregeln, Generator, Welt-Optik, Kamera, Sounds, Profil-Schema, Inhalte der Wahrscheinlichkeitsanzeige, die vom Nutzer angelegten Lighting-Effekte, `docs/referenz/`

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1: Eigene Fensterdeko folgt `f.ZIndex`; Inhaltsobjekte werden mindestens auf `f.ZIndex + 1`, beschriftete TextButtons auf `+2` angehoben, damit ihre Jelly-Flächen (`Button.ZIndex - 1`) unter dem Text bleiben. Höhere Inhaltswerte bleiben erhalten; neue/umgehängte Inhalte und spätere ZIndex-Zuweisungen werden ereignisbasiert erfasst. Standardhintergrund jetzt Transparenz 0: 0,04 ließ dahinterliegende Schrift noch schwach durchscheinen. Alle fünf geforderten Fenstertypen plus Laufergebnis im echten Ort im Play-Modus bildgeprüft. Zwei echte Einzelrufe mit jeweils 50 temporär ergänzten Edelsteinen; Bestand danach wieder 3, Ruf-/Verschmelzungsfortschritt gemäß erlaubtem Spielstandtest geändert. Level-Up/Laufergebnis/Ladekarte als UI-Darstellungsfixtures, Laufwahl mit realem Profil. MCP liefert keine lokalen Screenshotdateien; Bilder im Werkzeugergebnis betrachtet. Unabhängiges Review bleibt Claude vorbehalten.

- Schritt 2: Studio widerlegte die reine Schatten-Ursache: ohne Schatten blieb der gepolsterte Background/OuterBorder bei ca. 620 px, ohne Padding-Kompensation noch ca. 546 px. Bei `AutomaticSize` zeichnet deshalb der Fensterframe selbst den Verlauf; die Background-Deko ist unsichtbar und zählt nicht mit. Keine versetzten Schatten für anfangs automatische Fenster; nachträgliches Umschalten deaktiviert und nullt vorhandene Schatten. Statisch große Fenster behalten ihre komplette Deko. Messung bei fünf Ein-/Ausblendungen mit drei Wald-Zeilen: jeweils 66,92 px bei der aktuellen UI-Skalierung (78 Designpixel), stabil; Kampfbild geprüft. Automatisch große Fenster haben den Chromrand, aber keinen überstehenden ink-Außenrand/Glasreflex/Juwel, da diese Kinder die Größenrückkopplung auslösten.

- Schritt 3: `Jewel = true` steht ausschließlich in MenuUI `buildLobby`, `buildResult`, `buildWelcome`; CollectionUI `buildOdds`, `buildResults`; RunUI `RunWindow` und Aufgabedialog; UI Level-Up und Ladekarte. Rekrutierung und Kaserne teilen das Lobby-Hauptfenster. Alle übrigen Panel-Aufrufer bleiben ohne Juwel. Vorschauhöhe zentral `METRICS.forecastTop = 120`; gegenüber Phasenbanner Ende 92 bleiben nach beidseitigem Außenrand (je 6) 16 Designpixel frei, auch dessen Schatten bleibt frei. Studio-Kampfbild: tatsächliche Leon-Auswahl per Mausklick, Gelände, Info, zusätzlich Vorschau/Aktionsmenü als Darstellungsprobe; 0 sichtbare Juwelen, kein Kontakt der Fenster. Tutorialbedingt verborgene Menüknöpfe für das zweite Bild sichtbar gemacht. Ergänzung Schritt 2: echte Auswahl mit stabiler Sichtbarkeit und fünf Ein-/Ausblendungen ergibt jedes Mal 71,19 px (78 Designpixel); zuvor genannte 66,92 px waren der kurzzeitig verkleinerte Animations-/Ausblendstand. Das echte Auswahlbild zeigt den kleinen Geländekasten rechts.

- Schritt 4: Beschwörungsbanner nutzt die kompatiblen Theme-Aliase `bannerTop = holoShade`, `bannerBottom = panelBottom` und einen senkrechten Verlauf. UIKit baut den 3-px-Chromrand und einen ink-Außenrand als Geschwister der Scrollfläche (kein Abschneiden/kein Layoutplatz); Radius bleibt 24. Kampfszene: panelInset-Spur, 2-px-ink, 6-px-Ecken auch an der Füllung, KP-Trennlinien erhalten. Kaserne-Levelpillen panelInset/weiß mit bestehendem ink-Rand; Auswahl 6, Abwahl 4 über zentrale Metrics. Bilder von Rekrutierung und echter Tobi-Kartenauswahl geprüft (gemessen 6 px); Kampfszene als Darstellungsprobe mit echten Heldentemplates und Sibling-ScreenGui geprüft. Kein Juwel in Kampfszenenfenstern.

- Schritt 5: Konturgröße aus gerenderten TextBounds, bei expliziten Zeilen unter Berücksichtigung von LineHeight; umgebrochene Konturtexte über eine logarithmische TextService-Messung der Zeilenhöhe. Layoutsignale werden über task.defer gebündelt; kein RenderStepped-Anschluss, keine erneute Schriftmessung bei Transparenz-Fades oder konturlosen Texten. Explizite OutlineThickness wird an der jeweiligen Größenstufe gedeckelt, insbesondere unter 12 auf 1 px. Studio-Bildprobe mit echten UIKit-Knöpfen (`TextScaled`/Umbruch aktiv, TextSize 32), geschrumpftem „Gegnerphase überspringen“ und KP-Pille: Kontur 2 bzw. 1,5; zusätzliche Probe unter 12: 1. Schrift/Pillenzahlen offen. Kampfszene abschließend erneut mit vollständig eingeblendeter CanvasGroup (GroupTransparency 0) und Sibling bestätigt. Neue Notizen/Kommentare mit korrekter UTF-8-Pipeline geschrieben.

- Schritt 6: `check.ps1` OK (38 Dateien); `test-run-ui.ps1` OK (229 insgesamt, 56 neue Prüfungen für Global/Sibling, dynamische Deko-/Inhaltsebenen, Knopftext vor Fläche, umgehängte Unterbäume, Juwelstandard, deckende Fläche, anfängliches/nachträgliches AutomaticSize, Konturgrößen/Umbruch/Fade); `test-run.ps1` OK (34458 Lauf-/Boss-/Lager-Stubs, 338242 Brett-/Kameraprüfungen plus Landschaftsregressionen); `test-tutorial.ps1` OK (168); `test-levelgen.ps1` OK (19000 Level-/5000 Optionsprüfungen, 96 Landschaftskombinationen, 2400 Boss-/Minibosskarten). Alle Exit 0; Rojo-Build OK. Finale Sibling-Kampfszenenprobe in einem nur im Play-Modus geklonten BattleScene-Modul mit deaktivierter Intro-Einblendung: GroupTransparency exakt 0, keine Hintergrundschrift, abgerundete KP-Spuren und Trennlinien sichtbar. Damit ist die Angabe unter Schritt 5 bestätigt; die vorherige Live-Aufnahme lag noch in der Einblendung. Devlog #41 ergänzt, unabhängiges Claude-Review und Nutzer-/Handytests bleiben offen; manuelle Nutzer-Checkboxen bewusst nicht abgehakt. Studio abschließend Edit bestätigt. Keine Veröffentlichung durch Codex.
