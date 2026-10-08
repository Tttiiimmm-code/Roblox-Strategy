# PLAN: Rundschatten für Figuren

Ziel: Figuren werfen keinen Echtzeitschatten mehr, sondern haben einen festen, weich wirkenden Rundschatten am Boden. Kein Zittern bei Kamerabewegung, keine Größenänderung beim Zoomen, schneller am Handy. Bäume/Objekte behalten Echtzeitschatten.
Branch: `feature/level-optik` (weiter)

**Nutzer-Rückmeldung (08.10.2026, Test Etappe B):** Karten „sehen gut aus“. Mit `battleShadowSoftness = 1` werden Schatten beim Rauszoomen größer, beim Reinzoomen kleiner. **Entscheidung: Rundschatten für Figuren.**

**Bestehender Code:** Figuren entstehen über `src/shared/CharacterBuilder.luau` (Mesh/Avatar) bzw. `src/shared/ChibiBuilder.luau`, auf dem Brett über `src/server/UnitVisuals.luau` (u. a. `GroundOffset`, Skalierung); Animation/Zug-Ring/Auswahlring in `src/client/UnitAnimator.luau`; Klone in `src/client/BattleScene.luau` (Kampfszene), Porträts/ViewportFrames in `src/client/UIKit.luau`; Ghost-Vorschau in `Main.client.luau` (`showGhost`). Schattenweichheit im Kampf: `Config.FEEL.battleShadowSoftness` + `src/client/Atmosphere.luau` (Etappe B).

## Schritte

- [ ] 1. **Echtzeitschatten der Figuren aus** – alle Teile einer Figur (Körper, Kleidung, Waffe, Aura, Pferd) `CastShadow = false`, an einer zentralen Stelle (gemeinsame Nachbearbeitung im CharacterBuilder bzw. UnitVisuals), sodass Chibi-, Avatar- und Mesh-Figuren gleich behandelt werden. Thronsaal-Figuren (`HubBuilder`) unverändert lassen.

- [ ] 2. **Rundschatten** – ein flaches, dunkles Rund unter jeder Brett-Figur, das ihr folgt (am Wurzelteil verschweißt oder in `UnitAnimator` mitbewegt – so, dass es beim Laufen, Angreifen und Tod korrekt mitgeht und beim Tod mit ausblendet). Weich wirkend ohne Bild-Asset: z. B. 2–3 konzentrische flache Scheiben mit abnehmender Deckkraft nach außen (Größe/Deckkraft/Anzahl in `Config.FEEL`, Werte WIP; Größe relativ zur Figurenbreite, Pferde größer). Knapp über der Oberfläche, unter Zug-Ring und Overlays, über Raster/Flecken (Höhen wie in Etappe A2 dokumentiert), `CanCollide/CanQuery/CanTouch/CastShadow = false` (Klicks müssen weiter das Feld treffen). Möglichst wenige transparente Teile (Handy).
  - Auf allen Geländehöhen korrekt (Wald, Berg, Festung, Brücke) – Bezug ist die Feldoberfläche (`Grid.toWorld`/`GroundOffset`), nicht die Figurenhöhe.

- [ ] 3. **Kampfszene, Porträts, Ghost** – Kampfszene: Rundschatten auf dem Szenenboden passend mitnehmen oder dort neu setzen; Porträts/ViewportFrames: **kein** Rundschatten; Ghost-Vorschau: halbtransparent wie die Figur oder ohne – Hauptsache kein doppelter/falscher Schatten.

- [ ] 4. **Schattenweichheit zurück** – `battleShadowSoftness` entfernen bzw. auf den ursprünglichen Wert (Saalwert) setzen, damit Baum-/Objektschatten nicht mehr mit dem Zoom wachsen. Thronsaal unverändert.

- [ ] 5. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok, Prüfung mit Stubs (Rundschatten folgt der Figur, Klick-Raycast trifft weiter die Kachel, keine Figur wirft Schatten). Devlog #26 um Nachtrag ergänzen. **Ein Commit pro Schritt**, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Brett: jede Figur hat einen runden weichen Schatten, der beim Laufen/Angriff mitgeht und beim Tod verschwindet; kein Zittern, keine Größenänderung beim Zoomen
- [ ] Bäume/Objekte haben weiterhin normale Schatten, ohne Zoom-Effekt
- [ ] Kampfszene, Porträts und Bewegungsvorschau sehen richtig aus; Klicks funktionieren
- [ ] Thronsaal unverändert

## Nicht anfassen
- Generator/Bausteine, Spielregeln, Licht-Technik, Thronsaal

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden. Befehle außerhalb der Sandbox nur mit Freigabe des Nutzers.)

## Notizen (Codex)
-
