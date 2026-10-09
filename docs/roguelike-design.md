# Design: Roguelike-Läufe

Stand: 09.10.2026 – Entscheidungen des Nutzers. **Phasen 1–3 umgesetzt** (Grasland); Phase 3 in Studio/auf Handy ungetestet, Claude-Review ausstehend; Phasen 4–7 folgen. Grundlage für spätere Pläne in Etappen. Offene Punkte stehen am Ende und werden vor der jeweiligen Etappe mit dem Nutzer geklärt.

## Kernidee
Statt fester Missionen spielt man **Läufe** durch 4 Gebiete mit je 5 Leveln. Vor normalen Leveln wählt man aus 2–3 zufällig erzeugten Optionen; Level 3 und 5 sind feste Bosskämpfe. Die **Helden- und Waffensammlung wächst dauerhaft** (Metaprogression): Jeder Lauf macht stärker, auch ein gescheiterter.

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
- **Lager** ist selbst eine mögliche Option statt eines Kampfes. **Vor Level 5 gibt es einen garantierten Extra-Lagerhalt ohne Levelverbrauch.** In Level 1/2/4 ist höchstens eine Lageroption zufällig möglich (aktuelle Entscheidung Phase 3).
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
3. **Bosse + Lager (umgesetzt, Studio-Test/Review offen):** Miniboss (Level 3) und Gebietsboss (Level 5), Lager als Option und Extra-Halt vor Level 5, volle Heilung, Teamwechsel über Kaserne, Wiederbeleben, Teamplatz +1 nach Boss.
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

### Phase 2 umgesetzt (08.10.2026)
- Zwei kleine Tutorialkarten (`tutorial1`, `tutorial2`) mit festen Starter-Teams, Übungswerten auf Level 1 und servergeprüften Schritten. Client zeigt goldene Figuren-/Feld-/Knopfmarkierungen und sperrt andere Aktionen; Kampfvorschau wird vor dem Bestätigen erklärt. Nach M1 wird M2 angeboten, bei Niederlage startet die jeweilige Mission neu.
- Profilfeld `tutorial.state`: `new`, `done`, `skipped`. Alte gespeicherte Helden-Level (auch Level 1) oder Sterne markieren Bestandsspieler als `done`; alte Helden und Sterne bleiben gespeichert. Neue Profile erhalten Leon, Magierin und Ritter.
- Willkommenswahl mit Skip-Bestätigung; Läufe werden erst nach Abschluss/Überspringen freigegeben. Wiederholung im Thronmenü ohne Gold oder EP. Erster Abschluss beider Missionen: einmalig 150 Gold (`Config.TUTORIAL`, WIP). Tutorial verändert keine gespeicherten Heldenwerte und kann während eines laufenden Runs nicht gestartet werden.
- `starter_mage` (Magierin, Mage/Fire, ★3) und `starter_knight` (Ritter, Cavalier/IronLance, ★3) sind **Platzhalter – Design/Name vom Nutzer**; nicht rekrutierbar, fehlende Meshes verwenden den Klassen-Chibi. Bruno/Tobi bleiben in Altprofilen und im Gacha.
- Missionen 3–5, Sterneziele und Schwierigkeitspfade entfernt. Weltkarten-Reiter verborgen/entfernt; Kriegstisch öffnet die Lauf-Teamwahl. Die spätere Lauf-Karte bleibt offen.
- Prüfungen: `scripts/check.ps1`, `scripts/test-tutorial.ps1` (168 Stub-Prüfungen), `scripts/test-levelgen.ps1` und Rojo-Build. Zusätzlich 179 lokale UI-Anschlussprüfungen mit den vorhandenen Stubs. Darstellung, Replikation und Bedienung in Studio/auf dem Handy noch ungetestet; unabhängiger Review durch Claude ausstehend.

## Entscheidungen Phase 3 – Bosse + Lager (09.10.2026)
- **Grasland-Boss = Garrick** (Bandenführer, vorhandene Figur). **Miniboss = neuer Bandit** (z. B. sein Hauptmann; Name/Design Platzhalter, Nutzer entwirft).
- **Garrick (Level 5):** deutlich stärkere Werte; steht in einer **Festung** auf einer **handgemachten Boss-Karte** und bleibt dort, **bis er verletzt wird**, danach bewegt er sich. Fähigkeit **„Kriegsschrei“**: alle Banditen in der Nähe +Stärke für 1 Runde (alle paar Runden). **Phase 2 bei halben KP:** 2–3 Banditen stürmen vom Kartenrand herein, **eine Runde vorher angekündigt**.
- **Miniboss (Level 3):** höhere Werte, **bewegt sich aktiv**, aber mit geringerer Bewegungsweite als normale Gegner; **beschwört bei niedrigen KP 1–2 Gegner**. Keine weitere Phase.
- **Boss-Level gewonnen, sobald der Boss fällt** (restliche Gegner fliehen).
- **Lager:** volle Heilung, Teamwechsel über die Kaserne, Wiederbeleben. **Wiederbeleben kostet Gold (Grundpreis + Aufschlag pro Heldenlevel) oder einen festen Edelsteinpreis** (Werte WIP). Gefallene dürfen gegen Sammlungs-Helden **ausgewechselt** werden, bleiben aber tot, bis sie wiederbelebt werden.
- **Lager-Rhythmus je Gebiet:** L1 Wahl · L2 Wahl · **L3 Miniboss** (fest) · L4 Wahl · **Extra-Lager (garantiert, zählt nicht als Level)** · **L5 Boss** (fest). In den Wahlen L1/L2/L4 kann zufällig ein Lager unter den Optionen sein – gewählt **ersetzt es den Kampf dieses Levels** (kein Kampf, keine Kampfbelohnung, man rückt ein Level vor).
- **+1 Teamplatz nach jedem Gebietsboss** (wirksam beim nächsten Lager bzw. nächsten Gebiet).
- Händler, Waffenbeute, Rückblende-Item und Notfall-Beschwörung folgen in Phase 4.

