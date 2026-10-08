# Design: Roguelike-Läufe

Stand: 08.10.2026 – Entscheidungen des Nutzers, **noch nicht umgesetzt**. Grundlage für spätere Pläne in Etappen. Offene Punkte stehen am Ende und werden vor der jeweiligen Etappe mit dem Nutzer geklärt.

## Kernidee
Statt fester Missionen spielt man **Läufe** durch 4 Gebiete mit je 5 Leveln. Vor jedem Level wählt man aus 2–3 zufällig erzeugten Optionen. Die **Helden- und Waffensammlung wächst dauerhaft** (Metaprogression): Jeder Lauf macht stärker, auch ein gescheiterter.

## Ablauf eines Laufs
| Gebiet | Level 1–2 | Level 3 | Level 4 | Level 5 | Besonderheit |
|---|---|---|---|---|---|
| Grasland | Wahl | **Miniboss** | Wahl | **Boss** | mehr Hindernisse mit steigendem Fortschritt |
| Sumpf | Wahl | **Miniboss** | Wahl | **Boss** | Matsch und Gift |
| Eisgebiet | Wahl | **Miniboss** | Wahl | **Boss** | Schneesturm: Sicht nur im Radius um eigene Einheiten |
| Vulkan | Wahl | **Miniboss** | Wahl | **Boss** | Lava, Steinschlag |

- Reihenfolge immer **Grasland → Sumpf → Eis → Vulkan**.
- **Fester Boss pro Gebiet** mit Namen und Geschichte (z. B. Garrick im Grasland). Minibosse ebenfalls pro Gebiet.
- **Nach Level 20:** Wahl zwischen Lauf beenden (Sieg) und riskant weiterspielen für höhere Belohnungen und Punktzahl.
- **Niederlage:** Der Lauf ist verloren, wenn **alle Helden tot** sind.
- **Pausieren:** Nach jedem geschafften Level wird der Lauf gespeichert; beim nächsten Spielen geht es ab dem nächsten Level weiter. Wer **mitten im Level** aufhört (auch Verbindungsabbruch), beginnt dieses Level von vorne.

## Levelwahl
- Vor jedem normalen Level **zufällig 2 oder 3 Optionen**.
- Jede Option zeigt Symbole für **Gegnerschwerpunkt** (z. B. Bogen = viele Bogenschützen, Pferd = viele Ritter), **Gelände-Gefahren**, **Belohnung** (Gold, Edelsteine, Waffe) und **Leveltyp**.
- **Leveltypen:** Standard *Alle Gegner besiegen*; seltener *Boss besiegen*, *X Runden überleben*, *Ziel erreichen/verteidigen*. Boss-Level: Boss besiegen.
- **Lager** ist selbst eine mögliche Option statt eines Kampfes. **Vor jedem Boss (Level 3 und 5) ist garantiert ein Lager unter den Optionen.**
- **Kein Rundenlimit**; schnelle Siege geben Bonus-Punkte.

## Team
- Start mit **3 Helden** aus der Sammlung, **+1 Teamplatz nach jedem Gebietsboss** (3 → 4 → 5 → 6).
- **Tote Helden bleiben für den Rest des Laufs tot** – außer sie werden im Lager wiederbelebt.
- **Erfahrung und Level bleiben dauerhaft erhalten**, auch bei Helden, die im Lauf sterben.
- **Heilung:** Teilheilung nach jedem Level, volle Heilung im Lager.

## Lager
- Helden aus der Sammlung **austauschen**.
- Gestorbene Helden **wiederbeleben** gegen **Gold oder Edelsteine**.
- **Händler:** Waffen gegen Gold, **Rückblenden** (Zug zurücknehmen) als kaufbares Item.
- **Notfall-Beschwörung:** zufälliger Held gegen **Edelsteine**, teurer als im Hub. Wahrscheinlichkeiten vor dem Kauf sichtbar (Roblox-Regel, wie `Recruit.odds()`).
- Volle Heilung.

