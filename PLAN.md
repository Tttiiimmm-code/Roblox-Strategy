# PLAN: Schwebende Thronlande – Etappe D1b (Optik-Korrektur)

Ziel: D1 (Devlog #43) ist technisch fertig, wirkt in der Kampfansicht aber leer und trüb. Claude-Review in Studio (10.10.2026, Grasland Level 1): Wolkenmeer = gleichmäßig **weiße Leere**, Inselrand **dunkles Oliv** und leer, Nebeninseln wirken wie **schräge Bretter** und ragen an Bildrändern/hinter der Rundenanzeige ins Bild, Kante/Unterseite aus Spielsicht nur ein dünner Streifen. Wichtig: Die Spielkamera schaut **steil nach unten** – was der Spieler sieht, ist vor allem die Wolkendecke, kaum Himmel/Horizont.
Branch: `feature/thronlande` (weiterarbeiten, schon gepusht).

**Nutzerentscheidungen (10.10.2026)**, Zielbild = Bild-Entwurf „Thronlande Kampfansicht Wolkenmeer“ (beschrieben, da Codex es nicht sieht):
- **Wolken weich und rund**: voluminöse Wolkenhaufen mit weißen Oberseiten, **zart lila und hellcyan schattierten Zwischenräumen**, zum Bildrand hin lilafarbener; klar erkennbare Wolkenformen statt flacher Fläche. Umsetzung in D1b **ohne Credits** aus Roblox-Kugelteilen (`Shape = Ball`, `SmoothPlastic`), nicht aus Meshes.
- **Unterseite kombiniert**: oben ein Stück **senkrechte Felswand** (Erdschicht, darunter Steinschicht, WIP ≈ 1,5–2 Felder hoch, deutlich sichtbar von der Spielkamera), darunter **spitz zulaufend** wie bisher mit Thronkristallen.
- Kleine **Nebeninseln** lugen aus den Wolken, je mit Kristall im Gebietsakzent, spiegeln das aktuelle Gebiet (gilt weiter).
- Rand frisch und hell grün, leicht vom Brett abgesetzt; Wasserfall über die Kante bleibt.

**Bestehender Code:** `src/server/IslandBuilder.luau` (`shell`, `satellite`, `skyIslands`, `crystal`, `triangle`, `measure`), `src/server/LandscapeBuilder.luau` (Insel-Oberfläche, `details`), `src/shared/Config.luau` (`Config.ISLAND`, `Config.LANDSCAPE.palette`), `src/shared/Stages.luau` (Zeile ~18–20: `region.landscape.colors[Grass] = region.surroundColor`), `src/client/Atmosphere.luau` (Haze für `battle` bei Insel), `tests/island.test.luau`, `scripts/test-run.ps1`.

**Studio-Prüfung:** echter Ort „Throne Tales“, nur Play-Modus, **keine Kamera-Eingriffe** (nur Normalzoom + Mausrad-Übersicht), Studio-Fenster nicht minimiert (schwarzes Bild = minimiert → `frage`). Lauf über `Remotes.Command` `{type="ResumeLevel"}` bzw. `{type="ChooseLevel", index=1}`. Pro Schritt Normal- und Übersichtsbild, vorher/nachher kurz beschreiben.

**Leitlinien:** Alle neuen Werte zentral in `Config.ISLAND` (WIP-Kommentar). Deterministisch pro `mapKey`. Brett, Klickbarkeit, Figuren, UI, Hub, Lighting-Effekte des Nutzers (ColorGrading/Bloom) und `docs/referenz/` nicht anfassen. Teilebudget Insel insgesamt weiter **≤ 450**; wo nötig vorhandene Teile einsparen (z. B. CloudSea-Kacheln, Wedge-Wolkenberge ersetzen). Ein Commit pro Schritt. Geschmacksfragen → „Offene Fragen“.

## Schritte

- [x] 1. **Robustheit Budget** – `IslandBuilder.skyIslands`
  - `assert(count >= satelliteCount.min, …)` entfernen: Reicht das Budget nicht, weniger (auch 0) Nebeninseln bauen und Attribut setzen; Levelaufbau darf nie daran scheitern. Regression im Inseltest: künstlich knappes Budget baut ohne Fehler.

- [x] 2. **Heller Inselrand** – `Config.ISLAND`, `LandscapeBuilder`/`Stages`
  - Rand-Grasfarbe für Inseln heller und frischer als das jetzige Oliv (Terrain-Grass aktuell ≈ 73,86,64 in Studio): neuer WIP-Wert je Gebiet bzw. Aufhellung der Gebietsfarbe (`ISLAND.rimBrighten` o. ä.), Ergebnis mindestens so hell wie die Brett-Grasfelder, aber leicht abgesetzt (Brett bleibt erkennbar). Tal-Rückfall (`ISLAND.enabled=false`) unverändert.
  - Akzeptanz: Normalbild – Rand wirkt hellgrün, nicht trüb; Brett hebt sich ab.

- [ ] 3. **Kombinierte Unterseite** – `IslandBuilder.shell`
  - Unter der Kante zuerst eine **senkrechte Wand** entlang des Umrisses: Erdschicht (`earthColor`, ≈ 0,6 Feld) + Steinschicht (`stoneColor`, ≈ 1 Feld), WIP-Werte `cliffEarthTiles`/`cliffStoneTiles`; erst darunter die bestehenden Verjüngungsstufen bis zur Spitze und die Kristalle. Flussmündungen (`riverCuts`) wie bisher ausgespart.
  - Akzeptanz: Normal- und Übersichtsbild zeigen an der Vorderkante ein klar sichtbares Band Erde + Stein statt eines dünnen Streifens; keine Lücken zwischen Wand und Oberseite.

- [ ] 4. **Weiches Wolkenmeer** – `IslandBuilder.skyIslands`, `Config.ISLAND`, ggf. `Atmosphere.luau`
  - Flache weiße Kacheln nicht mehr als einziges Bild: Grundfläche **getönt** (zart lila/cyan, nicht reinweiß) und **darauf Wolkenhaufen aus Kugeln** (je Haufen 3–6 Kugeln verschiedener Größe, Oberseiten fast weiß, untere/äußere Kugeln lila bzw. hellcyan getönt; zum Rand hin lilafarbener). Haufen so verteilen, dass sie **im Kamerabild bei Normalzoom und Übersicht** rund um die Insel sichtbar sind (nicht nur weit draußen). Wedge-„Wolkenberge“ entfernen oder durch Kugelhaufen ersetzen.
  - Haze/Atmosphere so anpassen, dass die Wolken nicht zu einer gleichmäßig weißen Fläche verschwimmen (z. B. geringere Dichte/Haze für `battle` bei Insel). Nutzer-ColorGrading/Bloom nicht anfassen.
  - Budget: Wolken + Rest ≤ 450; Messung in Notizen.
  - Akzeptanz: Übersichtsbild zeigt erkennbare, weich schattierte Wolkenformen mit Lila/Cyan-Tönen, keine weiße Leere.

- [ ] 5. **Nebeninseln** – `IslandBuilder.satellite`/`skyIslands`
  - Form: kein Quadrat mehr – kleiner unregelmäßiger Polygon-Umriss (wie Hauptinsel, 6–8 Punkte), kurze Wand + Spitze, Kristall im Gebietsakzent, 1 Baum in Gebietsfarbe.
  - Platzierung: tiefer, **teilweise in den Wolken** („lugen heraus“), nie direkt vor der Kamera oder hinter der oberen Rundenanzeige; in der Übersicht 2–3 sichtbar am Rand, bei Normalzoom höchstens angeschnitten am Bildrand.
  - Akzeptanz: Übersichtsbild mit mindestens zwei Nebeninseln, die wie kleine Inseln (nicht Bretter) wirken.

- [ ] 6. **Abschluss** – Tests, Messung, Devlog
  - Inseltests anpassen/ergänzen (Budget-Fallback, Wand vorhanden, Wolkenhaufen im Sichtbereich, Determinismus, ≤ 450 Teile). `scripts/check.ps1`, `test-run.ps1`, `test-levelgen.ps1`, `test-tutorial.ps1`, `test-run-ui.ps1` OK; Rojo-Build.
  - Messung vorher/nachher (Teile, Aufbauzeit). Devlog **#44 „Thronlande D1b – Optik-Korrektur“**, „Nächste Schritte“ (D2: 12 Requisiten-Modelle + gemalter Himmel je Gebiet × Tageszeit). Committen, `git push` (bei Ablehnung durch die Freigabeprüfung: notieren, trotzdem `fertig`; Claude pusht). Studio im Edit-Modus, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Wolken unter der Insel weich, rund, lila/cyan schattiert – keine weiße Leere
- [ ] Rand hellgrün, Brett gut erkennbar; Vorderkante zeigt Erd- und Steinwand
- [ ] Nebeninseln sehen wie kleine Inseln aus und stören die Ansicht nicht
- [ ] Klicks/Bewegung wie vorher, Handy flüssig

## Nicht anfassen
- Spielregeln, Generator, Brett-Inhalt, UI, Hub, Lighting-Effekte des Nutzers, `docs/referenz/`, 3D AI Studio (keine Credits)

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen. **Design- und Geschmacksfragen nicht selbst entscheiden**.)

## Notizen (Codex)

- Schritt 1: Assertion entfernt, Nebeninselzahl auf mindestens 0 begrenzt; Regression mit partBudget=1 baut ohne Fehler und meldet 0 Nebeninseln. Ausgangsmessung: 450/450 Teilemaximum, Stub-Aufbau im Mittel 111,39 ms (200 Aufbauten); aktueller Studio-Lauf Seed 1748071667: 401 Insel-/1672 Brettteile. Bilder D1b_00_battle_normal/uebersicht bestätigen dunklen Rand, weiße Leere und Brett-Nebeninseln.

- Schritt 2: Inselpalette klonen und Brett-Gras je Gebiet um 30 % Richtung Weiß aufhellen; Talpalette und Brettwerte bleiben erhalten. Bilder D1b_02_rand_normal/uebersicht: Rand sichtbar heller und grün, Brett abgesetzt. Palettenregression an Schnee-/Vulkanmaterial angepasst. Referenzmessung Seed 1 vor Wand/Wolkenumbau: 450 Insel-/1823 Brettteile, 197,62 ms (Einzelmessung in Studio, nach Randkorrektur).
