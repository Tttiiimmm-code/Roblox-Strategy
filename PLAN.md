# PLAN: Handy-Fix – Banner/Hinweis oben abgeschnitten, Helden per Touch nicht anwählbar

Ziel: Nach dem Handy-Test von Devlog #27 zwei Fehler beheben.
Branch: `feature/level-optik` (weiter)

**Nutzer (08.10.2026, Handy, Querformat, Screenshot 2000×923 px, Lauf-Level):**
1. **Oben abgeschnitten:** Phasen-Banner (`pill` in `UI.buildTop`, jetzt 460×82 mit Runde/Phase/Untertitel) und Hinweis-Kasten oben links sind **an derselben waagerechten Linie (ca. y = 172 px von 923)** abgeschnitten – „Runde 1“ fehlt ganz, die erste Hinweiszeile ist halb weg. Inhalt wird also **abgeschnitten statt nach unten verschoben**. Zusätzlich bricht der Untertitel „Grasland · Level 1/5 · [Symbol] Bogenschützen“ in zwei Zeilen um und ragt unten aus dem Banner.
2. **Helden lassen sich per Touch nicht mehr anwählen** („es macht nichts, wenn ich auf einen Helden klicke“). PC/Studio noch nicht getestet. Vor dem Handy-Text-Umbau wurde im Studio am PC erfolgreich gespielt (Klickfix aus Devlog #25).

**Verdächtige Änderungen (Commits `417a400`, `09d9b50` u. a.):**
- `UI.init` / `buildLoading`: `ScreenInsets = CoreUISafeInsets` + `SafeAreaCompatibility = None` statt `IgnoreGuiInset = false/true`; `UIKit.createRoot`: neuer `SafeArea`-Frame, Skalierung jetzt über dessen `AbsoluteSize`; BattleScene ebenfalls `CoreUISafeInsets`.
- `UIKit.label` setzt standardmäßig `TextScaled` + `UITextSizeConstraint` (auch für alle Buttons), `UIKit.textList` (ScrollingFrame, standardmäßig `Active`), Hinweis-Kasten jetzt in Frame mit `UIListLayout`/`AutomaticSize`.
- Eingabe: `Main.client.luau` `UserInputService.InputBegan` (`processed` blockiert, Zeile ~636–650), Touch-Weg mit `camera:ScreenPointToRay(input.Position…)` (~723/730), Maus mit `ViewportPointToRay` (~750), `CameraController.isActive()`.

## Schritte

- [x] 1. **Ursache Abschneiden finden + beheben** – Roblox-Doku zu `ScreenGui.ScreenInsets`, `SafeAreaCompatibility`, `ClipToDeviceSafeArea`, `GuiService.TopbarInset`/`GetGuiInset` nachlesen (Quellen in Notizen). Ziel-Verhalten: Inhalt beginnt **unterhalb** der Roblox-Leiste und seitlich innerhalb der Aussparungen, nichts wird abgeschnitten. Wenn die Kombination unklar ist, zum vorher funktionierenden Aufbau (`IgnoreGuiInset = false`, ohne SafeAreaCompatibility-Änderung) zurück und den oberen Abstand selbst aus `GuiService.TopbarInset` (bzw. `GetGuiInset`) berechnen. Gilt für TacticsUI, Ladebildschirm, BattleScene.
  - Banner: Untertitel muss in den Banner passen (einzeilig per Fit oder Banner wächst mit), „Runde“-Zeile sichtbar.

- [ ] 2. **Ursache Touch finden + beheben** – systematisch prüfen: (a) bekommt `InputBegan` bei Touch `processed = true`, weil ein unsichtbares oder großes GUI-Element (`Active`, ScrollingFrame aus `textList`, Ladeoverlay/CanvasGroup nach dem Ausblenden, `SafeArea`/`Root`, Hinweis-Frame, Werkzeugspalte jetzt 300 breit) den Touch schluckt? (b) Stimmen Touch-Koordinaten und `ScreenPointToRay` nach der Inset-Änderung noch überein (Versatz um die Leistenhöhe → Treffer daneben)? (c) Bleibt `mode`/`canControl()` hängen (Ladeende, Lauf-Level)? (d) Hält Roblox-Touchsteuerung (TouchGui/Thumbstick des Avatars) den Touch fest? Mit Stubs/statisch belegen, Ursache in Notizen. Fix so, dass Maus und Touch funktionieren.
  - Zusätzlich vorübergehende, abschaltbare Diagnose (Config-Schalter, Standard aus): bei Touch/Klick im Output `processed`, Position, getroffene Instanz und `canControl()` ausgeben – damit der Nutzer bei Bedarf eine Zeile liefern kann.

- [ ] 3. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok. Devlog-Nachtrag zu #27. Ein Commit pro Schritt, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Handy: Banner komplett sichtbar („Runde 1“, „Spielerphase“, Untertitel im Banner), Hinweis-Kasten vollständig, nichts unter der Roblox-Leiste
- [ ] Handy: Held antippen → blaue Felder → Feld antippen → Bewegung/Menü
- [ ] PC/Studio: dasselbe mit der Maus

## Nicht anfassen
- Spielregeln, Generator, Brettoptik, Effekt-Schalter

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden. Bei defekter Sandbox gilt die Dauerregel in AGENTS.md.)

