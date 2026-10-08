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

## #13 – Review-Fixes Visual-Pass 2
**Datum:** 05.10.2026

**Ziel:** Saal und Serverstart von Avatar-Ladezeiten entkoppeln, Ladefehler abfangen und verspätete Porträtvorlagen anzeigen.

**Umsetzung**
- `UnitVisuals.init` setzt nur den Einheitenordner; `buildHeroTemplates` läuft nach dem Saalbau im Hintergrund. Der leere Vorlagenordner wird sofort repliziert und mit jeder fertigen Vorlage ergänzt. Fehler eines Helden werden mit dessen ID protokolliert; die übrigen Helden werden weiter gebaut.
- Beide Saal-NPCs werden nach dem synchronen Aufbau mit `task.defer` geladen. Boden, Möbel, Spawn und Prompts stehen bereits im Workspace, bevor ein Avatar nachgeladen wird.
- Auch der Avatar-Versuch ohne Accessoires läuft in `pcall`. Scheitert er, folgen Warnung und Fehlerweitergabe an die geschützten Aufrufer; kein defektes Ergebnis wird gecacht.
- Einheiten-Erstellung schützt den Bau und wiederholt ihn nach einem Fehler einmal nach einer Sekunde. Bei erneutem Fehler bleibt die Einheit ohne Modell; vorhandene Modell-Lookups verkraften das. NPC-Fehler führen zu einer Warnung und zum Weglassen des NPCs; Prompts bleiben an Möbeln bzw. Kreis.
- Beide modernen Licht-Eigenschaften einzeln geschützt, bei Problemen höchstens eine Warnung mit Studio-Hinweis. `default.project.json` setzt zusätzlich `Lighting.Technology = Future`; Rojo akzeptiert die Eigenschaft beim Build.
- Heldenporträts leeren bei fehlender Vorlage den Viewport und warten im Hintergrund mit jeweils zehn Sekunden Timeout auf Ordner/Vorlage. Die spätere Anzeige erfolgt nur bei noch vorhandenem Viewport und passendem `PortraitHero`-Attribut.
- Alten NPC-Haarfarben-Parameter und Zugriffe auf `Hair`/`HairBack` entfernt.

**Entscheidungen:** Die NPC-Aufrufe mussten zusätzlich zum Vorlagenbau verschoben werden, da andernfalls schon `HubBuilder.build` auf Netzwerk-Ladevorgänge gewartet hätte. Keine Änderungen an Asset-IDs, Spielregeln, Befehlsvalidierung oder Kampfzeiten.

**Probleme:** Keine blockierenden Probleme; der Rojo-Eintrag für Future musste nicht entfernt werden.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. Nach jedem Umsetzungsschritt `scripts/check.ps1`: **OK, 24 Dateien, Exit 0**. Abschluss-Build von `TacticsGame.rbxlx` erfolgreich. Strukturprüfung bestätigt, dass kein `HairBack`-Zugriff mehr existiert. Startverhalten, simulierte Ladefehler, Porträt-Nachladen und Licht müssen anhand der manuellen Prüfliste bestätigt werden; Claude-Review ausstehend.

---

## #14 – Terrain-Fix + Chibi-Prototyp
**Datum:** 05.10.2026

**Ziel:** Raster, Bewegungsfelder und Figuren auf dem Terrain sichtbar machen und eigene Chibi-Figuren als Vergleich zu den R15-Avataren bereitstellen.

**Umsetzung**
- Terrain-Füllung in `fillTerrain(sinkByChar)` ausgelagert. Nach der ersten Füllung wird je vorhandenem Geländezeichen außer Wasser eine Feldmitte mit einem Terrain-RayCast gemessen. Positive Höhenabweichungen einschließlich 0,15 Stud Abstand senken die zweite Füllung ab; Grundschichten und Umgebung berücksichtigen den Ebenenwert. Die Werte erscheinen einmal je Brettaufbau als „Terrain-Kalibrierung: …“ im Output. Grashalme abgeschaltet und Rasterlinien auf +0,08 Stud angehoben.
- Zentraler Schalter `Config.CHARACTER_STYLE = "chibi"`; `"avatar"` nutzt weiterhin den bestehenden R15-Pfad. Heldenvorlagen und Porträtanzeige verwenden denselben Schalter ohne weitere Anpassungen.
- Individuelle Aussehen-Daten für alle elf Helden und Standards für alle neun Klassen: Haut, Augen, Frisur, Haarfarbe, Kopfbedeckung, Outfit, Robe, Bart und Skalierung. Siegfrieds Federbusch ist goldfarben, Kais Federbusch trägt die Teamfarbe.
- Neuer netzwerkunabhängiger `ChibiBuilder` in Shared: großer Kugelkopf, farbige Augen mit Glanzpunkten, Mund, Wangenröte, sechs Frisuren und neun Kopfbedeckungen. Kurzer Körper mit Gürtel, Stiefeln und optionaler Robe; Teamfarbe an Schulterstücken und Brustschärpe.
- Gelenke `Root`, `Neck`, Schultern, Hüften und `CapeJoint` sowie Körpernamen und Attribute an die bestehenden Animator-/Porträtzugriffe angepasst. Waffen, Pferd mit Sitzpose und Seltenheits-Effekte aus dem früheren Teile-Baukasten an die Chibi-Maße angepasst: Schnalle, Kragen, Waffenglühen/Funken, Umhang/Saum, Wappen und Boden-Aura.
- Outfitteile speichern `BaseColor` zusätzlich zu `Tint`. Die von Claude freigegebene Ergänzung in `UnitVisuals.update` stellt aktive Outfitfarben wieder her und färbt fertige bzw. nicht eingesetzte Einheiten grau; Teile ohne `BaseColor` verwenden die Teamfarbe.
- Rückblende-Knopf mit `TextScaled` und `UITextSizeConstraint` auf höchstens Schriftgröße 13 begrenzt.

