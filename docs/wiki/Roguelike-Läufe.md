---
tags: [system]
---
# Roguelike-Läufe

Design und Entscheidungen: [[roguelike-design]] · Werte: `src/shared/RunConfig.luau` · Server: `RunService` · Oberfläche: `RunUI`.

## Ablauf (Zielbild)
Grasland → Sumpf → Eis → Vulkan, je 5 Level (Level 3 Miniboss, Level 5 Boss). Vor jedem Level 2–3 zufällige Optionen mit Gegnerschwerpunkt und Belohnung. Gold, Edelsteine und Erfahrung bleiben auch bei einer Niederlage.

## Umgesetzt (Phase 1–3)
- Nur **Grasland**, Brett **16 × 12**, Start mit 3 Helden (max. 6 Teamplätze).
- Optionen als Levelwahl-Karten: KAMPF, MINIBOSS, BOSS oder RAST; Gegnerschwerpunkt Axt-, Lanzen- oder Bogentrupp; Belohnung Gold oder Edelsteine.
- **Bosse und Lager** (Phase 3): Miniboss in L3, Extra-Lager vor L5, Boss Garrick in L5, Lager mit 30 % Chance als Option → [[Bosse und Lager]].
- 30 % Teilheilung nach jedem Level, volle Heilung im Lager.
- Lauf wird nach jedem Level im Profil gespeichert (`profile.run`, Laufversion 2).
- Kampflevel liegen auf den schwebenden [[Thronlande]].
- Läufe erst nach abgeschlossenem oder übersprungenem [[Tutorial]].

## Offen
Phase 4: Händler, Waffenbeute, Rückblende-Item, Notfall-Beschwörung · Phase 5–7: weitere Gebiete, Gefahren, Ränge, Bestenlisten → [[Roadmap]]

## Prüfen
`scripts/test-run.ps1` (Laufabfolgen, Bosse, Lager, Brett/Insel) und `scripts/test-run-ui.ps1` (Levelwahl-Oberfläche).

Verwandt: [[Levelgenerator]], [[Profil und Speichern]]
