# PLAN: Flüssiger Missionsstart (Ladebildschirm + schnellerer Aufbau)

Ziel: Nach „Mission starten" verschwindet die Weltkarte **sofort**, ein Ladebildschirm überbrückt die Wartezeit und verschwindet erst, wenn Brett und Terrain wirklich da sind. Der Aufbau selbst wird deutlich schneller und ruckelt weniger.
Branch: `feature/ladezeit` – abzweigen von `feature/mobile-lesbarkeit`
Kontext: Nutzer-Test: „Wenn man von der Weltkarte zu einem Level geht ruckelt es und es dauert etwas bis das Level geladen ist, es kann auch vorkommen, dass der Auswahlbildschirm auf dem Bildschirm bleibt, bevor das Level lädt."
Ursachen (Claude-Analyse):
- `Main.server.luau` `StartStage` → `setupStage` → `BoardBuilder.build(region)` füllt das Terrain **zweimal** (`fillTerrain({})`, Raycast-Kalibrierung, Bereich leeren, `fillTerrain(sink)`), über einen großen Bereich (`Config.FEEL.environmentMargin = 100` je Seite, 32 Studs hoch). Alle Voxel werden repliziert → Server-Hänger + Ruckeln beim Client.
- Jede Einheit wird über `ChibiBuilder.build` Teil für Teil neu erzeugt (~100–150 Parts) und danach skaliert.
- Der Client schließt die Lobby erst über `MenuUI.update` beim nächsten State – kommt der erst nach dem Aufbau, bleibt die Weltkarte stehen.

**Allgemein**
- Spielregeln, Kartendaten, Profil unverändert. Werte in `Config.FEEL`. Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt.

## Schritte

- [x] 1. **Messen** – Datei: `src/server/Main.server.luau` (`setupStage`)
  - Mit `os.clock()` die Dauer von `BoardBuilder.build` und vom Erstellen der Einheiten messen und einmal pro Start ausgeben: `print(("Missionsaufbau %s: Brett %.0f ms, Figuren %.0f ms"):format(stageId, ...))`. Gleiches für den Aufbau bei `BeginBattle` (Helden), falls dort Figuren entstehen.
  - Fertig, wenn: die Zeile erscheint bei jedem Start im Output.

