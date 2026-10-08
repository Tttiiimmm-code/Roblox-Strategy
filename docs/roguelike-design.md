# Design: Roguelike-Läufe

Stand: 08.10.2026 – Entscheidungen des Nutzers. **Phase 1 umgesetzt**, Studio-/Handy-Test und Claude-Review noch offen; Phasen 2–7 folgen. Grundlage für spätere Pläne in Etappen. Offene Punkte stehen am Ende und werden vor der jeweiligen Etappe mit dem Nutzer geklärt.

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

## Nachträge (08.10.2026)
- **1 Spieler pro Server** (Servergröße 1 in den Roblox-Spieleinstellungen). Das eine Spielbrett gehört immer dem einzigen Spieler.
- **Leon ist ein normaler Held:** frei wählbar, kein Pflichtmitglied, sein Tod beendet den Lauf nicht.
- **Tutorial = Mission 1 + 2**, Pflicht für neue Spieler, aber per Abfrage überspringbar. Die übrigen handgemachten Missionen werden **entfernt**.
- **Wer während eines Laufs das Spiel verlässt, landet beim nächsten Start direkt wieder im Lauf** (Levelwahl), nicht im Hub. **Aufgeben ist jederzeit möglich** und führt zurück in den Hub.
- **Teamwechsel und Kaserne nur im Lager**; dort auch die teurere Beschwörung. Während eines Laufs gibt es keinen Hub-Zugang.

## Phasen der Umsetzung
Genaue Werte sind Work in Progress: Alle Zahlen kommen als Platzhalter in ein zentrales Konfigurationsmodul.
1. **Lauf-Grundgerüst (Grasland) – umgesetzt:** Lauf starten/aufgeben/fortsetzen, Lauf-Speicherstand im Profil, Team aus 3 Helden, Seed-Generator mit Bausteinen und Lösbarkeitsprüfung, Levelwahl mit 2–3 Optionen (Gegnerschwerpunkt + Belohnung), Teilheilung, Tote bleiben tot, Niederlage wenn alle tot, Belohnung pro Level.
2. **Tutorial-Umbau:** Mission 1 + 2 als Pflicht-Tutorial mit Überspringen-Abfrage, übrige Missionen, Sterne und Schwierigkeitsstufen entfernen, Lauf-Knopf im Hub.
3. **Bosse + Lager:** Miniboss (Level 3) und Gebietsboss (Level 5), Lager als Option (garantiert vor Bossen), volle Heilung, Teamwechsel über Kaserne, Wiederbeleben, Teamplatz +1 nach Boss.
4. **Beute + Händler:** Waffensammlung, Waffen als Level-/Boss-Belohnung, Händler, Rückblende als Item, Notfall-Beschwörung (Wahrscheinlichkeiten sichtbar).
5. **Sumpf + Gefahren-System:** Matsch/Gift, KI meidet Gefahren, weitere Leveltypen (Überleben, Ziel erreichen/verteidigen, Boss besiegen), Gefahren-Symbole in der Wahl.
6. **Eis + Vulkan:** Schneesturm-Nebel (serverseitig verdeckt), Lava, angekündigter Steinschlag, wachsende Bretter.
7. **Punktzahl + Ränge:** Punktzahl, Bestenliste (global, Freunde, Rekord), Ränge nach Sieg, Weiterspielen nach Level 20.

