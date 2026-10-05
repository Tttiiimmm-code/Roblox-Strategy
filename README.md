# Tactics-Prototyp (Fire-Emblem-Stil) für Roblox

## Einrichten (Rojo)
1. Rojo installieren: VS-Code-Erweiterung **Rojo** + in Roblox Studio das **Rojo-Plugin**
   (oder `rokit install` im Projektordner).
2. Im Projektordner: `rojo serve`
3. Roblox Studio → neue Baseplate → Plugin „Rojo“ → **Connect** → **Play** (F5).

> **Wichtig:** Im Rojo-Fenster als Adresse **`127.0.0.1`** statt `localhost` eintragen (Port `34872`).
> Rojo lauscht nur auf IPv4; mit `localhost` versucht Studio teils IPv6 und meldet „Unknown HTTP error“.

Ohne Rojo: In Studio die Struktur von Hand anlegen (Dateiname = Objektname):
- `ReplicatedStorage/Shared` (Folder) → ModuleScripts aus `src/shared`
- `ServerScriptService/Server` (Folder) → `Main` als **Script**, Rest als ModuleScripts aus `src/server`
- `StarterPlayer/StarterPlayerScripts/Client` (Folder) → `Main` als **LocalScript**, Rest als ModuleScripts aus `src/client`

## Zusammenarbeit Claude + Codex
- `AGENTS.md` – gemeinsame Regeln, Befehle, Code-Stil (lesen beide Agenten)
- `CLAUDE.md` – Rolle von Claude (Planer/Reviewer)
- `PLAN.md` – aktuelle Aufgabe als abhakbare Schritte (Claude schreibt, Codex setzt um)
- `scripts/check.ps1` – Syntax- und Analyseprüfung aller Skripte:
  `powershell -ExecutionPolicy Bypass -File scripts/check.ps1`
- `docs/DEVLOG.md` – Entwicklungstagebuch (Eintrag nach jedem Plan)

## Steuerung
Linksklick: Einheit wählen → Zielfeld → Aktion · Rechtsklick: zurück ·
Gegner anklicken: dessen Reichweite anzeigen · WASD/Q/E/Mausrad: Kamera

## Aufbau
| Datei | Aufgabe |
|---|---|
| `shared/Config` | Gelände, Farben, Timings |
| `shared/UnitData` | Waffen, Klassen, Seltenheiten, Helden, Gegnertypen |
| `shared/Stages` | Missionen (Karten als ASCII, Startfelder), Schwierigkeitsstufen, Sterneziele, Freischaltung |
| `shared/Recruit` | Rekrutierung: Raten, Pity, Kosten, Verschmelzungen (alle Werte hier einstellbar) |
| `shared/CharacterBuilder` | Block-Figuren je Klasse & Seltenheit (Server: Spielfiguren, Client: Porträts) |
| `client/CollectionUI` | Rekrutierung (Banner, Wahrscheinlichkeiten, Enthüllung) und Kaserne |
| `server/ProfileStore` | Gold, Edelsteine, Sterne per DataStore |
| `client/UIKit` | gemeinsame UI-Bausteine, Skalierung |
| `client/MenuUI` | Kartenauswahl, Aufstellung, Ergebnis |
| `shared/Grid` | Dijkstra-Bewegung, Reichweiten, Pfade |
| `shared/Combat` | Waffendreieck, Treffer/Krit, Doppelangriff, 2RN, EP & Level-Up |
| `server/Main` | Spielzustand, Befehlsprüfung, Phasen, Sieg/Niederlage |
| `server/EnemyAI` | Angriffsbewertung, Vorrücken |
| `server/UnitVisuals` | Figuren platzieren, laufen, drehen, KP-Anzeige, Umfallen |
| `client/Main` | Eingabe, Bewegungsvorschau, Kampfvorschau |
| `client/UnitAnimator` | Idle/Laufen, Angriffsanimationen je Waffe, Treffer-Reaktionen |
| `client/UI` | Fenster, Porträt, Phasen-Banner, Level-Up |

Der Server ist autoritativ: Der Client schickt nur „Einheit X → Feld (x,y) → Warten/Angriff auf Y“,
der Server prüft alles nach.

## Nächste Schritte (Ideen)
- Echte Modelle/Animationen statt Zylinder
- Inventar & Waffenhaltbarkeit, Heilstäbe, Gegenstände
- Mehrere Kapitel + Speichern mit DataStoreService
- Unterstützungs-Gespräche, Dialoge zwischen Kapiteln
- PvP: Team pro Spieler statt fest „Player“
