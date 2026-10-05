# PLAN: Game-Feel-Pass 1 – Sound, Licht, Kampfinszenierung, Figuren, UI-Bewegung

Ziel: Das Spiel soll sich lebendig und modern anfühlen: hörbares Feedback, stimmungsvolles Licht, Kämpfe mit Wucht (Kamera, Shake, Zeitlupe), weichere Figurenbewegung und animierte Menüs. Keine Änderung an Spielregeln, Balancing oder Speicherformat.
Branch: `feature/game-feel-1` (von `main`)
Kontext: Nutzer-Feedback „wirkt altbacken, nicht dynamisch" (alle Bereiche). Projektverlauf: `docs/DEVLOG.md` #3 (Animationen), #5 (UI/Tempo), #8 (Thronsaal). Alles ist Grundgerüst – lieber einfach und zentral konfigurierbar als perfekt.

**Allgemein für alle Schritte**
- Neue Einstellwerte (Lautstärken, Shake-Stärke, Zoom, Dauer …) als Tabelle in `src/shared/Config.luau` unter `Config.FEEL = { ... }` sammeln, nicht im Code verstreuen.
- Jede Effekt-Dauer im Kampf über das bestehende Tempo skalieren (`UnitAnimator`: `info()/pause()/later()` nutzen; Server: `pause()`).
- Nach jedem Schritt `scripts/check.ps1` → muss `OK` liefern. Ein Commit pro Schritt (`feat: …`).

## Schritte

- [x] 1. **Sound-System (Grundgerüst)**
  - Neu `src/shared/Sounds.luau`: Tabelle `Sounds.IDS = { musicHub = "", musicBattle = "", musicVictory = "", musicDefeat = "", click = "", hover = "", open = "", close = "", hit = "", crit = "", miss = "", death = "", levelUp = "", phase = "", recruit = "", recruitRare = "", recruitLegendary = "", coin = "", step = "" }` (Strings `"rbxassetid://…"`, **leer lassen** – Nutzer trägt IDs aus der Roblox-Audio-Bibliothek ein) + `Sounds.VOLUME` je Eintrag.
  - Neu `src/client/SoundPlayer.luau`: `play(name, opts)` (einmalig, Pitch-Variation ±5 % optional), `playMusic(name)` mit 1-s-Überblendung zwischen Musikstücken, Lautstärke-Faktor. **Leere ID → still nichts tun, keine Warnung/Fehler.**
  - Einhängen: `UIKit.button` (click bei `Activated`, hover bei `MouseEnter`), Menü öffnen/schließen (`MenuUI.openLobby/closeLobby`), Treffer in `Main.client.luau` im `onImpact`-Callback von `UnitAnimator.playStrike` (hit / crit / miss), Tod (wenn `s.hpAfter == 0`), `UI.showLevelUp` (levelUp), Phasen-Banner in `UI.setPhase` (phase), Ergebnis-Sterne in `MenuUI` (coin pro Stern), Rekrutierungs-Enthüllung in `CollectionUI.showResults` (recruit / recruitRare ab ★4 / recruitLegendary ★5).
  - Musik: Thronsaal → `musicHub`, eigener Kampf → `musicBattle`, Ergebnis → `musicVictory`/`musicDefeat` (Umschalten in `Main.client.luau` `applyState`, dort wo `Hub.setBattleView` aufgerufen wird).
  - Fertig, wenn: alle Stellen rufen `SoundPlayer` auf; mit leeren IDs läuft das Spiel fehlerfrei; Doku-Kommentar in `Sounds.luau`, wie man IDs einträgt.

- [ ] 2. **Licht & Atmosphäre**
  - Neu `src/client/Atmosphere.luau` mit zwei Presets `hall` und `battle`, umgeschaltet in `applyState` (wie Musik). Lokal per Client erzeugen/anpassen: `BloomEffect`, `ColorCorrectionEffect`, `SunRaysEffect`, `Atmosphere`, `DepthOfFieldEffect` (nur `hall`, dezent) in `Lighting`; Übergang per Tween (0,8 s).
    - `hall`: warm, leicht gesättigt, Bloom für Gold/Kerzen; `battle`: klar, kräftigere Farben, leichter Dunst am Horizont.
  - `src/server/HubBuilder.luau`: Staubpartikel im Saal (ein großer unsichtbarer, nicht kollidierender Part mit langsam schwebenden, schwach leuchtenden Partikeln), Kerzen-Lichter in den Kronleuchtern leicht flackern lassen (Attribut `Flicker`, Animation im Client `Hub.luau` wie die bestehenden `Spin`-Objekte), 2–4 hohe Fenster in Ost-/Westwand mit Lichtstrahlen (halbtransparente Neon-Beams, `CanQuery=false`).
  - Schlachtfeld (`src/server/BoardBuilder.luau`): Umgebung statt Leere – großer Grasboden rund um das Brett (tiefer als die Felder), vereinzelte Bäume/Felsen außerhalb der Karte (deterministisch platziert, `CanQuery=false`), damit das Brett nicht im Nichts schwebt.
  - Fertig, wenn: Wechsel Saal ↔ Kampf blendet sichtbar zwischen beiden Stimmungen um; keine Auswirkung auf Klick-Erkennung der Felder.

