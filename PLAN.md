# PLAN: Level-Optik Etappe C1 – große Karten, geschwungene Flüsse, Seen, Klippen und Wasserfälle

Ziel: Lauf-Karten sollen der **Nutzer-Vorlage** näherkommen (gemalte Taktikkarten von oben: geschwungene Flüsse mit kleinen Brücken, Seen mit Inseln, Wasserfall von einer Felsklippe, dichte Wald- und Felsgruppen, belebte Wiesen). Diese Etappe C1 betrifft **Kartengröße und Generator**; die Optik (runde Ufer, dichter Wald mit Umriss, Wiesen-Deko) folgt in **C2**.
Branch: `feature/level-optik-c` (existiert, abgezweigt von `feature/lauf-phase3`, enthält Bosse/Lager)

**Nutzerentscheidungen (09.10.2026):** Kartengröße **wie die Vorlage, ca. 16×12 oder mehr** · **Kamera bleibt** (schräger Blick wie bisher) · Wald **dicht + Umriss** für Figuren (C2) · **Höhenstufen als Klippen mit Wasserfällen: ja**.

**Bestehender Code:** `src/shared/RunConfig.luau` (`BOARD_WIDTH = 10`, `BOARD_HEIGHT = 8`, `CHUNK_WIDTH/HEIGHT = 5/4`, `START_ROWS`, `ENEMY_ROWS`, Fluss-/Brückenwerte, Gegneranzahl je Tiefe, Bosswerte), `src/shared/LevelGen.luau` (Bausteine 2×2, Rand-Profile, Fluss quer links→rechts in Reihen 2–5, Brücken über volle Breite, Startfelder, Lösbarkeit, Boss-/Miniboss-Varianten), `src/shared/MapChunks.luau` (28 Grasland-Stücke 5×4 + Boss-Festung 10×8), `src/shared/Config.luau` (`TERRAIN`, `FEEL`), `src/server/BoardBuilder.luau` (Boden, Randfläche, Terrain-Freiraum, Deko), `src/client/CameraController.luau` (`bounds`, `zoom = clamp(max(size)·0.85, 45, 120)`), Tests `tests/levelgen.test.luau` + `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`.

