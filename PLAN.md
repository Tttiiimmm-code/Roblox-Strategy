# PLAN: Level-Optik Etappe B – bessere Bausteine, Flüsse mit Brücken, weichere Schatten

Ziel: Zufallslevel im Grasland sehen gewachsen statt zusammengestückelt aus: abwechslungsreichere Bausteine mit stimmigen Übergängen, **durchgehende Flüsse mit passenden Brücken**, sinnvolle Startfelder. Dazu **weichere Schatten**, damit sie bei Kamerabewegung nicht zittern.
Branch: `feature/level-optik` (weiter)

**Nutzer-Rückmeldung (08.10.2026, Test von A2):** „sieht schon besser aus“. Probleme: (1) Schatten unter den Figuren flackern bei Kamerabewegung. (2) Brücken ohne Wasser; Fluss 2 Felder breit, aber Brücke nur 1 Feld → Leon startete auf der Brücke und konnte nicht nach vorn, nur zurück. Frühere Rückmeldung zu den Bausteinen: Anordnung, Optik, zu wenig Abwechslung, Brett – „alles davon“.
**Nutzerentscheidungen:** Flüsse = **durchgehender Fluss quer übers Brett, Brücken genau an den Kreuzungen; Bausteine selbst ohne Wasser.** Schatten = **weichere Echtzeitschatten** (keine Rundschatten, keine andere Licht-Technik).

**Bestehender Code:** `src/shared/MapChunks.luau` (12 kleine 5×4-Stücke mit leerem Rand → Brett wirkt wie vier Inseln), `src/shared/LevelGen.luau` (`compose` 2×2 Stücke + Spiegelung, `populate` Startfelder untere 2 Reihen / Gegner, `reachable`, Rückfall-Level), `src/shared/RunConfig.luau`, Prüfskript `tests/levelgen.test.luau` + `scripts/test-levelgen.ps1`. Licht: `default.project.json` (Lighting, Technology Future), Client `src/client/Atmosphere.luau`. Brücken-Ausrichtung im Brett: `bridgeAngle` in `BoardBuilder`.

## Schritte

- [ ] 1. **Weichere Schatten** – Licht-Einstellungen (wo sie für das Schlachtfeld gesetzt werden: `default.project.json` und/oder `Atmosphere.luau` für den Zustand „battle“)
  - `Lighting.ShadowSoftness` deutlich erhöhen (Wert zentral, „WIP“), ggf. weitere Roblox-Einstellungen, die Zittern sichtbar reduzieren, ohne die Technik zu wechseln. Thronsaal-Licht darf sich nicht sichtbar verschlechtern (wenn nötig nur im Kampf setzen und beim Verlassen zurück).
  - Prüfen, ob Brett-Teile unnötig Schatten werfen (Flecken, Raster, Overlays, Zug-Ring, Seitenwände) → `CastShadow = false`.
  - Fertig, wenn: Werte und betroffene Stellen in Notizen; Studio-Test durch Nutzer.

- [ ] 2. **Neue Bausteine** – `src/shared/MapChunks.luau`
  - Mindestens **24** Grasland-Stücke **ohne `W`/`B`** (Wasser kommt nur noch vom Fluss-Schritt). Mehr Charakter: zusammenhängende Waldstücke, Felsgruppen/Hügelketten aus `M`, kleine Festungen/Gehöfte (`H` mit Wald drumherum), Lichtungen, Waldränder.
  - **Übergänge:** Ränder dürfen Gelände enthalten. Jedes Stück bekommt Rand-Kennungen je Seite (z. B. offen / Wald / Fels), `compose` wählt Nachbarn mit passender Kennung an der gemeinsamen Kante (Rückfall: offen), damit Wälder/Felsen über Stückgrenzen weiterlaufen statt abzubrechen. Spiegelung beibehalten (Kennungen mitspiegeln).
  - Grenzen: Anteil unpassierbarer Felder wie bisher begrenzt; keine Sackgassen-Kammern (Lösbarkeitsprüfung bleibt).
  - Fertig, wenn: Prüfskript zeigt Vielfalt (Anzahl verschiedener Karten in 1 000 Seeds, Anteil Felder mit Gelände) in den Notizen.

- [ ] 3. **Durchgehende Flüsse mit Brücken** – `src/shared/LevelGen.luau`, `src/shared/RunConfig.luau`
  - Mit Wahrscheinlichkeit `RIVER_CHANCE` (WIP, z. B. 0.4) zieht der Generator einen Fluss **von Rand zu Rand** (quer oder längs), leicht geschlängelt, Breite 1–2 (`RIVER_WIDTH`), nie durch die Startzone (untere 2 Reihen) und nicht direkt angrenzend daran.
  - **Brücken:** 1–2 Übergänge (`BRIDGES_MIN/MAX`); eine Brücke überspannt **die gesamte Flussbreite** an dieser Stelle (alle Wasserfelder der Querung werden `B`), beidseitig grenzt passierbares Land an (ggf. Ufer freiräumen). Wo der Fluss Wald/Fels kreuzt, ersetzt er das Gelände.
  - Lösbarkeit wie bisher: alle Gegner von allen Startfeldern erreichbar (jetzt über Brücken).
  - Ausrichtung im Brett (`bridgeAngle`) muss zu längs/quer verlaufenden Flüssen passen.
  - Fertig, wenn: Prüfskript bestätigt für alle Seeds mit Fluss: Fluss berührt zwei gegenüberliegende Ränder, jede Brücke überbrückt die volle Breite, keine Brücke ohne Wasser auf beiden Seiten (quer zur Laufrichtung), Startzone frei.

- [ ] 4. **Sinnvolle Startfelder** – `src/shared/LevelGen.luau`
  - Startfelder nur auf `.` (notfalls `F`), nie auf `B`/`H`/`W`/`M`; von **jedem** Startfeld führt ein Weg nach vorn (Richtung Gegner), ohne zuerst zurück zu müssen: mindestens ein passierbares Nachbarfeld mit kleinerem y (bzw. in Gegnerrichtung).
  - Fertig, wenn: Prüfskript prüft beide Regeln für alle Seeds/Teamgrößen 1–6.

- [ ] 5. **Prüfskript erweitern** – `tests/levelgen.test.luau`: alle neuen Regeln aus 2–4, Determinismus, Rückfallquote ≈ 0. Laufzeit des Skripts im Rahmen halten.

- [ ] 6. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok. Devlog **#26** „Level-Optik Etappe B“ (Teststatus ungetestet), „Nächste Schritte“. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Mehrere Lauf-Level: Karten wirken zusammenhängend (Wälder/Felsen laufen über Stückgrenzen), mehr Abwechslung
- [ ] Flüsse laufen von Rand zu Rand, Brücken überspannen die ganze Breite, keine Brücke auf dem Trockenen
- [ ] Keine Figur startet auf Brücke/Festung; jede kann sofort nach vorn ziehen
- [ ] Schatten unter Figuren zittern bei Kamerabewegung nicht mehr (oder kaum); Thronsaal sieht unverändert aus

## Nicht anfassen
- Story-Missionen (feste Karten), Spielregeln, Thronsaal-Aufbau, Figuren
- `RunConfig`-Werte außer den neuen Fluss-/Brücken-Werten

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden. Befehle außerhalb der Sandbox nur mit Freigabe des Nutzers.)

## Notizen (Codex)
-
