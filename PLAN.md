# PLAN: Roguelike Phase 2 – Tutorial-Umbau

Ziel: Neue Spieler werden beim ersten Start gefragt, ob sie das Tutorial spielen oder überspringen. Das Tutorial besteht aus zwei **Schritt-für-Schritt geführten** Missionen: Mission 1 nur mit Leon (bewegen, angreifen), Mission 2 mit Leon + Starter-Magierin + Starter-Ritter (verschiedene Eigenschaften: Reichweite der Magierin, Bewegungsweite des Ritters). Danach (oder nach Überspringen) Thronsaal mit „Lauf starten“. Tutorial jederzeit wiederholbar ohne Belohnung. Übrige Missionen, Sterne, Schwierigkeitsstufen und der Weltkarten-Reiter entfallen.
Branch: `feature/lauf-phase2` (existiert, von `main`)
Kontext: **`docs/roguelike-design.md`** lesen, Abschnitt „Entscheidungen Phase 2 – Tutorial“. Werte/Texte sind WIP.

**Bestehender Code:** `src/shared/Stages.luau` (Missionen s1–s5, `Difficulties`, Sterne-Helfer `bestStars/isCleared/isUnlocked/goalTexts/turnGoal/unitLimit`, `Regions` – Regionen bleiben, sie werden von Läufen/Brett genutzt), `src/shared/UnitData.luau` (`Heroes`, `STARTER_HEROES = { "leon", "bruno", "tobi" }`, `recruitable = false`), `src/server/ProfileStore.luau` (`normalize` ergänzt Starter, `stars`), `src/server/Main.server.luau` (`StartStage`, `Retry`, `BeginBattle` mit Leon-Pflicht, `finishBattle` mit Sternen/Gold/`unlockHero`, `checkResult` Lord-Regel für Story), `src/client/MenuUI.luau` (Weltkarte, Missionsdetails/Schwierigkeit, Prep, Ergebnis mit Sternen, Thronmenü), `src/client/Main.client.luau` (Eingabe `onClick`, `selectUnit`, `openMenu`, `startTargeting`, Hinweise `updateHint`), `src/client/UI.luau` (Hinweis-Kasten, Overlays), `RunUI.luau` (Lauf-Start).

**Leitlinien:** Server autoritativ (Tutorial-Schritte prüfen, was erlaubt ist – Client-Sperre allein reicht nicht für Fortschritt/Belohnung). Profil nur ergänzen, alte Profile weiterführen. Ein Commit pro Schritt, `scripts/check.ps1` = OK, `scripts/test-levelgen.ps1` = OK.

## Schritte

- [x] 1. **Starthelden** – `src/shared/UnitData.luau`
  - Zwei neue Helden als **Platzhalter**: `starter_mage` (Klasse `Mage`, Waffe `Fire`) und `starter_knight` (Klasse `Cavalier`, Waffe `IronLance`), Anzeigenamen vorläufig „Magierin“ und „Ritter“, Seltenheit vorläufig ★3, `recruitable = false`, Werte im Rahmen der vorhandenen ★3-Helden, Kommentar „Platzhalter – Design/Name vom Nutzer“. Optik über die vorhandenen Chibi-/Mesh-Wege (fehlendes Modell → Chibi).
  - `STARTER_HEROES = { "leon", "starter_mage", "starter_knight" }`. Bruno/Tobi bleiben im Spiel und im Gacha-Pool; bestehende Profile behalten sie (normalize entfernt nichts).
  - Fertig, wenn: neues Profil hat genau diese drei; altes Profil bekommt die zwei neuen dazu.

- [x] 2. **Missionen auf Tutorial reduzieren** – `src/shared/Stages.luau`
  - `s1`/`s2` werden `tutorial1`/`tutorial2` (eigene IDs, eigene kleine Karten; `unlockHero` entfällt). **Tutorial 1:** kleine Karte, nur Leon (1 Startfeld), 1–2 schwache Banditen, so gebaut, dass die geführte Abfolge sicher klappt. **Tutorial 2:** Leon + Magierin + Ritter (3 Startfelder), Gegner so gestellt, dass (a) die Magierin aus 2 Feldern angreifen kann, ohne Gegenangriff eines Nahkämpfers, (b) der Ritter mit großer Bewegung einen weit entfernten Gegner (z. B. Bogenschütze) erreicht, den Fußtruppen nicht erreichen.
  - `s3`–`s5` entfernen. `Difficulties` und Sterne-Helfer entfernen bzw. auf das reduzieren, was Tutorial braucht (feste Werte, kein Rundenziel, keine Sterne). Alle Verwendungen anpassen (MenuUI, Main.server, Main.client).
  - Fertig, wenn: keine Referenz mehr auf Schwierigkeit/Sterne außer ggf. toleriertem altem Profilfeld `stars` (bleibt unberührt gespeichert oder wird in normalize verworfen – in Notizen begründen).

