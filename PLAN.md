# PLAN: Level-Optik Etappe C4 – keine Baumschatten, lichterer Wald, natürlicher Waldring

Ziel: Feinschliff nach dem Studio-Test von C3 (Nutzer-Screenshots vom 09.10.2026).
Branch: `feature/level-optik-c` (enthält Phase 3, C1–C3)

**Befunde aus dem Test:**
1. **Schatten poppen auf und verschwinden** (Nutzer). Ursache: Seit C3 werfen über 100 große Bäume echte Schatten (`EnvironmentAssets.place`: `CastShadow = scaledSize.Y >= shadowHeight · TILE_SIZE`). Roblox rendert Schatten nur in begrenzter Reichweite/Auflösung, deshalb springen sie beim Kamerabewegen/Zoomen. Das kostet außerdem Leistung auf dem Handy.
2. **Der Wald verdeckt zu viel:** Kronen 1,35–1,5 Felder verdecken Raster und Figuren; Leon im Wald ist nur über einen schwachen Umriss zu erkennen.
3. **Der Waldring wirkt wie eine Hecke:** gleichmäßige Reihen rundum. Auf der Kameraseite (unten im Bild, +Z) verdecken große Bäume und die günstigen Kronen-Ersatzteile („grüne Eier“) das untere Brettende.

**Nutzerentscheidungen (09.10.2026):**
- **Baumschatten aus:** Bäume und Umgebung werfen keine echten Schatten; dafür ein dunklerer, ruhiger Waldboden für Tiefe. Figuren behalten ihre Rundschatten (`UnitShadow`).
- **Wald etwas lichter:** Kronen etwa 1,1–1,2 Felder statt 1,35–1,5; Raster und Figuren scheinen stärker durch. Umriss für Figuren im und am Wald **kräftiger**.
- **Waldring vorne niedrig, natürlicher:** Auf der Kameraseite nur niedrige Büsche und Felsen, hinten und an den Seiten hohe Bäume, unregelmäßig statt als Hecke. Kronen-Ersatzteile weg oder nur ganz hinten (außerhalb des normalen Sichtbereichs).

**Bestehender Code:** `src/server/EnvironmentAssets.luau` (`place`, CastShadow-Regel), `src/shared/Config.luau` (`ENVIRONMENT.shadowHeight`, `ENVIRONMENT.forest.treeWidth/treeHeight`, `ENVIRONMENT.outer` mit `tree.crownWidth`, `nearSpacing`, `farDistance/farWidth/farHeight`, `FOREST_OUTLINES`), `src/server/BoardBuilder.luau` (Waldfelder, Umgebungsring, Bodenfarben), `src/client/ForestOutlines.luau`, `src/client/CameraController.luau` (Kamerarichtung aus +Z, `rotation`), Tests `tests/outer.test.luau`, `tests/environment-metrics.test.luau`, `tests/forest-outlines.test.luau`, Messung `scripts/measure-environment.ps1`.

**Leitlinien:** Klickbarkeit, Figurenmitte, Brückenhöhen, Determinismus und Part-Fallback bleiben erhalten. Alle Werte WIP in `Config`. Teile/Dreiecke vorher/nachher mit `scripts/measure-environment.ps1` in den Notizen. Ein Commit pro Schritt, alle Prüfskripte grün. Geschmacksfragen: zurückhaltende Variante wählen, über Config umstellbar machen und in den Notizen nennen.

## Schritte

- [x] 1. **Keine Baum- und Umgebungsschatten** – `EnvironmentAssets.place`, `BoardBuilder`, `Config`
  - Umgebungsmodelle und Ersatz-Parts (Bäume, Büsche, Felsen, Ring, Wurzeln, Deko) werfen keine Schatten mehr. Ein Config-Schalter (z. B. `ENVIRONMENT.castShadows = false`) stellt das alte Verhalten wieder her.
  - Waldfelder bekommen einen etwas dunkleren, ruhigen Bodenton (WIP, Config), damit der Wald ohne Schatten Tiefe hat. Raster und Feldfarben bleiben lesbar.
  - Fertig, wenn: Ein Stub prüft, dass kein Umgebungsteil `CastShadow = true` hat (Schalter aus) und mit Schalter an das alte Verhalten gilt; Figuren-Rundschatten bleiben unverändert.