- [ ] 3. **Kampf-Inszenierung (Kamera & Wucht)**
  - `src/client/CameraController.luau`: neu `shake(strength, duration)` (abklingendes Zittern als Offset auf `camera.CFrame`), `focusOn(position, zoom, duration)` (weiches Hinfahren, merkt sich vorherigen Fokus/Zoom) und `restore(duration)`. Nur wirksam, wenn `active`.
  - `Main.client.luau` / `UnitAnimator.playStrike`: zu Beginn eines Schlagabtauschs Kamera auf den Mittelpunkt beider Kämpfer fokussieren und näher zoomen (`Config.FEEL.battleZoom`), nach dem letzten Schlag `restore`. Beim Treffer `shake` (Krit stärker, Verfehlt keiner).
  - **Hit-Stop:** im Treffer-Moment alle laufenden Kampfanimationen ~0,06 s „einfrieren" (einfachste Umsetzung: `later`-Verzögerung der Rückstoß-Reaktion + kurzer Kamera-Ruck) – Server-Timing (`Config.IMPACT_TIME`) **nicht** verändern.
  - **Krit:** kurzes Weiß-Aufblitzen des Bildschirms (Frame im HUD, Tween der Transparenz) + Zeitlupen-Gefühl durch langsameres Ausklingen des Shakes.
  - **Gegnerphase:** Kamera folgt der jeweils ziehenden gegnerischen Einheit (`focusOn` auf ihr Ziel-Feld beim Bewegungsbeginn). Server sendet dafür ein neues `BattleEvent { enemyMove = { unitId, x, y } }` direkt vor `UnitVisuals.moveAlong` in `runEnemyPhase` (`Main.server.luau`).
  - **Überspringen:** Button „⏩ Gegnerphase" im HUD (`UI.luau`, Werkzeugleiste), der während der Gegnerphase Tempo 3 setzt; `SetSpeed` im Server um `3` erweitern (Zeile mit `cmd.speed == 1 or cmd.speed == 2`), nach der Gegnerphase zurück auf den vorherigen Wert.
  - Fertig, wenn: jeder Angriff zoomt heran und wackelt beim Treffer; Krit wirkt deutlich stärker; Gegnerzüge sind mitzuverfolgen; Gegnerphase lässt sich beschleunigen.

- [ ] 4. **Bewegung & Figuren lebendiger**
  - `src/server/UnitVisuals.luau` `moveAlong`: Pfad als **eine** durchgehende Bewegung (konstante Geschwindigkeit, `EasingStyle.Sine` nur am Anfang/Ende, keine Mini-Stopps an jedem Feld); Drehung zur Laufrichtung weich.
  - `src/client/UnitAnimator.luau`:
    - Staubwölkchen an den Füßen beim Laufen (Partikel-Burst alle ~0,25 s, solange `Moving`).
    - Idle lebendiger: Atmen (leichtes Heben/Senken des Torsos), gelegentliche Zufalls-Geste pro Figur (Umsehen, Waffe heben) alle 6–12 s, nicht synchron.
    - Umhang schwingt nach (falls `Cape` vorhanden: Gelenk/Neigung abhängig von Bewegung).
    - Ausgewählte Einheit: hüpft kurz und bekommt einen leuchtenden Ring am Boden (Client-Effekt, aufgerufen aus `selectUnit` in `Main.client.luau`).
  - `src/shared/CharacterBuilder.luau` (nur Optik, Proportionen der Hitboxen beibehalten): Hände (kleine Hautblöcke), Stiefel, Augen/Gesichts-Decal-Platzhalter (`Config.FEEL.faceTexture`, Standard bleibt `rbxasset://textures/face.png`), abgeschrägte Schulterstücke (WedgeParts) – Ziel: weniger „Kiste", mehr Figur.
  - Reichweiten-Overlays in `Main.client.luau` `addOverlay`: sanftes Einblenden (Transparenz-Tween) und leichtes Pulsieren der Angriffsfelder.
  - Fertig, wenn: Laufen wirkt flüssig ohne Ruckeln; Figuren bewegen sich auch im Stand sichtbar; Auswahl hat klares visuelles Feedback.

