---
tags: [ui]
---
# Oberfläche und Handy

- Alle Fenster über `client/UIKit.luau` (blaue Fenster, Goldrand).
- Designgröße **1280 × 720**; Skalierung in `UIKit.createRoot`.
- **PC** (Maus ohne Touch): bis Faktor 1,25 größer (`Config.UI_SCALE`), begrenzt durch Mindestfläche 1184 × 664.
- **Handy:** sichere Bildschirmfläche (Notch, Leisten), einzeilige Kurztexte, große Buttons. 72 % der Roblox-Spieler sind mobil.
- Darstellungsfehler: `Config.INPUT_DIAGNOSTICS` einschalten und `[Eingabe]`-/`[UI-Diagnose]`-Zeilen aus dem Output liefern.

Verwandt: [[Client-Module]], [[Test in Studio]]
