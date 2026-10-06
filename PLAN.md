# PLAN: Kampfszene im Fire-Emblem-Stil

Ziel: Bei jedem Kampf blendet der Bildschirm in eine eigene **Kampfszene**: beide Chibis seitlich auf einer kleinen Geländeplattform, Angriffs-/Trefferanimationen, Schadenszahlen, unten je ein Panel mit Name, Waffe, **HIT/DMG/CRT** und **KP-Balken, die beim Treffer runterlaufen**. Danach zurück aufs Brett. Antippen überspringt; Schalter „Szenen an/aus".
Branch: `feature/kampfszene` – abzweigen von `feature/ladezeit`
Kontext: Nutzerwunsch mit Referenzbild (Fire Emblem GBA: Gegner links rot, Spieler rechts blau, oben Namen, unten HIT/DMG/CRT + KP). Entscheidungen: **volle Kampfszene**, **immer, überspringbar**, Schalter an/aus, bei 3× automatisch kurz.
Ist-Zustand: `Main.server.luau` `battle()` (~Zeile 321): `Combat.resolve` → `BattleEvent:FireAllClients({ strikes })` → je Schlag `pause(IMPACT_TIME)`, `UnitVisuals.setHp`, `pause(STRIKE_TIME - IMPACT_TIME)`. Client `Main.client.luau` `BattleEvent.OnClientEvent` (~Zeile 786) spielt pro Schlag `UnitAnimator.playStrike(s, weaponKey, onImpact)` auf dem Brett.

**Allgemein**
- Server bleibt autoritativ; die Szene ist reine Darstellung. Brett-Animationen laufen im Hintergrund weiter (wichtig für Überspringen).
- Werte in `Config.FEEL` (`battleScene…`). UI über `UIKit`, Designgröße 1280×720, Handy: große Schrift, Antippen zum Überspringen. Nur erlaubte Symbole (`★ ◆ ♦ ⚔ ⚠ ⓘ`).
- Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt.

## Schritte

- [x] 1. **Einstellung „Kampfszenen" (Server + Profil)** – Dateien: `src/server/ProfileStore.luau` (`normalize`), `src/server/Main.server.luau`
  - Profil-Feld `settings = { battleScenes = true }`; `normalize` ergänzt fehlende Werte (alte Profile bleiben gültig).
  - Neuer Befehl `{ type = "SetBattleScenes", on = bool }` – wie `SetSpeed`: im Kampf nur der Besitzer, sonst der Spieler selbst; Wert prüfen (`typeof(on) == "boolean"`), im Profil speichern und in `state.battleScenes` spiegeln (beim Missionsstart aus dem Profil des Besitzers übernehmen).
  - In `battle()`: wenn `state.battleScenes`, vor den Schlägen `pause(Config.FEEL.battleSceneIntro)` (0.45 s) und danach zusätzlich `pause(Config.FEEL.battleSceneOutro)` (0.5 s). Prüfen, ob `pause` mit dem Tempo skaliert; sonst durch `state.speed` teilen. Sonst keine Änderung an Kampfablauf/KP-Timing.
  - Fertig, wenn: Einstellung bleibt nach Rejoin erhalten; ohne Szenen ist der Kampf so schnell wie heute.

- [x] 2. **`UnitAnimator` für fremde Modelle öffnen** – Datei: `src/client/UnitAnimator.luau`
  - `Animator.playStrike(strike, weaponKey, onImpact, options)`: optional `options.attacker`, `options.target` (Modelle statt Suche im Einheitenordner) und `options.fxParent` (Ort für Pfeile/Feuer/Partikel, Standard wie bisher). Ohne `options` exakt bisheriges Verhalten.
  - Treffer-Reaktion und Tod (Umfallen/Ausblenden) für übergebene Modelle nutzbar machen (z. B. `Animator.playDeath(model)`), damit die Szene den Tod zeigt.
  - Fertig, wenn: Brett-Kampf unverändert; Szene kann Animationen auf eigenen Klonen abspielen.

