# PLAN: Rundschatten für Figuren

Ziel: Figuren werfen keinen Echtzeitschatten mehr, sondern haben einen festen, weich wirkenden Rundschatten am Boden. Kein Zittern bei Kamerabewegung, keine Größenänderung beim Zoomen, schneller am Handy. Bäume/Objekte behalten Echtzeitschatten.
Branch: `feature/level-optik` (weiter)

**Nutzer-Rückmeldung (08.10.2026, Test Etappe B):** Karten „sehen gut aus“. Mit `battleShadowSoftness = 1` werden Schatten beim Rauszoomen größer, beim Reinzoomen kleiner. **Entscheidung: Rundschatten für Figuren.**

**Bestehender Code:** Figuren entstehen über `src/shared/CharacterBuilder.luau` (Mesh/Avatar) bzw. `src/shared/ChibiBuilder.luau`, auf dem Brett über `src/server/UnitVisuals.luau` (u. a. `GroundOffset`, Skalierung); Animation/Zug-Ring/Auswahlring in `src/client/UnitAnimator.luau`; Klone in `src/client/BattleScene.luau` (Kampfszene), Porträts/ViewportFrames in `src/client/UIKit.luau`; Ghost-Vorschau in `Main.client.luau` (`showGhost`). Schattenweichheit im Kampf: `Config.FEEL.battleShadowSoftness` + `src/client/Atmosphere.luau` (Etappe B).

## Schritte

- [x] 1. **Echtzeitschatten der Figuren aus** – alle Teile einer Figur (Körper, Kleidung, Waffe, Aura, Pferd) `CastShadow = false`, an einer zentralen Stelle (gemeinsame Nachbearbeitung im CharacterBuilder bzw. UnitVisuals), sodass Chibi-, Avatar- und Mesh-Figuren gleich behandelt werden. Thronsaal-Figuren (`HubBuilder`) unverändert lassen.

- [x] 2. **Rundschatten** – ein flaches, dunkles Rund unter jeder Brett-Figur, das ihr folgt (am Wurzelteil verschweißt oder in `UnitAnimator` mitbewegt – so, dass es beim Laufen, Angreifen und Tod korrekt mitgeht und beim Tod mit ausblendet). Weich wirkend ohne Bild-Asset: z. B. 2–3 konzentrische flache Scheiben mit abnehmender Deckkraft nach außen (Größe/Deckkraft/Anzahl in `Config.FEEL`, Werte WIP; Größe relativ zur Figurenbreite, Pferde größer). Knapp über der Oberfläche, unter Zug-Ring und Overlays, über Raster/Flecken (Höhen wie in Etappe A2 dokumentiert), `CanCollide/CanQuery/CanTouch/CastShadow = false` (Klicks müssen weiter das Feld treffen). Möglichst wenige transparente Teile (Handy).
  - Auf allen Geländehöhen korrekt (Wald, Berg, Festung, Brücke) – Bezug ist die Feldoberfläche (`Grid.toWorld`/`GroundOffset`), nicht die Figurenhöhe.

- [x] 3. **Kampfszene, Porträts, Ghost** – Kampfszene: Rundschatten auf dem Szenenboden passend mitnehmen oder dort neu setzen; Porträts/ViewportFrames: **kein** Rundschatten; Ghost-Vorschau: halbtransparent wie die Figur oder ohne – Hauptsache kein doppelter/falscher Schatten.

- [x] 4. **Schattenweichheit zurück** – `battleShadowSoftness` entfernen bzw. auf den ursprünglichen Wert (Saalwert) setzen, damit Baum-/Objektschatten nicht mehr mit dem Zoom wachsen. Thronsaal unverändert.

- [x] 5. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok, Prüfung mit Stubs (Rundschatten folgt der Figur, Klick-Raycast trifft weiter die Kachel, keine Figur wirft Schatten). Devlog #26 um Nachtrag ergänzen. **Ein Commit pro Schritt**, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Brett: jede Figur hat einen runden weichen Schatten, der beim Laufen/Angriff mitgeht und beim Tod verschwindet; kein Zittern, keine Größenänderung beim Zoomen
- [ ] Bäume/Objekte haben weiterhin normale Schatten, ohne Zoom-Effekt
- [ ] Kampfszene, Porträts und Bewegungsvorschau sehen richtig aus; Klicks funktionieren
- [ ] Thronsaal unverändert

