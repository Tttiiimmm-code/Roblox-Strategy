# PLAN: Seltenheits-Effekte aus, Texte auf dem Handy passend

Ziel: (1) Seltenheits-Leuchten/-Partikel vorerst aus (Claude-Änderung prüfen + committen). (2) Alle Texte passen auf dem Handy in ihre Kästen und Knöpfe; nichts wird von der Roblox-Oberfläche oder dem Bildschirmrand abgeschnitten.
Branch: `feature/level-optik` (weiter)

**Nutzer (08.10.2026, Handy-Screenshot im Lauf-Level):** Rundschatten ok. „Particle Effects bei den Helden“ → sollen **ganz weg**. „Der Text passt auf Mobile nicht in die Textboxen.“ Im Screenshot (Querformat, ca. 2000×923 px): Hinweis-Kasten oben links („Tippe auf eine blaue Einheit, um sie zu bewegen. Rote Gegner antippen zeigt ihre …“) läuft über den Kasten hinaus und wird abgeschnitten; Knopf „Gefahr“ zeigt nur „Gefah“; Phasenbanner „Runde 1 / Spielerphase“ ist oben abgeschnitten (Roblox-Leiste); Untertitel „Grasland · Level 1/5 · Bogenschützen“ überlappt den Banner/Hintergrund schlecht lesbar.

## Schritte

- [x] 1. **Review + Commit Seltenheits-Effekte (Claude, uncommittet)** – `src/shared/Config.luau` (`FEEL.rarityEffects = false`), `src/shared/CharacterBuilder.luau`, `src/shared/ChibiBuilder.luau`: PointLight + Funken an der Waffe (★4+) sowie Bodenaura-Ring + Aura-Partikel (★5) nur noch bei `rarityEffects = true`. Schnalle/Kragen/Wappen/Umhangsaum bleiben. Prüfen: Chibi-/Mesh-/Avatar-Pfad, Thronsaal-NPCs, Kampfszene, Porträts, Cache-Schlüssel; nichts sucht die entfernten Teile zwingend. Ergebnis in Notizen, committen.

- [x] 2. **Bestandsaufnahme Texte** – alle UI-Module (`UI.luau`, `MenuUI.luau`, `RunUI.luau`, `CollectionUI.luau`, `UIKit.luau`): jede Textstelle mit fester Kastengröße auflisten, bei der der Text bei Handy-Skalierung (UIScale in `UIKit`, Designgröße 1280×720, Untergrenze 0,5) überlaufen kann. Typische Handy-Auflösungen im Querformat prüfen (z. B. 844×390, 915×412, 1280×720 und Tablet 1024×768 in Roblox-Punkten). Liste in Notizen.

