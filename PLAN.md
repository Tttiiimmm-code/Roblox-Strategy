# PLAN: Handy-Kamera, Rüstungsständer, Sumpf lesbar machen

Ziel: (a) Taktik-Kamera am Handy fühlt sich wie eine Karten-App an: ein Finger verschiebt, zwei Finger zoomen (und drehen erst bei deutlicher Drehbewegung), keine Sprünge. (b) Keine schwebenden Blöcke an der Kaserne. (c) Sumpf ist sofort erkennbar, Bewegungskosten sind sichtbar, und gesperrte Felder erklären sich selbst.
Branch: `feature/mobile-lesbarkeit` – abzweigen von `feature/weltkarte`
Kontext: Nutzer-Test am Handy nach Weltkarte (DEVLOG #15):
- „wenn ich mit einem Finger wische" passiert nicht das Erwartete, Zwei-Finger-Zoom „komisch".
- „neben der Kaserne fliegen 2 Blöcke rum".
- „Sumpf ist nicht wirklich zu erkennen, die Felder mit eingeschränkter Bewegung merkt man nicht, schwer zu erkennen, warum man auf manche Felder nicht rauf kann".
Ursachen (Claude-Analyse):
- Im Kampf sind die Roblox-Standard-Touch-Steuerung (Joystick/Sprung) und die Figurensteuerung aktiv → Wischen wird als `processed` geschluckt bzw. bewegt den Avatar.
- `Main.client.luau` Zeilen ~425–481: ein gemeinsames `press.last` für alle Finger → bei zwei Fingern schreiben beide abwechselnd hinein; beim Loslassen eines Fingers springt `panBy`. `CameraController` dreht über `TouchRotate` schon bei minimaler Drehung.
- `HubBuilder.buildBarracks`: `ArmorStand` (Höhe 4, Mitte y 4 → Unterkante y 2) und `ArmorHelm` (y 6.8) schweben über dem Boden (Boden-Oberkante y 0).

**Allgemein**
- Neue Werte in `Config.FEEL`. Maus-Bedienung am PC bleibt exakt wie bisher. Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt. Nur erlaubte Symbole (`★ ◆ ♦ ⚔ ⚠ ⓘ`).

## Schritte

- [x] 1. **Avatar-Steuerung im Kampf aus** – Datei: `src/client/CameraController.luau` (`setActive`)
  - Bei `setActive(true)`: Figurensteuerung deaktivieren (`require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Disable()`) und Touch-Steuerelemente ausblenden (`GuiService.TouchControlsEnabled = false`). Bei `setActive(false)`: beides wieder an. Alles in `pcall` (PlayerModule kann fehlen/umbenannt sein) – bei Fehler einmal `warn`.
  - Fertig, wenn: im Kampf kein Joystick/Sprungknopf sichtbar und Wischen bewegt nie den Avatar; im Thronsaal ist die Steuerung normal.

- [x] 2. **Eigene Touch-Gesten** – Dateien: `src/client/Main.client.luau` (Eingabe ~Zeile 423–481), `src/client/CameraController.luau`, `src/shared/Config.luau`
  - Touches **pro Finger** verfolgen: Tabelle `touches[input] = { start, last }` (Schlüssel = InputObject); `activeTouches` ergibt sich aus der Tabelle. Maus-Pfad (`press` mit `MouseButton1`/`MouseMovement`) unverändert lassen.
  - **1 Finger:** ab `DRAG_THRESHOLD` = Ziehen → `CameraController.panBy(pos - touch.last)` mit **dem eigenen** `last` dieses Fingers. Loslassen ohne Ziehen und ohne dass je ein zweiter Finger dabei war = Tippen → `onClick` wie bisher.
  - **2 Finger:** pro `InputChanged` aus beiden aktuellen Positionen: Abstand → `CameraController.zoomBy(neu / alt)`; Mittelpunkt-Verschiebung → `panBy`; Winkeländerung aufsummieren und erst drehen (`rotateBy`), wenn die Summe seit Gestenbeginn `Config.FEEL.touchRotateThreshold` (Grad, Start 18) überschreitet – danach direkt folgen. Kein Tippen auslösen.
  - Bei jeder Änderung der Fingerzahl (Finger dazu/weg) Basiswerte (Abstand, Mittelpunkt, Winkel, `last` aller Finger) neu setzen → **keine Sprünge**.
  - In `CameraController.start` die Handler für `TouchPinch` und `TouchRotate` entfernen (ersetzt durch Schritt 2). Mausrad-Zoom, Q/E, WASD bleiben.
  - Neue Werte: `Config.FEEL.touchRotateThreshold = 18`, `Config.FEEL.touchPanScale = 1` (Faktor auf `panBy` bei Touch, zum Feintuning).
  - Fertig, wenn: am Handy verschiebt ein Finger die Karte „unter dem Finger", Pinch zoomt ruhig, Drehen nur bei bewusster Drehung, kein Springen beim Absetzen eines Fingers; Tippen wählt weiterhin Einheiten/Felder.

- [x] 3. **Rüstungsständer reparieren** – Datei: `src/server/HubBuilder.luau` (`buildBarracks`)
  - `ArmorStand`/`ArmorHelm` ersetzen durch einen Ständer, der auf dem Boden steht (Oberkante Boden = y 0): Fußplatte (2.4×0.3×2.4, Holz, y 0.15), Stange (0.3×4.6×0.3, Holz, y 2.6), Querholz (2.6×0.3×0.3, y 4.4), Brustpanzer (2×2×1, Metall, y 3.7), Helm (Kugel Ø1.4 Metall, y 5.4) – alle über `part`/`deco` wie bisher an `at(x + 2, …, z + 6)`.
  - Fertig, wenn: nichts schwebt an der Kaserne (alle Teile berühren sich bzw. den Boden).

- [x] 4. **Sumpf sichtbar machen** – Dateien: `src/server/BoardBuilder.luau`, `src/server/Main.server.luau` (~Zeile 162), `src/shared/Stages.luau`, `src/shared/Config.luau`
  - `BoardBuilder.build(regionId)` (optional; Aufruf in `setupStage` mit `stage.region`, Startaufruf ~Zeile 43 ohne). Region-Daten in `Stages.Regions` ergänzen: `surroundMaterial` (greenland `Grass`, swamp `Mud`), `treeColor` (greenland wie bisher `Config.TERRAIN.F.color`, swamp (55,75,45)).
  - Umgebung (äußere Grasschicht und `OuterLeaves`) nutzt diese Werte.
  - Terrain-Farben: `workspace.Terrain:SetMaterialColor(Enum.Material.Mud, Config.FEEL.mudColor)` mit `mudColor = (70,58,38)` (deutlich dunkler/brauner als Gras).
  - `S` (Morast) zusätzlich: je Feld eine **Pfütze** (Terrain `Water`, 3×0.6×3, pseudozufällig versetzt aus x/y, Oberkante knapp über der Morastoberfläche) und 3–4 Schilfhalme mit brauner Kolben-Spitze (kleiner Zylinder 0.25×0.5 oben).
  - Fertig, wenn: Sumpfkarten wirken auf den ersten Blick braun-matschig mit Pfützen und Schilf, klar anders als Grünland.

- [x] 5. **Bewegungskosten anzeigen** – Datei: `src/client/Main.client.luau` (`showRanges` ~Zeile 176, `addOverlay`)
  - **Überholt (Nutzerwunsch, Commit 7d45dc1): Beschriftungen entfernt, Gelände über Aussehen erkennbar.** In `showRanges`: für jedes blaue Bewegungsfeld mit `Grid.moveCost(unit, x, y) >= 2` auf das Overlay eine kleine Beschriftung legen (`SurfaceGui` auf der Oberseite oder `BillboardGui` flach, Text `"×2"`/`"×3"`, dunkle Schrift mit hellem Rand, gut lesbar aus der Taktik-Kamera) **und** das Overlay etwas transparenter zeichnen.
  - **Überholt (7d45dc1).** Für Felder **direkt neben** dem blauen Bereich, die für diese Einheit unpassierbar sind (`Grid.moveCost` = nil, ohne Einheiten-Blockade), ein dezentes graues Overlay mit Beschriftung „X" anzeigen (Config.OVERLAY: neuer Eintrag `Blocked`, grau, Transparenz ~0.55). Gemeinsam mit den anderen Overlays aufräumen.
  - Fertig, wenn: bei ausgewählter Einheit sieht man auf einen Blick, welche Felder doppelt/dreifach kosten und welche angrenzenden Felder gesperrt sind.

- [x] 6. **Gesperrte Felder erklären** – Dateien: `src/client/Main.client.luau` (`onClick` ~Zeile 355–380), `src/client/UI.luau` (`UI.showTerrain` ~Zeile 507)
  - Tippt/klickt man bei ausgewählter eigener Einheit auf ein nicht erreichbares Feld: kurzer `UI.toast` mit Grund, z. B. „Tiefer Morast – für Fußtruppen unpassierbar", „Wasser – nicht betretbar", „Zu weit – Bewegung reicht nicht", „Feld besetzt". Reihenfolge der Prüfung: besetzt → unpassierbar (`Grid.moveCost` nil) → zu weit. Bestehendes Verhalten (Abwählen o. Ä.) danach unverändert.
  - Terrain-Panel (`UI.showTerrain`): zweite Zeile um Bewegungskosten ergänzen: „Bewegung: Fuß 2 · Pferd 3" bzw. „Fuß –" für unpassierbar (aus `terrain.cost`, Namen `foot` = Fuß, `horse` = Pferd).
  - Fertig, wenn: man nie rätselt, warum ein Feld nicht geht.

- [x] 7. `scripts/check.ps1` = `OK`; `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [x] 8. Devlog-Eintrag #16 „Handy-Kamera + Sumpf-Lesbarkeit“ (Teststatus „ungetestet“), Branch pushen, dann `.handoff/status` = `fertig`.

## Manueller Test (Nutzer, vor allem Handy)
- [ ] Kampf am Handy: kein Joystick/Sprungknopf; ein Finger verschiebt die Karte flüssig; zwei Finger zoomen ohne Ruckeln; Drehen nur bei deutlicher Drehbewegung; Finger absetzen → kein Springen; Tippen wählt Einheit/Feld
- [ ] Zurück im Thronsaal: Joystick wieder da, Avatar steuerbar
- [ ] PC: Maus-Ziehen, Mausrad, Q/E, WASD wie vorher
- [ ] Kaserne: Rüstungsständer steht auf dem Boden, nichts schwebt
- [ ] Sumpfkarten: braun-matschig, Pfützen, Schilf, dunklere Bäume; klar anders als Grünland
- [ ] Sumpfkarten ohne Beschriftung lesbar: Morast = brauner Schlamm mit Pfützen/Schilf, Tiefer Morast = trüber Tümpel mit Seerosen, Umgebung dunkles Gras
- [ ] Tippen auf Tiefen Morast/Wasser/zu weit/besetzt → Hinweis mit Grund; Terrain-Panel zeigt „Bewegung: Fuß 2 · Pferd 3"
- [ ] Output ohne rote Zeilen

## Nicht anfassen
- Spielregeln/Formeln (`Combat.luau`, `Grid.reachable`/`moveCost`-Logik), `EnemyAI.luau`, `Stages`-Kartendaten/Freischaltung, `ProfileStore.luau`, Server-Befehlsvalidierung

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)

## Notizen (Codex)
- Umsetzung auf `feature/mobile-lesbarkeit`, abgezweigt von `feature/weltkarte`; ein Commit je Schritt. Pflichtcheck nach jedem Schritt grün (25 Dateien); Rojo-Build erfolgreich. Studio-/Handy-Test ungetestet, Claude-Review ausstehend.
- PlayerModule-Lookup mit fünf Sekunden Timeout; Figuren- und Touch-Steuerung in getrennten pcalls, damit ein Fehler nicht das andere Umschalten verhindert. Höchstens eine Warnung.
- UI-begonnene Touches werden mitgezählt, lösen aber keine Kamerageste aus. Fingerwechsel setzt Gestenbasis zurück; Rotation beginnt ohne Nachholen des Schwellenwinkels. Lokale Prüfung der originalen Handler mit API-Stubs erfolgreich; Prüfhilfe unter `.handoff` uncommittet.
- Zusätzliche Darstellungswerte zentral in Config.FEEL. Pfützen sitzen nach der Kalibrierung an der lokal gemessenen Terrain-Oberfläche. Graue Sperrmarkierungen ersetzen dort rote Overlays, damit das X erkennbar bleibt.
- Terrain-Panel für drei Zeilen vergrößert und am Handy bei einer ausgewählten Einheit sichtbar gehalten, da dort kein Maus-Hover vorhanden ist.

### Review von Claudes Commit `7d45dc1`

- **P3 (niedrig) – Aktuelle Akzeptanzkriterien und Testliste erwarten entfernte Overlays.** `PLAN.md:43–46` (Schritt 5), `PLAN.md:62` (manueller Test) und die bisherige Overlay-Notiz beschreiben weiterhin ×2/×3-Beschriftungen und graue X-Sperrmarkierungen. `src/client/Main.client.luau:178–187` erzeugt nach diesem Commit bewusst nur noch Bewegungs-/Angriffsflächen. Damit ist der aktuelle Testpunkt nicht mehr erfüllbar und führt zu einer falschen Fehlermeldung beim Nutzertest. Kriterien/Testpunkt an die neue Darstellung anpassen und die bisherige Notiz als überholt kennzeichnen. Der historische Devlog-Eintrag muss dafür nicht umgeschrieben werden. Im Rahmen dieses Reviews keine Korrektur vorgenommen.
- **Keine funktionalen Code-Befunde in den geprüften Bereichen.** Repo-Suche: keine verbliebenen Verweise auf `addOverlayLabel`, `costOverlayTransparency`, `blockedOverlayTransparency` oder `Config.OVERLAY.Blocked` in `src`; auch der nicht mehr benötigte UIKit-Import wurde entfernt. Die übrigen Overlays werden weiterhin über `clearList(overlays)` zerstört; Terrain-Panel und Unpassierbarkeits-Hinweise bleiben erhalten.
- **Gebietswechsel/Start:** `BoardBuilder.build` setzt Grass und WaterColor bei jedem Aufruf (`src/server/BoardBuilder.luau:124–127`). Sumpf verwendet seine Regionsfarben; Grünland und der Start ohne Region verwenden ausdrücklich `Config.FEEL.grassColor`/`waterColor`, sodass beim Wechsel Sumpf → Grünland keine Sumpffarbe hängen bleibt. `Stages.getRegion(nil)` liefert nil; der Startaufruf (`Main.server.luau:42–44`) baut die erste Grünlandkarte. Bei `ToLobby` wird das Brett samt Farben beibehalten; der Hub besteht aus Parts und verwendet kein Terrain. In der aktuellen Architektur gibt es ein gemeinsames Brett, keine gleichzeitig separat eingefärbten Gebiete.
- **Seerosen/Reihenfolge:** Wasser für D-Felder wird innerhalb von `fillTerrain` angelegt (`BoardBuilder.luau:153`). Auf die erste Füllung und Oberflächen-Kalibrierung folgen Löschen und die finale Füllung (`:164–185`); erst danach ruft die Feldschleife `decorate` auf (`:208`). Dessen Raycast (`:60–65`) filtert ausschließlich Terrain; unsichtbare Klickflächen und Deko können ihn nicht verdecken. `IgnoreWater` ist standardmäßig false ([Roblox-API-Dokumentation](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/WorldRoot.yaml)); die fehlende explizite Zuweisung ist daher kein Fehler. Die Zylinder werden um 90° flach gedreht, ihre Unterkante liegt auf der gemessenen Höhe. Die tatsächliche Wasseroberfläche an den versetzten Seerosen und deren Sichtbarkeit sind noch in Studio zu prüfen.
- **Prüfung:** `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` → `OK`, 25 Dateien (Syntax + undefinierte Variablen), Exit 0. Nur statischer Review; Studio-/Handy-Test ungetestet. Ausschließlich Review-Notizen in PLAN.md ergänzt, kein Spielcode geändert.
