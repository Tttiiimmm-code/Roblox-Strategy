# PLAN: Review-Fixes zu Game-Feel-Pass 1

Ziel: Befunde aus Claudes Review von `feature/game-feel-1` beheben, damit Menüs korrekt aussehen und der Branch testbereit ist. Keine neuen Features.
Branch: `feature/game-feel-1` (weiterarbeiten, **nicht** neu abzweigen)
Kontext: Vorheriger Plan erledigt und in `docs/DEVLOG.md` #10 dokumentiert. Review-Ergebnis: 1× hoch, 1× mittel, 4× niedrig (siehe Schritte).

## Schritte

- [ ] 1. **(Hoch) Farbverlauf färbt Fensterinhalte ein** – Datei: `src/client/UIKit.luau`, Funktion `UIKit.panel`
  - Problem: `panel` erzeugt jetzt eine `CanvasGroup`; ein `UIGradient` als direktes Kind einer CanvasGroup wirkt auf den **gesamten** gerenderten Inhalt (Texte, Sterne, Porträts werden nach unten dunkel), nicht nur auf den Hintergrund.
  - Lösung: CanvasGroup selbst mit `BackgroundTransparency = 1` lassen; als erstes Kind einen Hintergrund-`Frame` „Background" anlegen (`Size = UDim2.fromScale(1, 1)`, `BackgroundColor3 = Color3.new(1, 1, 1)`, `BorderSizePixel = 0`, `ZIndex = 0`, mit `UICorner` 8) und **nur dort** den `UIGradient` (`THEME.top` → `THEME.bottom`) einhängen. `UIStroke` (Goldrand) und `UICorner` bleiben an der CanvasGroup.
  - Gewünschte Hintergrund-Transparenz (`props.BackgroundTransparency`, Standard 0,04) auf den Background-Frame übertragen.
  - `animateWindow` prüfen: blendet bei CanvasGroups über `GroupTransparency` aus – die Background-Transparenz darf dabei nicht mehr auf der CanvasGroup selbst gesetzt werden (sonst bleibt sie 1 bzw. springt). `windowState.background` entsprechend nur für Nicht-CanvasGroups nutzen.
  - Fertig, wenn: Texte/Sterne in allen Panels in ihrer eigentlichen Farbe erscheinen; Fenster blenden weiterhin weich auf/zu.

- [ ] 2. **(Mittel) Weniger CanvasGroups** – Dateien: `src/client/UIKit.luau`, `src/client/MenuUI.luau`
  - CanvasGroups kosten je eine eigene Textur (Handy-Speicher, Unschärfe, verschachtelte Gruppen).
  - `UIKit.panel(props, parent)`: neuer optionaler Schalter `props.Animated` (vor dem Erzeugen aus `props` entfernen). Nur dann `CanvasGroup`, sonst normaler `Frame` mit Background-Kind wie in Schritt 1 (gleiche Optik).
  - `Animated = true` nur für: Lobby-Fenster, Thron-Menü, Aktionsmenü, Kampfvorschau, Level-Up, Ergebnis-Box, Rekrutierungs-Ergebnis, Wahrscheinlichkeiten-Fenster, Toast. Alle übrigen Panels (Info-Panel, Gelände-Anzeige, Saal-Anzeige, Phasen-Pill, Aufstellung, Detailbereiche) als `Frame`.
  - Lobby-Reiterseiten (`lobby.pages` in `MenuUI`) zurück auf `Frame`; `UIKit.fadePage` für Nicht-CanvasGroups: einfach `Visible` umschalten (kein verschachteltes Ausblenden).
  - `animateWindow` für Frames ohne CanvasGroup: nur Skalieren + Gleiten, beim Schließen am Ende `Visible = false` (kein Ausblenden der Kinder nötig).
  - Fertig, wenn: keine CanvasGroup liegt in einer anderen CanvasGroup; Anzahl CanvasGroups ≤ 9.

