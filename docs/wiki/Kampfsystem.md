---
tags: [system]
---
# Kampfsystem

Formeln in `src/shared/Combat.luau`, angelehnt an die GBA-Fire-Emblem-Teile.

## Waffendreieck
**Schwert > Axt > Lanze > Schwert.** Vorteil: +1 Schaden, +15 Treffer; Nachteil umgekehrt.

## Formeln
| Wert | Berechnung |
|---|---|
| Schaden | (Str bzw. Mag) + Macht + Dreieck − (Def bzw. Res) − Geländeverteidigung |
| Treffer | Waffentreffer + Gesch × 2 + Glück/2 + Dreieck × 15 − Ausweichen |
| Ausweichen | Tempo × 2 + Glück + Geländebonus |
| Krit | Waffenkrit + Gesch/2 − Glück des Gegners |
| Doppelangriff | Tempo-Vorsprung ≥ 4 |
| Konter | nur, wenn die Entfernung in der Reichweite der eigenen Waffe liegt |

Wurfwaffen (z. B. Wurfspeer) treffen aus 2 Feldern schwächer (`farMight`, `farHit`).

## Erfahrung
- Besiegt: 30 + Levelunterschied × 4
- Schaden verursacht: 10 + Levelunterschied
- Sonst: 1 · Ab 100 EP Level-Up, jeder Wert steigt mit seiner Wachstumsrate der Klasse.

Im [[Tutorial]] gelten feste Werte: garantierte Treffer, keine Krits, keine EP.

Verwandt: [[Einheiten und Helden]], [[Server-Module]] (`EnemyAI`)
