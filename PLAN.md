# PLAN: Roguelike Phase 3 – Bosse und Lager

Ziel: Das Grasland bekommt einen **Miniboss in Level 3** und **Garrick als Gebietsboss in Level 5**, dazu das **Lager** (volle Heilung, Teamwechsel, Wiederbeleben) als Wahloption und als garantierten Extra-Halt vor dem Boss. Nach dem Gebietsboss +1 Teamplatz.
Branch: `feature/lauf-phase3` (existiert, von `main`)
Kontext: **`docs/roguelike-design.md`**, Abschnitt „Entscheidungen Phase 3 – Bosse + Lager“ – dort stehen alle Nutzerentscheidungen. **Alle Zahlen WIP** → zentral in `RunConfig` bzw. Gegnerdaten.

**Bestehender Code:** `src/shared/RunConfig.luau`, `src/shared/LevelGen.luau` (`generate`, `makeOptions`), `src/shared/MapChunks.luau`, `src/server/RunService.luau` (`start/choose/stage/finish/abandon`), `src/server/Main.server.luau` (`beginRunLevel`, `finishRunBattle`, `checkResult`, Gegnerphase `runEnemyPhase`, `makeUnit`), `src/server/EnemyAI.luau` (`ai = "stationary"` usw.), `src/shared/UnitData.luau` (`Enemies.chieftain` = Garrick, Klasse `Chieftain`, `ai = "stationary"`), `src/server/ProfileStore.luau` (`normalize` des Laufs), Client `src/client/RunUI.luau` (Wahl-Bildschirm), `MenuUI.luau`/`CollectionUI.luau` (Kaserne), `UI.luau` (Ansagen/Toasts), Prüfskripte `scripts/test-levelgen.ps1`, `scripts/test-tutorial.ps1`.

**Leitlinien:** Server autoritativ (Lager-Aktionen, Preise, Teamwechsel prüfen). Profil nur ergänzen; alte Lauf-Stände ohne neue Felder sauber weiterführen oder verwerfen. Fähigkeiten/Phasen **datengetrieben** an Gegnerdefinitionen (wiederverwendbar für spätere Gebietsbosse), nicht Garrick-spezifisch fest verdrahtet. Ein Commit pro Schritt, alle drei Prüfskripte grün.

## Schritte

- [x] 1. **Ablauf je Gebiet** – `RunConfig`, `LevelGen.makeOptions`, `RunService`
  - Schritte eines Gebiets: L1 Wahl · L2 Wahl · L3 **Miniboss** (einzige Option) · L4 Wahl · **Extra-Lager** (garantiert, zählt nicht als Level) · L5 **Boss** (einzige Option).
  - In den Wahlen L1/L2/L4 kann mit `CAMP_CHANCE` (WIP) eine Option „Lager“ erscheinen (max. 1 je Wahl). Wird sie gewählt: kein Kampf, keine Kampfbelohnung, Lager öffnen, danach `depth += 1`.
  - Laufstand erweitern (z. B. `run.phase = "choice" | "camp"`, `run.campExtra = bool`, `run.maxTeam`), normalize anpassen.
  - Fertig, wenn: Prüfskript erzeugt für viele Seeds die richtige Abfolge (L3/L5 einzige Option, Extra-Lager vor L5, Lager-Optionen nur in L1/L2/L4).

- [x] 2. **Bossdaten + Fähigkeiten** – `UnitData.luau` (Gegner), neues Modul `src/server/BossAbilities.luau`, `EnemyAI.luau`, `Main.server.luau`
  - **Miniboss** (Platzhalter-ID `brigand_captain`, Name „Banditenhauptmann“, Klasse `Brigand` o. ä., höhere Werte, Bewegungsweite unter normalen Gegnern, `ai` aktiv): Fähigkeit **„Verstärkung rufen“**: einmalig, wenn KP ≤ Schwelle (WIP, z. B. 40 %), erscheinen 1–2 Banditen auf freien Feldern nahe dem Miniboss.
  - **Garrick** (Boss): höhere Werte; KI **„Festung halten bis verletzt“** (stationär, solange KP = Max-KP; danach normal bewegend). **„Kriegsschrei“**: alle X Runden (WIP) erhalten Banditen im Umkreis (WIP) +Stärke für 1 Runde (sichtbar: Ansage + Effekt/Symbol an betroffenen Einheiten). **Phase 2** bei ≤ 50 % KP (einmalig): Ankündigung „Verstärkung naht!“ und markierte Randfelder; **in der nächsten Gegnerphase** erscheinen dort 2–3 Banditen.
  - Allgemein: Fähigkeiten als Daten (`abilities = { { type = "summon", ... }, { type = "warcry", ... }, { type = "reinforce", ... } }`), Ausführung serverseitig in der Gegnerphase, Ereignisse an Clients für Ansagen/Effekte. Beschworene Einheiten skalieren mit der Tiefe (RunConfig).
  - Fertig, wenn: Stub-Prüfungen für alle drei Fähigkeiten (Auslöser, Einmaligkeit, freie Felder, Ankündigung eine Runde vorher, Kriegsschrei-Dauer).

- [x] 3. **Boss-Karten** – `MapChunks.luau`/`LevelGen.luau`
  - **Boss-Level:** handgemachte Grasland-Boss-Karte mit **Festung (`H`) für Garrick** im oberen Teil, Leibwache davor, Startfelder unten (bis 6), Randfelder für die Verstärkung definiert. Leichte Variation per Seed erlaubt (Spiegelung), Lösbarkeit wie bisher prüfen.
  - **Miniboss-Level:** erzeugte Karte wie normale Level + Miniboss + kleine Leibwache.
  - Fertig, wenn: Prüfskript prüft Boss-/Miniboss-Karten (Erreichbarkeit, Startfelder, Verstärkungsfelder frei).

