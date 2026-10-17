---
tags: [system]
---
# Tutorial

Daten und Prüfungen in `src/shared/Tutorial.luau`, Missionen in `Stages`, Führung im Client über `TutorialGuide`.

- **Mission 1:** Leon übt Auswahl, Bewegung/Warten, Gegnerzug, Zielwahl und Kampfvorschau.
- **Mission 2:** Magierin greift aus 2 Feldern ohne Konter an, Ritter nutzt seine 7 Bewegungspunkte; danach freies Spiel.
- Willkommensfenster mit Überspringen (bestätigen), Neustart nach Niederlage, Wiederholung im Thronmenü.
- Erster Abschluss: einmalig 150 Gold. Wiederholung ohne Belohnung und ohne EP.
- Der Server prüft jeden Schritt (Mission, Schritt, Session, Figur, Ziel); veraltete Wünsche werden abgelehnt.
- Profilfeld `tutorial.state`: `new` · `done` · `skipped`.

## Prüfen
`scripts/test-tutorial.ps1` – Stub-Tests mit echten Server- und Kampfmodulen (`tests/tutorial.test.luau`).

Verwandt: [[Kampfsystem]], [[Profil und Speichern]]
