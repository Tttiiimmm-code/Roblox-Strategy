---
tags: [ui]
---
# Oberfläche und Handy

## Designsystem „Throne Tales“ (Devlog #40–#42)
- Y2K-Fantasy: Indigo-Glas-Fenster mit Chromrand, Kronjuwel (nur auf ausgewählten Fenstern), Jelly-Knöpfe mit fester Kante, eine Konturfarbe `ink`, Holo nur für Beschwörung/★5.
- Schriften: LuckiestGuy (Titel/Display), FredokaOne (UI), Michroma (Kennzeilen wie KAMPF/BOSS), GothamMedium (Fließtext).
- Knöpfe mindestens 48 px, zentrale Hauptaktionen 64 px.
- Alle Werte zentral in `client/UIKit.luau`; Vorlage ist das Designsystem-Artifact „Taktik-Fantasy“.

## Skalierung
- Designgröße **1280 × 720**; Skalierung in `UIKit.createRoot`.
- **PC** (Maus ohne Touch): bis Faktor 1,25 größer (`Config.UI_SCALE`), begrenzt durch Mindestfläche 1184 × 664.
- **Handy:** sichere Bildschirmfläche (Notch, Leisten), einzeilige Kurztexte, große Buttons. 72 % der Roblox-Spieler sind mobil.
- Darstellungsfehler: `Config.INPUT_DIAGNOSTICS` einschalten und `[Eingabe]`-/`[UI-Diagnose]`-Zeilen aus dem Output liefern.

Verwandt: [[Client-Module]], [[Test in Studio]], [[stil-guide]]