**Entscheidungen:** Chibi-Proportionen zentral in `Config.CHIBI`, Aussehen in `UnitData`; Spielwerte unverändert. Abgeflachte Helmschalen halten das Gesicht frei, die Boden-Aura ist ein offener Segmentring. `TopY` wird aus der tatsächlichen Teilehöhe einschließlich Kopfbedeckung berechnet. Haut, Gesicht und Haare erhalten kein `Tint`. Keine neuen Netz-Assets; R15-Modellbau und Asset-IDs unverändert.

**Probleme:** Der Konflikt zwischen individuellen Outfitfarben und dem bisherigen Teamfarben-Update führte zunächst zur Rückfrage in `PLAN.md`. Claude hat `BaseColor` und die gezielte Änderung von `UnitVisuals.update` freigegeben. Die zuvor gemeldeten R15-Ladefehler bei Kavalieren/Aurelia gehören weiterhin nicht zu diesem Plan.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. Nach jedem Umsetzungsschritt `scripts/check.ps1`: **OK**; Abschlussprüfung **25 Dateien, Exit 0**. Rojo-Build von `TacticsGame.rbxlx` erfolgreich. Terrain-Kalibrierwerte, Feldsichtbarkeit, Füße/Sitzpose, vollständige Modelle, Animationen, Porträts, Seltenheits-Effekte und Avatar-Vergleich müssen anhand der Prüfliste in `PLAN.md` bestätigt werden; Claude-Review ausstehend.

---

## #15 – Weltkarte + Nebelsumpf
**Datum:** 06.10.2026

**Ziel:** Missionsfortschritt auf einer verzweigten Weltkarte sichtbar machen und den Nebelsumpf als erstes neues Gebiet ergänzen.

**Umsetzung**
- Vier zentrale Gebietsdefinitionen in `Stages`: Grünland und Nebelsumpf aktiv, Frostgipfel und Glutberg als „Bald verfügbar“. Fünf Missionen mit Kartenpositionen und Vorgängern; Waldpass schaltet Banditenfestung und Nebelfurt frei, Nebelfurt schaltet Hexenhütte frei. Mindestens ein geschaffter Vorgänger genügt; Schwer erfordert weiterhin Normal derselben Mission.
- Morast mit Bewegungskosten Fuß 2/Pferd 3 und Ausweichen −15; tiefer Morast für beide Bewegungstypen unpassierbar. Schlamm-Terrain, 1 Stud Wasser über tiefem Morast, Schilf sowie abgestorbene Holzdekoration ergänzt. Die bestehende Kalibrierung misst beide neuen Zeichen. Gelände-Boni in beiden Infoanzeigen mit korrektem Vorzeichen formatiert.
- Gegnerklasse EnemyMage mit Chibi-Hexen-Aussehen und bestehendem Magier-Accessoire für den Avatar-Pfad; Sumpfhexe und stationäre Bosshexe Morwen mit Feuer, Morwen mit Seltenheit ★4.
- Handgebaute Karten Nebelfurt (12×9) und Hexenhütte (12×10) mit Aufstellungsfeldern, Gegnern und zusätzlichen Schwer-Gegnern gemäß Plan.
- Grünes Nebel-Preset für das Sumpfgebiet; die aktuelle Mission bestimmt die Atmosphäre im eigenen Kampf, mit Rückfall auf battle. Im Thronsaal bleibt hall aktiv.
- Weltkarten-Reiter mit 1200×720-Canvas zum Scrollen in X/Y und Wischen, farbigen Gebieten, vier Wegen und fünf runden 72-px-Knoten. Gesperrte Knoten zeigen „???“, offene pulsieren, geschaffte erhalten Goldrand und Sterne, die Auswahl einen hellen Zusatzring. Erste offene Mission als Standard, sonst letzte freigeschaltete; Kartenausschnitt darauf zentriert. Details rechts auf 40 % Breite mit Stufen, Regeln, Zielen, Belohnung und Start. Gesperrt-/Warte-Emoji entfernt.

**Entscheidungen:** Bestehende Stage-IDs und Sternedaten bleiben erhalten; kein neues Profilfeld. Karten s1–s3, Heldenwerte, Kampf-/KI-Formeln und Servervalidierung unverändert. UI über UIKit; Pulse werden nur bei Zustandswechsel erstellt und vor Neubau/Zerstörung beendet. Für die schmalere Detailansicht stehen Regeln und Ziele untereinander. Ein Commit je Planschritt auf `feature/weltkarte`, ausgehend von `feature/chibi-figuren`.

