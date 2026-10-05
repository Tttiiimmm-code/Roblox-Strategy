# Devlog – Tactics (Roblox, Fire-Emblem-Stil)

Chronologisches Entwicklungstagebuch. Jeder Eintrag: Ziel · Umsetzung · Entscheidungen · Probleme · Teststatus.
Neue Einträge kommen ans Ende.

---

## #1 – Spielbarer Prototyp
**Datum:** 05.10.2026

**Ziel:** Ein rundenbasiertes Strategiespiel im Stil von Fire Emblem als Roblox-Grundgerüst.

**Umsetzung**
- Projektstruktur für **Rojo** (`default.project.json`): `src/shared` → ReplicatedStorage, `src/server` → ServerScriptService, `src/client` → StarterPlayerScripts. Avatar deaktiviert (`CharacterAutoLoads = false`), reine Taktik-Kamera.
- **Karte** als ASCII-Text (12×10): Ebene, Wald, Berg, Wasser, Festung – jeweils mit Bewegungskosten, Ausweich- und Verteidigungsbonus; Festungen heilen 20 % pro Runde.
- **Bewegung:** Dijkstra-Wegfindung (`Grid.luau`); Verbündete passierbar, Gegner blockieren; Reiter im Wald langsamer, auf Bergen nicht möglich.
- **Kampf** (`Combat.luau`): Waffendreieck (Schwert > Axt > Lanze > Schwert, ±15 Treffer/±1 Schaden), Treffer/Krit-Formeln wie in den GBA-Teilen, „2RN“-Trefferwurf, Doppelangriff ab +4 Tempo, Gegenangriff nur in Reichweite, Bögen 2 Felder, Magie 1–2 Felder gegen Resistenz.
- **Kampfvorschau** vor jedem Angriff; **EP & Level-Up** mit Wachstumsraten pro Klasse; **Permadeath**; Sieg (alle Gegner besiegt) / Niederlage (Lord fällt).
- **Gegner-KI** (`EnemyAI.luau`): bewertet alle erreichbaren Angriffe (erwarteter Schaden, Kill-Bonus, Gegenangriff-Risiko), sonst Vorrücken auf echtem Weg; Boss bleibt stationär.
- **Server-autoritativ:** Client schickt nur „Einheit → Feld → Warten/Angriff“, Server prüft alles. Bewegung + Aktion als ein Befehl (Bewegung im Client nur als Vorschau) → kein Rückgängig-Problem.
- 5 Helden (Fürst, Kavalier, Bogenschütze, Magier, Kämpfer) gegen 7 Gegner inkl. Boss.

**Teststatus:** nicht ausgeführt (kein Studio/Luau-Werkzeug auf dem PC), nur Code-Review.

---

## #2 – Werkzeuge & Roblox Studio einrichten
**Datum:** 05.10.2026

**Umsetzung**
- Rojo 7.4.4 nach `tools/` heruntergeladen, Spieldatei `TacticsGame.rbxlx` per `rojo build` erzeugt.
- Roblox Studio war nicht installiert → offiziellen Installer geladen (Signatur der Roblox Corporation geprüft) und installiert.
- Rojo-Plugin für Studio installiert; `rojo serve` läuft im Hintergrund (Port 34872) für Live-Sync.

**Probleme**
- `rojo plugin install` schlug vor dem ersten Studio-Login fehl (fehlende Registry-Einträge) → Plugin (`Rojo.rbxm`) direkt in `%LOCALAPPDATA%\Roblox\Plugins` gelegt; nach dem Login funktionierte der reguläre Befehl.

**Teststatus:** ✅ Erster Start in Studio – Spiel lief, keine Script-Fehler im Log. Feedback: „Es scheint alles zu funktionieren.“

---

## #3 – Figuren, Kampfanimationen, UI im FE-Stil
**Datum:** 05.10.2026

**Ziel:** Platzhalter-Zylinder durch Charaktermodelle ersetzen, Kämpfe animieren, UI aufhübschen.

