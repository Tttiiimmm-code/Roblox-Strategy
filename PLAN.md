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

- [ ] 2. **Kein Wachsen bei `AutomaticSize`** – `UIKit.panel`, ggf. `UI.luau` (`GelaendeKasten`)
  - Schatten und andere Deko dürfen die automatische Größe nicht beeinflussen (z. B. bei `AutomaticSize` keinen versetzten Schatten als direktes Kind, oder Schatten so anlegen, dass er nicht mitzählt).
  - Akzeptanz: `GelaendeKasten.AbsoluteSize.Y` passt zum Inhalt (Richtwert ≤ 100 px bei drei Zeilen) und bleibt nach mehrmaligem Ein-/Ausblenden gleich (in den Notizen Messwerte nennen). Bild: Kampf mit ausgewähltem Feld.

- [ ] 3. **Kronjuwel nur auf großen Fenstern, Vorschau ohne Überlappung** – `UIKit.panel` und Aufrufer
  - Standard umdrehen: `Jewel` ist **aus**, außer ausdrücklich `Jewel = true`. Einschalten nur für große, eigenständige Fenster: Willkommen/Lobby-Hauptfenster und Lager-Dialog (`MenuUI`, `RunUI` `RunWindow` und Dialog), Rekrutierung/Kaserne-Hauptfenster, „Neue Verbündete“, „Wahrscheinlichkeiten“, Level-Up, Ladebildschirm-Karte. **Kein** Juwel auf: Phasenbanner, Einheiten-Info, Geländefenster, Aktionsmenü, Kampfvorschau, Toast, Pillen, Helden-Feldern im Lauf, Kampfszenen-Fenstern. Liste der tatsächlich gesetzten Stellen in den Notizen.
  - Kampfvorschau so weit nach unten setzen, dass sie das Phasenbanner nicht berührt (mindestens 8 px Abstand inklusive Rand).
  - Akzeptanz: Kampfbild mit Auswahl + Aktionsmenü + Kampfvorschau: höchstens ein Juwel sichtbar, keine Überlappung.

- [ ] 4. **Reste angleichen** – `UIKit.THEME`, `CollectionUI`, `BattleScene`
  - Beschwörungsbanner: Verlauf `holoShade` (#7a4fd6) oben → `panelBottom` unten statt Braun-Gold; Rand wie Fenster (Chrom 3 px + ink außen) statt Gold 2 px; Ecken 24 bleiben. Gold-Chrom-Titel bleibt.
  - Kampfszene-KP-Balken: Spur `panelInset`, Rand 2 px ink, Ecken 6; KP-Trennlinien bleiben.
  - Kaserne-Level-Abzeichen: `panelInset` mit ink-Rand und weißer Schrift; Pink (`holoPink`) bleibt allein „NEU!“ vorbehalten.
  - Kaserne-Auswahl: nicht gewählte Karten behalten 4 px (`METRICS.cardBorder`), gewählte 6 px.
  - Akzeptanz: Bilder Rekrutierung, Kaserne mit gewählter Karte, Kampfszene.

- [ ] 5. **Kontur nach angezeigter Größe** – `UIKit.outline`
  - Dicke nach der tatsächlich dargestellten Textgröße (`TextBounds`/`AbsoluteSize` bzw. aktuelle Größe bei `TextScaled`), mit denselben Stufen (≤ 16 → 1,5; 17–28 → 2; ≥ 32 → 3); bei sehr kleinem Text (< 12) höchstens 1 px. Günstig halten (kein Aktualisieren pro Frame).
  - Akzeptanz: Bild eines herunterskalierten Knopftexts (z. B. „Gegnerphase überspringen“) und der Pillenzahlen; Buchstaben offen und lesbar.

- [ ] 6. **Abschluss** – Tests, Devlog
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

- Schritt 1: Eigene Fensterdeko folgt `f.ZIndex`; Inhaltsobjekte werden mindestens auf `f.ZIndex + 1`, beschriftete TextButtons auf `+2` angehoben, damit ihre Jelly-Fl?chen (`Button.ZIndex - 1`) unter dem Text bleiben. H?here Inhaltswerte bleiben erhalten; neue/umgeh?ngte Inhalte und sp?tere ZIndex-Zuweisungen werden ereignisbasiert erfasst. Standardhintergrund jetzt Transparenz 0: 0,04 lie? dahinterliegende Schrift noch schwach durchscheinen. Alle f?nf geforderten Fenstertypen plus Laufergebnis im echten Ort im Play-Modus bildgepr?ft. Zwei echte Einzelrufe mit jeweils 50 tempor?r erg?nzten Edelsteinen; Bestand danach wieder 3, Ruf-/Verschmelzungsfortschritt gem?? erlaubtem Spielstandtest ge?ndert. Level-Up/Laufergebnis/Ladekarte als UI-Darstellungsfixtures, Laufwahl mit realem Profil. MCP liefert keine lokalen Screenshotdateien; Bilder im Werkzeugergebnis betrachtet. Unabh?ngiges Review bleibt Claude vorbehalten.
