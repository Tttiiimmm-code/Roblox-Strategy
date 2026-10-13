---
tags: [system]
---
# Roguelike-Läufe

Design und Entscheidungen: [[roguelike-design]] · Werte: `src/shared/RunConfig.luau` · Server: `RunService` · Oberfläche: `RunUI`.

## Ablauf (Zielbild)
Grasland → Sumpf → Eis → Vulkan, je 5 Level (Level 3 Miniboss, Level 5 Boss). Vor jedem Level 2–3 zufällige Optionen mit Gegnerschwerpunkt und Belohnung. Gold, Edelsteine und Erfahrung bleiben auch bei einer Niederlage.

## Umgesetzt (Phase 1–2)
- Nur **Grasland**, Brett 10 × 8, Start mit 3 Helden.
- Optionen: Gegnerschwerpunkt Axt-, Lanzen- oder Bogentrupp; Belohnung Gold oder Edelsteine.
- 30 % Teilheilung nach jedem Level.
- Lauf wird nach jedem Level im Profil gespeichert (`profile.run`).
- Läufe erst nach abgeschlossenem oder übersprungenem [[Tutorial]].

## Offen
Phase 3/4: Bosse, Lager, Wiederbelebung, Teamplätze, Waffenbeute, Händler · Phase 5–7: weitere Gebiete, Gefahren, Ränge, Bestenlisten → [[Roadmap]]

Verwandt: [[Levelgenerator]], [[Profil und Speichern]]
