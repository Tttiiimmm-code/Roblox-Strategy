# PLAN: Review-Fixes Visual-Pass 2 – Startreihenfolge, Avatar-Fallback, Licht absichern

Ziel: Die Befunde aus dem Review von Visual-Pass 2 beheben. Der Server soll nie wegen nachladender Avatare oder Licht-Eigenschaften abbrechen. Der Thronsaal steht sofort, und die Porträts erscheinen auch dann, wenn die Vorlagen später ankommen.
Branch: weiter auf `feature/visual-pass-2`
Kontext: `docs/DEVLOG.md` #12 (Visual-Pass 2, ungetestet).

**Allgemein**
- Kleine, gezielte Änderungen; keine weiteren Umbauten. Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt (`fix: …`).

## Schritte

- [x] 1. **Thronsaal zuerst, Avatar-Vorlagen im Hintergrund** – Dateien: `src/server/Main.server.luau`, `src/server/UnitVisuals.luau`
  - Problem: `Main.server.luau:41` `UnitVisuals.init(unitsFolder)` baut in einer Schleife synchron alle Helden-Vorlagen (`CharacterBuilder.build` → `CreateHumanoidModelFromDescriptionAsync`, lädt aus dem Netz). Erst danach baut Zeile 44 `HubBuilder.build()`. Spieler können also ein paar Sekunden ins Leere fallen.
  - `UnitVisuals.init` setzt nur noch `folder`. Den Bau der Vorlagen in eine neue Funktion `UnitVisuals.buildHeroTemplates()` verschieben.
  - Dort den Ordner `HeroTemplates` **sofort** (leer) in `ReplicatedStorage` anlegen und jede fertige Vorlage einzeln hineinlegen. Jeden Helden in `pcall` bauen; bei Fehler `warn` mit Helden-ID und mit dem nächsten Helden weitermachen.
  - In `Main.server.luau` erst `HubBuilder.build()` aufrufen, danach `task.spawn(UnitVisuals.buildHeroTemplates)`.
  - Fertig, wenn: `HubBuilder.build()` läuft vor jedem Avatar-Laden; ein fehlerhafter Held stoppt die übrigen Vorlagen nicht.

- [ ] 2. **Avatar-Fallback absichern** – Datei: `src/shared/CharacterBuilder.luau`, Funktion `avatar`
  - Problem: Der zweite Aufruf von `CreateHumanoidModelFromDescriptionAsync` ohne Accessoires steht ohne `pcall` da. Scheitert auch er, stürzt der Aufrufer ab.
  - Den zweiten Aufruf ebenfalls in `pcall` packen. Scheitert auch dieser: `warn` ausgeben und mit `error(...)` an den Aufrufer weitergeben, damit die `pcall`-Hüllen aus Schritt 1 und 3 greifen. Keinen dritten Ladeversuch und keine anderen Players-APIs einbauen.
  - Defekte Ergebnisse nicht cachen: `bases[key]` nur setzen, wenn ein Modell erfolgreich gebaut wurde.
  - Fertig, wenn: kein ungeschützter Aufruf von `CreateHumanoidModelFromDescriptionAsync` mehr; Fehler landen als `warn` im Output.

- [ ] 3. **Einheiten-Erstellung absichern** – Datei: `src/server/UnitVisuals.luau`, Funktion `UnitVisuals.create`; `src/server/HubBuilder.luau`, Funktion `npc`
  - `CharacterBuilder.build(unit)` in `pcall` aufrufen. Bei Fehler `warn` ausgeben und **zweiter Versuch einmalig** nach `task.wait(1)`. Scheitert auch dieser: Einheit ohne Modell lassen (`return nil`) – vorher prüfen, dass alle Aufrufer von `UnitVisuals.create`/Modell-Lookups mit fehlendem Modell klarkommen (`rg "UnitVisuals.create|FindFirstChild\(.*id" src/server`), fehlende `nil`-Prüfungen ergänzen.
  - Bei `npc` im Thronsaal: Fehler → `warn`, NPC weglassen, Saal-Aufbau läuft weiter (Proximity-Prompt bleibt am Möbel-Anker, nicht am NPC – prüfen, dass das so ist; sonst Prompt an den Anker hängen).
  - Fertig, wenn: Ein Avatar-Ladefehler bricht weder Kampfstart noch Thronsaal ab.