**Umsetzung**
- **CharacterBuilder** (Server): Block-Figuren mit Motor6D-Gelenken (Hüfte, Schultern, Nacken, Beine) – je Klasse eigenes Aussehen: Fürst mit Umhang & Diadem, Kavalier auf Pferd, Magier mit Spitzhut & Buch, Bogenschütze mit Kapuze & Köcher, Banditen mit Kopftuch, Soldaten mit Helm, Boss größer mit Hörnerhelm. Waffen sichtbar in der Hand.
- **UnitAnimator** (Client): Idle-Wippen, Laufanimation, Angriffe je Waffentyp (Schwert/Axt: Ausholen & Schlag, Lanze: Stoß, Bogen: Pfeil fliegt, Magie: Feuerball + Explosion), Treffer-Aufleuchten mit Rückstoß, Ausweichen zur Seite, Krit mit Sprung, Umfallen beim Tod.
- Server dreht Kämpfer zueinander und setzt KP exakt im Trefferzeitpunkt (`IMPACT_TIME`), Client animiert – synchron über feste Timings.
- **UI:** blaue Fenster mit Goldrand, Fondamento-Schrift, Phasen-Banner, 3D-Porträt (ViewportFrame) im Info-Fenster, KP-Balken mit Schadensvorschau, Geländeanzeige, Level-Up-Fenster, Waffendreieck-Pfeile ▲▼.

**Entscheidungen:** Animationen laufen nur auf dem Client (flüssig, keine Netzlast); der Server bestimmt nur Ergebnis und Timing.

**Qualität:** Offiziellen Luau-Compiler nach `tools/luau` geladen → alle Skripte syntaxgeprüft (Prüfung meldet Fehler nachweislich korrekt).

**Teststatus:** ✅ in Studio verwendet (Grundlage für die nächsten Schritte).

---

## #4 – Marktrecherche
**Datum:** 05.10.2026

**Ziel:** Von den erfolgreichsten Roblox-Spielen lernen (Gameplay, Optik, Monetarisierung, Spielschleife).

**Ergebnis** (Details: `docs/recherche-roblox-markt.md`, 22 Quellen)
- Hits haben einen in einem Satz erklärbaren Loop, Sammeln mit Seltenheiten, Events, soziale Elemente.
- Roblox-Algorithmus belohnt: wenig Absprung in den ersten 60 s, viele Spieltage, Spielen mit Freunden.
- 72 % Handy-Nutzung → Touch-Steuerung ist Pflicht.
- Zufallsitems gegen Robux erfordern sichtbare Wahrscheinlichkeiten.
- Kein großes Roblox-Taktikspiel gefunden → Nische; nächstes Genre ist Tower Defense mit Einheiten-Sammeln.

**Entscheidungen (mit dir abgestimmt):** Zugänglichkeit für alle Alters- und Könnensstufen + ansprechende Figuren mit Seltenheitsstufen haben Priorität.

---

## #5 – Etappe 1: Schwierigkeit, Sterne, Seltenheit, Zugänglichkeit
**Datum:** 05.10.2026

**Ziel:** Spiel für alle zugänglich machen; Leistung belohnen; Seltenheiten sichtbar machen.

**Umsetzung**
- **Spielablauf:** Kartenauswahl → Aufstellung → Kampf → Ergebnis → Nächste Mission / Nochmal.
- **3 Missionen** (`Stages.luau`): Grenzdorf (Einstieg, 3 Helden), Waldpass (Fluss mit Brücken – neues Gelände „Brücke“), Banditenfestung (Boss). Helden kommen nach und nach dazu.
- **Schwierigkeitsstufen pro Mission:**
  - *Leicht:* schwächere Gegner, 3× Rückblende, +4 Runden Ziel, 1× Gold, 5 ♦/Stern
  - *Normal:* Standard, 1× Rückblende, 2× Gold, 10 ♦/Stern
  - *Schwer:* stärkere + zusätzliche Gegner, max. 4 Einheiten, keine Rückblende, −1 Runde, 3× Gold, 20 ♦/Stern, erst nach Normal freigeschaltet