- [x] 2. **Ladebildschirm** – Dateien: `src/client/UI.luau` (oder `MenuUI.luau`, wo es besser passt), `src/client/Main.client.luau` (`onStart` ~Zeile 846 und alle Wege, die `StartStage`/`Retry`/nächste Mission senden), `src/shared/Config.luau`
  - `UI.showLoading(title, subtitle)` / `UI.hideLoading()`: Vollbild-Panel über allem (UIKit-Theme, dunkler Verlauf), Missionsname in Titel-Schrift, Gebietsname darunter, sanft pulsierender Text „Karte wird vorbereitet …". Ein-/Ausblenden mit `Config.FEEL.loadingFade` (0.25 s).
  - Beim Senden von `StartStage` (Weltkarte, „Nächste Mission" im Ergebnis-Fenster) und `Retry`: **sofort** `MenuUI.closeLobby()` + Ergebnis-Fenster schließen + `UI.showLoading(...)`.
  - Ausblenden erst, wenn alles bereit ist – per `RunService.Heartbeat` prüfen (max. `Config.FEEL.loadingTimeout` = 15 s):
    1. State ist `mode == "Battle"` mit der angeforderten `stageId` und gehört diesem Spieler,
    2. `workspace.Board` existiert und enthält `Grid.width() * Grid.height()` Felder (`Tile_x_y`),
    3. ein Raycast (nur `workspace.Terrain`) senkrecht über der Kartenmitte trifft Terrain (Voxel sind beim Client angekommen),
    4. alle Einheiten aus dem State haben ein Modell in `workspace.Units`.
  - Lehnt der Server ab (kein passender State binnen Timeout oder State bleibt `Lobby`): Ladebildschirm ausblenden, Lobby wieder öffnen, `UI.toast("Mission konnte nicht gestartet werden")`.
  - Fertig, wenn: Weltkarte verschwindet beim Klick sofort; keine halb aufgebaute Karte sichtbar; bei Fehlern kommt man zurück zur Weltkarte.

- [x] 3. **Terrain nur einmal füllen** – Dateien: `src/server/BoardBuilder.luau`, `src/shared/Config.luau`
  - Kalibrierwerte je Terrain-Zeichen in einer modulweiten Tabelle `sinkCache` speichern. Beim Aufbau nur die Zeichen der aktuellen Karte messen, die **noch nicht** im Cache sind; sind alle bekannt, direkt `fillTerrain(sinkCache)` (eine Füllung, keine Raycasts, kein zweites Leeren). Ausgabe „Terrain-Kalibrierung" nur bei neuen Messungen.
  - Gleiche Karte + gleiches Gebiet wie beim letzten Aufbau (z. B. `Retry`): Terrain **nicht** neu füllen, nur `Board`-Folder (Parts/Deko) neu bauen. Schlüssel: `table.concat(map, "|") .. regionId`. Achtung: Pfützen/Wasser aus `decorate` liegen im Terrain – beim Überspringen nicht doppelt anlegen.
  - `Config.FEEL.environmentMargin` von 100 auf **60** senken; prüfen (rechnerisch aus `CameraController`: Zoom max 140, Blickwinkel, `clampFocus`-Grenzen), dass bei maximalem Herauszoomen kein Rand der Umgebung sichtbar wird – sonst den kleinsten passenden Wert nehmen und in den Notizen festhalten. Randbäume (`environmentCount`) auf den kleineren Rand verteilen.
  - Fertig, wenn: zweiter Start einer Mission ohne Kalibrier-Raycasts; Retry baut kein Terrain neu; Messwerte aus Schritt 1 sinken.

- [x] 4. **Figuren aus Vorlagen klonen** – Datei: `src/shared/ChibiBuilder.luau`
  - Modulweiter Cache `templates[key]`, Schlüssel aus allem, was das Aussehen bestimmt: `heroId or class`, `team`, `weapon`, `rarity`, `isLord`. Beim ersten Aufruf bauen (bisheriger Code) und unparented als Vorlage ablegen; jeder Aufruf gibt `template:Clone()` zurück und setzt `Name = unit.id` (Attribute wie `UnitId`/`Team` setzt weiterhin `UnitVisuals`).
  - Sicherstellen, dass nichts Einheiten-Spezifisches in der Vorlage landet und dass `HeroTemplates`/Porträts weiter funktionieren.
  - Fertig, wenn: gleiche Gegner (z. B. mehrere Banditen) werden geklont statt neu gebaut; Aussehen unverändert.

- [x] 5. `scripts/check.ps1` = `OK`; `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [x] 6. Devlog-Eintrag #17 „Flüssiger Missionsstart" (Teststatus „ungetestet"), Branch pushen, dann `.handoff/status` = `fertig`.

## Manueller Test (Nutzer, PC + Handy)
- [ ] Weltkarte → Mission starten: Weltkarte verschwindet **sofort**, Ladebildschirm mit Missionsname erscheint
- [ ] Ladebildschirm verschwindet erst, wenn Brett, Gelände und Figuren vollständig da sind; kein Ruckeln/halbes Brett sichtbar
- [ ] Zweiter Start derselben oder einer anderen Mission spürbar schneller; „Nochmal versuchen" sehr schnell
- [ ] Output: Zeile „Missionsaufbau …" mit Zeiten (bitte an Claude melden); keine roten Zeilen
- [ ] Kartenrand bei maximalem Herauszoomen nicht sichtbar
- [ ] Figuren sehen aus wie vorher (inkl. ★-Effekte, Zug-Ring)

## Nicht anfassen
- Spielregeln (`Combat`, `Grid`-Logik, `EnemyAI`), `Stages`-Kartendaten, `ProfileStore`, Befehlsvalidierung im Server (nur Messung in `setupStage` ergänzen)

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)
- Darf `setupStage` zusätzlich zu den Zeitmessungen `ownerUserId` und `ownerName` aus dem bisherigen State erhalten? Aktuell ersetzt die Funktion den State ohne Besitzerfelder. `StartStage` setzt sie anschließend erneut, `Retry` jedoch nicht. Die in Schritt 2 vorgeschriebene Besitzerprüfung würde deshalb bei jedem Retry bis zum Timeout scheitern; auch die bestehenden Kampfbefehle werden danach wegen des fehlenden Besitzers abgelehnt. Das Erhalten der beiden Felder in `setupStage` lässt die Befehlsvalidierung unverändert, geht aber über „nur Messung in setupStage ergänzen“ hinaus. Bitte diese gezielte Ergänzung freigeben oder den Plan entsprechend anpassen.
  - **Antwort Claude: Ja.** Guter Fund – das ist sogar ein bestehender Fehler (nach `Retry` ist `ownerUserId` leer, dadurch lehnt `Main.server.luau:538` alle Kampfbefehle ab). `setupStage` übernimmt `ownerUserId`/`ownerName` aus dem bisherigen State in den neuen State; `StartStage` setzt sie danach wie bisher. Sonst nichts an der Validierung ändern. In den Notizen und im Devlog als behobenen Fehler vermerken. Weiter umsetzen.

## Notizen (Codex)
- Branch `feature/ladezeit` von `feature/mobile-lesbarkeit` angelegt. Vor der Umsetzung wegen des Widerspruchs zwischen Retry-Besitz und erlaubtem Serverumfang gestoppt; nach Claudes Antwort fortgesetzt.

- Schritt 1: Aufbauzeiten für Brett/Gegner und BeginBattle-Helden ergänzt; Besitzerfelder in setupStage gemäß Antwort erhalten (Retry-Fehler behoben). Check: OK; Output in Studio ungetestet.

- Schritt 2: Vollbild-Ladeoberfläche mit sofort deckendem Hintergrund und 0,25-s-Inhaltsfade, pulsierendem Text und Heartbeat-Bereitschaftsprüfung. Aufstellung/Ergebnis während des Ladens unterdrückt; Retry verlangt einen neuen State ohne altes Ergebnis. Timeout nach akzeptiertem Start sendet ToLobby, damit die Weltkarte wieder bedienbar ist. Check: OK; Darstellung/Replikation in Studio ungetestet.

- Schritt 3: Zeichenweise Kalibrierung im sinkCache; bekannte Kartenzeichen benötigen nur die endgültige Füllung. Gleiche Karte + Gebiet überspringt Terrain einschließlich S-Pfützen; Board/Part-Deko wird weiterhin erneuert. Lokaler Test mit originalen Modulen und API-Stubs: neue Zeichen, Karten-/Gebietswechsel, alle fünf Missions-Retries; kleines Testbrett kalt 23, warm 13, Retry 0 Terrain-Schreibaufrufe. Check: OK. Tatsächliche Zeitersparnis/Replikation in Studio ungetestet.
- Abweichung Umgebungsrand (im Plan erlaubter Ersatzwert): 60 Studs reichen rechnerisch nicht; auch 100 reichen nicht. CameraController: Offset (0, 112, 84) bei Zoom 140, Fokus bis zum Brettrand, beliebiges yaw, unveränderter Roblox-Standard mit vertikalem FOV 70°. Bei t = tan(35°), Seitenverhältnis a und Bodenhöhe g liegt die fernste Ecke bei x = (112 - g) * a * t / (0,8 - 0,6*t), z = 84 - (112 - g) * (0,6 + 0,8*t) / (0,8 - 0,6*t). Freie Drehung benötigt mindestens sqrt(x² + z²) Rand. 16:9/g=0: 448,65; 20:9/g=0: 526,36; konservativ bis 21:9/g=-terrainDepth=-12: 609,32 Studs. Gewählt: 612 (nächster 4-Stud-Voxelwert), Randdeko proportional verteilt. Annahme: Displays bis 21:9, Standard-FOV; noch breitere Displays/höheres FOV sind nicht abgedeckt. Quelle zum Standard-FOV: https://create.roblox.com/docs/reference/engine/classes/Camera. Der größere Rand verteuert den Erstaufbau und reicht räumlich unter den Hub; Auswirkungen auf Zeit/Replikation und Darstellung müssen Nutzer/Claude prüfen. Keine Kamera-/Hub-/Spielregeländerung vorgenommen.
- Schritt 4: ChibiBuilder legt unveränderte Geometrie unparented als Vorlage ab; jeder Aufruf liefert einen separaten Klon mit aktueller Unit-ID. Der Schlüssel enthält zusätzlich die Klasse, da diese auch bei heroId Pferd/Augenbrauen/Umhang bestimmt. Lokale API-Stubs bestätigen Wiederverwendung, getrennte Aussehensvarianten und Isolation von Modellmutationen/UnitId/Team; alle Heldenporträts und Gegnertypen gebaut. Check: OK; Aussehen, Skalierung und Animation in Studio ungetestet.

- Schritt 5: Abschlusscheck OK (25 Dateien, Exit 0); Rojo-Build TacticsGame.rbxlx erfolgreich. Lokale Prüfung der originalen Ladefunktionen mit API-Stubs bestätigt neue States, Besitzer/Stage/Schwierigkeit, alte Retry-Ergebnisse, alle Bereitschaftssperren, Doppelklick-Unterdrückung, Lobby-Ablehnung und beide Timeout-Pfade. Die Prüfhilfen bleiben unter .handoff und werden nicht committet.

- Schritt 6: Devlog #17 ergänzt, Nächste Schritte aktualisiert. Abschluss auf feature/ladezeit; Teststatus in Studio/auf dem Handy ungetestet. Branch wird vor dem abschließenden Signal an Claude gepusht.

- Review-Auftrag `.handoff/auftrag.md`, 06.10.2026, Spielcode-Commit `9b32bfa` (während des Reviews kam der reine CLAUDE.md-Commit `3dd564c` hinzu): **Keine belegten neuen Fehlerbefunde.** Spielcode unverändert; nur dieses Review-Ergebnis wird committet.
- Zug-Ringe: `undo()` ersetzt sämtliche Modelle; Missionsaufbau und Lobby verwenden `clearUnits()` / `UnitVisuals.remove(..., true)`. Der neue Ancestry-Handler zerstört den jeweiligen Ring beim Verlassen von `unitsFolder` und trennt seine Verbindung. Lokaler Test der originalen `turnRing`-Funktion mit API-Stubs: Entfernen ohne `Destroying`, neues Modell mit gleicher ID, Teamfarben, Verbergen bei `Done`/gefallen sowie 200 Modellwechsel ohne verbliebene Ringe oder Verbindungen bestanden. Die Segmentzahl bleibt 24; die breitere Geometrie erzeugt keine zusätzlichen Parts. Tatsächliche Replikation und sichtbare Ringbreite in Studio ungetestet. API-Abgleich: [AncestryChanged](https://create.roblox.com/docs/reference/engine/classes/Instance#AncestryChanged), [verzögerte Ereignisse und Disconnect](https://create.roblox.com/docs/scripting/events/deferred).
- Touch: Aktuelle Original-Handler mit API-Stubs geprüft: Tippen/Maus, Ziehen, Pinch, Drehschwelle/Winkelgrenze, UI-Touches, Cancel ohne Klick, beide Reihenfolgen von `InputEnded`/`TouchEnded` vor dem defer-Aufruf ohne Doppelverarbeitung, fünf Finger zurück auf einen und drei zurück auf zwei, `TouchEnded` ohne `InputEnded`, Entfernung alter End/Cancel-Touches beim nächsten Begin. Alles bestanden. Neue Bereinigung läuft nur bei Ereignissen, nicht pro Renderframe; Aufwand linear in der Zahl gespeicherter Touches, zusätzlich ein defer-Aufruf je `TouchEnded`. Geräte-Leistung ungemessen.
- Verbleibende Prüfgrenzen (keine auf dem Gerät bestätigten neuen Fehler): Wechseln Touches auf End/Cancel und fehlen **beide** Ende-Signale, räumt erst der nächste Aufruf von `resetTouchBasis` auf; ein noch aufgelegter Finger kann bis dahin blockiert bleiben. Kommt `InputEnded` erst **nach** dem defer-Aufruf, ist der Touch bereits gelöscht und der Tipp entfällt. Beide Grenzen sind mit Stubs reproduziert; ob diese Abläufe das gemeldete Handflächenproblem auf dem Handy verursachen, ist offen. [TouchEnded/InputEnded](https://create.roblox.com/docs/reference/engine/classes/UserInputService) sind bei fehlendem Fensterfokus nicht garantiert; [task.defer](https://create.roblox.com/docs/reference/engine/libraries/task#defer) wartet nur bis zum Ende des aktuellen Wiederaufnahmezyklus. Der Kommentar zur Ereignisreihenfolge ist daher kein Nachweis für alle Gerätefälle. Manueller Test: ganze Hand auflegen/abheben, danach Tippen, Ziehen und Pinch; zusätzlich App-Wechsel mit aufgelegten Fingern und Rückkehr.
- Review-Validierung: `scripts/check.ps1` **OK**, 25 Dateien, Exit 0. Lokale Prüfhilfen `.handoff/review-9b32bfa-touch.luau` und `.handoff/review-9b32bfa-ring.luau` bleiben uncommittet. Rückblende, Missionswechsel, Lobby und Touch-Abbrüche in Roblox Studio/auf dem Handy **ungetestet**. Kein neuer Umsetzungsplan abgeschlossen; Devlog unverändert.

### Review 2026-10-06: Zug-Ringe und Touch-Abbrüche

- Auftrag aus `.handoff/auftrag.md`: Spielcode unverändert lassen, Review dokumentieren. Prüfgegenstand ist `9b32bfa` (`fix: Verwaiste Zug-Ringe entfernen, Ring dicker, Touch-Abbrüche aufräumen`). HEAD bei Beginn war `3dd564c`, eine anschließende Änderung nur an `CLAUDE.md`; daher den im Auftrag ausdrücklich beschriebenen Fix geprüft.
- **Befunde nach Schwere: keine gesicherten Befunde.** Die folgenden Prüfgrenzen sind keine auf einem Gerät bestätigten Fehler.
- **Touch:** Aktuelle Original-Handler mit API-Stubs ausgeführt: Tippen genau einmal, beide Reihenfolgen von `InputEnded`/`TouchEnded` innerhalb desselben Ausführungszyklus, wiederholtes Ende ohne Doppelverarbeitung, Cancel ohne Klick, UI-Touches, Maus, Ziehen/Pinch/Drehschwelle, Fingerwechsel und Zehnfinger-Abbruch. Fehlendes `InputEnded` wird durch den verzögerten Fallback aufgeräumt; fehlen beide Ende-Ereignisse, entfernt der nächste Touch alte End-/Cancel-Einträge. Anschließend funktionieren Ziehen und neue Taps wieder. `resetTouchBasis` zählt verbleibende Touches neu und setzt die Gestenbasis zurück; kein zusätzlicher Aufwand pro Render-Frame.
- **Touch-Prüfgrenze (`src/client/Main.client.luau:617–624`):** Die Behauptung im Kommentar, `InputEnded` komme durch `task.defer` zuerst, ist nur für Ereignisse innerhalb desselben Ausführungszyklus durch die Simulation abgedeckt. Laut [Roblox-Dokumentation zu task.defer](https://create.roblox.com/docs/reference/engine/libraries/task#defer) wird die Funktion am Ende des aktuellen Zyklus ausgeführt; die [TouchEnded-Dokumentation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/UserInputService.yaml) garantiert keine Reihenfolge gegenüber `InputEnded`. Die künstliche Folge `TouchEnded → defer ausführen → InputEnded` verliert den Tap, weil der Fallback den Eintrag bereits gelöscht hat. Ob Roblox diese Folge im Spiel tatsächlich liefert, ist unbestätigt. Im Studio/auf dem Handy insbesondere schnelle Taps und Mehrfinger-Abbrüche prüfen. Die Aufräumlogik setzt außerdem voraus, dass ein verlorener Touch wenigstens End/Cancel annimmt oder `TouchEnded` liefert.
- **Zug-Ringe:** Aktuelle Originalfunktion mit API-Stubs geprüft: einmalige Erstellung mit 24 Segmenten, Breite 0,3 und Teamfarbe; Done/gefallene Modelle verbergen den Ring; Entfernen aus `Units` zerstört ihn einmal und trennt die Verbindung. 100 simulierte Modellwechsel mit derselben Unit-ID hinterlassen keine Ringe. Serverpfade für Rückblende (`undo`), Missionsstart/Retry (`setupStage`/`clearUnits`) und Lobby (`ToLobby`/`clearUnits`) entfernen die alten Modelle; `Units` selbst bleibt bestehen. [AncestryChanged](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Instance.yaml) meldet Änderungen der Elternhierarchie. Die Änderung fügt weder Segmente noch Verbindungen pro Frame hinzu; tatsächliche Replikation, Darstellung und Leistung auf dem Handy sind ungetestet.
- **Validierung:** `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` = OK, 25 Dateien, Exit 0. Lokale Prüfhilfen `.handoff/review-input-test.luau` und `.handoff/review-ring-test.luau` grün und durch Git ignoriert; sie simulieren keine Roblox-Engine. Kein Studio-/Gerätetest, kein Spielcode geändert. Nur `PLAN.md` wird committet und gepusht; anschließend Abschluss-Signal gemäß Auftrag.