## Umsetzung Phase 3 – Bosse und Lager (09.10.2026)
- Ablauf: L1/L2 Wahl, L3 Banditenhauptmann, L4 Wahl, Extra-Lager, L5 Garrick. Lager als Wahl ersetzt den Kampf ohne Belohnung. Nach Garrick endet der aktuelle Grasland-Lauf; der neue Teamplatz wird zuvor im Lauf und im Ergebnis vermerkt (spätere Gebiete noch offen).
- Bosskarte in `MapChunks.bossMaps.greenland`: Festung oben, drei Leibwachen, sechs Starts unten, vier freie Randfelder; horizontale Spiegelung nach Seed. Miniboss auf normal erzeugter Karte mit zwei Leibwachen.
- Fähigkeiten sind Gegnerdaten und werden durch `BossAbilities` serverseitig ausgeführt. Beschworene Banditen skalieren wie die ursprünglichen Laufgegner. Markierte Ankunftsfelder bleiben bei Belegung bis zur nächsten freien Gegnerphase offen. Ein Bossfall entfernt auch wartende Markierungen. Kriegsschrei ist als Ansage und goldenes Stärke-Symbol an betroffenen Einheiten sichtbar; endet vor der nächsten Gegnerphase.
- Lager: volle Heilung lebender aktiver Helden; vorhandene Kaserne für Ansicht und ausdrücklich bestätigte Platzwechsel. Todesstatus aller jemals eingesetzten Helden bleibt erhalten; lebende neu eingesetzte Helden starten mit vollen KP. Wiederbelebung per Gold oder Edelsteinen, Preise vor Kauf sichtbar. Ohne lebenden aktiven Helden bleibt „Weiter“ gesperrt, Tauschen/Wiederbeleben weiter möglich.
- Profil-Laufversion 2: `phase`, `campExtra`, `maxTeam` und Todeshistorie auch inaktiver Helden werden geprüft und gespeichert. Alte Phase-1-Läufe werden verworfen, Sammlung/Währungen/Erfahrung bleiben erhalten. Wahl- und Extra-Lager werden bei Wiederkommen fortgesetzt.

**WIP-Werte (noch kein finales Balancing):**

| Wert | Aktueller Platzhalter | Quelle |
|---|---|---|
| Lagerchance pro Wahl | 30 %, höchstens eine Option | `RunConfig.CAMP_CHANCE` |
| Wiederbeleben | 100 + 25 × Heldenlevel Gold oder 15 Edelsteine | `RunConfig.REVIVE_*` |
| Boss-/Miniboss-Belohnung | 3× / 2× normale Tiefenbelohnung, Gold | `RunConfig.*REWARD_MULTIPLIER` |
| Gegner je zusätzlichem Level | +2 KP, +1 Stärke, +1 Verteidigung | `RunConfig.ENEMY_STAT_PER_LEVEL` |
| Hauptmann | Basis 30 KP, Bewegung 3; bei ≤40 % KP einmal 1–2 Banditen, Radius 2 | `UnitData.Enemies.brigand_captain` |
| Garrick | Basis 40 KP; Kriegsschrei alle 3 Runden ab Runde 1, Radius 3, +3 Stärke für 1 Runde | `UnitData.Enemies.chieftain` |
| Garrick Phase 2 | bei ≤50 % KP Ankündigung, 2–3 Banditen in nächster Gegnerphase | `UnitData.Enemies.chieftain.abilities` |

`brigand_captain` / „Banditenhauptmann“ bleibt Platzhalter: Name und eigener Entwurf kommen vom Nutzer; Darstellung derzeit über die vorhandene Klasse Brigand. Händler, Waffenbeute, Rückblenden und Notfall-Beschwörung bleiben Phase 4.

Prüfungen: `scripts/check.ps1`, `scripts/test-levelgen.ps1` (90.000 normale Level, 5.000 Wahlabfolgen, 12.000 Bosskarten), `scripts/test-tutorial.ps1`, `scripts/test-run.ps1` (34.006 Stub-Prüfungen), `scripts/test-run-ui.ps1` (109 UI-Anschlussprüfungen) und Rojo-Build. Automatische Prüfungen simulieren kein echtes Rendering, Roblox-Replikation oder Handybedienung; manuelle Phase-3-Checkboxen in PLAN.md bleiben offen, Claude-Review ausstehend.

## Offene Punkte (vor der jeweiligen Etappe klären)
- Regeln für Matsch und Gift (Bewegungskosten? Schaden pro Runde? Dauer?), für Lava (unpassierbar? Schaden daneben?) und Hindernisse im Grasland.
- Konkrete Bosse und Minibosse je Gebiet (Namen, Fähigkeiten).
- Zahlen: Teilheilung in %, Preise (Wiederbeleben, Händler, Notfall-Beschwörung, Rückblende), Belohnungskurve, Punktzahl-Formel, Weiterspielen nach Level 20.
- Ränge: wie viele, was ändert sich pro Rang.
- Gestaltung der späteren Lauf-Karte (Gebiete und Fortschritt); Weltkarte bis dahin ausgeblendet.
- Waffensystem im Detail (Werte, Seltenheit, wer welche Waffe tragen darf).
