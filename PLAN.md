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

- [x] 2. **Lichterer Wald + kräftigerer Umriss** – `Config.ENVIRONMENT.forest`, `BoardBuilder.decorate` (Fall `F`), `ForestOutlines`, `Config.FOREST_OUTLINES`
  - Kronenbreite auf etwa 1,1–1,2 Felder, Höhe passend etwa 1,2–1,5 Felder (WIP). Kronen nicht mehr stärker in die Breite ziehen als nötig, damit nichts gestreckt wirkt.
  - Umriss kräftiger: zum Beispiel eine schwache Füllung in Teamfarbe (WIP etwa `fillTransparency` 0,75–0,8) zusätzlich zum Umriss, damit Figuren unter Kronen klar erkennbar sind. Prüfe die Verdeckungsregel für die kleineren Kronen und passe Nachbarradius/Sichtweite an (Regel in den Notizen).
  - Fertig, wenn: Fixture-Messung zeigt Kronenmaße im Zielbereich; die Waldabdeckung von oben wird wie C3 gemessen und nur informativ in den Notizen dokumentiert (Antwort unter Offene Fragen). Outline-Stub mit neuer Füllung grün; Budget und Vorrang unverändert.

- [x] 3. **Natürlicher Waldring, vorne niedrig** – `BoardBuilder` (Umgebungsring), `Config.ENVIRONMENT.outer`
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

- **Schritt 2 – Entscheidung zur Waldabdeckung nötig:** Die unveränderte maßhaltige C3-Methode (4×4 Wald, 32×32 Stichproben pro Feld, Union echter Kronen-AABBs) ergibt mit den vorgegebenen Kronenbreiten **1,10–1,20 Felder** und Baumhöhen **1,20–1,49 Felder** weiterhin **99,48 %** Abdeckung (C3: 99,99 %). Mit den bisherigen 2–3 Bäumen pro Feld und ihrer bisherigen Anordnung wird das Ziel **70–85 %** also nicht erreicht. Soll ich dafür **die Baumzahl reduzieren**, **die Bäume stärker gruppieren und bewusst Lücken lassen**, oder soll **die höhere AABB-Abdeckung bei den gewünschten kleineren Kronen akzeptiert** werden? Bitte eine Variante im Plan festlegen; Zahl/Anordnung bzw. Akzeptanzkriterium entsprechend freigeben. Keine dieser zusätzlichen Designentscheidungen wurde umgesetzt.
  - **Antwort (Claude):** Die Zahl 70–85 % war Claudes Schätzung, keine Nutzervorgabe. Die Nutzerentscheidung lautet „Kronen etwa 1,1–1,2 Felder“, das ist umgesetzt. **Höhere AABB-Abdeckung akzeptieren**, Baumzahl und Anordnung unverändert lassen. Die AABB-Methode überschätzt runde Kronen. Das Akzeptanzkriterium wird ersetzt durch: Kronenmaße im Zielbereich plus gemessene Abdeckung in den Notizen (nur informativ). Ob der Wald licht genug wirkt, beurteilt der Nutzer in Studio. Weiter mit Schritt 2 (abschließen/committen), dann 3 und 4.
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1: `ENVIRONMENT.castShadows = false`; aktivieren stellt die bisherige Höhenschwelle für Modelle wieder her. Ersatzteile bleiben wie vorher schattenlos. Waldboden regional um 10 % dunkler, Fleckkontrast halbiert (beides WIP/Config). UnitShadow unverändert. Schatten-Stubs mit/ohne Paket sowie Grünland-/Sumpfboden grün; `test-run.ps1` und `check.ps1` OK.
- Vorher (Git `fb0cb28`): 100 Grünland-Seeds, Teile Mittel 2.006,2 / Max 2.154; geschätzte Dreiecke Mittel 344.396 / Max 500.220; Stub-Aufbau Mittel 97,75 / Max 120,34 ms.

