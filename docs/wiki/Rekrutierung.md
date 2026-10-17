---
tags: [system, monetarisierung]
---
# Rekrutierung (Gacha)

Werte in `src/shared/Recruit.luau`, Oberfläche in `CollectionUI` (Banner, Wahrscheinlichkeiten, Enthüllung, Kaserne).

| Seltenheit | Chance |
|---|---|
| ★5 | 2 % |
| ★4 | 8 % |
| ★3 | 20 % |
| ★2 | 30 % |
| ★1 | 40 % |

- **Pity:** spätestens nach 30 Rufen ★4 oder besser, nach 80 Rufen ★5.
- **Kosten (Banner „Heldenruf“):** 50 Edelsteine einzeln, 450 für 10.
- **Doppelte Helden** werden verschmolzen (max. 10, je +1 KP).

> [!important] Roblox-Regel
> Sobald Edelsteine mit Robux kaufbar sind, müssen alle Wahrscheinlichkeiten **vor dem Kauf** sichtbar sein – über `Recruit.odds()`.

Verwandt: [[Einheiten und Helden]], [[Profil und Speichern]] (`pity`)