**Leitlinien:** Story-/Tutorial-Karten bleiben klein und unverändert. Lösbarkeit, Startfeld-Regeln (Devlog #26) und Determinismus bleiben Pflicht. Handy-Leistung: Teilezahl des Bretts im Blick (Ausgabe „Missionsaufbau … Brett/Figuren x ms“, Teilezahl in Notizen vor/nach). Alle Werte WIP in `RunConfig`/`Config`. Ein Commit pro Schritt, alle Prüfskripte grün.

## Schritte

- [x] 1. **Variable Brettgröße** – `RunConfig`, `LevelGen`, `BoardBuilder`, `CameraController`
  - Lauf-Karten **16×12** (Werte zentral, später je Gebiet/Leveltyp änderbar). Bausteingröße so wählen, dass das Brett glatt aufgeht (z. B. 4×4 → 4×3 Stücke, oder 4×3 → 4×4 Stücke – frei, in Notizen begründen); Startzone unten (2 Reihen), Gegnerzone obere Hälfte, Startfelder bis 6 mittig-unten verteilt.
  - Gegnerzahl an die größere Fläche anpassen (WIP-Formel, z. B. Basis + Tiefe, Obergrenze), damit Level nicht leer wirken, aber auf dem Handy nicht ewig dauern.
  - Kamera: Grenzen/Zoom für das große Brett (ganzes Brett erreichbar; Startansicht auf eigene Truppe; Zoom-Obergrenze so, dass man das Brett überblicken kann). Terrain-Freiraum/Randfläche im BoardBuilder auf die neue Größe.
  - Fertig, wenn: Lauf-Level 16×12 bauen; Tutorial unverändert; Teilezahl/Aufbauzeit vorher/nachher in Notizen.

- [ ] 2. **Neue, größere Bausteine** – `MapChunks.luau`
  - Bausteinsatz für die neue Größe neu anlegen (mind. 30 Stücke), im Stil der Vorlage: große zusammenhängende Waldflächen, Felsgruppen, Lichtungen, kleine Festungen/Ruinen, gemischte Wald-Fels-Ränder. Rand-Profile wie bisher (Anschlüsse passend). Bausteine weiterhin ohne Wasser.
  - Fertig, wenn: Vielfalt-Kennzahlen (verschiedene Karten, Geländeanteil, Anschlüsse) in den Notizen.

- [ ] 3. **Flüsse, Seen, Inseln** – `LevelGen.luau`, `RunConfig`
  - **Flüsse stärker geschwungen** (Mäander mit Kurven über mehrere Reihen, Breite 1–2), weiterhin von Rand zu Rand, nicht durch die Startzone; **2–3 Brücken** je nach Länge, jede über die volle Breite, Ufer frei.
  - **Seen/Teiche**: gelegentlich ein See (z. B. 3×3 bis 5×4, unregelmäßige Form), auf Wunsch mit **Insel** (1–2 Felder Land/Wald darin, nicht zwingend erreichbar – dann darf dort kein Gegner/Ziel stehen); ein Fluss darf in einen See münden bzw. aus ihm herausfließen. Zusätzlich kleine Teiche (1–2 Felder) als Hindernis.
  - Lösbarkeit: alle Gegner von allen Startfeldern erreichbar; Hindernisanteil begrenzt (Grenze ggf. für große Karten anpassen).
  - Fertig, wenn: Prüfskript prüft Mäander (Fluss verbindet zwei Ränder, orthogonal zusammenhängend), Brücken volle Breite, Seen/Inseln (keine Gegner auf unerreichbaren Inseln), Quoten in Notizen.

- [ ] 4. **Klippen und Wasserfälle** – `Config.TERRAIN` (neues Zeichen), `LevelGen.luau`, `BoardBuilder.luau`
  - Neues Gelände **„Klippe“/Plateau** (z. B. Zeichen `C`): erhöhte, **unpassierbare** Felsfläche (deutlich höher als Berg, senkrechter Felsrand), in Gruppen von mehreren Feldern am Kartenrand oder als Plateau. Darstellung im bestehenden stilisierten Bodenstil (dunklere Felswände), Klickfeld weiterhin abfragbar (für Info), Figuren können es nicht betreten.
  - **Wasserfall:** gelegentlich entspringt ein Fluss an einer Klippe am Kartenrand und fällt sichtbar herab (einfache stilisierte Darstellung: hellblaue/weiße Fallfläche + etwas Gischt-Deko, keine teuren Partikel auf dem Handy – höchstens wenige, abschaltbar in Config).
  - Fertig, wenn: Klippen/Wasserfälle erscheinen in einem Teil der Karten (Quote WIP), Lösbarkeit und Startzone bleiben ok, Brett baut ohne Fehler.

- [ ] 5. **Boss- und Miniboss-Karten auf neue Größe** – Grasland-Festung für Garrick als handgemachte 16×12-Karte (Festung oben, Leibwache, 6 Startfelder unten, Verstärkungs-Randfelder, gern mit Fluss/Klippe im Stil der Vorlage); Miniboss-Level nutzt den neuen Generator. Bossabläufe aus Phase 3 bleiben unverändert funktionsfähig.

- [ ] 6. **Prüfskripte** – `tests/levelgen.test.luau`, `scripts/test-run.ps1`: alle neuen Regeln (Größe, Mäander, Seen/Inseln, Klippen/Wasserfall, Boss-Karte), Determinismus, Rückfallquote ≈ 0. Laufzeit im Rahmen halten (ggf. Seedzahl anpassen und begründen).

- [ ] 7. Abschluss: `scripts/check.ps1`, `scripts/test-levelgen.ps1`, `scripts/test-run.ps1`, `scripts/test-tutorial.ps1` = OK, Rojo-Build. Devlog **#33** „Level-Optik Etappe C1“, „Nächste Schritte“ (C2: runde Ufer/Sandstreifen, dichter Wald + Umriss, Wiesen-Deko). Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Lauf-Level 16×12: Kamera erreicht das ganze Brett, Start zeigt die eigene Truppe, Zoom ok (PC + Handy)
- [ ] Flüsse geschwungen mit 2–3 Brücken; Seen mit Inseln; Klippen am Rand, manchmal Wasserfall
- [ ] Karten wirken abwechslungsreich, Startfelder sinnvoll, alle Gegner erreichbar
- [ ] Miniboss und Garrick funktionieren auf den neuen Karten
- [ ] Handy flüssig (Aufbauzeit/Bildrate)

## Nicht anfassen
- Tutorial-Karten, Lager-/Boss-Logik (nur Karten), Brett-Grundoptik (C2), Spielregeln

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – **Design-/Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)
- Schritt 1: Lauf 16×12, Bausteine 8×4 (2×3 Stücke; 32 statt 20 Felder pro Stück für größere zusammenhängende Gruppen). Bestehenden Katalog/Festung für lauffähige Zwischenstände auf neue Maße portiert; neue Entwürfe folgen in Schritt 2/5. Startfelder bevorzugen mittig die unteren zwei Reihen. Gegner WIP: min(12, 6 + Tiefe), obere sechs Reihen; Bosslogik unverändert. Grid/Brett bereits variabel; Umgebungsrand skaliert zusätzlich mit Größe. Laufkamera startet mittig unten, Zoom bis Brettdiagonale × 1,6 (16×12: 256 Studs); Tutorial bleibt zentriert.
- Ausgangsmessung: 100 Seeds (1–100), Tiefe 1, sechs Startfelder, Fallback-Deko ohne importierte Assets: 10×8 im Mittel 744,2 Brettteile (633–979), Stub-Aufbau 12,03 ms. Reale Roblox-Aufbauzeit/Bildrate/Figurenaufbau kann nur der Nutzer in Studio/auf Handy bestätigen; hier ungetestet. Nachmessung folgt nach dem finalen Generator.
