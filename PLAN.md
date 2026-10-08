# PLAN: Phase 2 Feinschliff – Tutorial-Lesbarkeit, PC-Textgröße, Level-Up wegtippen

Ziel: Vier Wünsche des Nutzers nach dem Tutorial-Test (09.10.2026) umsetzen. Tutorial selbst funktioniert (Willkommensfenster, beide Missionen, 150 Gold).
Branch: `feature/lauf-phase2` (weiter)

**Nutzerwünsche:**
1. „Die Tutorialnachrichten in den Missionen können etwas größer sein.“
2. „Die Felder, auf die man sich bewegen soll, können komplett gelb gefärbt werden, damit man es besser erkennt.“
3. „Der Text im Thronsaal ist auf PC ziemlich klein – kann man den nur auf PC etwas vergrößern?“ (Screenshot PC ~1590×660 Fenster: Thronsaal-Kopf „Thronsaal / 150 Gold / 300 Edelsteine“ und Bedienhinweis unten sehr klein.)
4. „Level-Up-Nachrichten von Helden durch Tippen sofort wegklicken, sonst bleiben sie immer ein paar Sekunden.“

**Bestehender Code:** `src/client/TutorialGuide.luau` (Markierung `marker` als Part, `ui.setTutorialMark`), `src/client/UI.luau` (Hinweis-Kasten, `UI.showLevelUp` ab Zeile ~707), `src/client/UIKit.luau` (`createRoot`, Skalierung `math.min(available.X / 1280, available.Y / 720, maximumScale or 1.15)` ~543), `src/client/MenuUI.luau` (Thronsaal-HUD/-Menü), `src/client/Main.client.luau` (Ablauf Kampf-Ereignisse, wartet ggf. auf Level-Up).

## Schritte

- [x] 1. **Tutorial-Texte größer** – Tutorial-Hinweis deutlich größer (Richtwert Schrift ~1,4× der bisherigen Hinweisgröße, Kasten wächst mit, Umbruch erlaubt), gut lesbar auf Handy und PC; kein Überdecken der Spielfläche über das Nötige hinaus (Position so, dass Ziel-Feld/Figur sichtbar bleibt). Werte in Config (WIP).

- [x] 2. **Ziel-Felder komplett gelb** – Bewegungsziel im Tutorial als **vollflächig gelb gefülltes Feld** (deckend bzw. kaum transparent, kräftiges Gelb, leichtes Pulsieren erlaubt) statt nur Rahmen/Pfeil; liegt über Bewegungs-Overlays, unter Figuren; Klicks treffen weiterhin das Feld (`CanQuery = false`, `CanCollide = false`). Ziel-Figuren/Gegner weiterhin klar markiert (bestehende Markierung oder gelber Ring). Farbe/Transparenz in Config.

- [x] 3. **Größere Oberfläche nur auf PC** – in `UIKit.createRoot` zusätzlicher Faktor für Maus-/Tastatur-Geräte ohne Touch (z. B. `UserInputService.TouchEnabled == false` bzw. `MouseEnabled and not TouchEnabled`), Wert in Config (Richtwert 1,25, WIP); Obergrenze so, dass auf typischen PC-Fenstern (1280×720 bis 1920×1080, auch kleine Studio-Fenster) nichts aus dem Bildschirm läuft oder sich überlappt. Gilt für Thronsaal-HUD, Menüs und Kampf-HUD gleichermaßen (nicht nur Thronsaal-Text). Handy/Tablet unverändert.

- [x] 4. **Level-Up wegtippen** – Level-Up-Fenster schließt sofort bei Tippen/Klick irgendwo auf das Fenster oder den Bildschirm (und Leertaste/Enter am PC); automatisches Schließen nach Zeit bleibt als Rückfall. Wartet der Kampfablauf auf das Ende des Fensters, muss er beim Wegtippen sofort weiterlaufen; der Tipp darf keine Spielaktion auslösen (kein Feld/keine Figur anwählen).

- [x] 5. Abschluss: `scripts/check.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-levelgen.ps1` = OK, Rojo-Build. Devlog-Nachtrag zu #30 (oder #31). Ein Commit pro Schritt, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Tutorial: Hinweise größer und gut lesbar; Zielfeld komplett gelb
- [ ] PC: Thronsaal-Text, Menüs und Kampf-HUD größer, nichts abgeschnitten; Handy unverändert
- [ ] Level-Up-Fenster per Tippen/Klick sofort weg, ohne versehentlich etwas anzuwählen

## Nicht anfassen
- Tutorial-Schrittlogik/Serverprüfung, Lauf, Generator, Brett

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden.)

## Notizen (Codex)
- Schritt 1: Tutorial-Hinweise mit 31 Designpunkten (vorher geführte Schritte 22), Mindesthöhe 92 und automatischem Umbruch/Höhenwachstum. Gilt auch für freie Tutorial-Schritte; links oben bleibt die bisherige schmale Spalte erhalten. Darstellung in Studio/auf Handy noch ungetestet.

- Schritt 2: Bewegungsziel mit voller Feldgröße, kräftigem Gelb und 3 % Transparenz. Dünne Fläche oberhalb von Bewegungsflächen/Cursor; keine Kollision, Touch- oder Raycast-Abfrage. Figuren-/Gegnermarkierungen bleiben erhalten.

- Schritt 3: PC-Faktor 1,25 nur bei MouseEnabled ohne TouchEnabled. Mindestfläche 1184 × 664 Designpunkte schützt die drei oberen HUD-Spalten und das 1000 × 640 große Kasernenfenster mit Randabstand. Deshalb in kleinen/höhenbegrenzten Fenstern weniger als 25 % Vergrößerung (z. B. etwa 8 % bei 1590 × 660); bei 1920 × 1080 bis zu 25 %. Touch-Geräte behalten die bisherige Skalierung.

- Schritt 4: Eigenes Level-Up-ScreenGui mit vollflächiger transparenter Schließtaste über Fenster und Bildschirm. Klick/Tipp schließt sofort; Leertaste/Enter/Nummernblock-Enter im Client ebenfalls. Weltsteuerung während der Meldung gesperrt, begonnene Maus-/Touchgesten verworfen. Alte 3,2-Sekunden-Timer können neue Meldungen nicht schließen. Kein Kampf-Wartepfad im bestehenden Client vorhanden.
- Die Schritt-3-Checkbox/Notiz wird mit Schritt 4 nachgetragen; UTF-8-Übertragung der neuen deutschen Kommentare und Notizen korrigiert.

- Lokale Prüfung: 180 bestehende UI-Anschlüsse, 99 Feinschliff-Prüfungen und 14 bestehende Eingabeprüfungen mit aktuellen Main.client-Callbacks bestanden. Prüfhilfe unter ignoriertem tools/; prüft sichere Flächen/HUD-Abstände/Timer/Schließgesten, ersetzt keine Roblox-Schriftmessung, den Eingaberouter oder Studio-/Handytests.

- Abschluss: Pflichtcheck OK (35 Dateien), Tutorialprüfung OK (168), Generatorprüfung OK (90.000 Level- und 5.000 Optionsprüfungen, 0 Rückfälle, erzwungener Rückfall OK), Rojo-Build erfolgreich. Devlog #31 ergänzt, nächste Schritte aktualisiert. Manuelle Tests und unabhängiger Claude-Review bleiben offen. Abschluss-Commit und Push auf feature/lauf-phase2; danach Handoff-Signal fertig.