## Notizen (Codex)
- Schritt 1: Doku bestätigt: `IgnoreGuiInset = false` entspricht `CoreUISafeInsets`; `ClipToDeviceSafeArea` clippt nur, `SafeAreaCompatibility.None` verschiebt selbst nichts. Gleiche Schnittkante spricht für den gemeinsamen Flächen-/Insetpfad, ist ohne Geräte-Renderer aber nicht reproduziert. Deshalb explizite Alternative: ScreenGuis mit `DeviceSafeInsets`, Inhalt vor der UIScale um die Differenz der von Roblox gelieferten Core-/Device-Rechtecke versetzen und auf Core-Breite/-Höhe begrenzen (`GuiService:GetInsetArea`). Kein fester Topbarwert und kein doppelter Inset. Root-Abmessungen in Design-Offsets statt gegenseitiger Scale-Kompensation; aktualisiert bei Topbar-/Viewport-/GUI-Größenänderungen. BattleScene nutzt denselben Pfad mit ihrer bisherigen Skalierungsobergrenze 1. Abweichung vom vorgeschlagenen IgnoreGuiInset-Rückbau: dieser würde laut Doku erneut dieselben CoreUISafeInsets wählen; die manuelle Fläche lässt sich dagegen vor der Skalierung belegen.
- Untertitel: `TextScaled` aktiviert laut Doku automatisch `TextWrapped`; der bisherige Fit ließ Umbruch mit Mindestschrift 12 zu. Jetzt Umbruch nach dem Fit explizit aus, Minimum 9, weiterhin maximal 14; alle vorhandenen Texte unverändert. Stubprüfung: 93 Anschlussprüfungen einschließlich 16 Flächen mit überprüftem oberen Abstand und rechten/unteren Grenzen. Keine reale Schriftmessung/Clipping-Simulation, Handybestätigung offen.
- Quellen: [ScreenGui: Insets, Compatibility, Clipping](https://create.roblox.com/docs/reference/engine/classes/ScreenGui), [GuiService: TopbarInset, GetGuiInset, GetInsetArea](https://create.roblox.com/docs/reference/engine/classes/GuiService), [TextScaled aktiviert Umbruch](https://create.roblox.com/docs/reference/engine/classes/TextLabel#TextScaled), [InputObject.Position](https://create.roblox.com/docs/reference/engine/classes/InputObject#Position), [Camera.ScreenPointToRay](https://create.roblox.com/docs/reference/engine/classes/Camera#ScreenPointToRay), [GuiObject.Active](https://create.roblox.com/docs/reference/engine/classes/GuiObject#Active).
