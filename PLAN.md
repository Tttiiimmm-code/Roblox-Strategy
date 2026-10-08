# PLAN: Seltenheits-Effekte aus, Texte auf dem Handy passend

Ziel: (1) Seltenheits-Leuchten/-Partikel vorerst aus (Claude-Änderung prüfen + committen). (2) Alle Texte passen auf dem Handy in ihre Kästen und Knöpfe; nichts wird von der Roblox-Oberfläche oder dem Bildschirmrand abgeschnitten.
Branch: `feature/level-optik` (weiter)

**Nutzer (08.10.2026, Handy-Screenshot im Lauf-Level):** Rundschatten ok. „Particle Effects bei den Helden“ → sollen **ganz weg**. „Der Text passt auf Mobile nicht in die Textboxen.“ Im Screenshot (Querformat, ca. 2000×923 px): Hinweis-Kasten oben links („Tippe auf eine blaue Einheit, um sie zu bewegen. Rote Gegner antippen zeigt ihre …“) läuft über den Kasten hinaus und wird abgeschnitten; Knopf „Gefahr“ zeigt nur „Gefah“; Phasenbanner „Runde 1 / Spielerphase“ ist oben abgeschnitten (Roblox-Leiste); Untertitel „Grasland · Level 1/5 · Bogenschützen“ überlappt den Banner/Hintergrund schlecht lesbar.

## Schritte

- [x] 1. **Review + Commit Seltenheits-Effekte (Claude, uncommittet)** – `src/shared/Config.luau` (`FEEL.rarityEffects = false`), `src/shared/CharacterBuilder.luau`, `src/shared/ChibiBuilder.luau`: PointLight + Funken an der Waffe (★4+) sowie Bodenaura-Ring + Aura-Partikel (★5) nur noch bei `rarityEffects = true`. Schnalle/Kragen/Wappen/Umhangsaum bleiben. Prüfen: Chibi-/Mesh-/Avatar-Pfad, Thronsaal-NPCs, Kampfszene, Porträts, Cache-Schlüssel; nichts sucht die entfernten Teile zwingend. Ergebnis in Notizen, committen.

- [ ] 2. **Bestandsaufnahme Texte** – alle UI-Module (`UI.luau`, `MenuUI.luau`, `RunUI.luau`, `CollectionUI.luau`, `UIKit.luau`): jede Textstelle mit fester Kastengröße auflisten, bei der der Text bei Handy-Skalierung (UIScale in `UIKit`, Designgröße 1280×720, Untergrenze 0,5) überlaufen kann. Typische Handy-Auflösungen im Querformat prüfen (z. B. 844×390, 915×412, 1280×720 und Tablet 1024×768 in Roblox-Punkten). Liste in Notizen.

- [ ] 3. **Texte passend machen** – zentral in `UIKit` lösen, wo möglich (Hilfsfunktion statt Einzelkorrekturen):
  - Fließtexte (Hinweis-Kasten, Beschreibungen, Ergebnis-Texte): `TextWrapped` + Kasten wächst mit (`AutomaticSize` Y) oder kürzerer Text; nie abgeschnitten.
  - Knöpfe/kurze Beschriftungen: `TextScaled` mit `UITextSizeConstraint` (Max = bisherige Größe, Min lesbar, z. B. 12) **oder** breitere Knöpfe; „Gefahr“, „Szenen an“, „1×“, „Zug beenden“, „Aufgeben“ vollständig lesbar.
  - Kästen dürfen auf kleinen Bildschirmen nicht übereinander liegen (Hinweis-Kasten vs. Aufgeben-Knopf, Banner vs. Untertitel).
  - Texte inhaltlich nicht kürzen, außer es geht nicht anders – dann in Notizen nennen (bei größeren Änderungen Frage eintragen).

- [ ] 4. **Sichere Bereiche** – Roblox-Leiste oben und Kamera-Aussparungen (Notch): ScreenGuis so einstellen, dass nichts darunter liegt (`ScreenInsets = CoreUISafeInsets` bzw. `IgnoreGuiInset` passend, Phasenbanner unterhalb der Roblox-Leiste). Thronsaal-HUD und Lauf-Bildschirme mitprüfen.

- [ ] 5. Abschluss: `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK, Rojo-Build ok. Devlog-Eintrag #27. Ein Commit pro Schritt, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer, Handy + Studio-Geräte-Emulator)
- [ ] Keine Leucht-/Partikeleffekte mehr an Helden; Wappen/Umhang noch da
- [ ] Hinweis-Kasten, alle Knöpfe (Gefahr, Szenen, Tempo, Zug beenden, Aufgeben), Phasenbanner, Untertitel, Lauf-Wahl, Ergebnis, Kaserne, Rekrutierung: Text vollständig, nichts abgeschnitten oder überlappend
- [ ] Nichts unter der Roblox-Leiste oder der Kamera-Aussparung

## Nicht anfassen
- Spielregeln, Generator, Brettoptik, Figurenformen

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – Geschmacksfragen nicht selbst entscheiden. Bei defekter Sandbox gilt die Dauerregel in AGENTS.md.)

## Notizen (Codex)
- Schritt 1: Claude-Änderung geprüft: Chibi, Mesh und Avatar erzeugen Waffenlicht/Funken ab ★4 sowie Bodenaura ab ★5 nur bei aktivem Schalter. Hub-NPCs und Server-HeroTemplates verwenden CharacterBuilder; Kampfszene und Porträts klonen deren Modelle. Keine externe Pflichtsuche nach AuraRing/AuraEmitter. Schnalle, Kragen, Wappen und Umhangsaum bleiben. Mesh-/Chibi-Cache-Schlüssel um den Schalter ergänzt, damit Umschalten keine alte Effektvorlage wiederverwendet. Avatar-Basiscache liegt vor der Seltenheitsdekoration. Eigene Ergänzung wird von Claude unabhängig geprüft; Studio-/Handytest offen.