- **3 Sterne:** Sieg · keine Verluste · Rundenziel. Gold je Sieg (mehr bei mehr Sternen), Edelsteine nur für **neue** Sterne → Wiederholen lohnt sich.
- **Rückblende** (Zug zurücknehmen) serverseitig per Zustands-Snapshot.
- **Speichern** (`ProfileStore.luau`, DataStore): Gold, Edelsteine, Sterne; fällt ohne API-Zugriff sauber auf Sitzungsspeicher zurück (Hinweis in der Kartenauswahl).
- **Seltenheiten ★1–★5** (Gewöhnlich → Legendär) mit aufwendigerem Design je Stufe: Schnalle → Metallkragen → leuchtende Waffe mit Funken & Umhangsaum → goldenes Wappen & Aura mit aufsteigenden Funken. Farbige Namen, Kartenrahmen, Porträts.
- **Zugänglichkeit:** Touch (Tippen, Ziehen, Pinch-Zoom, Zwei-Finger-Drehen), Zurück-Button, Kontext-Hinweise je Schritt, Gefahrenzone (alle Gegnerreichweiten), Tempo 1×/2×, Aufgeben mit Bestätigung, UI skaliert mit der Bildschirmgröße.
- Neue Client-Module: `UIKit` (gemeinsame Bausteine), `MenuUI` (Kartenauswahl, Aufstellung, Ergebnis mit animierten Sternen).

**Probleme**
- Tempo-Helfer in `UnitAnimator` wurden vor ihrer Definition benutzt → beim Prüfen gefunden und behoben.
- Luau-Analyzer zusätzlich eingesetzt: keine undefinierten Variablen (nur Roblox-Globals gemeldet).
- Hook „GateGuard“ blockierte jede neue Datei → `src/**` und `docs/**` per `.claude/settings.local.json` freigegeben.

**Offen:** Speichern in Studio erst nach Veröffentlichung + „Enable Studio Access to API Services“.

**Teststatus:** ✅ In Studio getestet – Feedback: „Hat alles funktioniert“.

---

## #6 – Etappe 2 (Grundgerüst): Rekrutierung, Kaserne, dauerhafte Helden
**Datum:** 05.10.2026

> ⚠ **Grundgerüst, nicht final.** Alle Zahlen, Helden, Texte und Layouts sind Platzhalter und bewusst zentral in Konfigurationstabellen abgelegt, damit sie jederzeit geändert werden können.

**Ziel:** Sammel- und Fortschrittssystem: Helden rekrutieren, sammeln, dauerhaft verbessern.

**Umsetzung**
- **Heldenpool:** 6 neue Helden → je 2 rekrutierbare pro Seltenheit (★1 Finn, Ida · ★2 Bruno, Kai · ★3 Tobi, Greta · ★4 Mira, Selina · ★5 Aurelia, Siegfried). Leon bleibt fester Startheld. Neue Helden mit eigener Haarfarbe zur Unterscheidung.
- **Rekrutierung** (`shared/Recruit.luau`, Server-seitig gewürfelt):
  - 1× = 50 ♦, 10× = 450 ♦
  - Chancen: ★5 2 % · ★4 8 % · ★3 20 % · ★2 30 % · ★1 40 %, innerhalb einer Stufe gleich verteilt
  - Pity: spätestens 30. Ruf ★4+, spätestens 80. Ruf ★5 (Zähler im Profil gespeichert)
  - Doppelte Helden → Verschmelzung (+1 KP je Stufe, max. 10) – Platzhalter-Effekt
  - Vollständige Wahrscheinlichkeitsliste je Held vor dem Kauf einsehbar (Roblox-Pflicht, sobald Edelsteine mit Robux kaufbar werden)
  - Enthüllung: Karten erscheinen nacheinander, „NEU!“ bzw. „+1 Verschm.“, Goldblitz bei ★5