- Schritt 2 teilweise umgesetzt, **nicht abgeschlossen/committet**: Kronen 1,1–1,2 Felder, Höhe 1,2–1,5 Felder, Fülltransparenz 0,8 und Füllfarbe folgt der Teamfarbe inklusive Teamwechsel. Outline-Stubs mit unverändertem Budget/Vorrang grün. Nachbarradius 1 und Sichtweite 2 vorläufig beibehalten: Kronenüberhang durch Eckpositionen; perspektivische Verdeckung kann mit 0,75 horizontalem Kameraoffset pro Höhenstud weiterhin bis zum übernächsten Feld reichen. Neue Fixture-Abnahme schlägt ausschließlich beim Abdeckungsziel fehl (99,48 % statt 70–85 %); deshalb Designfrage und Stopp vor Schritt 3.
- Kamera frei drehbar: `CameraController.rotateBy` und Zweifingerrotation in `Main.client.luau`; die konkrete Ringlösung ist noch nicht umgesetzt.
- Sandbox-Prozessstart defekt (`helper_unknown_error: setup refresh had errors`); autorisierte Projektbefehle gemäß Dauerregel über automatische Prüfung außerhalb ausgeführt. Studio/Handy weiterhin ungetestet. Devlog #36 und Abschlussprüfungen erst nach Fertigstellung des gesamten Plans.

- Schritt 2 abgeschlossen gemäß Claude-Antwort: Baumzahl/Anordnung unverändert; Kronen 1,10–1,20 Felder und Höhen 1,20–1,49. AABB-Abdeckung 99,48 % (C3 99,99 %) nur informativ. Nachbarradius 1 und Sichtweite 2 bleiben wegen Ecküberhang und Perspektive erhalten. Füllung 0,8 in Teamfarbe; Budget/Vorrang unverändert. Optische Abnahme durch Nutzer in Studio offen.

- Schritt 3 abgeschlossen: +Z und vordere Seitenecken (1 Feld) nur Büsche/Felsen, höchstens 0,5 Feld über Umgebungsboden. Kamera frei drehbar; niedrige Seite bleibt bewusst in Grundausrichtung, beim Drehen können hohe Seiten ins Vorderbild kommen. Config enthält die WIP-Grenzen.
- Hinten/seitlich Gruppen aus 2–4 Bäumen, Kronen 2,0–2,4 und Höhen 1,35–1,8 Felder; unterschiedliche Gruppentiefe bis 1 Feld, Überlappungen sowie niedrige Büsche/Felsen zwischen Gruppen. Tatsächliche Welt-Bounding-Boxen bestimmen Abstände (Lücken höchstens 0,5 Feld) und sichern Brettfreiheit. Ersatzkronen nur hinten ab 4,5 Feldern; ohne Paket echte Part-Baumgruppen statt großer Kroneneier in der Nahreihe.
- Ring-Stubs über 100 Paket-Seeds prüfen niedrige Vorderkante/Ecken, hohe Rück-/Seitenränder, entfernte Ersatzkronen, Lücken, Brettfreiheit und Klickbarkeit. Wiederholte Builds sind mit Paket und Part-Fallback deterministisch. Notwendige Stub-Korrektur: CFrame:Inverse berücksichtigt jetzt die volle Rotationsmatrix; bislang verfälschte ein zweites PivotTo die Position/Rotation. Keine Änderung an der Roblox-Kamera. test-run.ps1 und check.ps1 OK.
- Vergleich über scripts/measure-environment.ps1 mit identischen maßhaltigen Paket-Fixtures, 100 Grünland-Seeds: vor C4 (fb0cb28) Teile Mittel 2.006,2 / Max 2.154, geschätzte Dreiecke 344.396 / 500.220, Stub-Aufbau 98,57 / 118,89 ms; nach C4 Teile 1.989,5 / 2.128, Dreiecke 343.195 / 495.996, Stub-Aufbau 105,14 / 128,83 ms. Mittleres Dreieckbudget 350.000 eingehalten; Stub-Zeit leicht höher, reale Aufbauzeit/Handyleistung ungetestet.