- [ ] 5. **Menüs mit Bewegung & Feedback**
  - `src/client/UIKit.luau`:
    - `button`: beim Drücken auf 0,94 skalieren und zurückfedern (UIScale, `Back`-Easing), Hover 1,04 (nur Maus).
    - `popIn` ergänzen um `popOut(frame)` (Schließen mit Skalieren + Ausblenden, danach `Visible=false`) und Öffnen mit leichtem Hineingleiten von unten.
    - Neu `countUp(label, from, to, formatFn)` für Gold/Edelsteine (0,6 s).
  - `MenuUI.luau`: Lobby/Thron-Menü öffnen mit `popIn`, schließen mit `popOut`; Reiterwechsel mit kurzem Überblenden der Seiten; Gold/Edelsteine in Saal-Anzeige und Lobby per `countUp` bei Änderungen.
  - `UI.luau`: Info-Panel gleitet beim Wechsel der Einheit leicht ein; Toast gleitet von unten ein und blendet aus.
  - Mobil: `HapticService` – kurzer Impuls bei Treffer/Krit, falls verfügbar (`pcall`).
  - Fertig, wenn: kein Fenster erscheint/verschwindet mehr „hart"; Buttons reagieren sichtbar auf Drücken.

- [ ] 6. `scripts/check.ps1` ausführen – fertig, wenn: `OK` / Exit 0
- [ ] 7. Spieldatei bauen (`tools/rojo.exe build default.project.json -o TacticsGame.rbxlx`) – fertig, wenn: Build ohne Fehler
- [ ] 8. Devlog-Eintrag #10 in `docs/DEVLOG.md` (Teststatus „ungetestet", Liste der Sound-Platzhalter), „Nächste Schritte" aktualisieren; Branch pushen – fertig, wenn: Eintrag vorhanden, Branch auf GitHub

## Manueller Test in Studio (Nutzer)
- [ ] Ein paar Sound-IDs in `Sounds.luau` eintragen (Musik Saal/Kampf, hit, click) → hörbar; leere IDs verursachen keine Fehler
- [ ] Saal: warmes Licht, schwebender Staub, flackernde Kerzen, Lichtstrahlen
- [ ] Kampf beginnen: Stimmung/Musik wechselt; Brett hat Umgebung
- [ ] Angriff: Kamera zoomt heran, Treffer wackeln, Krit blitzt und wirkt stärker
- [ ] Gegnerphase: Kamera folgt Gegnern; „⏩" beschleunigt
- [ ] Laufen flüssig, Staub an den Füßen, Figuren atmen/gestikulieren, Auswahl hüpft mit Ring
- [ ] Menüs gleiten auf/zu, Buttons federn, Gold/Edelsteine zählen hoch
- [ ] Auf dem Handy: alles weiterhin bedienbar, Bildrate ok
- [ ] Output-Fenster ohne rote Zeilen

## Nicht anfassen
- Spielregeln und Formeln: `src/shared/Combat.luau`, `Grid.luau`, `src/server/EnemyAI.luau`
- Balancing/Inhalte: `Stages.luau`, `Recruit.luau`, Helden-Werte in `UnitData.luau`
- Speicherformat: `src/server/ProfileStore.luau`
- Server-Kampf-Timing (`Config.IMPACT_TIME`, `Config.STRIKE_TIME`) – nur Client-Effekte darum herum
- Befehls-Validierung in `Main.server.luau` (außer: `SetSpeed` um 3 erweitern, `enemyMove`-Event senden)

## Offene Fragen
- Konkrete Sound-IDs: sucht der Nutzer in Studio (Toolbox → Audio) aus und trägt sie in `Sounds.luau` ein.
- Echte 3D-Modelle (Meshes) statt Klötzchen wären ein eigener späterer Schritt (Blender/Asset-Erstellung) – nicht Teil dieses Plans.

## Notizen (Codex)
-