- **Kaserne:** Sammlung mit Fortschritt („Helden gesammelt: x / y“), Detailansicht mit 3D-Porträt, Werten, Level, EP, Verschmelzungen.
- **Dauerhafte Helden:** Level, EP und durch Level-Ups gestiegene Werte werden nach jedem Kampf (Sieg oder Niederlage) ins Profil geschrieben.
- **Aufstellung neu:** Missionen haben Startfelder statt fester Helden; du wählst deinen Trupp aus der Sammlung (Leon immer dabei, Limit je Karte/Stufe). Letzter Trupp wird vorausgewählt.
- **Story-Freischaltung:** Erster Sieg in Grenzdorf → Mira, in Waldpass → Selina (Anzeige im Ergebnis).
- **Lobby mit Reitern:** Missionen · Rekrutieren · Kaserne.
- Neue Profile: Leon, Bruno, Tobi + 300 ♦ Startguthaben (zum Ausprobieren).
- `CharacterBuilder` nach `shared` verschoben, damit der Client Porträts für Helden bauen kann, die nicht auf dem Feld stehen.

**Technik:** Profil-Schema v2 (`heroes`, `pity`) mit automatischer Ergänzung fehlender Felder. Bei der Rückblende werden die Helden-Referenzen mit den wiederhergestellten Einheiten aktualisiert, damit der Fortschritt korrekt gespeichert wird.

**Qualität:** alle 19 Skripte syntaxgeprüft, Luau-Analyzer ohne undefinierte Variablen.

**Teststatus:** ⏳ noch nicht in Studio getestet.

---

## #7 – Fix: Rojo-Verbindung („Unknown HTTP error“)
**Datum:** 05.10.2026

**Problem:** Studio konnte sich nicht mehr mit dem Rojo-Server verbinden – erst endloses Laden, dann „Unknown HTTP error“.

**Analyse:** Server lief und lieferte die Projektdaten korrekt aus (geprüft über `/api/rojo` und `/api/read`). Er lauscht aber nur auf `127.0.0.1` (IPv4); Studio löste `localhost` teils als IPv6 (`::1`) auf und erreichte ihn nicht. Server zusätzlich frisch neu gestartet.

**Lösung:** Im Rojo-Plugin als Adresse **`127.0.0.1`** eintragen (Port 34872). Hinweis in die README aufgenommen.

**Teststatus:** ✅ Verbindung klappt – bestätigt.

Nachtrag zu #6: ✅ Etappe 2 in Studio getestet – „Funktioniert“.

---

## #8 – Thronsaal-Hub (Grundgerüst)
**Datum:** 05.10.2026

**Idee (von dir):** 3D-Thronsaal in Weiß/Rot/Gold als Hub. Spieler laufen mit eigenem Avatar herum und treffen sich. Einrichtungen: Kriegstisch/Lageplan → Missionen, Soldatenquartier → Kaserne, Hofmagier mit Beschwörungskreis → Rekrutieren. Auf den großen Thron springen öffnet ein Schnellmenü mit allen Einrichtungen.

**Erledigt (Server)**
- `server/HubBuilder.luau`: Saal mit Marmorboden, rotem Teppich mit Goldkanten, Säulen, Wandbannern, Kronleuchtern, Empore mit Thron (`Seat` „Throne“), Kriegstisch mit Mini-Lageplan aus der echten Karte, Waffenständer + Hauptmann, Beschwörungskreis mit Runen, Partikeln und Magier. ProximityPrompts (Taste E) mit Attribut `Station` = missions/recruit/barracks. Spawn im Saal (`HubSpawn`).
- Avatare aktiviert (`CharacterAutoLoads = true`, auch in `default.project.json`).
- Kampf-Besitzer: Wer eine Mission startet, steuert sie allein (`ownerUserId/ownerName` im Snapshot); andere Spieler können nur noch rekrutieren und die Kaserne nutzen.

- Verlässt der Kampf-Besitzer das Spiel, wird der Kampf beendet.