- [x] 3. **Texte passend machen** – zentral in `UIKit` lösen, wo möglich (Hilfsfunktion statt Einzelkorrekturen):
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
- Schritt 2 – vollständige Risikoliste fester Textfelder (vor Änderung, Designpunkte):
  - UI: Runde 320×14, Phase 320×30, Karten-/Laufuntertitel 420×20; Hinweis 330×66 minus 16 Innenabstand (mehrzeilige Anleitung), darunter Aufgeben/Wirklich aufgeben; Gelände 324×62 mit Titel und Zusatzzeilen. Einheiteninfo: Sterne 112×18, Name 266×30, Klasse/Status 266×16, KP/EP, vier Statistikzellen, Waffenzeile 266×20; Aktionsüberschrift/-knöpfe; Vorschau: Namen/Waffen je ca. 215 Punkte, Schaden/Treffer/Krit und Beschriftungen. Werkzeugknöpfe: Gefahr/Tempo/Rückblende nur ca. 66 Punkte breit, Szenen, Zug beenden, Überspringen, Zurück. Meldung 460×44, Level-Up-Titel/Untertitel/Statistikzellen, Phasen-Einblendung, Lade-Titel 732×76, Lade-Untertitel 732×36, Fortschritt 732×34.
  - MenuUI: Weltkarten-Gebietsnamen und Bald verfügbar, Missionsname 220×30 und Sterne 220×22; Fenstertitel/Währung/Schließen, Speicherwarnung (eine Zeile), drei Seitenreiter. Missionsdetails: Name, Beschreibung 60 hoch, Schwierigkeit je ein Drittel der Detailbreite, Regeln 78 hoch, Ziele 86 hoch, Belohnung 50 hoch, dynamischer Startknopf. Aufstellung: langer Titel, Zähler, Info/Regeln und Start/Zurück. Ergebnis: Titel 444×64, Untertitel 444×20, Sterne, Ziele 404×90, Belohnung 444×30 (zusätzlicher Held erzeugt zweite Zeile; überlappt bereits den Knopfbereich), drei Knöpfe. Hub: Titel/Währung, Fremdkampf-Meldung 460×26, Bedienhinweis 640×30. Thron: Überschrift und fünf Einrichtungsknöpfe sowie Aufstehen.
  - RunUI: Überschrift, Untertitel 44 hoch, Auswahlzähler 30 hoch und Fußknöpfe. Teamstreifen: Name/Level/Gefallen in je einem Teamanteil und KP-Balken. Fortsetzungs-Thema/Belohnung, Neustartknopf. Optionskarten: Symbol 27 %, Themenname 22 %, Belohnung 20 % ihrer variablen Höhe. Ergebnisblock: 1×(Höhe−270), bis sechs Helden mit Leerzeilen → zu hoch. Aufgeben-Dialog 632×125 und beide Knöpfe.
  - CollectionUI: Bannername/-beschreibung/Fokus-Hinweis, Edelsteine, sechs Chancen-Zeilen 300×130, Garantie 300×44, Ruf-/Chancenknöpfe. Chancen-Dialog: Titel, Seltenheits-/Heldenzeilen und Garantie 488×52, Schließen. Rekrutierungsergebnis: Titel, Weiter, Karten-Badges. Kaserne: Sammlungszähler, Heldentitel, zweizeilige Klasse/Waffe/Level 276×36, EP, vier Statistikzeilen 276×100, Verschmelzung/Erklärung im Restbereich.
  - UIKit: sämtliche gemeinsamen Knöpfe und Balkentexte; Heldenkarten Name/Klasse/Sterne/Badge (besonders in 122-Punkte-Karten). Alle oben genannten festen Kurztexte brauchen Fit; Fließtexte Wachstum oder Scrollbereich. Weitere kurze Kampfszenentexte verwenden ebenfalls UIKit.label.
- Schritt 2 – rechnerischer Auflösungsabgleich (keine Roblox-Schriftmessung): alte Viewport-Skalierung für 844×390 / 915×412 / 1280×720 / 1024×768 = 0,542 / 0,572 / 1 / 0,8. Mit beispielhaft 36 Punkten Roblox-Leiste verbleiben nur 654 / 657 / 684 / 915 Designpunkte Höhe; die Fläche ist auf drei Geräten kleiner als die geplanten 720. Bei 844×390 mit je 44 Punkten seitlichem Notch-Abstand bleiben 1396×654 Designpunkte; selbst bei großer Breite läuft ein langer Text in einem festen Kasten weiterhin über. Das Verhältnis Text/Kasten bleibt durch UIScale gleich, daher lösen größere Fensterauflösungen diese festen Textfehler nicht. Echte Insets, TextBounds und Lesbarkeit muss der Studio-Geräte-Emulator bestätigen.
- Schritt 3: UIKit.fitText für feste Labels/Knöpfe, ein Größenlimit je Feld, Max folgt auch späterem TextSize; Min 12 bzw. kleinere bereits vorhandene Schriftgröße. Knöpfe mit Umbruch und sechs Punkten Innenabstand. UIKit.flowLabel mit Umbruch und AutomaticSize Y; UIKit.textList für längere Texte ohne feste Texthöhe. Hinweis/Aufgeben über UIListLayout, Gelände wächst; Phase/Untertitel in gemeinsamem 460×82-Fenster, Waffeninfo zweizeilig; Toast mit Abstand zur Einheiteninfo. Missionstexte, Aufstellungsinfos, Missionsergebnis-Ziele/-Belohnungen, Lauf-Ergebnisse, Bannerbeschreibung/Fokus/Chancen/Garantie und Kaserne wachsen in Scrollbereichen. Missionsergebnis höher, Speicherwarnung zweizeilig mit reserviertem Platz; Chancen-Garantie in der vollständigen Liste, zehn Rekrutierungskarten scrollbar. Keine Texte inhaltlich gekürzt. Pflichtcheck OK: 33 Dateien; echte Schriftmessung und Darstellung ungetestet.
