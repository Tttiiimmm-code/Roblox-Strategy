# PLAN: Level-Optik Etappe C3 – geschlossener Wald, Umgebung, felsige Klippen, Ufer- und UI-Korrekturen

Ziel: Korrekturen nach dem ersten Studio-Test von C2 (Nutzer-Screenshots vom 09.10.2026). Die Karten sollen der Vorlage näherkommen: geschlossene Waldflächen, ein Brett, das in eine Landschaft eingebettet ist statt wie eine Insel zu wirken, felsige Berge und Klippen, natürliche Ufer.
Branch: `feature/level-optik-c` (enthält Phase 3, C1, C2)

**Befunde aus dem Test (Claude, anhand der Screenshots):**
1. **Ufer:** Die runden Sandkappen und Füllscheiben (`Config.FEEL.shore`, BoardBuilder) sehen aus wie **gelbe Ringe/Kreise** auf dem Wasser. Sie wirken wie UI-Zielmarkierungen, nicht wie ein Ufer.
2. **Wald:** Die Bäume wirken klein, wie junge Bäume, etwa ein halbes bis 0,8 Feld hoch. Die Waldfelder sehen licht aus, nicht geschlossen. Vermutete Ursache: `forest.treeWidth` 0,6–0,9 begrenzt die Skalierung (Yasu-Kronen sind breit, `place` nimmt das Minimum aus Höhe und Breite). Meist stehen nur 2 Bäume (`thirdTreeChance = 0.1`).
3. **Gold-Symbol:** 🪙 (U+1FA99) zeigt die Roblox-Schrift als „▯“ an: in der Level-Auswahl, im Lager und auf dem Abschlussbildschirm (5 Stellen, `rg "🪙" src`). 💎 funktioniert.
4. **Level-Auswahl:** Große Auswahlkarten (`RunUI`, UIKit-Hover `buttonHoverScale = 1.04`) überlappen beim Hover die Nachbarkarte.
5. **Umgebung:** Rund ums Brett liegt eine flache, knallgrüne Fläche (`surroundColor`, SmoothPlastic) mit einzelnen schiefen Bäumen und Felsen. Das Brett wirkt wie eine Insel.
6. **Berge (`M`) / Klippen (`C`):** kahle braune Kisten mit glatten Seiten, nur oben Felsen.

**Nutzerentscheidung (09.10.2026):** Alle vier Punktgruppen beheben: Ufer + Gold-Symbol (+ Hover), Wald dichter/größer, Umgebung ums Brett, Berge/Klippen schöner.

**Leitlinien:**
- Handy-Leistung: Geschätzte Dreiecke einer typischen Karte inklusive Umgebung im Mittel ≤ 350.000 (WIP, `estimatedTriangleBudget` anpassen und begründen). Mittel- und Maximalwerte vor/nach jedem Schritt in den Notizen, mit den maßhaltigen Paket-Fixtures (`tests/environment-pack.fixture.luau`). Lieber größere Modelle als mehr Modelle.
- Klickbarkeit, Figurenmitte, Umrisse (`ForestOutlines`), Brückenhöhen und Determinismus bleiben erhalten. Der Part-Fallback ohne Paket bleibt funktionsfähig.
- Alle Mengen und Farben als WIP-Werte in `Config`. Ein Commit pro Schritt, alle Prüfskripte grün.
- **Geschmacksfragen nicht selbst entscheiden:** Gibt es mehrere sinnvolle Varianten (zum Beispiel Farbe des Umgebungsbodens), wähle eine zurückhaltende Variante, mache sie über Config umstellbar und nenne sie in den Notizen, damit der Nutzer sie im Test beurteilt.

## Schritte

- [x] 1. **Ufer ohne Ringe** – `BoardBuilder` (Uferaufbau), `Config.FEEL.shore`
  - Uferkappen, Füllstücke und Streifen sind **ausgefüllte** Flächen ohne kontrastierenden Rand. Keine wasserfarbene Maske, die eine Ringform erzeugt. Die Sandfarbe ist gedämpft und nah an Boden- und Erdtönen (WIP), nicht leuchtend gelb oder beige.
  - Aus Kamerasicht müssen Ufer wie ein weicher Übergang Land → Sand → Wasser wirken. Kreise oder Ringe auf der Wasserfläche dürfen nicht sichtbar sein. Gelingt eine runde Form nicht ohne Ringwirkung, sind gerade Sandstreifen mit leicht abgeschrägten Ecken vorzuziehen; Entscheidung und Begründung in die Notizen.
  - Fertig, wenn: Ein Stub prüft, dass keine Uferteile über der Wasserfläche liegen, die nicht an Land angrenzen, und dass keine Ringstruktur entsteht (zum Beispiel kein Teil mit Loch oder Masken-Kombination). Teilezahl vorher/nachher.