## Nicht anfassen
- Generator/Bausteine, Spielregeln, Licht-Technik, Thronsaal

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden. Befehle außerhalb der Sandbox nur mit Freigabe des Nutzers.)
- 08.10.2026 (Codex): Werkzeugzugriff blockiert: `Get-Content src/server/UnitVisuals.luau`, die UTF-8-Variante und `rg` scheitern wiederholt bereits beim Prozessstart mit `Rejected("Failed to create unified exec process: helper_unknown_error: setup refresh had errors")`. Bestehende freigegebene Befehle (`git status --short`, Branch-Abfrage, `scripts/check.ps1`) funktionieren. Bitte den Werkzeug-/Sandboxzugriff wiederherstellen und den Durchgang erneut starten. Keine Umgehung oder Ausführung außerhalb der Sandbox versucht; Umsetzung noch nicht begonnen.
  - **Antwort (Nutzer):** Dauerregel in AGENTS.md („Sandbox defekt“): nicht-destruktive Projektbefehle außerhalb der Sandbox mit Freigabe je Befehl. Bitte mit Schritt 1 beginnen.

## Notizen (Codex)
- 08.10.2026: Ausgangszustand sauber auf `feature/level-optik`; Pflichtcheck vor dem gestoppten Abschluss: OK, 32 Dateien (Syntax + undefinierte Variablen). Keine Spielcodeänderungen, keine neuen Studio-Tests, kein Commit/Push. Schritte bleiben offen.
- 08.10.2026 (Fortsetzung): Schritte 1–5 umgesetzt, jeweils eigener Commit auf `feature/level-optik`; Push-Ziel `origin/feature/level-optik`. Werkzeugzugriff teilweise weiterhin defekt; benötigte Projektbefehle mit der oben vorgesehenen Einzelfreigabe außerhalb der Sandbox ausgeführt. Keine neue offene Frage.
- Rundschatten im neuen gemeinsamen Modul `src/shared/UnitShadow.luau`; nur UnitVisuals erzeugt sie für Brett-Figuren. Drei konfigurierbare Scheiben (WIP), Durchmesser relativ zu Körper-/Pferdebreite; Höhen 0,0055–0,0085 Studs über der Feldoberfläche, unter Standardoverlays. Verankert und horizontal mitgeführt, Feldhöhe aus Grid statt Root-Höhe/-Neigung; bei Feldwechseln folgt die Höhe der Oberfläche des Felds unter dem Root. Bestehende Todespfade blenden die Scheiben mit aus. Kampfszene baut auf ihrem Boden neu auf und trennt die Render-Verbindung beim Ende; Porträts/Ghost entfernen Klonschatten. battleShadowSoftness und die Atmosphere-Zuweisung entfernt; Thronsaal unverändert.
- Pflichtcheck nach jedem Umsetzungsschritt grün; Abschluss **OK, 33 Dateien, Exit 0**. Generator **OK: 90.000 Levelprüfungen, 5.000 Optionsprüfungen, 0 Rückfälle (0,00 %)**; erzwungener Rückfall OK. Rojo-Build erfolgreich.
- Lokale Stubs unter ignoriertem `tools/`: **1.681 Assertions**, 48 Chibi-/Avatar-/Mesh-Fixtures (Fuß/Reiter) über alle acht Geländearten; **192 Klickstrahlen** durch Schatten auf Kacheln. Aktuelle UnitVisuals/UnitShadow/UnitAnimator/BattleScene/Atmosphere sowie Porträtfunktion/Ghost-Aufbau geprüft: vollständiges CastShadow-Aus, relative Maße, Höhenfolge, flache Scheiben, Serverlauf, Clientbewegung/Angriffslift, beide Todespfade, Szenenboden/Originalgröße, Verbindungsabbau, Porträt/Ghost ohne Scheiben, keine Duplikate, Saalfigur und ursprüngliche Weichheit unverändert. Keine Rendering-, Replikations- oder echten Assettests; **in Studio/auf dem Handy ungetestet**, manueller Test und unabhängiger Claude-Review offen. Devlog #26 um Nachtrag ergänzt, nächste Schritte aktualisiert.