**Erledigt (Client)**
- `CameraController.setActive`: Taktik-Kamera nur im eigenen Kampf, sonst normale Avatar-Kamera.
- `client/Hub.luau`: Prompts → Menü öffnen, Sitzen auf dem Thron → Schnellmenü, drehende Runen/Kreis, Avatar-Steuerung und Prompts im Kampf gesperrt.
- `MenuUI`: Menüs öffnen nur auf Wunsch (✕ zum Schließen), Schnellmenü am Thron (Missionen/Rekrutieren/Kaserne/Aufstehen), Saal-Anzeige mit Gold/Edelsteinen und Hinweis „X kämpft gerade“; Missionsstart gesperrt, solange ein anderer kämpft. Nach Kampf/Aufstellung zurück → Missionsmenü öffnet sich direkt wieder.
- `Main.client`: Kampfansicht, Eingaben und EP-Meldungen nur im eigenen Kampf.

**Qualität:** Syntaxcheck und Analyzer ohne Fehler.

**Teststatus:** ⏳ noch nicht in Studio getestet.

**Bekannte Einschränkung:** Der Server führt nur einen Kampf gleichzeitig. Eigene Kampf-Instanzen pro Spieler wären der nächste größere Umbau.

---

## #9 – Arbeitsweise: Claude + Codex
**Datum:** 05.10.2026

**Ziel:** Weiterentwicklung auf zwei KI-Agenten aufteilen, um Nutzungslimits zu schonen: Claude plant und reviewt, Codex setzt um, du testest.

**Umsetzung**
- `AGENTS.md` (gemeinsame Regeln) mit echten Projektdaten gefüllt: Roblox/Luau/Rojo, Ordnerstruktur, Befehle, Architekturregeln (Server autoritativ, Werte zentral, Profil-Schema, Odds-Pflicht), manueller Testablauf, Devlog-Pflicht für beide Agenten.
- `CLAUDE.md`: Rolle Planer/Reviewer; Pläne mit konkreten Dateien, Mustern und Studio-Prüfpunkten.
- `PLAN.md`: Vorlage um Kontext, Prüf-/Build-/Devlog-Schritte und einen Abschnitt „Manueller Test in Studio“ ergänzt.
- `scripts/check.ps1`: ein Befehl für Syntax + undefinierte Variablen über alle Skripte (Exit 0 = ok).
- Git-Repository angelegt (`main`), `.gitignore` für Build-Datei, `tools/` und lokale Einstellungen.

**Probleme:** Windows PowerShell 5.1 wertet stderr des Analyzers bei `ErrorActionPreference = Stop` als Abbruch → auf `Continue` gestellt; Umlaute in der Ausgabe durch ASCII ersetzt.

**Teststatus:** ✅ `check.ps1` läuft (21 Dateien, OK).

---

## #10 – Game-Feel-Pass 1: Sound, Licht, Kampf und UI
**Datum:** 05.10.2026

**Ziel:** Lebendigeres Spielgefühl im Thronsaal, auf dem Schlachtfeld und in den Menüs, ohne Änderungen an Spielregeln, Balancing oder Profilformat.

**Umsetzung**
- `shared/Sounds.luau` und `client/SoundPlayer.luau`: stumme Audio-Platzhalter mit Lautstärken, optionaler Pitch-Variation und Musik-Überblendung. Buttons, Menüs, Treffer/Krit/Verfehlen, Tod, Level-Up, Phasen, Ergebnissterne und Rekrutierung sind angebunden; Musik folgt Saal, Kampf und Ergebnis.
- `client/Atmosphere.luau`: lokale Licht-Presets für warmen Saal und klareres Schlachtfeld mit Bloom, Farbkorrektur, Sonnenstrahlen, Dunst und dezenter Tiefenunschärfe im Saal. Wechsel über 0,8 Sekunden.
- Saal mit schwebendem Staub, flackernden Kronleuchtern und vier hohen Fensterflächen mit Lichtstrahlen. Grasboden, deterministische Bäume und Felsen außerhalb des Bretts; Dekoration bleibt für Feld-Klicks durchlässig (`CanQuery=false`).
- Kamera fokussiert Schlagabtausche und gegnerische Bewegungsziele, wackelt beim Treffer und kehrt anschließend zurück. Krits erhalten stärkeren/längeren Shake und Weißblitz. Trefferreaktion um 0,06 Sekunden verzögert, über das Kampf-Tempo skaliert.
- HUD-Button „⏩ Gegnerphase“ setzt Tempo 3; am Phasenende stellt der Server das vorherige Tempo wieder her. Neues `enemyMove`-Event vor Gegnerbewegungen.
- Laufpfade als durchgehende Bewegung mit Sinus-Anlauf/Auslauf und weichen Richtungswechseln. Staub-Bursts, Atmen, zufällige Gesten, nachschwingende Umhänge und Auswahlhüpfer mit leuchtendem Ring; auch Saal-Figuren bewegen sich im Stand.
- Figuren mit Händen, Stiefeln, konfigurierbarem Gesichts-Decal und abgeschrägten Schulterstücken. Körper-Hitboxen bleiben gleich. Reichweiten blenden ein, Angriffsfelder pulsieren.
- Buttons skalieren beim Drücken/Hovern; Fenster gleiten und blenden auf/zu, Reiter überblenden, Gold/Edelsteine zählen bei Änderungen. Info-Panel und Toasts animiert; Haptik bei Treffer/Krit wird geschützt über `pcall` versucht, falls vom Gerät unterstützt.

