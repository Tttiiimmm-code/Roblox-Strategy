# PLAN: Handy-Fix 2 – Oberfläche oben nicht mehr abgeschnitten, kurze Texte einzeilig

Ziel: Zwei verbleibende Darstellungsfehler auf dem Handy endgültig beheben.
Branch: `feature/level-optik` (weiter)

**Nutzer (08.10.2026, Handy, Querformat, Screenshot 2000×923 px):** Antippen der Helden funktioniert wieder (Devlog #28 ok). Aber:
1. **Oben weiterhin abgeschnitten – an exakt derselben waagerechten Linie (ca. y = 172 px von 923) für ALLE oberen Elemente:** Hinweis-Kasten links (erste Zeile halb weg), Phasen-Banner Mitte („Runde 1“ unsichtbar, Banner-Oberkante fehlt), Gelände-Kasten rechts („Ebene“-Titel halb weg). Das war schon vor allen Handy-Änderungen so (erster Screenshot mit `IgnoreGuiInset = false`). Die Inset-Varianten aus #27/#28 (CoreUISafeInsets, DeviceSafeInsets + GetInsetArea-Versatz) haben nichts geändert. Untertitel steht noch zweizeilig unter/über dem Bannerrand.
2. **Neu kaputt durch #27:** Infofenster unten links: Werte-Raster überlappt („Mag“/„Vert“/„Tmp“/„Bew“ in zwei Zeilen über den Zahlen), „KP“/„EP“-Beschriftung über dem Balken. Ursache: `UIKit.label` setzt standardmäßig `TextScaled`, und `TextScaled` schaltet laut Roblox-Doku `TextWrapped` ein → kurze Beschriftungen brechen um statt kleiner zu werden.

## Schritte

- [x] 1. **Kurze Texte einzeilig** – `src/client/UIKit.luau` (`fitText`/`label`/Buttons): Bei Fit-Texten nach `TextScaled = true` immer `TextWrapped = false` erzwingen (auch wenn später gesetzt), außer der Aufrufer verlangt ausdrücklich Umbruch (z. B. Option `wrap = true` bzw. `flowLabel`). Alle Stellen prüfen, die bisher bewusst `TextWrapped = true` mit festem Kasten nutzen (Waffenzeile im Infofenster, Beschreibungen) – dort entweder `flowLabel` oder Umbruch ohne TextScaled. Infofenster-Raster: jede Zelle einzeilig „Str 2“, „Mag 8“ …; nichts überlappt.

- [x] 2. **Oben nicht abschneiden – deterministischer Aufbau** – `src/client/UIKit.luau` (`createRoot`), `src/client/UI.luau`, `src/client/BattleScene.luau`, Ladebildschirm:
  - ScreenGuis: `IgnoreGuiInset = true`, `ScreenInsets = None`, `ClipToDeviceSafeArea = false` → Layoutfläche beginnt bei Bildschirmpixel 0, **nichts wird von Roblox geclippt**.
  - Sicheren Bereich selbst berechnen: oben = `GuiService.TopbarInset.Max.Y` (Unterkante der Roblox-Leiste in Bildschirmpunkten; falls 0 → `GuiService:GetGuiInset()` Y), links/rechts/unten aus Geräte-Aussparungen (`GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)` relativ zum vollen Bildschirm). Der `SafeArea`-Frame bekommt genau diese Position/Größe (in Pixeln, außerhalb der UIScale), `Root` mit UIScale liegt darin. Aktualisierung bei Änderung von `TopbarInset`, `ViewportSize`.
  - **Diagnose:** Bei `Config.INPUT_DIAGNOSTICS = true` (oder eigenem `UI_DIAGNOSTICS`) einmalig und bei Änderung ausgeben: Viewport, TopbarInset, GuiInset, InsetArea, AbsolutePosition/Size von SafeArea, Root, Phasen-Banner, Hinweis-Kasten, UIScale-Wert – damit der Nutzer bei Bedarf Zahlen liefern kann.
  - Banner: Untertitel einzeilig im Banner (Fit), „Runde x“ sichtbar; Gelände-Kasten und Hinweis-Kasten vollständig.

- [ ] 3. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok. Devlog-Nachtrag (#29). Ein Commit pro Schritt, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Handy: Banner (Runde, Phase, Untertitel einzeilig), Hinweis-Kasten und Gelände-Kasten vollständig, knapp unter der Roblox-Leiste, nichts abgeschnitten
- [ ] Infofenster: Werte sauber in Zeilen, nichts überlappt
- [ ] Antippen/Bewegen funktioniert weiter
- [ ] PC/Studio: Oberfläche sieht aus wie vorher

## Nicht anfassen
- Eingabe-/Touch-Logik aus #28 (funktioniert), Spielregeln, Generator, Brett

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden.)

## Notizen (Codex)
- Schritt 1: Fit-Kurztexte und Buttons erzwingen Einzeiligkeit auch nach späteren Zuweisungen; ausdrücklicher Fit-Umbruch über wrap = true. Waffenzeile, Ladetitel, Speicherwarnung und Laufbeschreibungen behalten Umbruch ohne TextScaled. Eingabelogik unverändert.
- Schritt 2: ScreenGuis ohne automatische Insets/Clipping; SafeArea in Bildschirm-Punkten vor der UIScale. Geräte-Ränder aus DeviceSafeInsets relativ zu ScreenInsets.None, da GetInsetArea laut offizieller GuiService-Doku relativ zur Core-UI liefert. Oben TopbarInset.Max.Y mit GetGuiInset-Fallback, mindestens oberer Geräte-Rand. Kamerawechsel bindet die Viewport-Aktualisierung neu.
- INPUT_DIAGNOSTICS = true protokolliert [UI-Diagnose] einmal und bei Layoutänderungen inklusive Viewport, beider InsetArea-Rechtecke, Topbar-/GuiInset, SafeArea/Root, oberem Phasenbanner, Hinweis, Gelände und UIScale. Standard bleibt false.
- 128 lokale Anschlussprüfungen mit aktuellen Modulen erfolgreich: 16 sichere Flächen einschließlich seitlicher/unterer Aussparungen und negativer InsetArea-Ursprünge, TextScaled-Umbruch-Nebenwirkung, spätere Property-Zuweisungen, expliziter Fit-Umbruch, Leisten-Fallback, Kamerawechsel, Bereinigung und Diagnose. Prüfhilfen in ignoriertem tools/. Kein Roblox-Renderer; manueller Studio-/Handytest und Claude-Review offen.
- Sandbox-Prozessstart defekt; Projektbefehle gemäß Dauerfreigabe über automatische Prüfung außerhalb ausgeführt.
