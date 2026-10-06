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

- [ ] 2. **Ladebildschirm** – Dateien: `src/client/UI.luau` (oder `MenuUI.luau`, wo es besser passt), `src/client/Main.client.luau` (`onStart` ~Zeile 846 und alle Wege, die `StartStage`/`Retry`/nächste Mission senden), `src/shared/Config.luau`
  - `UI.showLoading(title, subtitle)` / `UI.hideLoading()`: Vollbild-Panel über allem (UIKit-Theme, dunkler Verlauf), Missionsname in Titel-Schrift, Gebietsname darunter, sanft pulsierender Text „Karte wird vorbereitet …". Ein-/Ausblenden mit `Config.FEEL.loadingFade` (0.25 s).
  - Beim Senden von `StartStage` (Weltkarte, „Nächste Mission" im Ergebnis-Fenster) und `Retry`: **sofort** `MenuUI.closeLobby()` + Ergebnis-Fenster schließen + `UI.showLoading(...)`.
  - Ausblenden erst, wenn alles bereit ist – per `RunService.Heartbeat` prüfen (max. `Config.FEEL.loadingTimeout` = 15 s):
    1. State ist `mode == "Battle"` mit der angeforderten `stageId` und gehört diesem Spieler,
    2. `workspace.Board` existiert und enthält `Grid.width() * Grid.height()` Felder (`Tile_x_y`),
    3. ein Raycast (nur `workspace.Terrain`) senkrecht über der Kartenmitte trifft Terrain (Voxel sind beim Client angekommen),
    4. alle Einheiten aus dem State haben ein Modell in `workspace.Units`.
  - Lehnt der Server ab (kein passender State binnen Timeout oder State bleibt `Lobby`): Ladebildschirm ausblenden, Lobby wieder öffnen, `UI.toast("Mission konnte nicht gestartet werden")`.
  - Fertig, wenn: Weltkarte verschwindet beim Klick sofort; keine halb aufgebaute Karte sichtbar; bei Fehlern kommt man zurück zur Weltkarte.

- [ ] 3. **Terrain nur einmal füllen** – Dateien: `src/server/BoardBuilder.luau`, `src/shared/Config.luau`
  - Kalibrierwerte je Terrain-Zeichen in einer modulweiten Tabelle `sinkCache` speichern. Beim Aufbau nur die Zeichen der aktuellen Karte messen, die **noch nicht** im Cache sind; sind alle bekannt, direkt `fillTerrain(sinkCache)` (eine Füllung, keine Raycasts, kein zweites Leeren). Ausgabe „Terrain-Kalibrierung" nur bei neuen Messungen.
  - Gleiche Karte + gleiches Gebiet wie beim letzten Aufbau (z. B. `Retry`): Terrain **nicht** neu füllen, nur `Board`-Folder (Parts/Deko) neu bauen. Schlüssel: `table.concat(map, "|") .. regionId`. Achtung: Pfützen/Wasser aus `decorate` liegen im Terrain – beim Überspringen nicht doppelt anlegen.
  - `Config.FEEL.environmentMargin` von 100 auf **60** senken; prüfen (rechnerisch aus `CameraController`: Zoom max 140, Blickwinkel, `clampFocus`-Grenzen), dass bei maximalem Herauszoomen kein Rand der Umgebung sichtbar wird – sonst den kleinsten passenden Wert nehmen und in den Notizen festhalten. Randbäume (`environmentCount`) auf den kleineren Rand verteilen.
  - Fertig, wenn: zweiter Start einer Mission ohne Kalibrier-Raycasts; Retry baut kein Terrain neu; Messwerte aus Schritt 1 sinken.

- [ ] 4. **Figuren aus Vorlagen klonen** – Datei: `src/shared/ChibiBuilder.luau`
  - Modulweiter Cache `templates[key]`, Schlüssel aus allem, was das Aussehen bestimmt: `heroId or class`, `team`, `weapon`, `rarity`, `isLord`. Beim ersten Aufruf bauen (bisheriger Code) und unparented als Vorlage ablegen; jeder Aufruf gibt `template:Clone()` zurück und setzt `Name = unit.id` (Attribute wie `UnitId`/`Team` setzt weiterhin `UnitVisuals`).
  - Sicherstellen, dass nichts Einheiten-Spezifisches in der Vorlage landet und dass `HeroTemplates`/Porträts weiter funktionieren.
  - Fertig, wenn: gleiche Gegner (z. B. mehrere Banditen) werden geklont statt neu gebaut; Aussehen unverändert.

- [ ] 5. `scripts/check.ps1` = `OK`; `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [ ] 6. Devlog-Eintrag #17 „Flüssiger Missionsstart" (Teststatus „ungetestet"), Branch pushen, dann `.handoff/status` = `fertig`.

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
- Branch `feature/ladezeit` von `feature/mobile-lesbarkeit` angelegt. Vor der Umsetzung wegen des Widerspruchs zwischen Retry-Besitz und erlaubtem Serverumfang gestoppt; noch keine Codeänderungen.

- Schritt 1: Aufbauzeiten für Brett/Gegner und BeginBattle-Helden ergänzt; Besitzerfelder in setupStage gemäß Antwort erhalten (Retry-Fehler behoben). Check: OK; Output in Studio ungetestet.