**Probleme:** Keine blockierenden Probleme. Ein UTF-8-Übertragungsfehler bei der ersten Ergänzung wurde korrigiert. Spielbarkeit, Darstellung und tatsächliche Speicherung benötigen den Studio-Test.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. Nach jedem Umsetzungsschritt `scripts/check.ps1`: **OK**; Abschlussprüfung **25 Dateien, Exit 0**. Rojo-Build von `TacticsGame.rbxlx` erfolgreich. Lokale Prüfung mit tatsächlichen Luau-Shared-Modulen und Werttyp-Stubs bestätigt Verzweigung, ODER-Vorgängerregel, Freischaltungen mit alten Sternedaten und Schwer-Regel; Morast-Kosten 2/3, Unpassierbarkeit von D, Trefferchance +15 durch Ausweichen −15 und Vorzeichenformatierung. Auf beiden Karten ist jeder Gegner einschließlich Schwer-Zusätzen von jedem Startplatz mit `Grid.reachable` zu Fuß erreichbar. Hexenwerte, Feuerreichweite und Gebietsatmosphäre geprüft. Die lokale Prüfhilfe unter `.handoff` wird nicht committet. Darstellung, Touch, Missionsstart, Sieg, Sternespeicherung, Nebel und Terrain-Oberflächen anhand von `PLAN.md` manuell testen; Claude-Review ausstehend.

---

## #16 – Handy-Kamera + Sumpf-Lesbarkeit
**Datum:** 06.10.2026

**Ziel:** Verlässliche Karten-Gesten am Handy, ein auf dem Boden stehender Rüstungsständer und verständliche Sumpf- und Bewegungsanzeigen.

**Umsetzung**
- Taktik-Kamera schaltet Avatar-Steuerung und Touch-Steuerelemente geschützt aus und bei Rückkehr in den Thronsaal wieder ein. Fehlendes PlayerModule hat fünf Sekunden Timeout; Umschaltfehler erzeugen höchstens eine Warnung.
- Jeder Touch hat eigene Start-/Letzte-Position. Ein Finger verschiebt ab der Ziehschwelle; zwei Finger zoomen über ihren Abstand und verschieben über den Mittelpunkt. Rotation folgt erst nach 18 Grad bewusster Drehung. Fingerzahlwechsel setzen alle Basiswerte neu; Mehrfinger-Gesten lösen keine Auswahl aus. Roblox-Pinch-/Rotate-Handler entfernt; Maus, Mausrad und Tastatur behalten ihre Bedienung.
- Rüstungsständer aus Holzfuß, Stange, Querholz, Brustpanzer und Kugelhelm mit den geplanten Maßen aufgebaut; Fußplatte berührt den Boden, Helm und Stange überlappen.
- Grünland und Nebelsumpf definieren Umgebungsmaterial und Baumfarbe. Mission übergibt ihr Gebiet an BoardBuilder; Sumpfumgebung nutzt braunen Schlamm und dunklere Bäume. Morastfelder erhalten eine versetzte Terrain-Wasserpfütze und drei bis vier Schilfhalme mit braunen Spitzen.
- Blaue Felder mit erhöhten Bewegungskosten erhalten transparentere Overlays und flache Oberseiten-Beschriftungen. Unbesetzte, unpassierbare Nachbarfelder sind grau mit X; alle Beschriftungen werden mit ihren Overlays aufgeräumt.
- Nicht erreichbare Ziele erklären zuerst Besetzung, dann Unpassierbarkeit und schließlich fehlende Bewegungsreichweite. Das bisherige Auswählen/Abwählen folgt danach. Das Gelände-Panel zeigt Fuß-/Pferdekosten, fehlende Kosten als Gedankenstrich und am Handy das Gelände der ausgewählten Einheit.

**Entscheidungen:** Neue Gesten- und Darstellungswerte in Config.FEEL, graue Farbe in Config.OVERLAY. UI-begonnene Finger zählen zur Gestenunterdrückung, steuern aber keine Kamera. Nach Überschreiten der Drehschwelle werden nur weitere Winkeländerungen angewendet, damit kein nachträglicher Drehungssprung entsteht. Pfützen werden nach der Terrain-Kalibrierung an der lokal gemessenen Schlammoberfläche platziert. Graue Sperrmarkierungen ersetzen an denselben Feldern rote Angriffs-Overlays für eine eindeutige Anzeige. Gelände-Panel auf drei Zeilen vergrößert. Keine Änderungen an Spielregeln, KI, Kartendaten, Freischaltung, Profilen oder Befehlsvalidierung.