- [ ] 3. **(Niedrig) Tempo nur durch Kampf-Besitzer** – Datei: `src/server/Main.server.luau`
  - `SetSpeed` wird vor der Besitzer-Prüfung behandelt → jeder Spieler kann das Tempo eines fremden Kampfes ändern. Prüfung ergänzen: im Modus `Battle` nur, wenn `state.ownerUserId == player.UserId` (sonst `return false`).
  - `enemySpeedBefore` zurücksetzen (`nil`), wenn der Zustand neu aufgesetzt wird (`setupStage`, `lobbyState`-Wechsel in `ToLobby` und im `PlayerRemoving`-Handler).
  - Fertig, wenn: fremde `SetSpeed`-Befehle abgelehnt werden; nach Kampfabbruch keine alte Tempo-Rückstellung mehr.

- [ ] 4. **(Niedrig) Sieg/Niederlage-Musik nicht in Schleife** – Datei: `src/client/SoundPlayer.luau`
  - `playMusic(name, opts)`: `opts.loop` (Standard `true`); `musicVictory`/`musicDefeat` mit `loop = false` aufrufen (`Main.client.luau`, Stelle mit `SoundPlayer.playMusic`).
  - Fertig, wenn: Ergebnis-Musik einmal spielt, Saal-/Kampfmusik weiter loopt.

- [ ] 5. **(Niedrig) Hover-Sound drosseln** – Datei: `src/client/UIKit.luau` (`button`, `MouseEnter`)
  - Nur abspielen, wenn `UserInputService.MouseEnabled` und seit dem letzten Hover-Sound mind. `Config.FEEL.hoverSoundCooldown` (neu, 0,08 s) vergangen ist.
  - Fertig, wenn: schnelles Überfahren mehrerer Buttons keine Klangkette erzeugt; auf Touch kein Hover-Sound.

- [ ] 6. **(Stil) `require`-Zeilen unter den Datei-Kommentar** – Dateien: `src/client/Main.client.luau`, `CollectionUI.luau`, `MenuUI.luau`, `UI.luau`, `UIKit.luau`, `Hub.luau`
  - Jede Datei beginnt mit dem Beschreibungskommentar; die neu hinzugekommenen `require`-/`local`-Zeilen in den bestehenden Block mit den anderen `require`s verschieben.
  - Fertig, wenn: erste Zeile jeder dieser Dateien ist der `--`-Kommentar.

- [ ] 7. `scripts/check.ps1` ausführen – fertig, wenn: `OK` / Exit 0
- [ ] 8. Spieldatei bauen (`tools/rojo.exe build default.project.json -o TacticsGame.rbxlx`) – fertig, wenn: Build ohne Fehler
- [ ] 9. Devlog-Eintrag #11 „Review-Fixes Game-Feel" in `docs/DEVLOG.md` (Teststatus „ungetestet"), „Nächste Schritte" aktualisieren; Branch pushen – fertig, wenn: Eintrag vorhanden, Branch auf GitHub

## Manueller Test in Studio (Nutzer)
- [ ] Alle Fenster (Info, Aktionsmenü, Kampfvorschau, Lobby, Thron-Menü, Ergebnis, Level-Up, Rekrutierung) zeigen Texte in normaler Farbe (weiß/gold), nicht abgedunkelt
- [ ] Fenster gleiten weiterhin weich auf und zu; Reiterwechsel in der Lobby funktioniert
- [ ] 3D-Porträts (Info-Panel, Aufstellung, Kaserne, Rekrutierung) sind sichtbar
- [ ] Handy: Menüs scharf, flüssig
- [ ] Ergebnis-Musik spielt einmal (sobald Sound-IDs eingetragen)
- [ ] Output-Fenster ohne rote Zeilen

## Nicht anfassen
- Alles aus dem vorherigen Plan, das nicht in den Schritten oben genannt ist (Kamera, Animationen, Atmosphäre, Laufbewegung funktionieren laut Review)
- Spielregeln, Balancing, Speicherformat (`Combat`, `Grid`, `EnemyAI`, `Stages`, `Recruit`, `UnitData`-Werte, `ProfileStore`)

## Offene Fragen
-

## Notizen (Codex)
-