- [ ] 3. **Profil + Server-Ablauf** – `src/server/ProfileStore.luau`, `src/server/Main.server.luau`
  - `profile.tutorial = { state = "new" | "done" | "skipped" }` (normalize: altes Profil **mit** vorhandenen Helden-Leveln oder Sternen → `done`, damit Bestandsspieler nicht gefragt werden; ganz neues → `new`).
  - Befehle: `TutorialChoice { play = bool }` (nur bei `new`; skip → `skipped`), `StartTutorial { mission = 1|2, replay = bool }`. Tutorial-Kampf: Helden fest (M1 nur Leon, M2 die drei Starter) ohne Prep-Bildschirm; Niederlage → Mission neu; Lord-Regel nur im Tutorial. Sieg M1 → direkt M2 anbieten/starten; Sieg M2 → `done` (erste Absolvierung: kleine Belohnung WIP, z. B. Gold aus Config; Wiederholung ohne Belohnung). Läufe bleiben bis `done`/`skipped` gesperrt.
  - Tutorial-Kampfregeln für sicheren Ablauf (WIP, in Config): Angriffe des Spielers treffen im Tutorial immer; Gegner-KI vorhersehbar (z. B. Gegner in M1 greifen erst nach dem gezeigten Schritt an).
  - Entfernen: `StartStage`/`Retry` für alte Missionen, Sterne-/Schwierigkeits-Belohnungen, `unlockHero`.
  - Fertig, wenn: statische Durchsicht aller Befehle; ungültige Wünsche abgelehnt.

- [ ] 4. **Geführter Ablauf (Client)** – neues Modul `src/client/TutorialGuide.luau`, Anbindung in `Main.client.luau`/`UI.luau`
  - Schrittliste je Mission als Daten (Text + Ziel + erlaubte Aktion), z. B. M1: „Tippe auf Leon“ (nur Leon antippbar) → „Tippe auf das markierte Feld“ (nur dieses Feld) → „Warten“/Zug beenden → Gegnerzug → „Tippe auf den Banditen, um anzugreifen“ → Kampfvorschau erklären → bestätigen. M2: Magierin auswählen, Reichweite 1–2 erklären, aus 2 Feldern angreifen (kein Gegenangriff); Ritter auswählen, große Bewegungsweite erklären, fernen Gegner erreichen; Rest frei mit kurzem Hinweis.
  - Darstellung: gut sichtbare Markierung (pulsierender Rahmen/Pfeil) auf Figur, Feld oder Knopf; Hinweistext im Hinweis-Kasten (groß, handytauglich); alles andere ist bis zum Schritt gesperrt (Eingaben ignorieren + kurzer Hinweis). Gefahr-/Tempo-/Szenen-Knöpfe im Tutorial ausblenden oder sperren.
  - Server prüft Schritt-Fortschritt mit (keine Aktion außerhalb des aktuellen Schritts annehmen).
  - Fertig, wenn: Ablauf statisch und mit Stubs durchgespielt (beide Missionen, Fehltipps, Neustart nach Niederlage).

- [ ] 5. **Oberfläche** – `src/client/MenuUI.luau`, `RunUI.luau`
  - Erster Start (`tutorial.state = "new"`): Fenster „Willkommen …“ mit **„Tutorial spielen“** / **„Überspringen“** (Bestätigung beim Überspringen).
  - Weltkarten-/Missionsreiter **ausblenden** (Lauf-Karte folgt in späterer Phase), Missionsdetails/Schwierigkeit/Sterne-Anzeigen entfernen; Ergebnisbildschirm für Tutorial ohne Sterne.
  - Thronsaal: „Lauf starten“ (erst nach `done`/`skipped`), **„Tutorial wiederholen“**; Kaserne/Rekrutierung unverändert. Lauf-Teamwahl zeigt die neuen Starter.
  - Fertig, wenn: keine Sterne/Schwierigkeit mehr sichtbar; Texte handytauglich (UIKit-Fit-Regeln aus #29).

- [ ] 6. **Doku + Abschluss** – `docs/roguelike-design.md` (Phase 2 umgesetzt, Platzhalter nennen), Charakter-Pipeline: Starter-Magierin/-Ritter als neue Figuren mit IDs `starter_mage`/`starter_knight` in der Figurenliste. `scripts/check.ps1`, `scripts/test-levelgen.ps1`, Rojo-Build. Devlog **#30** „Roguelike Phase 2 – Tutorial“. Committen, pushen, `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Neues Profil (Studio, DataStore leer bzw. ohne API-Zugriff): Willkommensfenster → „Tutorial spielen“
- [ ] Mission 1: nur Leon, jeder Schritt markiert, andere Eingaben gesperrt, Angriff trifft, Sieg → Mission 2
- [ ] Mission 2: Magierin greift aus 2 Feldern ohne Gegenangriff an; Ritter erreicht fernen Gegner; Sieg → Thronsaal
- [ ] „Lauf starten“ funktioniert, Teamwahl zeigt Leon, Magierin, Ritter
- [ ] „Tutorial wiederholen“ → keine Belohnung
- [ ] Neues Profil → „Überspringen“ → direkt Thronsaal, Lauf möglich
- [ ] Bestehendes Profil wird nicht nach dem Tutorial gefragt
- [ ] Keine Sterne/Schwierigkeit/Weltkarte mehr sichtbar; Handy-Texte passen

## Nicht anfassen
- Lauf-Logik (Phase 1), Generator, Brettoptik, Eingabe-/Touch-Grundlogik aus #28 (nur um Tutorial-Sperren ergänzen)

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen – **Design-/Geschmacksfragen nicht selbst entscheiden**, der Nutzer will gefragt werden.)

## Notizen (Codex)
- Schritt 2 entfernt auch die alten Start-/Prep-Pfade und Missionsmenüs, damit keine Aufrufe entfernter Sterne-/Schwierigkeits-Helfer verbleiben. Tutorial-Profilablauf und neue Oberfläche folgen in Schritten 3–5.
- Das alte Profilfeld `stars` bleibt unverändert gespeichert, wird aber nicht mehr an den Client gesendet oder im Spiel ausgewertet.
-