- [x] 2. **Gold-Symbol und Hover-Überlappung** – `src/client/RunUI.luau` (und alle weiteren Treffer von `rg "🪙" src`), `UIKit`
  - 🪙 überall durch **💰** ersetzen. Zentral als Konstante, zum Beispiel `Config.ICONS.gold`; 💎 für Edelsteine ebenfalls zentral.
  - Große Auswahlkarten der Level-Wahl überlappen beim Hover nicht mehr, zum Beispiel ohne Hover-Vergrößerung bei großen Karten oder mit genug Abstand. Kleine Buttons behalten ihr Hover-Feedback.
  - Fertig, wenn: `rg "🪙" src` liefert keine Treffer; ein UI-Stub prüft, dass sich die Auswahlkarten auch bei Hover-Maßstab nicht überschneiden.

- [x] 3. **Geschlossener Wald** – `BoardBuilder.decorate` (Fall `F`), `Config.ENVIRONMENT.forest`
  - Die Bäume werden deutlich größer: Kronen etwa 1,1–1,5 Felder breit, Höhe etwa 1,3–1,8 Felder (WIP). Die Größe darf nicht mehr durch eine zu kleine Breitengrenze gedeckelt werden; prüfe die Skalierungslogik in `EnvironmentAssets.place`.
  - Kronen benachbarter Waldfelder überlappen, sodass Waldflächen von oben wie ein **zusammenhängendes Kronendach** wirken; Ränder zu Wiesen bleiben leicht unregelmäßig. Baumanzahl dafür nicht stark erhöhen, sondern mit Größe und Streuung arbeiten; den dritten Baum nur, wenn das Budget es zulässt.
  - Umrisse (`ForestOutlines`) müssen weiter greifen. Prüfe, ob größere Kronen jetzt auch Figuren auf Feldern **neben** dem Wald verdecken, und passe die Verdeckungsregel an (Regel in den Notizen).
  - Fertig, wenn: Fixture-Messung zeigt größere Kronenmaße und eine Abdeckung der Waldfläche von oben (zum Beispiel ≥ 85 % der Waldfelder-Fläche von Kronen-Bounding-Boxen überdeckt; Methode in den Notizen); Dreiecke im Budget.

- [ ] 4. **Umgebung ums Brett** – `BoardBuilder` (Umgebungsrand, `surroundColor`, `outer`-Platzierung), `Stages`/`Config`
  - Ein **dichter Waldrand** umschließt das Brett, etwa 2–4 Felder tief, mit großen Bäumen, Büschen und Felsen, unregelmäßig und nicht in Reihen. Weiter außen geht er in ruhigeren, **gedämpften Boden** über (dunkler und weniger gesättigt als das aktuelle Knallgrün). Farbe pro Region in `Stages` (WIP, umstellbar).
  - Leistung: Die erste Reihe am Brett aus echten Modellen. Weiter entfernte Bereiche dürfen günstiger sein, zum Beispiel größere Modelle mit weniger Stück oder einfache Kronenblobs, die von weitem gleich wirken. Kamera-Zoom-Grenzen aus C1 beachten: Beim maximalen Herauszoomen soll kein harter, leerer Rand sichtbar sein.
  - Der Rand darf das Brett nicht verdecken; keine Objekte auf Brettfeldern; die Kamera erreicht alle Ecken weiterhin.
  - Fertig, wenn: Ein Stub prüft, dass der Ring geschlossen ist (keine großen Lücken pro Seite), dass keine Objekte auf Brettfeldern stehen und dass alles deterministisch ist. Dreiecke/Teile vorher/nachher.

- [ ] 5. **Felsige Berge und Klippen** – `BoardBuilder` (Bodenaufbau `M`/`C`, Felsplatzierung), `Config`
  - Die Seitenwände von Berg- und Klippenfeldern wirken felsig statt glatt, zum Beispiel durch Felsmodelle, die an freiliegenden Außenkanten an die Wand gelehnt bzw. halb eingelassen sind, und leicht unregelmäßige Oberkanten. Die Oberseite bleibt als Feld erkennbar und anklickbar. Die Figurenmitte bleibt frei auf `M` (begehbar).
  - Farbe der Seitenwände dunkler und kühler als die Oberseite (WIP), passend zu den Felsmodellen.
  - Nur Außenkanten, die an niedrigeres Gelände grenzen, bekommen Felsen, nicht Innenkanten zwischen zwei `C`/`M`-Feldern.
  - Fertig, wenn: Ein Stub prüft, dass freie Außenkanten Felsen bekommen, Innenkanten nicht, und dass die Klickbarkeit erhalten bleibt. Dreiecke im Budget.