- [ ] 4. **Licht-Eigenschaften absichern** – Datei: `src/server/HubBuilder.luau` (Ende von `HubBuilder.build`)
  - `Lighting.LightingStyle` und `Lighting.PrioritizeLightingQuality` jeweils in eigenes `pcall` setzen; bei Fehler einmalig `warn("LightingStyle per Skript nicht setzbar – in Studio unter Lighting einstellen")`.
  - Zusätzlich in `default.project.json` unter `Lighting` die Eigenschaft `"Technology": "Future"` als `$properties` eintragen (falls `Lighting` dort noch nicht existiert, Knoten `"Lighting": { "$properties": { "Technology": "Future" } }` anlegen). Rojo setzt sie beim Sync/Build, unabhängig von Skript-Rechten. Mit `tools/rojo.exe build` prüfen, dass der Build fehlerfrei bleibt; meldet Rojo die Eigenschaft als unbekannt, Eintrag wieder entfernen und in den Notizen vermerken.
  - Fertig, wenn: `HubBuilder.build` läuft auch durch, wenn die Licht-Eigenschaften nicht setzbar sind.

- [ ] 5. **Porträts warten auf Vorlagen** – Datei: `src/client/UIKit.luau`, Funktion `UIKit.heroPortrait`
  - Ist `HeroTemplates` oder die Vorlage `heroId` noch nicht da: Viewport leeren und per `task.spawn` mit `WaitForChild(…, 10)` auf die Vorlage warten; danach `UIKit.portrait` aufrufen, **aber nur**, wenn der Viewport noch existiert (`viewport.Parent`) und inzwischen kein anderer Held dort angezeigt wird (Attribut `PortraitHero = heroId` am Viewport setzen und vor dem späten Aufruf vergleichen).
  - Fertig, wenn: Kaserne/Rekrutierung direkt nach dem Spielstart zeigt Porträts, sobald die Vorlagen da sind, ohne erneutes Öffnen; schnelles Durchklicken zeigt nie den falschen Helden.

- [ ] 6. **Toter Haarfarben-Code im Thronsaal** – Datei: `src/server/HubBuilder.luau`, Funktion `npc`
  - Die Schleife über `"Hair", "HairBack"` und den Parameter `hair` entfernen (R15-Avatare haben keine solchen Teile); Aufrufe von `npc(...)` entsprechend anpassen.
  - Fertig, wenn: `rg '"HairBack"' src` liefert nichts.

- [ ] 7. `scripts/check.ps1` = `OK`, `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [ ] 8. Devlog-Eintrag #13 „Review-Fixes Visual-Pass 2" (Teststatus „ungetestet"), Branch pushen.

## Manueller Test in Studio (Nutzer)
- [ ] Beim Play-Start steht der Thronsaal sofort, die eigene Figur fällt nicht ins Leere
- [ ] Output: keine roten Zeilen; höchstens gelbe Warnungen zu Avatar/LightingStyle (dann Text an Claude melden)
- [ ] Kaserne direkt nach Spielstart öffnen: Porträts erscheinen (ggf. nach kurzer Verzögerung) und zeigen den richtigen Helden
- [ ] Mission starten: alle Figuren erscheinen, Kampf läuft normal
- [ ] Saal: Licht mit Schatten, nicht überbelichtet
- [ ] Außerdem die offenen Punkte aus Visual-Pass 2: Hüte/Haare, Waffe in der Hand, Kavalier-Sitzhaltung, Laufen/Idle, Figuren auf Bergen/Brücken an der Oberfläche, Sounds

## Nicht anfassen
- Spielregeln, Formeln, KI (`Combat.luau`, `Grid.luau`-Bewegungslogik, `EnemyAI.luau`), `Stages.luau`, `Recruit.luau`, `ProfileStore.luau`
- Befehls-Validierung und Kampf-Timing in `Main.server.luau` (nur die Init-Reihenfolge aus Schritt 1 ändern)
- Asset-IDs (Sounds, Accessoires, Animationen)

## Offene Fragen
- (Codex: hier eintragen und stoppen, falls etwas unklar ist)

## Notizen (Codex)
- Zusätzlich werden die beiden NPC-Aufrufe im HubBuilder mit task.defer nach dem synchronen Saalbau ausgeführt. Ohne diese Anpassung würde HubBuilder.build selbst weiterhin auf Avatar-Ladevorgänge warten.