**Probleme:** Keine blockierenden Probleme. Beim Vormerken von Schritt 2 blockierte die Sandbox den Git-Index; der autorisierte erneute Aufruf war erfolgreich.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. Nach jedem Schritt `scripts/check.ps1`: **OK, 25 Dateien, Exit 0**. Abschluss-Build von `TacticsGame.rbxlx` erfolgreich. Lokale Prüfung der originalen Eingabe-Handler mit API-/Vector2-Stubs bestätigt Einfinger-Ziehen, Pinch-Verhältnis, 18-Grad-Drehschwelle, kontinuierliche Rotation, Fingerwechsel zwischen eins/zwei/drei Fingern ohne Sprung, Winkelwechsel über ±180 Grad, Unterdrückung von UI-Touches und Mehrfinger-Taps sowie Maus-Ziehen/Klicken. Prüfhilfe unter `.handoff` bleibt uncommittet. Darstellung und tatsächliche Roblox-Touch-Ereignisse müssen anhand der manuellen Prüfliste bestätigt werden; Claude-Review ausstehend.

---

## #17 – Flüssiger Missionsstart
**Datum:** 06.10.2026

**Ziel:** Die Weltkarte beim Missionsstart sofort schließen, den Aufbau mit einem Ladebildschirm überbrücken und wiederholte Terrain-/Figurenaufbauten vermeiden.

**Umsetzung**
- `setupStage` misst Brett- und Gegneraufbau mit `os.clock`; `BeginBattle` protokolliert separat den Heldenaufbau. Output je Start: „Missionsaufbau …: Brett … ms, Figuren … ms“.
- `setupStage` erhält gemäß Claudes Freigabe `ownerUserId` und `ownerName` aus dem bisherigen State. Der bestehende Retry-Fehler mit verlorenem Besitzer und anschließend abgelehnten Kampfbefehlen ist behoben; die Befehlsvalidierung bleibt unverändert.
- Sofort deckender Vollbild-Ladebildschirm über allen Spielmenüs, dunkler Verlauf, blaues Fenster mit Goldrand, Missions-/Gebietsname und pulsierender Text. Inhalt wird über `Config.FEEL.loadingFade = 0.25` eingeblendet; die gesamte Oberfläche nach Bereitschaft ausgeblendet. Weltkarte, Ergebnis und Aufstellung bleiben während des Ladens geschlossen.
- Weltkartenstart, nächste Mission und Retry nutzen denselben Ladeweg. Heartbeat verlangt einen neuen eigenen Battle-State mit passender Stage/Schwierigkeit ohne altes Ergebnis, alle Rasterfelder, einen Terrain-Ray unter der Kartenmitte und sämtliche Einheitenmodelle mit PrimaryPart. Ein alter lokaler Lobby-/Retry-State löst weder Erfolg noch Sofortabbruch aus. Doppelte Startklicks werden unterdrückt. Neuer Lobby-State oder 15 Sekunden Timeout führen zur Fehlermeldung und Weltkarte; ein bereits gestarteter eigener Kampf wird dafür über den bestehenden ToLobby-Befehl verlassen.
- `BoardBuilder` speichert erfolgreiche Kalibrierwerte je Geländezeichen einschließlich Nullwerten. Nur neue Zeichen benötigen Kalibrier-Raycasts und die vorbereitende Füllung; bekannte Zeichen nutzen direkt die endgültige Füllung. Gleiche Karte und gleiches Gebiet überspringen Terrain-Schreibzugriffe vollständig, einschließlich Sumpfpfützen. Board-Felder und Part-Dekoration werden weiter neu gebaut.
- `ChibiBuilder` speichert unparented Vorlagen und gibt ausschließlich unabhängige Klone mit aktueller Unit-ID zurück. Schlüssel: Held/Klasse, zusätzliche Klasse, Team, Waffe, Seltenheit und Lord-Flag. Die zusätzliche Klasse berücksichtigt klassenabhängige Pferde, Augenbrauen und Umhänge. Einheitenattribute, Brettskalierung und Porträtklone verändern die gespeicherte Vorlage nicht.