**Entscheidungen**
- Neue Effekt-Einstellungen zentral in `Config.FEEL`; Audio-IDs und Einzellautstärken in `Sounds`.
- Audio-IDs bleiben leer, bis der Nutzer passende freigegebene Roblox-Audios auswählt. Leere IDs erzeugen weder Sounds noch Warnungen.
- Hit-Stop nutzt die im Plan vorgesehene verzögerte Rückstoß-Reaktion; `Config.IMPACT_TIME` und `Config.STRIKE_TIME` bleiben unverändert.
- CanvasGroups erlauben gemeinsames Ausblenden der Fensterinhalte einschließlich Texten und Porträts. Schnell aufeinanderfolgende Animationen brechen ihre Vorgänger ab.
- Kampf-Effekte laufen nur für den Besitzer des Kampfes. Kamera-Effekte werden beim Wechsel der Karte/Ansicht zurückgesetzt.

**Sound-Platzhalter (alle IDs leer):** `musicHub`, `musicBattle`, `musicVictory`, `musicDefeat`, `click`, `hover`, `open`, `close`, `hit`, `crit`, `miss`, `death`, `levelUp`, `phase`, `recruit`, `recruitRare`, `recruitLegendary`, `coin`, `step`.

**Probleme:** Verbindung während der Umsetzung unterbrochen; auf dem bestehenden Feature-Branch fortgesetzt. Undefinierte Config-Referenz sowie PowerShell-Zeichenkodierung bei einzelnen Ersetzungen korrigiert. Ergebnismusik an den vorhandenen Ergebnis-String `Victory`/`Defeat` angepasst; Tempo-Rückstellung am tatsächlichen Phasenende ergänzt.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. `scripts/check.ps1`: **OK, 24 Dateien, Exit 0**. Rojo-Build von `TacticsGame.rbxlx` erfolgreich. Manuelle Prüfliste steht in `PLAN.md`; unabhängiger Review durch Claude steht aus.

---

## #11 – Review-Fixes Game-Feel
**Datum:** 05.10.2026

**Ziel:** Die sechs Befunde aus Claudes Review zum Game-Feel-Pass beheben und den bestehenden Branch `feature/game-feel-1` für den manuellen Test vorbereiten.