## Stand Phase 1
- Fünf Grasland-Level aus zwölf spiegelbaren 5×4-Bausteinen, Brett 10×8; jeder Lauf hat einen Server-Seed. Wahl und Karten sind deterministisch.
- Drei frei gewählte eigene Helden; Leon ist optional. Nach einem Sieg 30 % der Max-KP als Teilheilung (auf ganze KP aufgerundet, höchstens volle KP); Gefallene bleiben tot. Kein Belohnungsabzug bei Niederlage/Aufgabe, Heldenfortschritt wird beim Kampfabschluss/Aufgeben übernommen.
- Lauf und feste Levelwahl werden im Profil gespeichert. Wiederbeitritt zeigt direkt die Wahl; ein abgebrochenes Level startet mit demselben Seed und den KP vor dem Level neu. Fehlerhafte/unbekannte Speicherstände werden verworfen.
- Bestehende Weltkarte, Missionen, Sterne und Schwierigkeiten bleiben in Phase 1 spielbar. Bosse, Lager, zusätzliche Gebiete, Waffenbeute und Punktzahl folgen in späteren Phasen.
- **Alle Laufwerte WIP in src/shared/RunConfig.luau:** 3 Starthelden (Startfelder bis 6 vorbereitet), 5 Level je Gebiet, 2–3 Optionen, 60 % Gegnerschwerpunkt (auf ganze Gegner aufgerundet), Gegnerzahl 4 + Tiefe, Gegnerlevel 1 + Tiefe. Goldoption: 80 + 40 × Tiefe (120–280); Edelsteinoption: 4 + 2 × Tiefe (6–14). Mindestabstand 4 Felder, höchstens 25 % unpassierbare Felder, 50 Erzeugungsversuche vor offener Rückfallkarte.
- Generatorprüfung: powershell -ExecutionPolicy Bypass -File scripts/test-levelgen.ps1; 15.000 Level- und 5.000 Optionsprüfungen, Rückfallquote 0 %. Stubs prüfen zusätzlich Profil- und Laufübergänge; echte Darstellung/Replikation bleibt manuell zu testen.
- **Vor dem Studio-/Handy-Test Servergröße auf 1 setzen** (Roblox-Spieleinstellungen). Diese Einstellung ist nicht per Spielcode setzbar; das Spiel verwendet weiterhin ein gemeinsames Brett pro Server.

## Entscheidungen Phase 2 – Tutorial (08.10.2026)
- **Starthelden:** Leon + **eine neue Starter-Magierin + ein neuer Starter-Ritter** (vom Nutzer zu entwerfen; bis dahin Platzhalter, nicht im Gacha-Pool). Bruno und Tobi sind keine Starter mehr (bestehende Profile behalten sie, Gacha bleibt).
- **Tutorial-Mission 1:** nur Leon; erklärt Figuren bewegen und Gegner angreifen. **Tutorial-Mission 2:** erklärt, dass Helden verschiedene Eigenschaften haben – Magierin mit größerer Reichweite, Ritter mit größerer Bewegungsweite.
- **Führung Schritt für Schritt:** Markierung zeigt genau, was zu tun ist; andere Aktionen sind bis dahin gesperrt.
- **Überspringen:** Abfrage beim allerersten Start („Tutorial spielen“ / „Überspringen“).
- **Wiederholen:** jederzeit im Menü, ohne erneute Belohnung.
- **Weltkarte:** wird in einer späteren Phase zur Lauf-Karte (Gebiete, Fortschritt); bis dahin **ausgeblendet**. Übrige handgemachte Missionen (3–5), Sterne und Schwierigkeitsstufen entfallen.

## Offene Punkte (vor der jeweiligen Etappe klären)
- Regeln für Matsch und Gift (Bewegungskosten? Schaden pro Runde? Dauer?), für Lava (unpassierbar? Schaden daneben?) und Hindernisse im Grasland.
- Konkrete Bosse und Minibosse je Gebiet (Namen, Fähigkeiten).
- Zahlen: Teilheilung in %, Preise (Wiederbeleben, Händler, Notfall-Beschwörung, Rückblende), Belohnungskurve, Punktzahl-Formel, Weiterspielen nach Level 20.
- Ränge: wie viele, was ändert sich pro Rang.
- Welche Missionen bilden das Tutorial; Weltkarte als Lauf-Ansicht?
- Waffensystem im Detail (Werte, Seltenheit, wer welche Waffe tragen darf).