- [x] 4. **Sieg bei Bossfall** – `Main.server.luau` (`checkResult`), `RunService.finish`
  - In Boss-/Miniboss-Leveln: Boss fällt → sofort Sieg, übrige Gegner „fliehen“ (entfernen mit kurzer Ansage). Höhere Belohnung (WIP). Nach dem **Gebietsboss**: `run.maxTeam += 1` (bis `MAX_TEAM`), Hinweis im Ergebnis. Da aktuell nur das Grasland existiert, endet der Lauf danach wie bisher als „geschafft“ – Teamplatz-Logik muss trotzdem korrekt im Laufstand landen (für spätere Gebiete).
  - Fertig, wenn: Stub-Prüfung Boss-Sieg mit lebenden Gegnern, Miniboss-Sieg, Teamplatz.

- [ ] 5. **Lager** – Server (`RunService`/`Main.server.luau`, neue Befehle) + Client (`RunUI.luau`, Kaserne wiederverwenden)
  - Beim Betreten: **volle Heilung** aller lebenden Teammitglieder.
  - **Teamwechsel:** Helden aus der Sammlung gegen Teammitglieder tauschen (bis `run.maxTeam` Plätze; leere Plätze nach Teamplatz-Zuwachs füllen). **Gefallene dürfen ausgewechselt werden, bleiben aber tot** (wer später zurückkommt, ist weiter tot). Neu ins Team geholte Helden starten mit vollen KP.
  - **Wiederbeleben:** gefallener Held → lebendig mit vollen KP; Preis in Gold = `REVIVE_GOLD_BASE + REVIVE_GOLD_PER_LEVEL × Level` **oder** fester Edelsteinpreis `REVIVE_GEMS` (WIP); Spieler wählt die Währung; Server prüft Guthaben.
  - **Kaserne** im Lager ansehen (bestehende Kaserne-Ansicht wiederverwenden, nur lesen + Teamwechsel).
  - „Weiter“ verlässt das Lager → nächste Wahl bzw. Boss. Verlassen des Spiels im Lager → beim Wiederkommen wieder im Lager.
  - Oberfläche handytauglich (UIKit-Regeln), Preise sichtbar vor dem Kauf.
  - Fertig, wenn: Stub-Prüfungen für Heilung, Tausch (inkl. Toter), Wiederbeleben beider Währungen, zu wenig Guthaben, Teamgröße, Wiederkommen ins Lager.

- [ ] 6. **Wahl-Bildschirm** – `RunUI.luau`: Lager-Option mit eigenem Symbol; L3/L5 als Boss-Karte mit Namen („Miniboss: Banditenhauptmann“, „Boss: Garrick“) statt Wahl; Extra-Lager vor dem Boss klar erkennbar.

- [ ] 7. **Doku + Abschluss** – `docs/roguelike-design.md` (Phase 3 umgesetzt, Platzhalter/Werte), Charakter-Pipeline: Miniboss `brigand_captain` als neue Figur in der Liste. Prüfskripte erweitern (`test-levelgen` für Abfolge/Karten, neues oder bestehendes Stub-Skript für Fähigkeiten/Lager). `scripts/check.ps1`, alle Prüfskripte, Rojo-Build. Devlog **#32** „Roguelike Phase 3 – Bosse und Lager“. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Lauf: L1/L2 Wahl (manchmal mit Lager-Option), L3 Miniboss, L4 Wahl, Extra-Lager, L5 Garrick
- [ ] Miniboss bewegt sich (kürzer als normale Gegner), ruft bei niedrigen KP 1–2 Banditen
- [ ] Garrick bleibt in der Festung bis zum ersten Treffer; Kriegsschrei sichtbar; bei halben KP Ankündigung, eine Runde später Verstärkung vom Rand
- [ ] Boss fällt → sofort Sieg, Rest flieht
- [ ] Lager: volle Heilung, Tausch mit Sammlungs-Helden (Gefallene bleiben tot), Wiederbeleben mit Gold oder Edelsteinen, Preise sichtbar
- [ ] Lager als Option in L1/L2/L4 ersetzt den Kampf
- [ ] Spiel im Lager verlassen → beim Wiederkommen wieder im Lager
- [ ] Handy: alles lesbar und bedienbar

## Nicht anfassen
- Tutorial, Brettoptik, Generator-Grundlogik normaler Level (nur erweitern), Gacha im Hub

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – **Design-/Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)
- Schritt 1: Laufversion 2; alte Phase-1-Laufst?nde werden verworfen, Sammlung/W?hrungen bleiben erhalten. WIP-Werte zentral. Neuer Stub-Runner `scripts/test-run.ps1` pr?ft 1000 vollst?ndige Abfolgen.

- Schritt 2: Bewegungsweite als Einheitenwert (Grid mit erweitert); Bossereignisse, Randmarkierungen und Kriegsschrei-Symbol angebunden. Besetzte angekündigte Felder warten auf eine spätere freie Gegnerphase. Fähigkeiten- und KI-Stubs grün; Darstellung in Studio ungetestet.

- Schritt 3: Grasland-Festung horizontal gespiegelt, sechs stabile Startfelder, drei Leibwachen und vier freie Randfelder. Normale Generatoraufrufe bleiben unverändert; Bossvarianten werden explizit gewählt. 2000 Lauf-Aufstellungen grün, zusätzliche 12000 Kartenprüfungen im Generatorrunner.

- Schritt 4: Bossfall beendet den Kampf sofort, Leibwache flieht. Gebietsboss schreibt den Teamplatz vor Laufende in den Laufstand und ins Ergebnis. Echte Server-Stubs für beide Bosslevel grün.