- [x] 3. **Kampfszene** – neue Datei `src/client/BattleScene.luau`
  - `BattleScene.play(info)`; `info = { left, right, strikes, speed, onDone }`. Seiten wie im Referenzbild: **Gegner links, Spieler rechts**; ohne Spieler-Einheit (Sonderfall) Angreifer rechts.
  - Pro Seite: `unit` (State-Daten inkl. KP **vor** dem Kampf), `model` (Klon aus `workspace.Units`, `ScaleTo(1)` wie in `UIKit.portrait`, BillboardGuis entfernt), `forecast` (`Combat.forecast` aus Sicht dieser Seite – Werte für HIT/DMG/CRT; Seite ohne Konter zeigt `--`), `terrain` (Feld, auf dem die Einheit steht).
  - **Darstellung:** Vollbild-`ScreenGui` (über HUD, unter Toasts/Level-Up) mit `ViewportFrame` + `WorldModel`:
    - Plattform: flacher Block (ca. 16×1×6) mit Farbe/Material des **Felds des Verteidigers** (`Config.TERRAIN[...].color/material`), Rand etwas dunkler.
    - Hintergrund: Verlauf Himmel → Gebietsfarbe (`Stages.getRegion(...).color`), 2–3 flache Hügel-Silhouetten.
    - Figuren seitlich zueinander (Abstand ~6 Studs), Kamera seitlich leicht von oben wie im Referenzbild; Pferde/★-Effekte sichtbar.
  - **UI unten (zwei Hälften über die ganze Breite):** links rotes, rechts blaues Panel (UIKit-Theme, Goldrand): Name (Titel-Schrift), Waffe, `HIT nn  DMG nn  CRT nn`, KP-Zahl + segmentierter KP-Balken. Oben links/rechts zusätzlich der Name als Schild wie im Bild.
  - **Ablauf:** Einblenden (`battleSceneIntro`), dann pro Schlag im selben Takt wie der Server (`(i-1) * STRIKE_TIME / speed`): `UnitAnimator.playStrike(..., { attacker = Klon, target = Klon, fxParent = WorldModel })`; im Impact-Moment: Treffer-Sound wie bisher, Schadenszahl/„Verfehlt"/„KRITISCH!" als UI-Text über der getroffenen Figur, KP-Balken animiert auf `hpAfter`, bei Krit kurzer Weißblitz (`UI.flashCrit`) und Wackeln der Szene; bei `hpAfter == 0` Tod-Animation. Nach dem letzten Schlag kurz halten, dann ausblenden (`battleSceneOutro`) und `onDone`.
  - **Überspringen:** Antippen/Klicken irgendwo in der Szene → sofort ausblenden (Brett läuft weiter). Hinweis unten mittig „Tippen zum Überspringen".
  - Alle Zeiten durch `speed` teilen (3× = automatisch kurz). Szene räumt sich vollständig auf (Klone, Tweens, Verbindungen), auch wenn während der Szene der State wechselt (Lobby, Retry, Ergebnis).
  - Fertig, wenn: jede Schlagfolge (inkl. Konter, Doppelschlag, Verfehlen, Krit, Tod) korrekt dargestellt wird.

- [x] 4. **Einbinden** – Datei: `src/client/Main.client.luau` (`BattleEvent.OnClientEvent`, `payload.strikes`)
  - Wenn `state.battleScenes` (Rückfall: true): KP vor dem Kampf aus `state.units` lesen, Seiten/Forecast/Terrain bestimmen und `BattleScene.play` starten. Die Brett-Animation läuft parallel weiter (Kamera-Fokus), **Sounds/Schadenstexte nur einmal** – in der Szene, nicht doppelt auf dem Brett. Ohne Szene alles wie bisher.
  - Info-Panel, Kampfvorschau und Hinweise während der Szene ausblenden; danach wiederherstellen.
  - Fertig, wenn: eigene Angriffe **und** Gegnerphase zeigen die Szene; keine doppelten Sounds.

- [x] 5. **Schalter „Szenen"** – Dateien: `src/client/UI.luau` (Werkzeugleiste `buildTools`/`setTools`), `src/client/Main.client.luau`
  - Neuer Werkzeugknopf „Szenen an" / „Szenen aus" (Stil `active` wenn an) → sendet `SetBattleScenes`; nur für den Besitzer sichtbar.
  - Fertig, wenn: Umschalten wirkt ab dem nächsten Kampf und bleibt gespeichert.

- [x] 6. `scripts/check.ps1` = `OK`; `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [ ] 7. Devlog-Eintrag #18 „Kampfszene" (Teststatus „ungetestet"), Branch pushen, dann `.handoff/status` = `fertig`.

## Manueller Test (Nutzer, PC + Handy)
- [ ] Eigener Angriff: Szene blendet ein, Gegner links/rot, eigene Figur rechts/blau, Plattform im Look des Felds, HIT/DMG/CRT stimmen mit der Kampfvorschau überein
- [ ] KP-Balken laufen im Treffer-Moment runter; Verfehlt/Kritisch/Kein Schaden erscheinen; Konter und Doppelschläge korrekt; Tod sichtbar
- [ ] Gegnerphase zeigt ebenfalls Szenen; Tempo 2×/3× macht sie kürzer
- [ ] Antippen überspringt sofort; danach stimmt das Brett (KP, Figuren, Ringe)
- [ ] „Szenen aus" → Kämpfe wie bisher nur auf dem Brett; Einstellung nach Neustart erhalten
- [ ] Keine doppelten Sounds; Output ohne rote Zeilen; Handy: Panels lesbar, flüssig

## Nicht anfassen
- Kampfformeln (`Combat.luau`), `Grid`, `EnemyAI`, Kartendaten; KP-/Treffer-Timing im Server (nur Intro/Outro-Pausen ergänzen)

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)

## Notizen (Codex)

- Schritt 4 ergänzt im Server-Kampfereignis die aktuellen Feldkoordinaten: Der letzte State liegt vor der Bewegung; ohne diese Daten wären Gelände und Kontervorschau falsch. Kampfregeln und KP-Timing bleiben unverändert.
- Intro, Szeneneinstellung und Tempo werden pro Kampfereignis mitgegeben, damit Brett und Szene denselben Start verwenden. Bei fehlenden Klonen greift die bisherige Brettdarstellung.