**Entscheidungen:** Kamerarechnung ergab, dass der vorgeschlagene Umgebungsrand von 60 Studs und auch der bisherige von 100 bei maximalem Zoom nicht ausreichen. Deshalb den im Plan erlaubten Ersatzwert gewählt: 612 Studs, passend für Zoom 140, Standard-FOV 70°, Seitenverhältnisse bis 21:9, frei gedrehte Kamera, Fokus am Brettrand und eine konservative Bodenebene bis −12 Studs. Maximale Entfernung 609,32 Studs, auf 4-Stud-Voxelbreite aufgerundet; vollständige Formel in PLAN.md. [Roblox-Dokumentation zum Standardblickwinkel](https://create.roblox.com/docs/reference/engine/classes/Camera). Randdeko proportional auf dem gewählten Rand verteilt. Noch breitere Displays oder höheres FOV sind nicht abgedeckt. Keine Änderungen an Kamera, Hub, Karten, Profilen, Kampfregeln oder Validierung. Ein Commit pro Planschritt auf `feature/ladezeit`.

**Probleme:** Der größere Terrain-Rand umfasst wesentlich mehr Voxel und reicht räumlich unter den Hub. Der erste Aufbau kann dadurch teurer werden; Caches ersparen bei neuen bekannten Karten die zweite Füllung und bei Retry sämtliche Terrain-Schreibzugriffe. Ohne Studio-Messung ist keine tatsächliche Zeitersparnis belegt. Claude soll diesen Zielkonflikt im Review prüfen. Der Git-Index erforderte wie zuvor einen autorisierten Aufruf außerhalb der Sandbox.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. Nach jedem Umsetzungsschritt `scripts/check.ps1`: **OK, 25 Dateien, Exit 0**. Abschluss-Build von `TacticsGame.rbxlx` erfolgreich. Lokale Prüfungen mit originalen Modulen/Funktionen und API-Stubs bestätigen: Terrain-Wiederverwendung auf allen fünf Missionen; nur neue Zeichen kalibrieren; Gebietswechsel füllt neu; kleines Testbrett kalt 23, warm 13, Retry 0 Terrain-Schreibaufrufe. Figurenvarianten bleiben getrennt, gleiche Gegner werden geklont, Klonmutationen und UnitId/Team gelangen nicht in die Vorlage; alle Helden/Porträts und Gegnertypen gebaut. Ladeprüfung deckt alte Lobby-/Retry-States, fehlende Felder/Terrain/Modelle, Besitzer/Stage/Schwierigkeit, Doppelklick, Ablehnung und beide Timeout-Pfade ab. Die API-Stubs prüfen Abläufe, simulieren keine Roblox-Voxelreplikation, Geometrie oder Darstellung. Prüfhilfen unter `.handoff` bleiben uncommittet. Claude-Review und die manuelle Prüfliste in PLAN.md bleiben offen.

---
## #18 – Kampfszene
**Datum:** 06.10.2026

**Ziel:** Eigene Angriffe und Gegnerangriffe als überspringbare Kampfszene mit Figuren, Kampfwerten und animierten KP darstellen; Szenen dauerhaft abschaltbar machen.

**Umsetzung**
- Profilfeld `settings.battleScenes` mit Standard `true`, Migration fehlender/ungültiger Werte sowie Laden, Speichern und Profil-Payload ergänzt. `SetBattleScenes` prüft Boolean und Kampfbesitzer, speichert die Einstellung und spiegelt sie im State. Missionsstart übernimmt die Einstellung des Besitzers; Retry erhält sie.
- Server ergänzt ausschließlich die mit dem Tempo skalierten Intro-/Outro-Pausen. Kampfereignisse liefern Szeneneinstellung, Tempo und aktuelle Feldkoordinaten. Bestehende Schlagfolge, Kampfregeln und relativer Zeitpunkt des KP-Abzugs bleiben erhalten.
- `UnitAnimator.playStrike` akzeptiert eigene Angreifer-/Zielmodelle, Effektbereich und Tempo. Pro Aufruf getrennte Animationskontexte verhindern, dass gleichzeitig laufende Brett- und Szeneneffekte denselben Bereich verwenden. Rückgabefunktionen stoppen zugehörige Tasks und Tweens; `playDeath` zeigt Umfallen/Ausblenden auf Szenenklonen.
- Neues `BattleScene`-Modul: Vollbild mit Himmel-/Gebietsverlauf, Hügeln, seitlicher Viewport-Kamera, WorldModel und Plattform im Gelände des ursprünglichen Verteidigers. Unabhängige Figurenklone in Originalgröße ohne Billboards; Gegner links/rot, eigene Einheit rechts/blau, ohne eigene Einheit Angreifer rechts. Goldumrandete Namensschilder und untere Panels mit Waffe, HIT/DMG/CRT, KP-Zahl und segmentiertem, animiertem KP-Balken.
- Schlagfolge einschließlich Konter und Doppelschlägen wird im Server-Takt dargestellt. Treffer-/Verfehl-/Krit-/Tod-Sounds, Schadenstexte, KP-Animation, Kritblitz und Wackeln kommen aus der Szene; Brettanimation und Kamerafokus laufen parallel ohne doppelte Treffer-Sounds. Bei fehlenden Klonen wird auf die Brettdarstellung zurückgefallen.
- Antippen beendet die Szene sofort. Normaler Abschluss sowie Lobby, Retry, Ergebnis und Missionswechsel entfernen Klone, Verbindungen, Tasks und Tweens. HUD, Info, Gelände und Vorschau werden während der Szene versteckt; HUD und Hinweise danach wiederhergestellt. Meldungen bleiben über der Szene sichtbar.
- Besitzer-Schalter „Szenen an“/„Szenen aus“ in der Werkzeugleiste, aktiv hervorgehoben bei eingeschalteten Szenen. Alle Szenenzeiten skalieren mit 1×/2×/3×; Timingwerte stehen in `Config.FEEL`.

**Entscheidungen:** Die Positionen im Kampfereignis sind eine notwendige Ergänzung zu Schritt 4: Der letzte State liegt vor der Bewegung, sodass eine allein daraus berechnete Vorschau falsches Gelände und falsche Konterreichweiten verwenden würde. Einstellung und Starttempo werden pro Ereignis mitgegeben. Ein Umschalten der Szeneneinstellung gilt erst für den nächsten Kampf. Eigene ScreenGui unter dem Meldungs-Gui; das HUD wird während der Szene verborgen. Keine Änderungen an Combat, Grid, EnemyAI oder Kartendaten. Ein Commit pro Planschritt auf `feature/kampfszene`, abgezweigt von `feature/ladezeit`.

**Probleme:** Der Git-Index erforderte autorisierte Aufrufe außerhalb der Sandbox. Keine blockierenden Probleme bei Syntaxprüfung oder Build. Ein Tempo-Wechsel während einer bereits übersprungenen Schlagfolge verwendet weiterhin die bestehende dynamische Server-Wartezeit; die Clientdarstellung verwendet das Starttempo des Kampfereignisses. Dieses Zusammenspiel ist im Studio zu prüfen.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. Nach jedem Umsetzungsschritt `scripts/check.ps1`: **OK**; Abschlussprüfung **26 Dateien, Exit 0**. Rojo-Build von `TacticsGame.rbxlx` erfolgreich. Darstellung, Viewport-Effekte, Konter/Doppelschläge, Treffer-/Krit-/Tod-Animationen, Audio, KP-Balken, Überspringen, Tempo, Besitzerrechte und Speichern nach Rejoin müssen anhand der manuellen Prüfliste in `PLAN.md` bestätigt werden. Claude-Review ausstehend.

---
## #19 – Figurenstil mesh
**Datum:** 06.10.2026

**Ziel:** Fertige Anime-R15-Modelle je Held oder Gegnerklasse verwenden und bei fehlenden Vorlagen automatisch auf Chibi zurückfallen. Modell-Erstellung und Import sind in [charakter-pipeline.md](charakter-pipeline.md) beschrieben.

**Umsetzung**
- Rojo bindet `assets/characters` als `ReplicatedStorage.CharacterModels` ein. Eine ignorierte README hält den Ordner auch ohne Modelle im Projekt.
- Neuer Figurenstil `mesh`: Helden-ID vor Klassenname, Nicht-Model-Kinder ignoriert, Pflichtteile und ihre Typen geprüft. Fehlende, unvollständige oder nicht klonbare Vorlagen ergeben Chibi mit höchstens einer Warnung je Modell-ID.
- Avatar und Mesh verwenden gemeinsame R15-Aufbereitung: Skripte entfernen, Root/PrimaryPart verankern, übrige Teile ohne Kollision/Touch und masselos, Humanoid-Anzeige aus, Animator ergänzen, Fußhöhe als GroundOffset, Waffen, Seltenheits-Effekte, Pferd und HeadY/TopY. Mesh-Waffen folgen der Handposition und -ausrichtung.
- Aufbereitete Mesh-Vorlagen werden nach Modell-ID, Klasse, Team, Waffe, Seltenheit und isLord getrennt zwischengespeichert und pro Einheit geklont. Der Mesh-Pfad funktioniert auf Client und Server ohne Netzaufrufe; die Avatar-Sperre für Clients bleibt bestehen.
- Importierte Farben und Texturen bleiben erhalten; Tint nur auf vom Spiel ergänzten Teamteilen. Zusätzlicher Avatar-Wappenrock und Avatar-Umhang entfallen bei Mesh, damit die modellierte Kleidung sichtbar bleibt.
- Porträtkamera für Mesh verwendet Kopf-/Oberkörperspanne aus TopY/HeadY/GroundOffset sowie Sichtfeld und Seitenverhältnis. Bestehende Brett-Skalierung, R15-Animationen, Zug-Ring, Kampfszene und Ghost-Vorschau sind angeschlossen; Chibi-Porträtkamera unverändert.

**Entscheidungen:** Standard bleibt `chibi`, bis der Nutzer Modelle importiert und auf `mesh` umstellt. Keine echten Modelldateien erstellt; die R15-Testvorlage und Prüfhilfen bleiben ausschließlich unter `.handoff` und uncommittet. Spielregeln, Karten, ProfileStore und Servervalidierung unverändert. Ein Commit pro Planschritt auf `feature/mesh-figuren`, abgezweigt von `feature/kampfszene`.

**Probleme:** Der Git-Index erforderte die bereits autorisierten Aufrufe außerhalb der Sandbox. Die lokale Prüfhilfe benötigte den Roblox-Standardwert Anchored=false; nach Korrektur des Stubs alle Prüfungen erfolgreich. Keine blockierenden Syntax- oder Buildprobleme.

**Teststatus:** **ungetestet in Roblox Studio und auf dem Handy**. Pflichtcheck nach jedem Schritt: **OK**; Abschluss **26 Dateien, Exit 0**. Rojo-Build erfolgreich. **175 lokale Prüfungen** mit aktuellen Originalmodulen und API-Stubs: vollständiges R15, jeder fehlende Pflichtteil, falscher Teiltyp, Klassenersatz, Skriptentfernung, Physik, Humanoid/Animator, Waffen/Aura, Pferd, Texturerhalt, einmalige Warnungen, Cache-Trennung und Klonisolation, Client-/Serverpfade ohne Mesh-Netzaufrufe. Alle 11 Helden und 7 Gegnertypen fallen ohne Modelle auf dieselbe Teile-/Farbsignatur wie Chibi zurück. Statische Anschlussprüfung gemäß PLAN.md durchgeführt; unabhängiger Claude-Review ausstehend. Stubs simulieren weder Rendering noch Rotationen, Animationen oder Replikation. Echte Modelle und die manuelle Prüfliste müssen im Studio/auf dem Handy getestet werden.

---
## #20 – Leon-Import, eigene Figurenwaffen, Startlicht
**Datum:** 06.10.2026

**Ziel:** Erstes echtes Anime-Modell (Leon, TRELLIS → Avatar Setup) spielbar machen; Waffen festlegen; verzögertes Licht/unscharfen Text beim Start beheben.

**Umsetzung**
- `CHARACTER_STYLE = "mesh"`, `assets/characters/leon.rbxm`. AnimationConstraints → Motor6D mit weltachsen-ausgerichteten Gelenkframes; T-Pose-Arme um `meshArmDrop` abgesenkt (in C1, nur wenn die Hand < 30° unter dem Oberarm liegt), damit Angriffsposen den Arm quer zum Körper heben.
- Größe auf `meshTargetHeight` normiert, `BaseScale`-Attribut für Brett/Porträt/Kampfszene; AutomaticScaling aus; Root-PivotOffset zurückgesetzt (Figur sank nach dem Laufen ein); InitialPoses entfernt; bei Mesh keine Buckle/Collar/Crest/AuraRing-Deko.
- **Eigene Waffe je Figur:** `CharacterModels.<id>_waffe` (Pivot = Griff, −Z = Klinge), Länge je Waffentyp oder Attribut `Laenge`, Bogen/Buch links, sonst rechts; ohne Datei Platzhalter. Ausrüstung ändert nur Werte (Nutzerentscheidung). Style-Guide (Abschnitt 5) und Pipeline-Doku angepasst.
- Atmosphäre-Effekte sofort beim Clientstart mit Zielwerten, Tiefenunschärfe ohne Überblenden; Saal-Lighting direkt in `default.project.json` statt erst nach dem Brettaufbau.

**Entscheidungen:** Figuren und Waffen entwirft/generiert der Nutzer selbst (`docs/stil-guide.md`); steife Animationen werden in der Endphase verbessert.

**Probleme:** Rojo 7.4.4 konnte Avatar-Setup-Instanzen nicht lesen → Upgrade auf 7.7.1. Codex-Reviews fanden u. a. absolute ScaleTo-Semantik, Armachse entlang des Arms, pauschalen Drop, Buch in falscher Hand – alle behoben.

**Teststatus:** Vom Nutzer in Studio bestätigt: Leon steht auf dem Boden, Arme hängen, Angriff hebt den Arm (noch etwas steif), Hub sofort richtig beleuchtet. Eigene Waffenmodelle noch ungetestet (keine Datei vorhanden). Pflichtcheck OK.

---
## #23 – Roguelike Phase 1
**Datum:** 08.10.2026

**Ziel:** Einen gespeicherten Lauf über fünf erzeugte Grasland-Level mit frei gewähltem Dreierteam, fester Levelwahl, Teilheilung und dauerhaftem Heldenfortschritt spielbar machen.

**Umsetzung**
- RunConfig bündelt alle Lauf-Platzhalterwerte, Gegnerthemen (Axt/Lanze/Bogen), Gold-/Edelsteinbelohnungen und Generatorgrenzen. MapChunks enthält zwölf handgemachte 5×4-Stücke. LevelGen kombiniert/spiegelt sie mit eigenem deterministischem PRNG zu 10×8-Karten; prüft Fußwege von allen Startfeldern, Passierbarkeit, Mindestabstand, Hindernisanteil und Gegnerplätze. Nach maximal 50 Versuchen offene Rückfallkarte.
- Committiertes Luau-CLI-Prüfskript ohne Roblox: 1.000 Seeds × fünf Tiefen × drei Themen, Teamgrößen 1–6, Determinismus, Schwerpunkt, unabhängige Erreichbarkeitsprüfung, Optionen und erzwungener Rückfall. Pflichtcheck unverändert; Testaufruf in AGENTS.md ergänzt.
- Profil ergänzt Seed, Gebiet/Tiefe, Reihenfolge, KP/Alive-Team, Optionen/feste Wahl, verdiente Währungen und geschaffte Level. Normalisierung verwirft defekte/unbekannte Läufe, übernimmt alte Profile; Client erhält eine unabhängige Kopie. DataStore-Schreibaufrufe sind geordnet; Laufübergänge warten auf Speicherung.
- Gemeinsamer setupBattle-Aufbau für Story und erzeugte Stages. RunService kapselt Laufdaten; Kampfablauf bleibt gemeinsam. StartRun prüft exakt drei verschiedene eigene Helden, Leon optional. ChooseLevel speichert die feste Wahl vor Aufbau und stellt Überlebende automatisch mit gespeicherten KP auf. ResumeLevel verwendet identischen Seed und den Stand vor dem Level.
- Lauf-Niederlage erst ohne eigene Einheiten; Story-Lordregel bleibt bestehen. Kein Undo/Retry/StartStage oder Rekrutieren während des Laufs. Siege übernehmen EP/Level auch Gefallener, heilen Überlebende teilweise und buchen die gewählte Belohnung sofort. Nach fünf Siegen, Niederlage oder Aufgeben endet der Lauf; verdiente Währungen bleiben vollständig erhalten. Aufgeben wartet laufende Aktionen ab; Verlassen erhält die feste Wahl/KP vor dem Level.
- RunUI nutzt UIKit für Teamwahl, KP/Gefallene, große Themen-/Belohnungskarten, Resume, Aufgabebestätigung und Ergebnisse. Gespeicherter Lauf öffnet direkt die Wahl. Thronknopf, HUD-Tiefe/Thema und Ladeoverlay angebunden; Ladebereitschaft verlangt passende Brett-Seed-Kennung, Felder, Terrain und Modelle. Bisherige Missionsbildschirme bleiben bestehen.

**Entscheidungen:** Alle Werte WIP in RunConfig; Teilheilung auf ganze KP aufgerundet. Gegnerlevel nutzen die bestehende Einheitenkonstruktion. Weitere Gebiete, Bosse, Lager, Waffen und Ränge bleiben spätere Phasen. ToLobby dient bei Lauf-Ladefehlern zur internen Rückkehr zur Wahl mit unverändertem current/KP; Lauf-UI verhindert Hub-Zugang. Servergröße **1** muss der Nutzer in Roblox-Spieleinstellungen setzen, nicht per Code. Ein Commit je Planschritt auf feature/lauf-phase1. Nummer #23 laut PLAN.md, da #21/#22 auf anderem Branch liegen.

**Probleme:** Normaler Terminal-Start scheiterte am Prozess-Setup; alternative lokale Prozessaufrufe funktionierten. Git-Schreibzugriffe nutzten dauerhaft freigegebene Git-Aufrufe. Ohne DataStore-API-Zugriff gelten Profile wie bisher nur für die Sitzung. Keine blockierenden Syntax-/Generatorprobleme; unabhängiger Claude-Review steht aus.

**Teststatus:** **Ungetestet in Roblox Studio und auf dem Handy.** Pflichtcheck nach jedem Schritt grün, Abschluss **31 Dateien, Exit 0**. Generator **OK: 15.000 Level, 5.000 Optionen, 0 % Rückfall**, erzwungener Rückfall geprüft. Profil-Migration mit echtem ProfileStore.load und Stubs: altes Profil, gültiger/gewählter Lauf und 16 defekte Stände OK. RunService-Übergänge einschließlich fünf Siegen, Heilung/Gefallenen, Niederlage/Aufgabe OK. Echte Main-Befehle mit Roblox-Stubs: Fehleingaben/Besitz, feste Wahl/Resume, Profilkopie, Sieg ohne Lord, Belohnungen ohne Sterne, Aufgabe/Niederlage und Story-Lordregel OK. RunUI-Bildschirmwechsel mit UI-Stubs OK. Rojo-Abschlussbuild erfolgreich. Stubs simulieren weder Rendering noch Replikation oder echten DataStore; manuelle Prüfliste in PLAN.md bleibt offen. Temporäre Prüfhilfen unter tools werden nicht committet.

---
## Nächste Schritte (Plan)
1. **Claude-Review und manueller Lauf-Test:** Servergröße 1 setzen; komplette Prüfliste in PLAN.md auf PC und Handy prüfen, besonders Wiederbeitritt, Speicherung, Tote/Heilung, Gegnerphase-Aufgabe, fünf Level und bestehende Missionen.
2. **Offene Figuren-/Darstellungstests:** eigenes Waffenmodell (leon_waffe), weitere Mesh-Modelle, Kampfszenen, Erstaufbau/Ladepfade, Handy-Kamera und Weltkarte/Terrain prüfen.
3. **Roguelike Phase 2 – Tutorial:** Missionen 1+2 mit Überspringen-Abfrage; übrige Missionen, Sterne und Schwierigkeiten gemäß roguelike-design.md umbauen.
4. **Roguelike Phase 3/4:** Bosse/Lager, Wiederbelebung/Teamwechsel/Teamplätze, danach Waffenbeute, Händler, Rückblenden und Notfall-Beschwörung.
5. **Roguelike Phase 5–7:** Sumpf/Gefahren/Leveltypen, Eis/Vulkan, danach Punktzahl/Ränge/Bestenlisten. Detailentscheidungen vorher klären.
6. Sounds probehören, Output und Bildrate beobachten; gemeldete Avatar-/Asset-Ladefehler mit ID dokumentieren und gesondert beheben.
7. Ausrüstung/Items als reine Werte (Aussehen bleibt die eigene Waffe der Figur).
8. Beschwörungs-Show mit animierter Rekrutierung, Lichtsäule in Seltenheitsfarbe, Kamerafahrt und Pose.
9. Helden-Showcase mit großem drehbarem Modell in der Kaserne.
10. Eigene Angriffs-Effekte für ★4/★5.
11. Skins und Ausrüstungs-Stufen: Aussehen wächst mit Verschmelzen/Level, dazu kaufbare Skins.
12. Anime-R15-Modelle schrittweise gemäß `docs/charakter-pipeline.md` erstellen/importieren; der Figurenstil `mesh` ist vorbereitet, fehlende Modelle bleiben Chibi.
13. Belohnungen & Klassenwechsel.
14. Tägliche Belohnungen / Quests, Co-op-Raid, Saison-Pass und Rewarded Ads.