- [ ] 6. **Messung + Prüfskripte** – Tests für alle Schritte. In den Notizen: Teile und geschätzte Dreiecke (Mittel/Max, 100 Seeds, mit Paket-Fixtures, inklusive Umgebung) sowie Stub-Aufbauzeit vorher/nachher.

- [ ] 7. **Abschluss:** `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1`, `scripts/test-run-ui.ps1` alle OK, dazu Rojo-Build. Devlog **#35** „Level-Optik Etappe C3“, „Nächste Schritte“ aktualisieren. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Ufer: weicher Sandübergang, keine gelben Ringe/Kreise mehr
- [ ] Gold zeigt 💰 in Level-Wahl, Lager und Abschluss; Auswahlkarten überlappen beim Hover nicht
- [ ] Waldflächen wirken geschlossen (Kronendach), Figuren im und am Wald haben gut sichtbare Umrisse
- [ ] Brett ist von dichtem Wald umgeben, außen ruhiger, gedämpfter Boden; auch ganz herausgezoomt kein leerer Rand
- [ ] Berge/Klippen mit felsigen Wänden; alle Felder anklickbar
- [ ] Noch aus C2 offen: Figuren stehen auf dem Brückenbogen (nicht schwebend); Kronenfarbe ohne Warnung im Output
- [ ] Handy flüssig, Aufbauzeit („Missionsaufbau …“) im Rahmen

## Nicht anfassen
- Spielregeln, Generator, Tutorial-Karten, Lager-/Boss-Logik, Brückenlogik (außer falls nötig für Uferanschluss), Bodentexturen (`GROUND_TEXTURES`-Werte setzt der Nutzer)

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)

- Schritt 1: Gerade, deckende Sandstreifen auf Land statt runder Scheiben mit Land-/Wassermasken; verhindert die beobachtete Ringwirkung, spart Teile und laesst Brueckenenden frei. Farbe WIP in Config (123/119/89), Studio-Beurteilung offen. Ufer-Fixture: vorher 11, nachher 4 Teile. Seeds 1-100 mit Paket-Fixtures: vorher Teile Mittel/Max 1762,2/1971, Dreiecke 296921/453272, Stub 89,62 ms; nachher 1732,4/1925, 293732/453272, 85,49 ms. check.ps1 und test-run.ps1 OK.

- Schritt 2: Config.ICONS.gold/gems zentral in RunConfig und RunUI; Goldsymbol ersetzt. Auswahlkarten HoverScale=1 mit Quad beim Loslassen (kein Ueberschwingen), kleine Buttons unveraendert. UI-Stub 116 Pruefungen, Hover-/Loslassereignisse fuer 480/900/1600 Breite; check und run OK, keine alten Goldsymbole in src. Paketmessung unveraendert: Teile 1732,4/1925, Dreiecke 293732/453272, Stub vorher 85,49 / nachher 92,21 ms (Messschwankung).

- Schritt 3: Baumhoehe 1,3-1,8 Felder bestimmt die Skalierung; Kronen separat horizontal auf 1,35-1,5 verbreitert, damit schmale Paketvarianten nicht als Jungbaeume erscheinen. Zwei bis drei Baeume unveraendert. Masshaltige 4x4-Wald-Fixture: vorher Kronen 0,41-0,87 / Hoehe 0,38-1,32 Felder, nachher 1,35-1,50 / 1,30-1,78. Union der Kronen-AABBs mit 32x32 Stichproben pro Feld: 68,03 -> 99,99 % Abdeckung (Bounding-Box-Naeherung, keine Aussage ueber echte Mesh-Luecken). Umrisse auf allen acht direkten Nachbarn sowie bis zwei Felder hinter der dominanten Kamerablickachse inkl. seitlichem Nachbarn; entfernte Felder vor Wald ohne Umriss. Highlightbudget unveraendert. Paketmessung vorher/nachher Teile 1732,4/1925, Dreiecke 293732/453272; Stub 92,21 -> 88,29 ms. check und run OK.