- [ ] 2. **Lichterer Wald + kräftigerer Umriss** – `Config.ENVIRONMENT.forest`, `BoardBuilder.decorate` (Fall `F`), `ForestOutlines`, `Config.FOREST_OUTLINES`
  - Kronenbreite auf etwa 1,1–1,2 Felder, Höhe passend etwa 1,2–1,5 Felder (WIP). Kronen nicht mehr stärker in die Breite ziehen als nötig, damit nichts gestreckt wirkt.
  - Umriss kräftiger: zum Beispiel eine schwache Füllung in Teamfarbe (WIP etwa `fillTransparency` 0,75–0,8) zusätzlich zum Umriss, damit Figuren unter Kronen klar erkennbar sind. Prüfe die Verdeckungsregel für die kleineren Kronen und passe Nachbarradius/Sichtweite an (Regel in den Notizen).
  - Fertig, wenn: Fixture-Messung zeigt Kronenmaße im Zielbereich und eine Waldabdeckung von oben von etwa 70–85 % (Methode wie C3). Outline-Stub mit neuer Füllung grün; Budget und Vorrang unverändert.

- [ ] 3. **Natürlicher Waldring, vorne niedrig** – `BoardBuilder` (Umgebungsring), `Config.ENVIRONMENT.outer`
  - **Kameraseite** (in Grundausrichtung +Z, unteres Bildende): nur niedrige Büsche, Felsen und vereinzelt kleine Bäume, die das Brett aus der Start- und Normalansicht nicht verdecken (WIP Höchsthöhe, z. B. ≤ 0,5 Feld nah am Brett). **Hinten und an den Seiten**: hohe Bäume, unregelmäßig gruppiert (Cluster und Lücken statt gleichmäßiger Reihen), gemischt mit Büschen und Felsen.
  - Kronen-Ersatzteile („Eier“) nur noch ganz hinten bzw. weit außen, wo sie von Bäumen davor teilweise verdeckt sind; auf der Kameraseite gar nicht.
  - Kamera dreht sich (`rotation`): Prüfe, ob die Rotation in der Normalansicht fest ist oder frei drehbar. Bei freier Drehung nenne die gewählte Lösung in den Notizen (z. B. Seiten nach Grundausrichtung oder überall mittelhoch).
  - Fertig, wenn: Ein Stub prüft, dass auf der Kameraseite keine Objekte über der Höchsthöhe nahe am Brett stehen, der Ring hinten/seitlich weiterhin lückenarm ist, keine Objekte auf Brettfeldern stehen und alles deterministisch bleibt. Teile/Dreiecke vorher/nachher.

- [ ] 4. **Abschluss:** `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-run-ui.ps1` alle OK, dazu Rojo-Build. Devlog **#36** „Level-Optik Etappe C4“, „Nächste Schritte“ aktualisieren. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Keine aufpoppenden Schatten mehr beim Drehen/Zoomen; Figuren haben weiter Rundschatten
- [ ] Wald dicht, aber Raster und Figuren scheinen durch; Figuren im/am Wald klar erkennbar (Umriss + leichte Füllung)
- [ ] Waldring: vorne niedrig, nichts verdeckt das untere Brettende; hinten/seitlich hohe, unregelmäßige Bäume; keine „grünen Eier“ im Vordergrund
- [ ] Noch offen aus C2/C3: Figuren stehen auf dem Brückenbogen; keine Warnung zur Kronenfarbe; Thronsaal unverändert; Handy flüssig, Aufbauzeit („Missionsaufbau …“)

## Nicht anfassen
- Spielregeln, Generator, Tutorial-Karten, Lager-/Boss-Logik, Brücken, Ufer, Felswände, UI außer Umriss-Darstellung

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1: `ENVIRONMENT.castShadows = false`; aktivieren stellt die bisherige Höhenschwelle für Modelle wieder her. Ersatzteile bleiben wie vorher schattenlos. Waldboden regional um 10 % dunkler, Fleckkontrast halbiert (beides WIP/Config). UnitShadow unverändert. Schatten-Stubs mit/ohne Paket sowie Grünland-/Sumpfboden grün; `test-run.ps1` und `check.ps1` OK.
- Vorher (Git `fb0cb28`): 100 Grünland-Seeds, Teile Mittel 2.006,2 / Max 2.154; geschätzte Dreiecke Mittel 344.396 / Max 500.220; Stub-Aufbau Mittel 97,75 / Max 120,34 ms.