**Umsetzung**
- Fensterverlauf auf einen eigenen Background-Frame verschoben; der transparente Fenstercontainer trägt Goldrand und Rundung. Texte, Sterne und Porträts werden nicht mehr vom CanvasGroup-Verlauf eingefärbt.
- `UIKit.panel` erzeugt nur mit `Animated = true` eine CanvasGroup. Genau neun Fenster nutzen sie: Lobby, Thron-Menü, Aktionsmenü, Kampfvorschau, Level-Up, Ergebnis-Box, Rekrutierungs-Ergebnis, Wahrscheinlichkeiten und Toast. Übrige Panels und Lobby-Reiter sind Frames; CanvasGroups werden nicht ineinander verschachtelt.
- CanvasGroups blenden über `GroupTransparency`; Frames skalieren und gleiten und werden erst nach dem Schließen unsichtbar. Reiterseiten schalten ihre Sichtbarkeit direkt um.
- `SetSpeed` im Kampf nur noch durch dessen Besitzer möglich. `enemySpeedBefore` wird beim Aufsetzen einer Mission sowie bei Rückkehr in die Lobby und beim Verlassen des Besitzers zurückgesetzt.
- `SoundPlayer.playMusic(name, opts)` unterstützt `opts.loop` (Standard `true`); Sieg-/Niederlage-Musik wird mit `loop = false` angefordert.
- Hover-Sounds nur bei aktivierter Maus und mit zentralem Cooldown von 0,08 Sekunden für alle UIKit-Buttons.
- Beschreibungskommentare wieder als erste Zeile in den sechs betroffenen Client-Dateien; hinzugefügte Imports im bestehenden Importblock.

**Entscheidungen:** Aktions- und Thron-Menü erhalten einen inneren Inhalts-Frame, damit der neue Hintergrund keinen Platz in ihrem Listenlayout beansprucht. Padding wird am Hintergrund ausgeglichen, damit der Verlauf die gesamte Fensterfläche bedeckt. Keine Änderungen an Kamera, Figurenanimation, Atmosphäre, Laufbewegung, Spielregeln, Balancing oder Profilformat.

**Probleme:** Keine blockierenden Probleme. Der neue Hintergrund musste bei Layout und Padding ausdrücklich berücksichtigt werden.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. `scripts/check.ps1`: **OK, 24 Dateien, Exit 0**. Rojo-Build von `TacticsGame.rbxlx` erfolgreich. Strukturprüfung bestätigt neun animierte Fenster und die sechs Dateikopf-Kommentare. Farben, Porträts, Übergänge und Mehrspieler-Tempo müssen anhand der manuellen Prüfliste bestätigt werden.

---

## #12 – Visual-Pass 2
**Datum:** 05.10.2026

**Ziel:** Sichtbarer Qualitätssprung durch R15-Figuren, Terrain mit Höhen und Wasser, besser belichteten Thronsaal, lesbare UI-Symbole und hörbare Sounds.

**Umsetzung**
- Nicht unterstützte Deko-Symbole durch lesbaren Text bzw. `X` ersetzt. Rückblende mit Schriftgröße 13, Tempo als `1×`/`2×`/`3×`, Gegnerphase mit ausgeschriebenem Buttontext.
- Saal-Farben wärmer und dunkler; Helligkeit 1,2, Belichtung −0,35, Schatten aktiviert, Bloom und Farbkorrektur reduziert. Kerzen-Helligkeit 1,2. Alle Beschriftungen erhalten einen eigenen aufrechten, unsichtbaren Anker.
- Die 16 vorgegebenen Sound-IDs eingetragen; Musiklautstärke 0,3, Klick 0,4, Treffer/Verfehlen 0,6 und Krit 0,8. `hover`, `phase` und `step` bleiben leer. Kommentar für die Hörprobe in Studio beibehalten.
- Gelände-Höhen und Terrain-Materialien zentral in Config; `Grid.tileHeight` ergänzt, `Grid.toWorld` liefert die Feldhöhe. Kamera-Fokus bewahrt diese Höhe.
- Terrain-Grundfläche und Feldblöcke mit erhöhten Bergen, echten Wasserflächen über Sand und deterministischen Kuppen. Nur der Brett-Bereich einschließlich Umgebung wird vor dem Aufbau geleert. Unsichtbare Klickflächen behalten X/Y-Attribute; dezentes Raster und Deko sind nicht abfragbar. Waldbäume mit gestapelten Kronen; Außenbäume/-felsen stehen auf dem Terrain.
- R15-Avatare aus HumanoidDescriptions, vorgegebene Kopfbedeckungen/Haare, Team-/Royal-Farben und Wappenrock. Waffen an Händen; Schnalle am LowerTorso, Kragen/Wappen und Umhang am UpperTorso; Waffenglühen und Boden-Aura erhalten. Kavalier mit Pferd und Sitzpose.
- Server erzeugt `ReplicatedStorage.HeroTemplates`; Client-Porträts klonen diese in WorldModels. Zugriffe auf den früheren Figuren-Root auf PrimaryPart umgestellt; R15-Root-Gelenk zugeordnet. Standard-Idle/Laufen ergänzen die eigenen Kampfposen.