## Beute und Währungen
- **Helden** gibt es nur über Beschwörung (Hub-Gacha oder teurer im Lager), immer zufällig.
- **Waffen:** Level-Belohnung, Boss-/Miniboss-Beute, Händler. Waffen gehen **nicht** kaputt und bleiben dauerhaft in der Sammlung. Aussehen bleibt die eigene Waffe der Figur, Ausrüstung ändert nur Werte (Entscheidung aus Devlog #20).
- **Gold und Edelsteine** behält man nach Sieg *und* Scheitern **vollständig**. Kein Prozent-Abzug: Stattdessen geben schwierigere Level von sich aus mehr – je weiter man kommt, desto mehr verdient man pro Level.

## Schwierigkeit und Punktzahl
- Gegnerstärke steigt **mit dem Fortschritt im Lauf**: höhere Gegnerlevel, bessere Klassen, mehr Hindernisse. Level 1 ist in jedem Lauf gleich schwer – eine starke Sammlung macht frühe Level spürbar leichter (gewollt).
- **Wählbarer Rang:** Nach einem Sieg wird ein höherer Rang mit stärkeren Gegnern freigeschaltet (ähnlich Ascension in Slay the Spire).
- **Bisherige Sterne und Schwierigkeitsstufen entfallen.** Am Ende gibt es eine **Punktzahl** (Fortschritt, besiegte Gegner/Level, Tempo-Bonus, Rang).
- **Bestenliste:** global und Freunde, dazu eigener Rekord.

## Gebiete und Gefahren
- **Grasland:** Grundgelände, mit steigendem Fortschritt mehr Hindernisse.
- **Sumpf:** Matsch und Gift (Regeln offen, siehe unten).
- **Eisgebiet:** Schneesturm = Nebel des Krieges. Gegner nur im Sichtradius eigener Einheiten sichtbar. **Der Server schickt verdeckte Gegnerpositionen nicht an den Client.**
- **Vulkan:** Lava; **Steinschlag eine Runde vorher markiert**, trifft wer stehen bleibt (auch Gegner).
- **Brettgröße:** wächst leicht mit den Gebieten (etwa 10×8 bis 12×10) und hängt zusätzlich vom Leveltyp ab.
- Die Gegner-KI muss alle Gefahren kennen und meiden.

## Bestehendes Spiel
- Die ersten handgemachten Missionen bleiben als **Tutorial** für neue Spieler. Danach nur noch Läufe.
- Rekrutierung (Gacha), Kaserne, Heldensammlung, Waffen und Thronsaal-Hub bleiben.
- Profil-Schema erweitern (Lauf-Speicherstand, Waffensammlung, Rang, Rekord) – alte Profile über `ProfileStore.normalize` weiterführen.

## Technische Leitlinien
- Der **Server erzeugt** jedes Level aus einem **Seed** pro Lauf und Level (wiederholbar, nicht manipulierbar).
- **Bausteine statt reinem Zufall:** handgemachte Kartenstücke je Gebiet, zufällig kombiniert, gespiegelt und variiert.
- **Lösbarkeits-Prüfung** nach dem Erzeugen (alle Gegner erreichbar, Mindestabstand zum Start, Hindernisanteil begrenzt); bei Fehlschlag neu erzeugen.
- **Punktebudget** pro Level für Gegner und Gefahren; der Gegnerschwerpunkt der Option bestimmt, wofür das Budget ausgegeben wird.
- Prüfskript, das viele Seeds automatisch erzeugt und auf Lösbarkeit/Schwierigkeit prüft.

## Offene Punkte (vor der jeweiligen Etappe klären)
- Regeln für Matsch und Gift (Bewegungskosten? Schaden pro Runde? Dauer?), für Lava (unpassierbar? Schaden daneben?) und Hindernisse im Grasland.
- Konkrete Bosse und Minibosse je Gebiet (Namen, Fähigkeiten).
- Zahlen: Teilheilung in %, Preise (Wiederbeleben, Händler, Notfall-Beschwörung, Rückblende), Belohnungskurve, Punktzahl-Formel, Weiterspielen nach Level 20.
- Ränge: wie viele, was ändert sich pro Rang.
- Welche Missionen bilden das Tutorial; Weltkarte als Lauf-Ansicht?
- Waffensystem im Detail (Werte, Seltenheit, wer welche Waffe tragen darf).