**Entscheidungen**
- Aktuelle API-Namen: `LightingStyle.Realistic` mit `PrioritizeLightingQuality` statt des veralteten `Technology.Future`; `CreateHumanoidModelFromDescriptionAsync` statt der veralteten synchron benannten Variante. Quellen: [Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting), [Technology](https://create.roblox.com/docs/reference/engine/enums/Technology), [Players](https://create.roblox.com/docs/reference/engine/classes/Players).
- GroundOffset aus der Fußposition hält R15-Figuren und Reiter auf Feldhöhe. Platzierung, Laufwege, Vorschau, Staub und Auswahlring berücksichtigen diesen Abstand.
- Avatar-Grundmodelle werden serverseitig gecacht. Bei Ladefehlern wird ohne Accessoires erneut gebaut; fehlende Accessoires werden mit den vorgegebenen IDs protokolliert. Keine zusätzlichen Asset-IDs recherchiert oder eingebaut.
- Spielregeln, Bewegungsformeln, Balancing, Speicherformat, Server-Kampfzeiten und Befehlsvalidierung unverändert.

**Verwendete Asset-IDs**

| Audio | ID |
|---|---|
| musicHub | 1839906422 |
| musicBattle | 1837301451 |
| musicVictory | 9041812129 |
| musicDefeat | 9048278630 |
| click | 9119717523 |
| open | 9120709477 |
| close | 9113842150 |
| hit | 9119746592 |
| crit | 9116673678 |
| miss | 9119749145 |
| death | 9113480915 |
| levelUp | 1836860398 |
| recruit | 9116394545 |
| recruitRare | 9116395089 |
| recruitLegendary | 9116395085 |
| coin | 127645268874265 |

- Kopfbedeckungen: Lord `3756500192`, Kavalier `98450287`, Soldat `8796225`, Bogenschützen `102623080`, Magier `13121508`, Kämpfer/Bandit `74221074`, Bandenführer `108829551`.
- Haare: Leon `12819292`, Mira `1513252656`, Selina `376527350`, Aurelia/Ida `398673196`, Greta `1708329071`.
- Animationen: Idle `507766388`, Laufen `507777826`.

**Probleme:** Umsetzung unterbrochen und anschließend auf demselben Branch fortgesetzt. Veraltete API-Aufrufe auf aktuelle Entsprechungen angepasst. Asset-Verfügbarkeit und tatsächliche Terrain-Oberflächen können außerhalb von Studio nicht bestätigt werden; keine einzelnen Ladefehler bisher beobachtet.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. `scripts/check.ps1`: **OK, 24 Dateien, Exit 0**. Rojo-Build von `TacticsGame.rbxlx` erfolgreich. Strukturprüfung: keine gesperrten UI-Symbole; Client-Porträts bauen keine Avatare mehr lokal. Sichtbarkeit, Accessoires, Sounds, Animationen, Höhenübergänge und Klickflächen benötigen den manuellen Test aus `PLAN.md`; Claude-Review ausstehend.

---

## Nächste Schritte (Plan)
1. Claude prüft `feature/visual-pass-2`.
2. Visual-Pass-Prüfliste in Studio und auf dem Handy durchführen; Sounds probehören, Accessoires/Porträts und Terrain-Klicks prüfen, Output und Bildrate beobachten.
3. Gemeldete Asset-Ladefehler mit ID dokumentieren; Sounds und Optik nach Nutzer-Feedback abstimmen.
4. Belohnungen & Klassenwechsel.
5. Tägliche Belohnungen / Quests, Co-op-Raid, Saison-Pass und Rewarded Ads.
