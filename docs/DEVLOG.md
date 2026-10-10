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
## #21 – Aufräum-Werkzeug für KI-Modelle
**Datum:** 07.10.2026

**Ziel:** KI-Figurenmodelle mit einem Befehl für Roblox aufbereiten und das Gesicht trotz 1024er-Textur scharf erhalten.

**Umsetzung**
- `scripts/cleanup.ps1` startet Blender headless für FBX/GLB; Parameter für Ausgabe, Blickrichtung, Texturgröße, Kopfanteil, Dreieckslimit und optionale Cel-Palette.
- `scripts/cleanup/cleanup_model.py` verbindet Meshes, entfernt Rig/Animationen, richtet die Figur aus, verschweißt Punkte, entfernt winzige Teile, glättet nach Kantenwinkel und trianguliert. Neue UV-Anordnung reserviert standardmäßig 25 % UV-Fläche für den Kopf; Emission-Bake mit doppelter Auflösung überträgt die Originaltextur auf 1024 px.
- Vorder-/Rückansicht, Gesicht und Originalvergleich mit 1K sowie Bericht mit Farbtreue-Check. Optionales K-Means-Cel mit Gesichtsschutz und Erhalt selten abweichender Körperfarben.
- FBX (nur Mesh, FBX Units Scale, Forward −Z / Up Y) und GLB mit eingebetteter Textur; FBX-Re-Import in eine leere Szene prüft Dreieckszahl, Texturgröße und bytegleiche eingebettete PNG-Daten. Pipeline und Figuren-README erklären Download → Aufbereitung → Studio-Import → Avatar Auto Setup.

**Entscheidungen:** Generator-Texturen in 4K herunterladen; neue UVs geben dem Kopf mehr Fläche. Kopfgewichtung obere 13 %/Radius < 12 % der Höhe; nach Claudes Freigabe schützt Cel die oberen 16 % einschließlich Kinn. Körperpixel mit euklidischem RGB-Abstand > 40 zur Palette behalten ihre Originalfarbe. Cel-Farbtreue wird nur berichtet. Rohdaten, Prüfbilder und Exporte bleiben unter ignoriertem `assets/raw/`; Spielcode und bestehendes `leon.rbxm` unverändert. Separate Commits pro Schritt auf `feature/modell-cleanup`.

**Probleme:** Die ursprüngliche 13-%-Cel-Maske ließ Leons Kinn grau werden; mit freigegebener 16-%-Maske behoben. Blender 5.2 verwendet `shade_smooth_by_angle` für die 40°-Glättung. Blender meldet nur Deprecation-Warnungen zu `Material.use_nodes` für eine künftige Version; beide abschließenden Aufrufe erfolgreich (Exit 0). Git-Index für den Doku-Commit nur mit bereits freigegebenem Aufruf außerhalb der Sandbox schreibbar.

**Teststatus:** **In Roblox Studio und auf dem Handy ungetestet; unabhängiger Claude-Review ausstehend.** Leon mit und ohne Cel unter `assets/raw/leon/clean/` erfolgreich erzeugt: jeweils 16 862 Dreiecke, 25 574 → 8 556 Punkte, alle 21 Teile erhalten, UV-Inseln 4 674 → 2 605, Kopfanteil 25,00 %, Textur 1024×1024. FBX-Re-Import beider Varianten identisch, PNG eingebettet und bytegleich; beide FBX/GLB-Dateien vorhanden. Mittlere Farbabweichung normal 2,77/255 (RGB 3,16 / 2,69 / 2,48), Cel 5,42/255 (informativ). Cel: 16 Farben auf 122 620 Körperpixeln; 172 Pixel (0,1401 %) wegen Farbabweichung erhalten; Kopf, seltene Farben, Hintergrund und Randpixel bytegleich. Prüfbilder angesehen: Vorder-/Rückausrichtung passt, Iris/Pupillen/Augenränder schärfer als im Original auf 1K; Cel-Gesicht einschließlich Kinn sichtbar unverändert. Pflichtcheck **OK, 26 Dateien, Exit 0**.

---
## #22 – Textur selbst bemalen
**Datum:** 07.10.2026

**Ziel:** Aufbereitete Figuren ohne Blender-Vorkenntnisse anhand der eigenen Referenzbilder nachmalen und die gespeicherte 1024er-Textur für Studio exportieren.

**Umsetzung**
- `scripts/paint.ps1` startet Setup/Export mit Figuren-ID, optionalem Eingabeordner und derselben Blender-Suche wie das Aufräum-Werkzeug. Fehlende Parameter/Dateien ergeben verständliche Meldungen und Exit 1; Blender-Exit-Codes werden durchgereicht.
- Setup importiert das aufbereitete GLB, verbindet die externe `*_tex_bemalt.png` über `UV_neu` und erzeugt zugeschnittene Vorder-/Rückreferenzen, ein 1024er-UV-Raster mit halbtransparenten Linien sowie `*_malen.blend` mit relativen Bildpfaden. Zwei lokale Pinsel-Assets: „Referenz vorne“ als Schablone und „Flach malen“ mit konstantem Abfall; Rückreferenz als umschaltbare Textur. Canvas, Texturansicht und ausgeschaltete Spiegelung vorbereitet.
- Bestehende Mal-Dateien sind ohne `-Force` geschützt. Force sichert eine vorhandene bemalte PNG mit Zeitstempel und behält sie bei; neue PNGs sind Kopien der Originaltextur.
- Export liest ausschließlich die PNG von der Festplatte, prüft deren Größe, warnt bei einer mehr als 60 Sekunden neueren Blender-Datei und erzeugt bemalte FBX/GLB, drei Prüfbilder sowie einen Bericht mit Anteil geänderter Pixel. Exportoptionen und Re-Import-Prüfung in `cleanup_model.export_files`, Kamerarahmen/Prüfbilder in gemeinsame Funktionen ausgelagert. `paint_common.py` teilt Eingabeprüfung und GLB-Import zwischen Setup und Export.
- `docs/textur-malen.md` erklärt Setup, Navigation inklusive Laptop-Einstellungen, Schablone, Flächen, Rückgängig, beide Speicherschritte, Export und Studio sowie den Alternativweg in Krita/Photopea. Verweise in Charakter-Pipeline und Figuren-README.

**Entscheidungen:** Beide Pinsel bleiben als lokale Assets in der Mal-Datei; keine Installation in eine persönliche Asset-Bibliothek nötig. Maltextur und Referenzen bleiben externe Dateien im Ordner `clean`. In Blender 5.2 gilt für die Pipette **Umschalt + X** statt des im Plan genannten S; die Anleitung verwendet die tatsächlich installierte Standard-Keymap und zusätzlich F3 → Sample Color. Der Texture-Paint-Arbeitsbereich wird vom Nutzer geöffnet. Rohdaten, Prüfskripte und erzeugte Dateien bleiben ignoriert; Spielcode, Rojo-Projekt und `leon.rbxm` unverändert. Ein Commit pro Planschritt auf `feature/modell-cleanup`.

**Probleme:** `ImagePaint.brush` ist in Blender 5.2 schreibgeschützt; Aktivierung über `brush.asset_activate` mit LOCAL und `Brush/<Name>` erfolgreich. UV-PNG-Export braucht headless `gpu.init()`. Blender lädt externe Bilddaten erst bei Bedarf; Größen-/Pixelzugriff nach Neuöffnung geprüft. Sandbox-Meldungen zu persönlichen Asset-Cache-/Thumbnail-Verzeichnissen beeinträchtigten die lokalen Pinsel und Ausgaben nicht; Hauptläufe Exit 0. Gerenderte PNGs besitzen veränderliche Metadaten, daher Regression über Bildpixel statt Dateihash. Windows-PowerShell-Aufruf mit UTF-8-BOM für deutsche Meldungen.

**Teststatus:** **Vom Nutzer in Blender, Roblox Studio und auf dem Handy ungetestet; unabhängiger Claude-Review ausstehend.** Leon-Setup erzeugt alle geforderten Dateien; nach headless Neuöffnung aktives Mesh, `UV_neu`, Material, externes Canvas, Referenztexturen und beide aktivierbaren Pinsel geprüft. Zuschnitte vorne 1173×1051, hinten 1165×1046; UV-Raster 1024×1024, maximale Linien-Deckkraft 128/255. Wiederholtes Setup ohne Force: Exit 1 und alle Dateihashes/Zeitstempel unverändert; Force-Sicherung und Erhalt der Textur geprüft. Export unveränderter Kopie: **0 %**; magentafarbenes Testrechteck: **25 % / 262144 Pixel**, im Gesichts-Prüfbild sichtbar. Originalkopie wiederhergestellt. Falsche Bildgröße 512×512 wird mit Exit 1 abgelehnt; Zeitwarnung beobachtet. Cleanup-Regression: weiterhin **16862 Dreiecke**, Re-Import bestanden, ursprüngliche Textur bytegleich und Vorder-Prüfbild pixelgleich. Bemalte FBX-Re-Importe: 1024×1024, genau ein Mesh, eingebettetes PNG bytegleich. Abschließende Setup-/Export-Läufe erfolgreich, unveränderte `leon_tex_bemalt.png` hinterlassen. Python-Syntax der vier Module geprüft; Pflichtcheck **OK, 26 Dateien, Exit 0**. UI-/Keymap-Dateien abgeglichen; tatsächliche Bedienung und Studio-Import durch den Nutzer bleiben offen.

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

**Nachtrag (08.10.2026):** Vom Nutzer in Studio getestet – Lauf funktioniert. Behoben nach dem Test: Figuren waren nach dem Laden eines Lauf-Levels erst nach Klick auf „Szenen“ anklickbar (Eingabe blieb nach dem Laden gesperrt); Gefallene werden sofort gespeichert, damit ein Neustart sie nicht wiederbelebt, und ein Neustart erzeugt dasselbe Level (Nutzerentscheidung); Wurfspeer aus 2 Feldern −3 Stärke/−20 Treffer (Nutzerentscheidung, Werte WIP). Rückmeldung: Levelbausteine (Layout, Optik, Abwechslung, Brett) noch nicht schön; Umgebungs-Assets will der Nutzer selbst im Figurenstil generieren.

**Teststatus:** **Ungetestet in Roblox Studio und auf dem Handy.** Pflichtcheck nach jedem Schritt grün, Abschluss **31 Dateien, Exit 0**. Generator **OK: 15.000 Level, 5.000 Optionen, 0 % Rückfall**, erzwungener Rückfall geprüft. Profil-Migration mit echtem ProfileStore.load und Stubs: altes Profil, gültiger/gewählter Lauf und 16 defekte Stände OK. RunService-Übergänge einschließlich fünf Siegen, Heilung/Gefallenen, Niederlage/Aufgabe OK. Echte Main-Befehle mit Roblox-Stubs: Fehleingaben/Besitz, feste Wahl/Resume, Profilkopie, Sieg ohne Lord, Belohnungen ohne Sterne, Aufgabe/Niederlage und Story-Lordregel OK. RunUI-Bildschirmwechsel mit UI-Stubs OK. Rojo-Abschlussbuild erfolgreich. Stubs simulieren weder Rendering noch Replikation oder echten DataStore; manuelle Prüfliste in PLAN.md bleibt offen. Temporäre Prüfhilfen unter tools werden nicht committet.

---
## #24 – Level-Optik Etappe A
**Datum:** 08.10.2026

**Ziel:** Cel-passenden Brettboden mit dezentem Raster und schrittweisem Austausch der Part-Deko durch eigene Umgebungsmodelle vorbereiten; Objekt-Aufbereitung und Anleitung ergänzen.

**Umsetzung**
- Rojo lädt assets/environment nach ServerStorage.EnvironmentModels. EnvironmentAssets prüft Model/BasePart, bereinigt Klone von Skripten, Sounds, Interaktionen und Partikeleffekten, verankert Teile und deaktiviert Kollision/Query/Touch. Warnung einmal je Datei; fehlende Kategorien bleiben Part-Deko. Sortierte Varianten, Karten-/Feldschlüssel, deterministische Drehung und Größenstreuung, proportionale Maximalmaße und Pivot unten Mitte. Vorlagen bleiben serverseitig; Änderungen am Asset-Ordner verwerfen den Cache.
- BoardBuilder ersetzt Terrain-Füllung und Höhenkalibrierung durch SmoothPlastic-Rechtecke mit flacher farbiger Oberseite und dunkleren Seiten. Gleiche benachbarte Felder werden zusammengefasst; Wasser/Morast-Pfützen sind flache stilisierte Parts. Vier Flächen bilden die Umgebung mit leichtem Absatz; altes Terrain wird im Brettbereich entfernt. Feldoberkante bleibt exakt Grid.toWorld; dünne Rasterkanten folgen jeder Höhe und doppelte Kanten gleicher Höhe entfallen.
- Client-Ladebereitschaft wartet auf die passende Kartenkennung, alle Klickfelder und Boden-/Seiten-Parts sowie Einheiten und Lauf-Seed. Wald/Berg/Festung nutzen Modelle an Ecken, Brücken drehen sich nach Nachbarfeldern; seltene Blumen/Steine/Gras/Zäune bleiben am Feldrand. Bäume/Felsen/Büsche am äußeren Rand nutzen größere Grenzen.
- cleanup.ps1 -Prop / cleanup_model.py --prop: standardmäßig 3000 Dreiecke, 512 px, gleichmäßige UV-Verteilung ohne Kopferkennung oder Kopf-Gewichtung, Prüfbilder vorne/Seite/oben. Farbtreue und Exportprüfung bleiben erhalten; Figuren-Modus bleibt unverändert.
- Stil-Guide ergänzt Cel-Regeln und Regionsfarben; umgebung-assets.md enthält Größen-/Dreieckstabelle, Grasland-Checkliste, Prompt-Vorlage, Paket-Hinweise und Bild → Meshy → -Prop → Studio → .rbxm → Rojo. Charakter-Pipeline und Asset-README verweisen darauf.

**Entscheidungen:** Werte zentral in Config.ENVIRONMENT/FEEL/TERRAIN und Stages.Regions. Größenstreuung ±10 % bleibt auch bei gedrehten Modellen innerhalb der Grenzen. Festungsmodell ist ein Eckelement (vier pro Feld); Brücken brauchen freie Mitte ohne erhöhte Laufplatte, damit Figuren auf Brettniveau stehen. Ruinenelemente sind für Etappe B vorbereitet. HubBuilder, Grid, Figuren-Code, Spielregeln, Generator-Layout und Rohdaten unverändert. Ein Commit je Planschritt auf feature/level-optik.

**Probleme:** Normale Befehlsausführung scheitert weiterhin beim Prozessstart; Befehle gemäß vorhandener Nutzerfreigabe in PLAN.md außerhalb der Sandbox mit normalen Terminal-Freigaben ausgeführt. Lokale Prüfhilfen und Blender-Ausgaben liegen ausschließlich unter ignoriertem tools/. Stub-Zeitmessungen bilden weder Terrain-Voxel noch Roblox-Replikation oder Rendering ab: Beispiel vorher/nachher Story s2 7,89/6,24 ms, Sumpf s4 5,84/8,59 ms, Lauf Seed 12345 3,71/3,29 ms; Werte schwanken, Leistungsziel in Studio noch unbestätigt. Reale „Missionsaufbau … Brett“-Zeiten müssen vor/nach der Änderung verglichen werden.

**Teststatus:** **In Roblox Studio und auf dem Handy ungetestet; unabhängiger Claude-Review ausstehend.** Pflichtcheck nach jedem Schritt grün, Abschluss **OK, 32 Dateien, Exit 0**; Rojo-Build nach Schritt 2–4 und Abschluss erfolgreich. Generator **OK: 15.000 Level, 5.000 Optionen, 0 % Rückfall**, erzwungener Rückfall geprüft. Luau-Stubs: leerer Asset-Ordner, Vorlagenprüfung/Bereinigung, Warnung einmal, deterministische Größe/Platzierung, Maximalmaße auch bei 45°, Boden-Pivot und Klickdurchlass bestanden. Story/Sumpf/Lauf: jedes Feld genau einmal abgedeckt, Oberkante stimmt, Raster und Klickattribute korrekt; Bodenrechtecke 51/108, 57/108, 29/80. Echte missionReady mit fehlenden Boden-Parts, falscher Karte, fehlenden Einheiten und Lauf-Seed geprüft. Ohne Assets Part-Deko identisch zu Schritt 2; mit lokalen Testvorlagen alle Kategorien, freie Feldmitte, äußere Platzierung und beide Brückenrichtungen geprüft. Blender-Testfels: **3968 → 3000 Dreiecke**, **512×512**, Farbabweichung **0,0594/255**, FBX-Re-Import samt eingebettetem PNG bestanden; drei Prüfbilder angesehen. Leon normal/Cel: Berichte außer Laufzeit, Texturpixel und Vorder-/Rück-/Gesichts-Prüfbilder identisch zu Devlog #21 (**16862 Dreiecke**, **25 % Kopf**, Farbabweichung **2,7728/5,4210**). Stubs ersetzen keinen Studio-/Handytest.

---
**Nachtrag Etappe A2 (08.10.2026):** Etappe A wurde vom Nutzer in Studio getestet: Raster und sichtbare Objekte passen, der Boden war zu grell/flach und blaue Bewegungsfelder nahmen Klicks nicht an. Der vorbereitete Klickfix entfernt Kollisionen von Surround-/Side_-/Ground_-Parts, sodass CanQuery = false wirksam ist. Boden-/Randfarben sind nun gedämpft; flache deterministische Flecken und austauschbare Oberseiten-/Seitenbilder ergänzen die Optik. Anleitung in `docs/umgebung-assets.md`. **Klickfix und neue Farben/Texturen in Studio/auf dem Handy ungetestet; Claude-Review ausstehend.** Pflichtcheck, Generator und Rojo-Build grün; Einzelheiten siehe #25.

---
## #25 – Level-Optik Etappe A2: Klickfix und Boden-Textur
**Datum:** 08.10.2026

**Ziel:** Feldklicks wieder durch den Brettboden lassen und den Boden nach Nutzerentscheidung dunkler und mit dezenter Textur darstellen; eigene Bilder vorbereiten.

**Umsetzung**
- Claudes uncommittierten Klickfix unabhängig geprüft und separat committiert: Boden, Seiten und Umgebung ohne Kollision. Auch Fallback-Deko, Pfützen, Wasser und importierte Umgebungsmodelle lassen Abfragen durch; Tile_x_y bleibt das Klickziel.
- Alle acht Bodenfarben und Sumpf-Boden-/Randüberschreibungen mit HSV-Sättigung ×0,70 und Helligkeit ×0,75 gedämpft, RGB gerundet. Seiten bleiben zusätzlich 22 % dunkler. Vorher-/Nachher-Farbtabelle in PLAN.md; Werte WIP.
- Config.GROUND_TEXTURES bietet je Geländeart top/side, studsPerTile und transparency. Texture-Instanzen färben Bilder passend zum Gelände/Gebiet ein und kacheln über die Oberseite bzw. vier Seiten von Boden und Seitenkörper. Ohne Oberseiten-ID zwei flache unterschiedlich große/gedrehte Dreiecksflecken, auf Gras/Wald gelegentlich ein Halm-/Steinfleck; alle ohne Kollision/Query/Touch/Schatten.
- Einsteiger-Anleitung mit KI-Prompts, 2×2-Nahtprüfung, Studio-Upload/Bild-ID, Config-Beispiel, Geländezeichen, Einstellungen und Fehlersuche. Aktuelle offizielle Roblox-Doku nennt Fenster/Start → Asset Manager, älterer Ansicht-Menüweg ebenfalls erklärt.

**Entscheidungen:** Maximal drei zusätzliche Teile je Feld, Mitte mit 2,3 Studs Abstand und Rasterrand frei. Flecken liegen 0,001–0,004 Studs über dem Boden, Raster ab 0,005 und Standardoverlays ab 0,01. Flecken deterministisch aus Gebiet, Karteninhalt und Feld; Kartenkennung wird je Feld nur einmal gehasht. Oberseitenbild ersetzt Flecken, Seitenbild unabhängig; nil/leer stellt Standard wieder her. Keine echten Bilder generiert/hochgeladen. Weltkarten-/Schwierigkeitsfarben, Layout, Spielregeln, Figuren und Thronsaal unverändert. Vier Umsetzungscommits plus Abschlussdoku auf feature/level-optik.

**Probleme:** Sandbox-Prozessstart scheitert am Setup; benötigte Terminalbefehle mit Nutzerfreigabe außerhalb der Sandbox ausgeführt. Lokale Prüfhilfen bleiben unter ignoriertem tools/. Stub-Zeiten bilden weder Rendering noch Replikation ab; zusätzliche Parts müssen auf dem Handy bestätigt werden.

**Teststatus:** **Neue Änderungen in Roblox Studio und auf dem Handy ungetestet; unabhängiger Claude-Review ausstehend.** Pflichtcheck **OK, 32 Dateien, Exit 0**; Generator **OK: 15.000 Level, 5.000 Optionen, 0 % Rückfall**, erzwungener Rückfall OK; Rojo-Build erfolgreich. Raycast-Stub mit Strahl/Quader-Schnitt und Roblox-Kollisionsregel: **5.616 Strahlen** auf allen fünf Storykarten, Lauf Seed 12345 und allen acht Geländearten, senkrecht sowie echter Kamerawinkel/70° aus vier Drehrichtungen treffen die richtige Kachel. Textur-Test-ID korrekt auf Oberseite und sämtlichen Seiten, passende Farbe/Transparenz/U-/V-Kachelung und weiterer Klickdurchlass. Vollständig rotierte WedgePart-Geometrie bestätigt Höhenfolge, Feldgrenzen, freie Mitte, zwei Flecken je Feld, Höchstzahl (auch Limit 1), Determinismus und Gebietsschlüssel. nil/leer und nur Seitenbild geprüft. Vorher/nachher bei je 30 Aufbauten im selben Stub-Lauf: s1 **4,61/11,58 ms, 449/639 Parts**; s2 **7,83/17,98 ms, 776/1.029**; s3 **7,32/18,28 ms, 681/953**; s4 **9,24/19,04 ms, 874/1.115**; s5 **10,93/22,35 ms, 985/1.254**; Lauf **4,82/12,42 ms, 479/669**. Stubs ersetzen keinen Studio-/Handytest.

---
## #26 – Level-Optik Etappe B
**Datum:** 08.10.2026

**Ziel:** Zusammenhängendere, abwechslungsreiche Laufkarten mit durchgehenden Flüssen, vollständigen Brücken, freien Wegen vor den Startplätzen und weicheren Echtzeitschatten erzeugen.

**Umsetzung**
- 28 wasserfreie Graslandstücke: Lichtungen, zusammenhängende Wälder, Waldsäume, Felsketten und bewaldete Gehöfte. Jedes Stück trägt genaue Geländeprofile seiner vier Ränder. LevelGen spiegelt Zeilen und Kennungen zusammen und wählt passende Nachbarn; offener Anschluss als Rückfall für später unvollständige Kataloge.
- Separater Flussschritt nach Zusammensetzen der Stücke, Chance 40 %, Breite 1–2 und ein bis zwei Querungen. Flussbett zusammenhängend von links nach rechts, leichte Knicke, Abstand zur Startzone. Jede Brücke ersetzt den vollständigen Querschnitt, hat seitlich Wasser und beidseitig passierbares Land. Ersatzgeländer nutzen dieselbe Ausrichtung wie importierte Brückenmodelle.
- Startfelder bevorzugen Ebene, ersatzweise Wald; direkt davor ein auch für Reiter passierbares Feld. Keine unmittelbar hintereinander stehenden Startfiguren. Alle Starts und Gegner bleiben gemeinsam erreichbar; Hindernisgrenze unverändert.
- Config.FEEL.battleShadowSoftness = 1 (WIP), im Kampf/Sumpf lokal gesetzt; beim Verlassen ursprünglichen Saalwert wiederherstellen. Brett-/Effektteile werfen bereits keine unnötigen Schatten, Licht-Technik bleibt bestehen.
- Generatorprüfung auf alle Teamgrößen je Seed/Tiefe/Thema erweitert: unabhängige Fluss- und Brückenprüfung, geschützte Startzone, Weg nach vorn, passende gespiegelte Übergänge, Vielfalt, Determinismus, Chance 0/1 und Randseeds.

**Entscheidungen:** Exakte Randprofile verhindern abrupte Geländewechsel an den Nähten. Nur Querflüsse, da die untere Startzone samt Abstand einen durchgehenden Längsfluss ausschließt. Ein einfeldbreiter Knick wird lokal zweifeldbreit, damit keine diagonale Unterbrechung entsteht. Flussentscheidung bleibt bei Neuversuchen gleich, um die konfigurierte Quote zu erhalten. Bestehende RunConfig-Werte, Story-Karten, Spielregeln, Figuren und Thronsaalaufbau unverändert. Umsetzung auf feature/level-optik.

**Probleme:** Sandbox-Prozessstart scheitert weiterhin am Setup; benötigte Befehle mit Nutzerfreigabe außerhalb ausgeführt. Lokale Darstellungsprüfungen verwenden Roblox-Stubs und bestätigen keine sichtbare Schattenberuhigung, Darstellung oder Handy-Leistung.

**Teststatus:** **In Roblox Studio und auf dem Handy ungetestet; unabhängiger Claude-Review ausstehend.** Pflichtcheck **OK, 32 Dateien, Exit 0**; Rojo-Build erfolgreich. Generator **OK: 90.000 Levelprüfungen, 5.000 Optionen, 0 Rückfälle (0,00 %)**, erzwungener Rückfall OK; alle Teamgrößen 1–6 je Seed/Tiefe/Thema. **995/1.000 verschiedene Karten, 38,27 % Geländeanteil, 40,10 % Flussquote; 36.114 Flussprüfungen.** Zusätzlich 1.000 Karten ohne Fluss mit exakt passenden Nähten nach Spiegelung, **2.260 Wald-/1.303 Felsanschlüsse**, Chance 0/1 und Randseeds. Aktuelle BoardBuilder-/Atmosphere-Module mit Stubs: **12 Ersatzgeländer und sechs Modell-Brücken** für Quer-/Längsfluss und Breiten 1/2 korrekt ausgerichtet, kleine Brettteile ohne Schatten; Kampf/Sumpf mit Weichheit 1, ursprünglicher Saalwert 0,23 nach Wechseln wiederhergestellt. Temporäre Prüfhilfen unter ignoriertem tools/; manuelle Prüfliste in PLAN.md bleibt offen.

---
## Nachtrag zu #26 – feste Rundschatten für Figuren (08.10.2026)

**Ziel / Nutzer-Rückmeldung:** Die Karten „sehen gut aus“. Echtzeitschatten änderten mit `battleShadowSoftness = 1` beim Zoomen ihre Größe; nach Nutzerentscheidung bekommen Figuren feste, weich wirkende Rundschatten.

**Umsetzung:** `UnitVisuals.create` schaltet für sämtliche Teile der Brett-Figuren einschließlich Kleidung, Waffen, Aura und Pferd `CastShadow` aus, unabhängig vom Baustil. Das neue gemeinsame `UnitShadow` erzeugt drei konzentrische, flache Zylinderscheiben. Server-Lauf und Client-Animation führen sie horizontal mit; ihre Höhe kommt von der jeweiligen Feldoberfläche aus Grid, unabhängig von GroundOffset, Angriffslift und Root-Neigung. Beide vorhandenen Todespfade blenden die Scheiben mit aus. Kampfszenen entfernen den Brettschatten vor der Skalierung und erzeugen ihn in Originalgröße auf ihrem eigenen Boden neu; die Verbindung endet mit der Szene. Porträts und Ghost entfernen die Scheiben aus ihren Klonen. Die besondere Kampf-Schattenweichheit ist entfernt; Atmosphere verändert den ursprünglichen Wert nicht mehr. Thronsaal, Umgebung, Generator und Spielregeln bleiben unverändert.

**Entscheidungen:** Alle Schattenwerte in Config.FEEL, WIP: Durchmesser = Körperbreite × 1,8, beim Pferd mindestens größte HorseBody-Ausdehnung × 1,15; drei Schichten mit Größenfaktoren 0,65/0,82/1 und Transparenz 0,70/0,84/0,93. Unter-/Oberkanten liegen 0,0055–0,0085 Studs über der Feldoberseite, damit über Raster/Flecken und unter Standardoverlays/Zug-Ring. Alle Scheiben ohne Kollision/Query/Touch/Echtzeitschatten. Verankerte Scheiben folgen der Figur über UnitShadow.update statt einer kippenden Root-Schweißverbindung. Unveränderte Position/Höhe überspringt CFrame-Schreibzugriffe; keine Bild-Assets. Vier Umsetzungscommits plus Abschlussdoku auf feature/level-optik.

**Probleme:** Sandbox-Prozessstart weiterhin teilweise defekt; nötige Projektbefehle mit der im Plan vorgesehenen Nutzerfreigabe außerhalb ausgeführt. Lokale Prüfhilfen bleiben im ignorierten tools/. Stubs prüfen Anschlüsse und Geometrie, simulieren aber weder Roblox-Rendering/Replikation noch echte importierte Figuren oder Handy-Leistung.

**Teststatus:** Neue Rundschatten **in Roblox Studio und auf dem Handy ungetestet; unabhängiger Claude-Review ausstehend**. Pflichtcheck nach jedem Schritt grün, Abschluss **OK, 33 Dateien, Exit 0**; Rojo-Build erfolgreich. Aktuelle UnitShadow-, UnitVisuals-, UnitAnimator-, BattleScene- und Atmosphere-Module sowie die Porträtfunktion und der Ghost-Aufbau mit Stubs: **1.681 Assertions**, 48 Figuren-Fixtures für Chibi/Avatar/Mesh, Fuß/Reiter und alle acht Geländearten. Relative Maße, flache Orientierung, Höhenfolge, **192 Klickstrahlen durch die Schatten auf Kacheln**, echter Server-Lauf, Clientbewegung/Angriffslift, beide Todespfade, Szenenboden/Originalgröße, Verbindungsabbau, Porträt-/Ghost-Klone, kein doppelter Schatten und unveränderte Saalfigur/Weichheit bestanden. Generator-Abschlussprüfung siehe Notizen in PLAN.md.

**Generator-Abschlussprüfung:** **OK: 90.000 Levelprüfungen, 5.000 Optionsprüfungen, 0 Rückfälle (0,00 %)**; erzwungener Rückfall OK. Vielfalt 995/1.000 Karten, Geländeanteil 38,27 %, Flussquote 40,10 %, 36.114 Flussprüfungen und 2.260 Wald-/1.303 Felsanschlüsse. Generator unverändert.

---
## #27 – Seltenheits-Effekte aus und Handytexte passend
**Datum:** 08.10.2026

**Ziel:** Die vom Nutzer unerwünschten Seltenheits-Leuchten/-Partikel abschalten und die gemeldeten abgeschnittenen Handytexte sowie Überlappungen mit Roblox-Leiste, Untertitel und Knöpfen beheben.

**Umsetzung:** Claude-Änderung für Waffenlicht/Funken ab ★4 und Bodenaura ab ★5 in Chibi-, Mesh- und Avatar-Pfaden geprüft und übernommen; `Config.FEEL.rarityEffects = false`. Schnalle, Kragen, Wappen und Umhangsaum bleiben. Mesh-/Chibi-Cache-Schlüssel berücksichtigen den Schalter. Hub-NPCs und Heldenvorlagen nutzen dieselben Builder; Kampfszenen/Porträts klonen ihre Modelle, externe Pflichtsuchen nach den Aura-Teilen gibt es nicht.

Alle festen Textfelder in UIKit und den vier UI-Modulen erfasst. Gemeinsames `fitText` passt Kurztexte und Knöpfe mit TextScaled/UITextSizeConstraint an; die bisherige bzw. später gesetzte TextSize bleibt Obergrenze, mindestens 12 Designpunkte oder die kleinere vorhandene Schriftgröße. `flowLabel` lässt Fließtexte mit Umbruch in der Höhe wachsen, `textList` hält lange Bereiche scrollbar. Hinweis und Aufgeben stehen in einer automatischen Liste mit Abstand, Phase und Laufuntertitel in einem gemeinsamen Fenster. Werkzeugspalte breiter, Waffeninfo zweizeilig. Missionsdetails, Aufstellungsinfos, Missions-/Lauf-Ergebnisse, Bannertexte, Chancen/Garantie und Kaserneninformationen wachsen in Scrollbereichen. Missionsergebnis höher, Speicherwarnung mit reserviertem Platz, zehn Rekrutierungskarten scrollbar. Keine Texte inhaltlich gekürzt.

HUD einschließlich Thronsaal-/Lauf-Bildschirmen, MissionLoading und BattleScene verwenden explizit CoreUISafeInsets und deaktivieren die automatische Vollbild-Erweiterung. Skalierung anhand einer unskalierten GUI-Fläche nach Abzug der Roblox-Leiste und Geräte-Aussparungen; Reaktion auf Flächenänderungen. Untergrenze 0,5 bei weniger als 360 sicheren Punkten aufgehoben, damit mindestens 1280×720 Designpunkte Platz finden; Obergrenze 1,15 bleibt.

**Entscheidungen:** Lange Texte behalten ihre Schriftgröße und werden bei Bedarf gescrollt. Kurze Texte passen in ihre bestehenden Felder; Gefahr/Rückblende erhalten zusätzlich mehr Breite. Sichere Fläche über Roblox-Insets statt feste Leisten-/Notch-Annahmen im Spielcode. Offizielle API: [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui), [Größenmodifikatoren](https://create.roblox.com/docs/ui/size-modifiers). Spielregeln, Generator, Brettoptik und Figurenformen unverändert; fünf Schritt-Commits auf feature/level-optik.

**Probleme:** Sandbox-Prozessstart teilweise defekt; erforderliche Projektbefehle jeweils mit Nutzerfreigabe außerhalb ausgeführt. Lokale Prüfhilfen bleiben im ignorierten tools/. Stubs messen keine Roblox-Schriften/TextBounds und simulieren weder AutomaticSize/UIListLayout-Rendering noch echte Geräte-Insets.

**Teststatus:** **Neue Änderungen in Roblox Studio und auf dem Handy ungetestet; unabhängiger Claude-Review der Codex-Ergänzungen ausstehend.** Pflichtcheck **OK: 33 Dateien, Exit 0**; Rojo-Build erfolgreich. Aktuelle UIKit-/UI-/MenuUI-/RunUI-/CollectionUI-Module mit Stubs: **77 Anschlussprüfungen**. Vier Auflösungen 844×390, 915×412, 1280×720 und 1024×768, je 36/58 Punkte Leiste und 0/88 Punkte seitliche Aussparungen: 16 sichere Flächen, mindestens 1280×720 Designpunkte, skalierte Oberfläche innerhalb der Grenzen. Aktueller HUD-Aufbau und alle drei Menüseiten, zehn Rufkarten im Scrollbereich, Laufzustände Team/Wahl/Laden/Fortsetzung/Kampf/Ergebnis/Hub mit sechs Helden und scrollbar erreichbare Ergebniszeilen ausgeführt. Die manuelle Prüfliste in PLAN.md bleibt offen.

**Generator-Abschlussprüfung:** **OK: 90.000 Levelprüfungen, 5.000 Optionsprüfungen, 0 Rückfälle (0,00 %)**; erzwungener Rückfall OK. Vielfalt 995/1.000 Karten, Geländeanteil 38,27 %, Flussquote 40,10 %, 36.114 Flussprüfungen und 2.260 Wald-/1.303 Felsanschlüsse. Generator unverändert.

---
## #28 – Handy-Fix: sicherer Bannerbereich und Welt-Taps (Nachtrag zu #27)
**Datum:** 08.10.2026

**Ziel:** Nach dem Handytest im Querformat das gemeinsame Abschneiden von Runde/Banner/Hinweis und die ausgefallene Heldenauswahl beheben.

**Umsetzung:** TacticsUI, MissionLoading und BattleScene respektieren Geräte-Aussparungen über DeviceSafeInsets; UIKit positioniert den unskalierten Inhaltsbereich ausdrücklich im Core-Safe-Rechteck. Größe und oberer Abstand kommen aus GuiService:GetInsetArea, nicht aus festen Bildschirmwerten. Topbar-/Viewport-/GUI-Änderungen aktualisieren die Fläche, die UIScale sitzt erst darunter. Root-Größe in Design-Offsets, BattleScene nutzt dieselbe Berechnung mit ihrer bisherigen Obergrenze 1. Der Banneruntertitel erhält einzeiligen Fit (9–14 Designpunkte); Umbruch wird nach TextScaled ausdrücklich ausgeschaltet.

Touch-Auswahl verwendet ausschließlich TouchTapInWorld mit ViewportPointToRay und dessen GUI-Verarbeitungsprüfung. InputBegan/InputChanged/InputEnded bleiben für Pan, Pinch und Drehen; Drag, Mehrfinger und Abbruch lösen keine Auswahl aus. Die Auswahl hängt dadurch nicht mehr am gespeicherten processed-Wert des Touch-Beginns oder an einer verlorenen InputEnded-Auswahl. Maus bleibt bei InputObject.Position/ScreenPointToRay. Ladeoverlay beim Ausblenden sofort passiv, anschließend ScreenGui deaktiviert; erneutes Laden aktiviert es wieder. Avatar-Touchsteuerung wird sofort beim Kamerawechsel gesperrt/freigegeben, ältere PlayerModule-Jobs berücksichtigen den neuesten Modus. Config.INPUT_DIAGNOSTICS ist standardmäßig false; true protokolliert Beginn/Welt-Tap/Mausklick samt processed, Position, Instanz/Feld, canControl(), mode, Kamera, Laden und aktiven GUI-Treffern.

**Entscheidungen:** Explizite Inhaltsposition vor der Skalierung statt Rückbau auf IgnoreGuiInset=false, das laut Doku wieder dieselben CoreUISafeInsets setzt. Der alte Touch-Ray war laut offizieller Koordinatenzuordnung korrekt; der neue Welt-Tap hat bewusst einen anderen Koordinatenraum. Keine Spielregel-, Generator-, Brettoptik- oder Effektänderungen. Quellen und Untersuchung der vier Verdachtspfade stehen in PLAN.md.

**Probleme:** Die gleiche Schnittkante weist auf den gemeinsamen Flächen-/Insetpfad hin, wurde hier aber nicht mit einem Roblox-Geräterenderer reproduziert. Ladeoverlay-/Avatar-Verzögerung und der gespeicherte Touch-Blocker sind im Code belegt; der konkrete Auslöser auf dem Handy bleibt bis zum manuellen Test bzw. einer Diagnosezeile offen. Die vorherigen Stubs prüften Größen, aber keinen tatsächlich gerenderten Versatz, Clipping oder Schriftumbruch. Defekte Sandbox: notwendige Projektbefehle mit Nutzerfreigabe außerhalb ausgeführt; neue Prüfhilfen bleiben im ignorierten tools/.

**Teststatus:** Pflichtcheck **OK: 33 Dateien, Exit 0**, Rojo-Build erfolgreich. **101 UI-Anschlussprüfungen** mit aktuellen Modulen: 16 Flächen, expliziter Leistenabstand und rechte/untere Grenzen, Banneraufbau sowie Ladeoverlay einschließlich unterbrochener Ausblendung. **14 Eingabeprüfungen** mit tatsächlichen Main.client-Callbacks: beide Ereignisreihenfolgen, Held/Feld, GUI-Sperre, Ziehen, zwei Finger, Cancel, Kontrollsperren, Maus, Diagnose und Ladeende. **6 Avatar-Steuerungsprüfungen** mit tatsächlichen CameraController-Funktionen und verzögerten Jobs. Stubs ersetzen weder Roblox-Eingaberouter/Schriftmessung noch Studio-/Handytest. **Änderungen in Studio/auf Handy ungetestet; unabhängiger Claude-Review ausstehend.** Manuelle Prüfliste in PLAN.md bleibt offen.

**Generator-Abschlussprüfung:** **OK: 90.000 Levelprüfungen, 5.000 Optionsprüfungen, 0 Rückfälle (0,00 %)**; erzwungener Rückfall OK. Vielfalt 995/1.000 Karten, Geländeanteil 38,27 %, Flussquote 40,10 %, 36.114 Flussprüfungen und 2.260 Wald-/1.303 Felsanschlüsse. Generator unverändert.

---
## #29 – Handy-Fix 2: sichere Bildschirmfläche und einzeilige Kurztexte
**Datum:** 08.10.2026

**Ziel:** Das weiterhin gemeinsame Abschneiden der oberen Handy-Oberfläche und die seit #27 umbrechenden Werte-/KP-/EP-Beschriftungen beheben.

**Umsetzung:** UIKit.fitText schaltet nach TextScaled den Umbruch ausdrücklich aus und erzwingt dies auch bei späteren TextWrapped-/TextScaled-Zuweisungen. Labels erlauben ausdrücklich wrap = true, Buttons optional den fünften Parameter. Fließtexte behalten AutomaticSize und feste Schrift; Waffeninfo, Ladetitel, Speicherwarnung und die festen Laufbeschreibungen umbrechen ohne TextScaled. Das Werte-Raster und die kurzen Balkenbeschriftungen verwenden einzeiligen Fit; Laufuntertitel bleibt im Phasenfenster mit 9–14 Designpunkten.

TacticsUI, MissionLoading und BattleScene verwenden IgnoreGuiInset = true, ScreenInsets.None, SafeAreaCompatibility.None und ClipToDeviceSafeArea = false. UIKit setzt diese Eigenschaften zusätzlich in fester Reihenfolge, weil IgnoreGuiInset die Insets beeinflussen kann. SafeArea liegt in Bildschirm-Punkten außerhalb der UIScale: oben TopbarInset.Max.Y, bei 0 GetGuiInset().Y, mindestens der obere Geräte-Rand; links/rechts/unten Geräte-Aussparungen. GetInsetArea(DeviceSafeInsets) wird relativ zu GetInsetArea(None) umgerechnet; dessen Rechteckgröße beschreibt den vollständigen Bildschirm. Topbar-, GUI- und Viewport-Änderungen aktualisieren die Fläche; nach Kamerawechsel wird der Viewport-Listener neu gebunden, beim Zerstören getrennt.

Bei Config.INPUT_DIAGNOSTICS = true erscheinen gebündelte [UI-Diagnose]-Zeilen einmalig und bei Änderungen: Viewport, TopbarInset, beide GuiInset-Werte, InsetArea(None/Device), AbsolutePosition/Size von SafeArea, Root, Phasenbanner, Hinweis- und Geländekasten sowie UIScale. Standard bleibt false.

**Entscheidungen:** Geräte-Ränder ausdrücklich in den Bildschirm-Koordinatenraum umrechnen; kein fester Leisten-/Notch-Wert. Die offizielle [GuiService-Dokumentation](https://create.roblox.com/docs/reference/engine/classes/GuiService) zeigt negative InsetArea-Ursprünge, die berücksichtigt werden. TextScaled-Nebenwirkung gemäß [TextLabel](https://create.roblox.com/docs/reference/engine/classes/TextLabel); mehrzeilige feste Felder behalten Umbruch ohne Skalierung. Eingabe-/Touch-Logik aus #28, Spielregeln, Generator und Brett unverändert. Ein Commit pro Plan-Schritt auf feature/level-optik.

**Probleme:** Sandbox-Prozessstart defekt; erlaubte Projektbefehle gemäß Dauerregel vom 08.10.2026 über automatische Prüfung außerhalb ausgeführt. Lokale Prüfungen simulieren Property-Ereignisse und die TextScaled-Umbruch-Nebenwirkung, aber keine Roblox-Schriften, tatsächliches Clipping oder Geräte-Rendering. Prüfhilfen bleiben im ignorierten tools/.

**Teststatus:** Pflichtcheck **OK: 33 Dateien, Exit 0**, Rojo-Build erfolgreich. **128 UI-Anschlussprüfungen** mit aktuellen Modulen erfolgreich: 16 sichere Flächen (vier Auflösungen, zwei Leistenhöhen, seitliche und untere Aussparungen, negative InsetArea-Ursprünge), einzeilige Labels/Buttons auch nach Property-Änderungen, ausdrücklicher Fit-Umbruch, Fließtext, Leisten-Fallback, Kamerawechsel, Listener-Bereinigung, initial gebündelte Diagnose mit den drei oberen Kästen; bestehende HUD-/Menü-/Sammlungs-/Lauf- und Ladeoverlay-Pfade. **Neue Darstellung in Roblox Studio/auf Handy ungetestet; unabhängiger Claude-Review ausstehend.** Nutzer bestätigt Helden-Taps aus #28; Darstellung blieb dort abgeschnitten. Manuelle Prüfliste in PLAN.md bleibt offen.

**Generator-Abschlussprüfung:** **OK: 90.000 Levelprüfungen, 5.000 Optionsprüfungen, 0 Rückfälle (0,00 %)**; erzwungener Rückfall OK. Vielfalt 995/1.000 Karten, Geländeanteil 38,27 %, Flussquote 40,10 %, 36.114 Flussprüfungen und 2.260 Wald-/1.303 Felsanschlüsse. Generator unverändert.

---
## #30 – Roguelike Phase 2 – Tutorial (08.10.2026)

**Ziel:** Den Einstieg durch zwei geführte Tutorial-Missionen mit Überspringen und Wiederholen ersetzen; übrige Story-Missionen, Weltkarten-Reiter, Sterneziele und Schwierigkeiten entfernen.

**Umsetzung:** Starter-Team jetzt Leon, `starter_mage` und `starter_knight`. Zwei kleine Karten mit festem Team ohne Aufstellungsfenster: Leon übt Auswahl, Bewegung/Warten, Gegnerzug, Zielwahl und Kampfvorschau/Bestätigung; danach Magierin aus zwei Feldern ohne Konter und Ritter mit sieben Bewegungspunkten zum entfernten Schützen. Der Rest von Mission 2 ist frei. Neues gemeinsames Modul `Tutorial` enthält Schritte und Prüfungen; `TutorialGuide` filtert Eingaben und zeigt pulsierende goldene Markierungen auf Figuren, Feldern und Buttons. Server prüft Besitz, Phase, aktuelle Mission/Schritt, Session-ID, Figur, Ziel und Position; direkte/stale Wünsche werden abgelehnt. Profilmigration ergänzt `tutorial.state`. Willkommensfenster mit bestätigtem Skip, M2-Angebot nach M1, Neustart nach Niederlage, Wiederholung im Thronmenü und Lauf-Sperre bis `done`/`skipped`. Kriegstisch öffnet ebenfalls die Lauf-Teamwahl. Kaserne und Rekrutierung bleiben erhalten.

**Entscheidungen:** Neue Magierin/Ritter sind ★3-Platzhalter, Name/Design vom Nutzer; Klassen-Chibi bis zum Mesh-Import und kein Gacha. Bruno/Tobi bleiben in Altprofilen und im Pool. Alte Helden-Level (einschließlich Level 1) oder vorhandene Sterne kennzeichnen Bestandsspieler als `done`; `stars` bleibt unverändert im DataStore und wird nicht mehr im Spiel verwendet oder an den Client geschickt. Übungskämpfe verwenden feste Level-1-Werte, garantierte Spielertreffer, keine kritischen Treffer, keine Szenen und keine EP; Profile behalten ihre Heldenwerte. M1-Gegner bewegt sich gescriptet ohne Angriff, später bleiben Gegner stationär. Erste Absolvierung beider Missionen gibt einmalig 150 Gold aus Config (WIP), Wiederholung keine Belohnung. Sechs Schritt-Commits auf `feature/lauf-phase2`.

**Probleme:** Defekte Sandbox-Prozessstarts; erlaubte Projektbefehle nach der Nutzer-Dauerregel über automatische Prüfung außerhalb ausgeführt. Stub-Tests deckten die Bewegungsgrenze stationärer Gegner und zu weit entfernte Übungsziele auf; Scriptbewegung verwendet eine explizite Weggrenze, Ritter-/Abschlusspositionen anhand echter Grid-Wege korrigiert. Alte Missions-/Prep-Pfade bereits beim Entfernen der Shared-Helfer entfernt, um ungültige Aufrufe zu vermeiden. Lokale UI-Prüfhilfen bleiben im ignorierten `tools/`.

**Teststatus:** Pflichtcheck **OK: 35 Dateien, Exit 0**; Rojo-Build erfolgreich. **168 reproduzierbare Tutorial-Prüfungen** über `scripts/test-tutorial.ps1`: echte Server-, Profil-, Kampf- und Guide-Module mit Roblox-Stubs, beide Missionen, Fehltipps/falsche Figuren/Felder, Umgehen der Vorschau, veraltete Wünsche, fremder Spieler, beide Niederlagen/Neustarts, Profilmigration, Wiederholung ohne Belohnung/EP und Lauf nach Abschluss/Skip. **179 UI-Anschlussprüfungen**: Willkommenswahl, ausdrückliche Skip-Bestätigung, Ergebnis/Weiter/Neustart, Lauf-Sperre, neue Starter in der Teamwahl und Knopf-/Figuren-/Feldmarkierungen. **Studio/Handy ungetestet; Claude-Review ausstehend.** Die manuellen Checkboxen in PLAN.md bleiben offen.

**Generator-Abschlussprüfung:** **OK: 90.000 Levelprüfungen, 5.000 Optionsprüfungen, 0 Rückfälle (0,00 %)**; erzwungener Rückfall OK. Vielfalt 995/1.000 Karten, Geländeanteil 38,27 %, Flussquote 40,10 %, 36.114 Flussprüfungen und 2.260 Wald-/1.303 Felsanschlüsse. Generator unverändert.

---
## #31 – Phase 2 Feinschliff: Tutorial, PC-Skalierung und Level-Up
**Datum:** 09.10.2026

**Ziel:** Vier Wünsche nach dem Tutorial-Test umsetzen: größere Hinweise, vollständig gelbes Bewegungsziel, größere PC-Oberfläche und Level-Up-Meldungen sofort wegklicken.

**Umsetzung:** Tutorial-Hinweise mit 31 statt bisher 22 Designpunkten in geführten Schritten; Mindesthöhe 92, Umbruch und automatisches Höhenwachstum. Freie Tutorial-Schritte verwenden dieselbe größere Schrift; die schmale Spalte links oben bleibt erhalten. Bewegungsziele füllen das ganze Feld kräftig gelb mit 3 % Transparenz, oberhalb der Bewegungsflächen und des Cursors; keine Kollision, Touch- oder Raycast-Abfrage. Figuren-/Gegnermarkierungen bleiben erhalten. Neue Darstellungswerte stehen in Config.TUTORIAL.

UIKit.createRoot vergrößert Oberflächen auf Geräten mit Maus ohne Touch um bis zu Faktor 1,25 aus Config.UI_SCALE. Mindestens 1184 × 664 Designpunkte schützen die oberen HUD-Spalten und den Rand des 1000 × 640 großen Kasernenfensters. Kleine/höhenbegrenzte Fenster bekommen entsprechend weniger Vergrößerung: etwa 8 % bei 1590 × 660, bis zu 25 % bei 1920 × 1080. Touch-Geräte einschließlich Maus/Touch-Hybrid behalten die bisherige Skalierung.

Level-Up verwendet ein eigenes ScreenGui mit einer vollflächigen transparenten Schließtaste vor Fenster und übriger Oberfläche. Klick/Tipp schließt sofort, ebenso Leertaste/Enter/Nummernblock-Enter. Weltsteuerung während der Meldung gesperrt; begonnene Maus-/Touchgesten verworfen. Automatisches Schließen nach 3,2 Sekunden bleibt; veraltete Timer schließen keine neue Meldung. Der bestehende Kampfablauf wartet nicht auf das Fenster.

**Entscheidungen:** PC-Vergrößerung durch vorhandene Layoutgrenzen begrenzt. Tutorial-Feld nahezu deckend, bestehender Rahmen pulsiert weiter. Sofortiges Ausblenden der Level-Up-Meldung ohne Schließanimation; Eingabefläche schließt beim abgeschlossenen Klick/Tipp. Tutorial-Schrittlogik, Serverprüfung, Lauf, Generator und Brett unverändert. Vier Umsetzungs-Commits und ein Abschluss-Commit auf feature/lauf-phase2.

**Probleme:** Sandbox-Prozessstart defekt; erlaubte Projektbefehle gemäß Dauerregel über automatische Prüfung außerhalb ausgeführt. PowerShell-Pipe übertrug neue deutsche Kommentare/Notizen zuerst mit falscher Kodierung; UTF-8 eingestellt und Texte korrigiert. Schritt-3-Checkbox/Notiz im Schritt-4-Commit nachgetragen. Automatische Prüfung lehnte einen kombinierten Abschlussbefehl wegen des noch nicht belegten Remote-Ziels für git push ab; origin und Branch-Tracking anschließend lesend verifiziert. Lokale Prüfhilfe bleibt im ignorierten tools/; Stubs simulieren keine Roblox-Schriftmessung, tatsächliches Rendering oder den echten Eingaberouter.

**Teststatus:** Grundtutorial inklusive Willkommensfenster, beider Missionen und 150 Gold vor diesem Plan vom Nutzer bestätigt. **Neue Darstellung und Level-Up-Bedienung in Studio/auf Handy ungetestet; unabhängiger Claude-Review ausstehend.** Pflichtcheck **OK: 35 Dateien, Exit 0**; scripts/test-tutorial.ps1 **OK: 168 Prüfungen**; Rojo-Build erfolgreich. Zusätzlich **180 bestehende UI-Anschlussprüfungen**, **99 Feinschliff-Prüfungen** (15 PC-/Touch-/Hybrid-Flächen, HUD-Abstände, Kasernenrand, Tutorialtext/-feld, sofortiges Schließen, Timer, Maus/Tastatur und beide Touch-Ereignisreihenfolgen mit tatsächlichen Main.client-Callbacks) und **14 bestehende Eingabeprüfungen** erfolgreich. Manuelle Checkboxen in PLAN.md bleiben offen.

**Generator-Abschlussprüfung:** **OK: 90.000 Levelprüfungen, 5.000 Optionsprüfungen, 0 Rückfälle (0,00 %)**; erzwungener Rückfall OK. Vielfalt 995/1.000 Karten, Geländeanteil 38,27 %, Flussquote 40,10 %, 36.114 Flussprüfungen und 2.260 Wald-/1.303 Felsanschlüsse. Generator unverändert.

---
## #32 – Roguelike Phase 3 – Bosse und Lager
**Datum:** 09.10.2026

**Ziel:** Grasland mit festem Miniboss in Level 3, Garrick in Level 5 und Lager für Heilung, Teamwechsel und Wiederbelebung erweitern.

**Umsetzung:** Laufabfolge L1/L2 Wahl, L3 Banditenhauptmann, L4 Wahl, Extra-Lager ohne Levelverbrauch, L5 Garrick. Zufällige Lageroptionen ersetzen normale Kämpfe ohne Belohnung. Laufversion 2 speichert Lagerphase, Extra-Halt, maximale Teamgröße und Todeshistorie auch ausgewechselter Helden; alte Phase-1-Läufe werden ohne Verlust von Sammlung/Währungen/Erfahrung verworfen.

Neues Servermodul `BossAbilities` führt Fähigkeiten aus Gegnerdaten aus: Hauptmann bewegt sich kürzer und ruft einmal bei niedrigen KP Banditen. Garrick hält die Festung bis zum ersten Treffer (auch nach späterer voller Heilung bleibt er aktiv), stärkt nahe Banditen per Kriegsschrei und kündigt die Verstärkung bei halben KP eine Gegnerphase vorher an. Stärke-Symbol/Ansage und markierte Randfelder sichtbar; besetzte angekündigte Felder warten auf eine spätere freie Gegnerphase. Ursprüngliche und beschworene Laufgegner skalieren zentral mit der Tiefe. Bosskarte mit Festung, drei Leibwachen, sechs Starts und vier Randfeldern wird nach Seed gespiegelt; Minibosskarte erweitert den bisherigen Generator mit zwei Leibwachen. Bossfall beendet den Kampf sofort, übrige Gegner fliehen. Gebietsboss erhöht den Teamplatz vor dem aktuellen Laufende auf vier; Ergebnis zeigt den Zuwachs.

Lager heilt alle lebenden aktiven Helden vollständig. Platzwechsel verwenden die bestehende Kaserne (Frame wird vor jedem Neuaufbau zurückgegeben), prüfen Besitz/Teamgrenze/Duplikate und den erwarteten bisherigen Platzinhaber. Gefallene bleiben beim Auswechseln/Zurückholen tot. Wiederbelebung wahlweise mit Gold oder Edelsteinen, Preise sichtbar vor Kauf, Guthaben/Phase servergeprüft. Ohne lebenden aktiven Helden kann man tauschen oder wiederbeleben, aber nicht fortsetzen. Wahl-UI zeigt Lager mit Zelt-Symbol und feste Bosskarten mit Namen. Bewegungsanzeige berücksichtigt die geringere Hauptmann-Reichweite. Charakter-Pipeline um `brigand_captain` als neue Platzhalterfigur ergänzt.

**Entscheidungen:** Nutzerentscheidungen aus `docs/roguelike-design.md` umgesetzt. Alle Zahlen WIP in RunConfig/Gegnerdaten: 30 % Lagerchance je Wahl; Wiederbelebung 100 + 25 × Level Gold oder 15 Edelsteine; Miniboss/Boss 2×/3× Goldbelohnung; Hauptmann-Schwelle 40 %, Garrick-Phase 2 bei 50 %; Kriegsschrei ab Runde 1 alle drei Runden, +3 Stärke, Radius 3, eine Runde. Hauptmann-Name/Entwurf bleiben Nutzerplatzhalter; Darstellung derzeit über Brigand. Grasland bleibt einziges Gebiet, weitere Gebiete und Händler/Waffen/Rückblenden/Notfall-Beschwörung folgen später. Sechs Umsetzungs-Commits und ein Abschluss-Commit auf `feature/lauf-phase3`.

**Probleme:** Sandbox startet weiterhin keine Prozesse; erlaubte Projektbefehle gemäß Dauerregel über automatische Prüfung außerhalb ausgeführt. PowerShell-Pipe zunächst mit falscher Zeichencodierung, danach UTF-8 eingestellt und betroffene Texte korrigiert. Server-Stubs benötigen für eine frische Lagerwahl einen zurückgesetzten `current`-Wert; Testfixture korrigiert. Die zusätzliche UI-Prüfung lädt CollectionUI vor RunUI entsprechend der neuen Abhängigkeit. Keine Designfragen offen.

**Teststatus:** Pflichtcheck **OK: 36 Luau-Dateien, Exit 0**; Rojo-Build `TacticsGame.rbxlx` erfolgreich. `scripts/test-tutorial.ps1`: **168 Prüfungen grün**. `scripts/test-run.ps1`: **34.006 Prüfungen grün**, einschließlich 1.000 vollständiger Laufabfolgen, 2.000 Bossaufstellungen über RunService, Fähigkeiten/KI, sofortigem Boss-/Miniboss-Sieg trotz lebender Leibwache, Belohnungen/Teamplatz, Lagerheilung nach L4, beiden Währungen/Guthaben, Todeshistorie/Teamgrenze, ungültigen/fremden Befehlen, Profilnormalisierung und echtem Stub-Save/Release/Load im Lager. `scripts/test-run-ui.ps1`: **109 Anschlussprüfungen grün** für Preise/Touchflächen, Währungswahl, Kasernenwiederverwendung/Tausch, Boss-/Lagerkarten, Neustart und Rückkehr in die Hub-Kaserne. **Phase 3 in Studio/auf Handy ungetestet; unabhängiger Claude-Review ausstehend.** Manuelle Checkboxen in PLAN.md bleiben offen; Stubs simulieren keine echte Schriftmessung, Darstellung, Replikation oder Handygesten.

**Generator-Abschlussprüfung:** **90.000 normale Level, 5.000 Optionsprüfungen und 12.000 Boss-/Minibosskarten grün**. Kein normaler Rückfall (0,00 %); erzwungener Rückfall geprüft. Vielfalt 995/1.000 Karten, Geländeanteil 38,27 %, Flussquote 40,10 %, 36.114 Flussprüfungen und 2.260 Wald-/1.303 Felsanschlüsse. Bossprüfungen sichern deterministische Spiegelung, Festung, Startfelder, Leibwache, Erreichbarkeit und freie Randfelder ab.

---
## #33 – Level-Optik Etappe C1
**Datum:** 09.10.2026

**Ziel:** Laufkarten entsprechend der Nutzer-Vorlage auf 16×12 erweitern, größere zusammenhängende Landschaften und geschwungene Flüsse, Seen/Inseln, Klippen und einfache Wasserfälle erzeugen. Tutorialkarten und Spiel-/Bossabläufe unverändert lassen; Grundoptik bleibt bis C2 erhalten.

**Umsetzung:** Laufmaße zentral in RunConfig, sechs 8×4-Bausteine pro Brett. Katalog mit 36 Stücken aus vier handgezeichneten Wald-/Fels-/Ruinenkernen und neun exakten Randkombinationen; alle Nord-/Westkombinationen vorhanden, Spiegelungen bleiben passend. Startfelder bevorzugen die Mitte der unteren zwei Reihen; Gegner stehen in der oberen Hälfte, WIP-Anzahl min(12, 6 + Tiefe). Laufkamera startet mittig bei der eigenen Truppe, alle Ecken erreichbar, Übersichtszoom bis Brettdiagonale × 1,6 (256 Studs); Umgebungsrand und Terrain-Freiraum passen sich den aktuellen Grid-Maßen an. Tutorialgrößen 6×5 und 10×6 sowie ihre Kamera-Startwerte unverändert.

Flüsse von links nach rechts, 1–2 Felder breit, Kurven über mindestens drei Reihen und 2–3 vollständige Brücken mit geschützten freien Ufern. Unregelmäßige Seen 3×3 bis 5×4, optional 1–2 Land-/Waldfelder als Insel; Fluss und See können zusammenfließen. Kleine Teiche mit 1–2 Feldern. Gegner nur auf von allen Starts erreichbaren Feldern, auch bei isolierten Inseln. Neues Gelände C „Klippe“: Höhe 8 gegenüber Berg 4, unpassierbar, gruppiert am Rand, dunklere senkrechte Seiten im bisherigen Bodenstil; Klickfeld bleibt an der Oberseite. Gelegentlich Quellklippe am linken Flussrand mit hellblauem Quellstreifen, Fallfläche und drei Gischtteilen, fünf zusätzliche Parts ohne Partikel; in Config abschaltbar. Generatorfeatures bleiben Serverdaten und werden beim Brettaufbau übergeben.

Garricks handgezeichnete 16×12-Karte mit Festung oben, drei Leibwachen, oberen Randklippen, Querfluss mit zwei Brücken, sechs mittigen Starts unten und vier freien Verstärkungs-Randfeldern. Seed-Spiegelung und Bosslogik erhalten; Miniboss verwendet den neuen Generator.

**Entscheidungen:** 8×4 statt kleinerer Stücke gibt mehr Raum für zusammenhängende Gruppen und teilt 16×12 ohne Rest. WIP-Hindernisgrenze 32 %; gewünschte Featurechancen Fluss 40 %, See 30 %, Insel 50 % der Seen, Teiche 35 %, Klippen 40 %, Wasserfall 50 % bei geeignetem Fluss/Klippenplatz. Tatsächliche Quote niedriger, wenn geschützte Ufer/Seen keine geeignete Quellklippe zulassen. Werte zentral in RunConfig/Config. Teure vollständige Prüfmatrix auf 200 Seeds reduziert, alle fünf Tiefen/drei Themen/sechs Teamgrößen bleiben geprüft; zusätzliche 1.000 Seeds für Vielfalt/Quoten/Anschlüsse und 96 erzwungene Landschaftskombinationen mit Randseeds. Ein Commit pro Schritt auf feature/level-optik-c. Keine Designfragen offen.

**Probleme:** Sandbox-Prozessstart weiterhin defekt; erlaubte Projektbefehle gemäß Nutzer-Dauerregel über automatische Prüfung außerhalb ausgeführt. Beim vorläufigen Größenport verschobene Verstärkungsfelder wieder an den Rand gesetzt. Neue unabhängige Zusammenhangsprüfung fand bei kleinen Inselseen getrennte Wasserflächen durch mehrere abgeschnittene Ecken; nur eine Ecke wird ausgeschnitten, damit auch der Ring um eine Insel zusammenhängend bleibt. Geometrie-Testfixtures auf echte Klassen/Tutorialmaße und CFrame-Zielweitergabe korrigiert. Notwendige Größenports des alten Katalogs/der Festung bereits in Schritt 1, endgültige Entwürfe in Schritt 2/5. Server-/Client-Main nur für Kamera-/Brettanschlüsse geändert, keine Spielregeln.

**Teststatus:** Pflichtcheck **OK: 36 Luau-Dateien, Exit 0**; Rojo-Build TacticsGame.rbxlx erfolgreich. scripts/test-levelgen.ps1: **19.000 normale Levelprüfungen, 5.000 Optionsprüfungen, 2.400 Boss-/Minibosskarten und 96 erzwungene Landschaftskombinationen grün**, Determinismus/Randseeds/erzwungener Rückfall geprüft; **0 reguläre Rückfälle (0,00 %)**, Laufzeit 49,24 s. 1.000/1.000 verschiedene Karten, Gelände 50,64 %, Flüsse 40,10 %, Seen 29,80 %, Inselkarten 14,60 %, Teiche 34,80 %, Klippen 39,90 %, Wasserfälle 3,60 %; 7.763 Flussprüfungen und 7.554 Wald-/3.522 Felsanschlüsse. Unabhängige Flutsuche von jedem Start, verbundene Fluss-/See-/Teich-/Klippengruppen, ganze Brücken/freie Ufer, Insel-Erreichbarkeit, Klippenpassierbarkeit, Bosskarte und freie Randfelder abgesichert.

scripts/test-run.ps1: **34.458 Lauf-/Boss-/Lagerprüfungen grün**, zusätzlich **421.719 Brett-/Kamera-/Teileassertionen** mit tatsächlichen BoardBuilder-, Grid- und Kamera-Modulen in Geometrie-Stubs; kleine/große Bretter, Klippen-Klickhöhe/Fuß-/Reiter-Wegfindung, Wasserfallhöhe/Gischt/Abschaltung, Terrain-Freiraum bei Größenwechsel, Startfokus, alle vier Ecken und Zoomgrenzen. scripts/test-tutorial.ps1: **168 Prüfungen grün**. **C1 in Studio/auf Handy ungetestet; unabhängiger Claude-Review ausstehend.** Manuelle Checkboxen in PLAN.md bleiben offen. Stubs simulieren keine Darstellung, echten Eingaberouter, Asset-Replikation oder Handy-Bildrate.

**Teilezahl/Aufbauzeit:** Gleiche Seeds 1–100, Tiefe 1, sechs Startfelder, Fallback-Deko ohne importierte Umgebungsassets: vorher 10×8 im Mittel **744,2 Brettteile** (633–979), **12,03 ms Stub-Aufbau**; nachher 16×12 im Mittel **1.848,6 Brettteile** (1.570–2.305), **33,46 ms Stub-Aufbau**, zwei Wasserfälle. Brettfläche 2,4×, Teilezahl ungefähr 2,48×. Reale Brett-/Figurenaufbauzeiten über die bestehende Ausgabe „Missionsaufbau …“ und Bildrate in Studio/auf Handy noch vom Nutzer zu messen; Stub-Zeiten sind keine Roblox-Laufzeitmessung.

---
## #34 – Level-Optik Etappe C2
**Datum:** 09.10.2026

**Ziel:** Die vom Nutzer ausgewählten Creator-Store-Modelle für dichte Wälder, gemischte Kronen, abwechslungsreiche Felsen, gewölbte Brücken, runde Sandufer und belebte Wiesen einsetzen. Wasserfälle an mehr Ufern und Seen ermöglichen, ohne Tutorialkarten oder Spielregeln zu ändern.

**Umsetzung:** Paket `assets/environment/grasland_pack.rbxm` mit 83 Modellen / 118 Teilen importiert; Ordner-Lader aus Claude-Commit 18698ea geprüft und nicht klonbare MaterialVariants abgesichert. Credits stehen in `assets/environment/README.md`: Yasu's Stylized Tree Pack (mvyasu), Stylized Rock Pack (nizendo), Blumen (Galaxy_girl644YT), Gras (Mistertitanic44), Zaun (Eikezan), Wooden Bridge (Justinnk231). Modellskripte, Sounds und Interaktionen entfernt, Deko fängt keine Feldklicks ab.

Wald mit 2–3 größeren Bäumen pro Feld sowie optional Busch/Wurzel; eigene WIP-Größen für Wald und Umgebungsrand. Regionale Kronenpaletten, im Grünland 90 % Grün und 10 % Herbst, Platzhalter für Sumpf/Eis/Vulkan. Färbung nur an Kronen über SurfaceAppearance.Color, mit geprüftem MeshPart.Color-Ersatz; Stämme unverändert. Client-Modul `ForestOutlines` zeigt blaue/rote Umrisse auf Wald und dem verdeckten Nachbarfeld entlang der dominanten Kamerablickachse. Höchstens 20, insgesamt 31 Slots mit mindestens 8 reservierten Slots; fremde Highlights berücksichtigt, Spieler zuerst, Bewegung/Tod/Kampfende räumen korrekt auf.

Berge mit großem Fels plus 1–2 kleinen, Klippen mit Felsen auf der Oberkante; Steinchen verwenden bei Bedarf Felsvarianten. Eine gewölbte Brücke je zusammenhängender Querung, X-Längsachse der Vorlage und beide Kartenrichtungen geprüft. Brücken- und bedeckte Uferhöhen per Include-Raycast gemessen, zentral in Grid und im Server-Snapshot an den Client übertragen. Figuren, Overlays, Ringe, Schatten und Kampfkamera verwenden diese Höhen. Unter B-Feldern Wasser; bei fehlendem Modell oder nicht messbarem Boden bisherige Part-Brücke. Ufer mit Sandstreifen, runden Kappen und konkaven Füllstücken, WIP-Budget 12 Parts/Feld; Rundung durch optische Masken, Klickraster bleibt erhalten. Etwa jedes zweite freie Wiesenfeld mit 1–2 Grasbüscheln, gelegentlich Blumen/Steinchen, selten Zaun; Slots/Gegnerfelder frei. Wasserfall-Klippen an geeigneten See-/Flussufern in allen vier Richtungen, weiterhin außerhalb der Startzone und geschützter Brückenufer.

**Entscheidungen:** Alle Mengen/Größen/Farben zentral in Config, gleiche Karte erzeugt gleiche Deko. Nach Messung dritter Baum auf 10 %, Busch/Wurzel auf 20 %, zweiter kleiner Fels auf 35 % abgestimmt; gewünschte Anzahlbereiche und 50-%-Wiesenquote erhalten. Bedingte Wasserfallchance 0,56 ergibt 15,60 % normaler Karten. Bodentexturwerte, Tutorialkarten, Kampf-/Lager-/Bossregeln unverändert. Ein Commit je Planschritt auf `feature/level-optik-c`; unabhängiger Review durch Claude steht aus.

**Probleme:** Sandbox-Prozessstart defekt, erlaubte Projektbefehle gemäß Dauerregel über automatische Prüfung außerhalb ausgeführt. Das im Plan vorausgesetzte Paket fehlte zunächst; Frage/Handoff nach Schritt 1, nach Bereitstellung durch den Nutzer entfernt und fortgesetzt. Vorläufige Dreieckschätzung über Ziel, Mengen innerhalb der Vorgaben abgestimmt. Kopierte Highlights (z. B. im Figuren-Ghost) anhand echter Instanzidentität als fremde Slots berücksichtigt, damit geklonte Attribute das Budget nicht umgehen; zusätzlicher Stub. Die lokale Datei enthält Mesh-Verweise statt verwertbarer Render-Dreieckzahlen; Schätzung ersetzt keine GPU-/Handymessung. Reale Brücken-Kollisionsoberfläche und optische Uferrundung müssen in Studio geprüft werden.

**Teststatus:** `check.ps1` **OK, 37 Luau-Dateien, Exit 0**; `test-levelgen.ps1` **19.000 Level-, 5.000 Options-, 2.400 Boss-/Minibossprüfungen und 96 erzwungene Landschaftskombinationen grün**, 0 reguläre Rückfälle, 15,60 % Wasserfallkarten, Seen/alle Richtungen nachgewiesen. `test-run.ps1` bestehende **34.458 Lauf-/Boss-/Lagerprüfungen**, zusätzliche echte Snapshot-Tests und **478.454 Brett-/Kameraassertionen** grün; C2-Tests für Lader/Bereinigung, Farben/Farbersatz, Umrissbudget/Vorrang/Kameradrehung/Lebenszyklus, Felsgrößen, Brücken/Wasser/Höhen/Fallbacks, Uferbudget, Wiesendichte/Starts und Determinismus grün. `test-tutorial.ps1` **168 Prüfungen**, `test-run-ui.ps1` **109 Prüfungen** grün. Rojo-Build `TacticsGame.rbxlx` erfolgreich. **Studio/Handy ungetestet**, manuelle Checkboxen in PLAN.md offen.

**Messung:** Seeds 1–100, Grünland, Tiefe 1, sechs Starts, 16×12 inklusive Rand. Maßhaltige Stubs sämtlicher Paketvarianten aus dem lokalen Rojo-Export, echte Maße/Rotationen/Teileklassen, geschätzte Mesh-Dreiecke. **1.762,2 Teile im Mittel / max. 1.971**, **296.921 Dreiecke im Mittel / max. 453.272**, **87,87 ms mittlerer Stub-Aufbau**. Das typische geschätzte Ziel ≤ 300.000 wird im Mittel erreicht; dichte Maximalfälle liegen darüber. Ohne Paket **1.936,9 Teile im Mittel / max. 2.350**, **41,77 ms mittlerer Stub-Aufbau**, Part-Fallback vollständig geprüft. Keine Aussage über reale Roblox-Aufbauzeit, Downloads oder Handy-Bildrate.

---
## #35 – Level-Optik Etappe C3
**Datum:** 09.10.2026

**Ziel:** Die Befunde aus dem ersten C2-Studio-Test beheben: ringförmige Sandufer, kleine lichte Wälder, fehlendes Goldzeichen, überlappende Auswahlkarten, knallgrüner leerer Umgebungsboden und glatte Berg-/Klippenwände.

**Umsetzung:** Ufer als deckende, gedämpfte Sandstreifen vollständig auf Land; alle Scheiben und optischen Masken entfernt, Brückenenden bleiben frei. `Config.ICONS.gold/gems` zentral für Laufbelohnungen, Lager und Ergebnisse; Gold zeigt 💰. Große Levelkarten verwenden HoverScale 1 und Quad beim Loslassen, mit unverändertem Farb-/Randfeedback; kleine Buttons behalten ihre Vergrößerung.

Waldbaumhöhe und Kronenbreite getrennt skaliert, damit schmale Paketvarianten nicht durch die Breitengrenze verkleinert werden. Weiterhin zwei bis drei Bäume je Feld; gemessene Kronenbreite 1,35–1,50 Felder, Baumhöhe 1,30–1,78. Umrisse berücksichtigen alle acht direkten Nachbarn und bis zu zwei Felder hinter der dominanten Kamerablickachse einschließlich seitlicher Nachbarn; Highlightbudget und Spielervorrang bleiben erhalten. Maßhaltige 4×4-Wald-Fixture: Kronen-AABB-Abdeckung steigt von 68,03 auf 99,99 %, gemessen über 32×32 Stichproben pro Waldfeld. Bounding-Box-Abdeckung ersetzt keinen Sichttest echter Mesh-Lücken.

Geschlossener, unregelmäßiger Waldrand mit großen Paketbäumen in der ersten Reihe, wenigen Büschen/Felsen und günstigen Kronen-Parts dahinter; Randtiefe einschließlich Kronen knapp vier Felder. Gedämpfte regionale Bodenfarben in Stages, Grass statt SmoothPlastic, WIP und umstellbar. Sichtboden beim C1-Maximalzoom separat erweitert und in Parts bis 512 Studs geteilt; der bisherige Terrain-Freiraum bleibt erhalten. Keine Umgebungsobjekt-Bounding-Box ragt auf das Brett. Berge/Klippen erhalten kühlere, dunklere Seiten und drei geneigte Stein-Facetten je freiliegender Außenkante mit unregelmäßiger Oberkante, ergänzt durch wenige halb eingelassene Paketfelsen. Keine Dekoration zwischen M/M, C/C oder M/C. Berg-Oberfelsen weiter an die Ecken gerückt und begrenzt, sodass 1,4 Studs um die Figurenmitte frei bleiben. Klickfelder unverändert.

**Entscheidungen:** Gerade Sandstreifen verhindern die beobachtete Ringwirkung und sparen Teile. WIP-Farben bewusst zurückhaltend: Sand 123/119/89, Grünland-Umgebung 73/86/64, Sumpf 55/67/49, Felsseiten 77/82/82; Eis/Vulkan mit regionalen Platzhaltern. Baumgröße statt stark erhöhter Baumzahl; Ferne und Felswände überwiegend aus günstigen Parts. Mittleres geschätztes Dreieckbudget auf 350.000 angehoben, inklusive Umgebung. Das Maximum bleibt darüber und muss gesondert auf dem Handy geprüft werden. Ein Commit pro Planschritt auf `feature/level-optik-c`; unabhängiger Review durch Claude ausstehend. Spielregeln, Generator, Tutorialkarten, Lager-/Bosslogik, Brückenlogik und Bodentexturwerte unverändert.

**Probleme:** Sandbox-Prozessstart weiterhin defekt; autorisierte Projektbefehle gemäß Nutzer-Dauerregel über automatische Prüfung außerhalb ausgeführt. Neue Tests erforderten `FindFirstChildOfClass` im Instanz-Stub. Die geometrische Zoom-Abnahme fand, dass der bisherige C1-Bodenrand den Sichtbereich bei maximalem Zoom nicht vollständig abdeckte; nur den sichtbaren Boden erweitert. Frühere Zwischenzeiten enthielten teils Assertionen, daher zusätzlich ein einheitlicher Messrunner ohne Prüf-/Zählzeit. Stubs prüfen weder Rendering noch Schriftunterstützung, Asset-Downloads, reale Kollisionsgeometrie oder Handy-Bildrate.

**Teststatus:** `check.ps1` **OK, 37 Luau-Dateien, Exit 0**; `test-levelgen.ps1` **19.000 Level-, 5.000 Options-, 2.400 Boss-/Minibossprüfungen und 96 Landschaftskombinationen grün**, 0 reguläre Rückfälle. `test-run.ps1` **34.458 Laufprüfungen und 523.294 bisherige Brett-/Kameraassertionen** sowie zusätzliche C3-Tests grün: Ufer ohne Masken und freistehende Sandteile, Kronenmaße/Abdeckung, seitliche/diagonale Waldumrisse, deterministische Modelle/Positionen/Größen/Rotationen/Farben, geschlossener Rand über 100 Paket-Seeds, freies Brett, Außen-/Innenkanten, freie Bergmitte, Paket-/Part-Fallback und Abschaltung. Boden-Strahlschnitte beim Maximalzoom für alle vier Brettecken, acht Kameradrehungen und 4:3/16:9/21:9 geprüft (C1-Neigung, 70° FOV). `test-tutorial.ps1` **168**, `test-run-ui.ps1` **116 Prüfungen** grün; Auswahlkarten bei Hover/Loslassen für drei Breiten ohne Überlappung, kleine Buttons weiterhin animiert. Rojo-Build `TacticsGame.rbxlx` erfolgreich. **C3 in Studio/auf Handy ungetestet**; manuelle PLAN.md-Checkboxen bleiben offen, insbesondere Brückenfüße und Kronenfarben aus C2.

**Messung:** `scripts/measure-environment.ps1 -Revision ...` liest Git-Stände ohne Checkout. Seeds 1–100, Grünland, Tiefe 1, sechs Starts, 16×12 inklusive Umgebung; dieselben maßhaltigen Paket-Fixtures, geschätzte Mesh-Dreiecke. Aufbauzeit ohne Assertionen und Teilezählung, schwankende Stub-Zeiten ohne Aussage über Roblox-Laufzeit.

| Stand | Teile Mittel / Max | Dreiecke Mittel / Max | Stub-Aufbau ms Mittel / Max |
|---|---:|---:|---:|
| Vor C3 | 1.762,2 / 1.971 | 296.921 / 453.272 | 85,13 / 104,69 |
| Ufer | 1.732,4 / 1.925 | 293.732 / 453.272 | 88,06 / 109,61 |
| Symbole/Hover | 1.732,4 / 1.925 | 293.732 / 453.272 | 87,88 / 120,45 |
| Wald | 1.732,4 / 1.925 | 293.732 / 453.272 | 88,34 / 146,52 |
| Umgebungsrand | 1.810,4 / 2.003 | 337.318 / 496.188 | 92,63 / 120,85 |
| Felswände | 1.972,2 / 2.120 | 343.436 / 499.260 | 98,58 / 124,48 |
| Final inklusive Zoom-Boden | 2.006,2 / 2.154 | 344.396 / 500.220 | 101,71 / 150,11 |

---
## #36 – Level-Optik Etappe C4
**Datum:** 09.10.2026 · Branch `feature/level-optik-c`

**Ziel:** Nach dem C3-Studio-Test aufpoppende Umgebungsschatten entfernen, Waldkronen verkleinern, Figuren besser sichtbar machen und den Waldring vorne niedrig und hinten/seitlich natürlicher gestalten.

**Umsetzung:**
- Umgebungsschatten standardmäßig aus (`ENVIRONMENT.castShadows`); aktivieren stellt die bisherige Modell-Höhenschwelle wieder her. Figuren-Rundschatten bleiben erhalten. Waldboden 10 % dunkler, Fleckkontrast halbiert.
- Waldkronen 1,1–1,2 Felder, Baumhöhen 1,2–1,5; Baumzahl und Anordnung erhalten. Figurenumriss mit Teamfarben-Füllung (Transparenz 0,8), auch bei Teamwechsel. Highlight-Budget und Spielervorrang erhalten.
- Waldring vorne (+Z) und an den vorderen Seitenecken (1 Feld) nur Büsche/Felsen bis 0,5 Feld Höhe über dem Umgebungsboden. Hinten/seitlich Gruppen aus 2–4 Bäumen mit wechselnden Höhen, Breiten, Abständen und Tiefen, dazwischen niedrige Büsche/Felsen. Welt-Bounding-Boxen halten Lücken bis 0,5 Feld und Umgebungsteile außerhalb des Bretts. Part-Fallback mit Baumgruppen; günstige Ersatzkronen nur weit hinten ab 4,5 Feldern.

**Entscheidungen:** Kronen-AABB-Abdeckung nur informativ: Claude hat das geschätzte Ziel 70–85 % ausdrücklich zurückgenommen. Gemessen im 4×4-Wald mit 32×32 Stichproben je Feld: 99,99 % vor C4, 99,48 % nach C4; Kronen 1,10–1,20, Höhen 1,20–1,49 Felder. AABBs überschätzen runde Kronen; der Nutzer beurteilt die Lichtheit in Studio. Nachbarradius 1 und Sichtweite 2 bleiben wegen Ecküberhang und perspektivischer Verdeckung erhalten. Kamera frei drehbar; der niedrige Rand bleibt in Grundausrichtung und folgt der Kamera nicht. Alle Gestaltungswerte sind WIP in Config.

**Probleme:** Defekte Sandbox-Prozessstarts gemäß Projekt-Dauerregel über automatisch geprüfte Projektbefehle außerhalb der Sandbox umgangen. Die Ringprüfung zeigte einen Fehler im vorhandenen CFrame-Inverse-Stub bei erneutem PivotTo; vollständige Rotationsmatrix ergänzt. Reales Rendering und Handy-Leistung sind durch Stubs nicht bestätigt.

**Messung:** `scripts/measure-environment.ps1`, identische maßhaltige Paket-Fixtures und 100 Grünland-Seeds; Dreiecke geschätzt, keine GPU-Messung.

| Stand | Teile Mittel / Max | Dreiecke Mittel / Max | Stub-Aufbau ms Mittel / Max |
|---|---:|---:|---:|
| Vor C4 (`fb0cb28`) | 2.006,2 / 2.154 | 344.396 / 500.220 | 98,57 / 118,89 |
| Nach C4 | 1.989,5 / 2.128 | 343.195 / 495.996 | 105,14 / 128,83 |

**Teststatus:** `check.ps1` OK (37 Dateien), `test-run.ps1` OK (34.458 Lauf-/Boss-/Lager-Stubs und 528.020 Brett-/Kameraprüfungen, zusätzliche Umgebungs-/Ring-/Outline-Stubs), `test-tutorial.ps1` OK (168), `test-run-ui.ps1` OK (116), Rojo-Build nach `TacticsGame.rbxlx` OK. `test-levelgen.ps1` OK (19.000 Level-, 5.000 Optionsprüfungen, 96 erzwungene Landschaftskombinationen, 2.400 Boss-/Minibosskarten). Ring-Tests über 100 Paket-Seeds plus Part-Fallback: Vorderhöhe, hohe Rück-/Seitenränder, Ersatzkronenlage, Lücken, Brettfreiheit, Klickbarkeit und Determinismus. Mittelbudget 350.000 eingehalten; Maximalwert und leicht erhöhte Stub-Aufbauzeit bleiben Anlass zur realen Leistungsmessung. **Studio/Handy für C4 ungetestet; Claude-Review ausstehend.**

---
## #37 – Level-Optik Etappe C5
**Datum:** 10.10.2026 · Branch `feature/level-optik-c`

**Ziel:** Natürliche Formen, eine in die Landschaft eingebettete Karte und keine Kronen-Platzhalter. Das C4-Feedback („Berge wie braune Würfel“, Wald zu dicht, zufälliger Objektring) durch ein Terrain-Tal, Felshügel und weniger Waldbäume umsetzen.

**Umsetzung:**
- Wald mit 1–2 Bäumen, 35 % zweite Bäume, Einzelbäume etwas außermittig. C4-Kronenmaße 1,1–1,2 Felder erhalten. Paket-/Fallback-Determinismus und Baumzahl je Feld geprüft; ohne Paket kantige Tannensilhouetten statt Kugelkronen.
- `LandscapeBuilder` ersetzt den Umgebungsring, alle rückwärtigen Ersatzkronen und den Sichtboden aus Parts. Flacher Wiesenrand, unregelmäßige Grashügel, höhere Rock-/Slate-Kuppen hinten/seitlich, flache +Z-Vorderseite. Fernboden aus großen Terrain-Blöcken reicht bis zum bisherigen Zoomrand, Nahlandschaft aus gebündelten `WriteVoxels`-Blöcken. Wenige echte Yasu-Baumgruppen, Felsen und Büsche; maximal 32 Landschaftsbäume. Regionale Materialien/Farben in `Stages`, WIP-Werte in `Config.LANDSCAPE`.
- M/C-Bodenkörper und Wedge-Felsfacetten entfernt. Zusammenhängende M-Felder verschmelzen in derselben Terrain-Matrix, C-Klippen erhalten unregelmäßige Oberkanten. Kleine felsfarbene Standkappen auf M garantieren exakt 4 Studs Standhöhe; Terrain darunter bei 3,73–3,85. Rasterlinien und Klickfelder bleiben in Feldhöhe. Größere Paketfelsen stehen außerhalb der Standflächen; Klippenmodelle folgen der Terrainhöhe. Wasserfallkanal auf 8 Studs, bestehende Quelle und Fallfläche schließen dort an. Ohne Felsmodelle bleibt Terrain funktionsfähig.
- Jeder Aufbau entfernt das bisherige Terrain vollständig, auch bei gleicher Brettgröße und Tutorialwechsel. Der Hub-Schutzbereich (±80/±100 Studs um `HUB_ORIGIN`) wird aus allen Bau-/Löschregionen ausgeschnitten. Alte Löschhöhe wird mitgeführt. Terrain-Messwerte und neue Stubs in den bestehenden Laufprüfungen integriert.

**Entscheidungen:** Die flache Vorderseite bleibt wie C4 an der Grundausrichtung +Z; die Kamera bleibt frei drehbar. Terrain ist der Hauptträger der Umgebung, ohne Paket entfallen äußere Modelldetails. Optionale Terrain-Flussfortsetzung vorerst ausgelassen. Kleine Standkappen gleichen das feste 4-Stud-Voxelraster aus; keine vollständigen Bergkisten bleiben stehen. M-Rasterlinien liegen weiterhin auf Feldhöhe. Wald-AABB-Abdeckung 99,48 % → 95,43 % bei denselben C4-Kronenmaßen, nur informativ. Keine Änderungen an Spielregeln, Generator, UI, Brücken, Ufern, Wiesen-Deko oder Client-Raycastfilter.

**Messung:** Identische maßhaltige Paket-Fixtures, 100 Grünland-Seeds, Tiefe 1, 16×12-Bretter. Modelldreiecke sind Schätzwerte **ohne Terrain-Geometrie**; Stub-Zeit enthält Terrain-Datenaufbau und Stub-Validierung, kein Rendering. Zwischenstand-Festvolumen um überlappenden Fern-/Nahboden bereinigt.

| Stand | Teile Mittel / Max | Part-/Modelldreiecke Mittel / Max | Stub-Aufbau ms Mittel / Max |
|---|---:|---:|---:|
| Vor C5 (`ad26c63`) | 1.989,5 / 2.128 | 343.195 / 495.996 | 103,07 / 144,07 |
| Wald (`817d258`) | 1.908,0 / 2.072 | 282.045 / 368.996 | 92,75 / 115,69 |
| Tal (`59cf25e`) | 1.863,7 / 2.020 | 279.952 / 370.596 | 207,32 / 234,20 |
| Felshügel/Messung | 1.657,3 / 1.787 | 273.495 / 367.368 | 197,67 / 267,75 |

Terrain: vorher 0 Festvolumen, ein initialer Air-Aufruf pro 100 gleich großen Karten. Tal netto 44.585.014/44.664.539 Studs³, final 44.611.829/44.707.799 Studs³ (Mittel/Max, aus Belegung berechnet). Final 247.327/258.048 verarbeitete Nah-Voxels, 16 `WriteVoxels` plus 8 Fernboden-`FillBlock` je Brett; 4 Air-Aufrufe beim Erstaufbau, 8 beim Folgeaufbau. Insgesamt 28/32 Aufrufe, Mittel 31,96. Weniger Parts und geschätzte Modelldreiecke, dafür zusätzliches Terrain und längere Stub-Aufbauzeit; reale GPU-Geometrie, Serverzeit und Handy-Bildrate bleiben zu messen.

**Probleme:** Defekte Sandbox-Prozessstarts gemäß Nutzer-Dauerregel über automatisch geprüfte Projektbefehle außerhalb der Sandbox umgangen. PowerShell-Pipeline ersetzte in einigen neuen Test-/Notiztexten Umlaute; vor Abschluss korrigiert. Vergleichsrunner berücksichtigt Revisionen ohne Landschaftsmodul. Terrain-Stubs prüfen Schreibdaten und räumliche Grenzen, nicht die vom Roblox-Mesher erzeugte Oberfläche. Die separate Hub-Schutzfläche ist in den Zoomtests ausgespart; Dunst, sichtbare Ränder und mögliche Terrainüberhänge an Feldgrenzen müssen in Studio beurteilt werden.

**Teststatus:** `check.ps1` **OK, 38 Dateien, Exit 0**; `test-levelgen.ps1` **19.000 Level-, 5.000 Optionsprüfungen, 96 Landschaftskombinationen, 2.400 Boss-/Minibosskarten**, 0 reguläre Rückfälle. `test-run.ps1` **34.458 Lauf-/Boss-/Lager-Stubs und 408.732 Brett-/Kameraprüfungen** plus Wald-/Landschafts-/Felshügeltests grün. Geprüft: gültige, ausgerichtete Terrain-Arrays, alle Schreibblöcke außerhalb des Hubs, Hub-Sentinel erhalten, deterministische Landschaft/Modelle, alte Landschaft bei gleicher/anderer Kartengröße gelöscht, Tutorial-Karten, flache Vorderseite, hintere/seitliche Berge, freies Brett, Zoom-Strahlschnitte, M-Standhöhe/Overlayfreiheit, höhere unpassierbare C-Klippen und Wasserfallanschluss. `test-tutorial.ps1` **168**, `test-run-ui.ps1` **116 Prüfungen** grün; Rojo-Build nach `TacticsGame.rbxlx` erfolgreich. **C5 in Studio/auf dem Handy ungetestet; Claude-Review ausstehend.** C4 vom Nutzer am 10.10. bestätigt: Thronsaal normal, keine Warnungen, Schatten und Brückenfüße ok, Samsung S25+ flüssig.

---
## #38 – Level-Optik Etappe C6
**Datum:** 10.10.2026

**Ziel:** C5-Feedback umsetzen: sinnvoller maximaler Zoom ohne Kartenende, gedämpfter Materialboden, saubere Felshügel, Wurzelfüße und Wasserfälle auf etwa jeder vierten bis fünften normalen Laufkarte.

**Umsetzung:** Gemeinsames Kamera-/Sichtstrahlmodell in Config für Brettdiagonale, FOV und Bildschirmformat; Kamera begrenzt Zoom auch nach Fensterwechsel und Kamerafahrten. Landschaftsrand aus Sichtreichweite plus zwei Feldern Reserve, modellierter Nahbereich von 24 auf 18 Felder verkleinert. Hub gemäß beantworteter Planfrage räumlich außerhalb von Landschaft und Sichtbereich versetzt; Abstand aus größtem aktuellem Brett (16×12) und Hub-Schutzgröße abgeleitet. Layout/Spawn bleiben relativ zum Ursprung, Client interagiert mit Instanzen und stellt die Avatar-Kamera wieder her. Sichtprüfung ohne Hub-Ausnahme: vier Fokusecken, acht Drehungen, 4:3/16:9/21:9, FOV 60/70/75, neun Strahlen und Projektion aller Brettecken.

Bodenparts verwenden Roblox-Materialien und dieselbe regionale Palette wie das Terrain; Wald bleibt etwas dunkler. Flecken zentral abschaltbar und standardmäßig aus, Sandstreifen gedämpfter mit Ground-Material. Eigene Bodenbilder behalten Vorrang, einschließlich M-Standkappen. M-Terrain um eine halbe Voxelauflösung plus Abstand unter die unveränderte Figuren-/Overlayhöhe abgesenkt; Standkappen in Felsfarbe reichen zur Basis. Felsdetails reduziert, innerhalb des Felds und mit neun Terrain-Raycast-Auflagen leicht eingesunken; Material/Farbe aus Terrainpalette. Jeder Paketbaum erhält einen deterministisch gedrehten Wurzelfuß am Wood-Stamm; lose Unterholz-Wurzeln entfallen. Wasserfallquelle oberhalb des flachen Kanals, Quelle und Fallfläche bündig an der Klippenkante, Kanal mit Voxelreserve auch stromaufwärts/seitlich. Bedingte Wasserfallchance 0,56 → 0,8, gemessen insgesamt **21,60 %**.

**Entscheidungen:** Zurückhaltende, zentral umstellbare WIP-Optik: Materialdetail statt Bodenflecken; ein Felsdetail auf M, 0–1 auf C, keine kleinen Begleiter. Spielhöhen unverändert statt neuer Figurenhöhen. Terrainreserve 2 Studs plus 0,15 Studs, Detail-Einsinken 0,2 Studs; fehlende Raycast-Auflage führt zum Weglassen des Details. Wurzelbreite 1,1× Wood-Bounding-Box-Breite, 0,12 Studs Einsinken. Baumdichte/Kronenmaße, Part-Fallback, Brücken, Ufergeometrie, Regeln, UI und Thronsaalaussehen unverändert. Generator nur bei Wasserfallchance geändert.

**Messung:** 100 identische Seeds mit Original-Paket-Fixtures, C5 (`47acb81`) → C6: Teile Mittel **1657,3 → 1381,2**, Max 1787 → 1576. Geschätzte Modelldreiecke Mittel **273495 → 302111**, Max 367368 → 460324; Pflichtwurzeln erhöhen Dreieckzahl, mittleres WIP-Budget 350000 bleibt eingehalten. Terrain-Aufrufe inklusive Löschen Mittel **31,96 → 17,99**, Max 32 → 18 (Air 7,96 → 1,99, WriteVoxels 16 → 12). Schreibvoxels Mittel **247327 → 123945**, Max 258048 → 134144. Festvolumen Mittel **44611829 → 33960719 Studs³**, Max 44707799 → 34065017. Terrain-Dreiecke nicht geschätzt. Stub-Aufbau im Vergleichslauf Mittel 298,16 → 183,49 ms, Max 461,07 → 387,31 ms; teilweise parallel zur Brettprüfung, deshalb kein Studio-Leistungsnachweis oder Vergleich mit den vom Nutzer gemeldeten 263 ms.

**Probleme:** Defekte Sandbox-Prozessstarts gemäß Nutzer-Dauerregel über automatisch geprüfte Projektbefehle umgangen. Minimale Config-Testvektoren um XYZ-Felder ergänzt. Neue Wurzelprüfung nach ihrer Fixture-Hilfsfunktion eingeordnet. Wasserfall-Volumenprüfung unterscheidet erlaubten bündigen Grenzflächenkontakt von Durchdringung; Anschluss separat exakt geprüft. Stamm-Bounding-Box bildet die tatsächliche Dicke des verjüngten Mesh-Endes nur näherungsweise ab. Terrain-Stubs prüfen Belegung, Reserve, räumliche Grenzen und deterministische Geometrie, simulieren aber nicht Roblox-Smooth-Terrain-Meshing. Reale Überhänge, sichtbare Auflagen, Wurzelproportionen, Wasserfallkante und Handy-Leistung bleiben manuell zu beurteilen; Maximaldreieckwert durch Wurzeln gestiegen.

**Teststatus:** `check.ps1` **OK, 38 Dateien, Exit 0**. `test-levelgen.ps1`: **19000 Level-/5000 Optionsprüfungen, 96 Landschaftskombinationen, 2400 Boss-/Minibosskarten**, keine regulären Rückfälle; Wasserfälle in allen vier Richtungen, an Seen und anderen Ufern. `test-run.ps1`: **34458 Lauf-/Boss-/Lager-Stubs, 341244 Brett-/Kameraprüfungen** plus Material-/Textur-, Fels-, Wurzel-, Wasserfall-, Landschafts-, Brücken-/Ufer-/Wiesenregressionen grün. `test-tutorial.ps1`: **168**, `test-run-ui.ps1`: **116 Prüfungen**, beide grün; Rojo-Build nach `TacticsGame.rbxlx` erfolgreich. Alle Exit 0. **C6 in Studio/auf dem Handy ungetestet; Claude-Review ausstehend.** C5 vom Nutzer am 10.10. getestet: Brett 263 ms, Figuren 16 ms, PC/Handy flüssig, Wald gut, Thronsaal unverändert; die gemeldeten Zoom-/Boden-/Fels-/Wurzel-/Wasserfallprobleme sind Gegenstand von C6.

---
## #39 – Level-Optik Etappe C7
**Datum:** 10.10.2026 · Branch `feature/level-optik-c`

**Ziel:** Die von Claude in Studio gefundenen C6-Probleme beheben: dunkles Brett, Kunststoffwasser, Standplatten auf Bergen, runde Klippen und verdeckte Wasserfälle. Jeden Optik-Schritt zusätzlich anhand echter Studio-Bilder prüfen.

**Umsetzung:** Regionale Part-Aufhellung gleicht die Abdunklung der Roblox-Materialien aus; Wald bleibt unterscheidbar, Raster heller. W-Felder und Wasser unter Paketbrücken verwenden Terrain-Wasser mit regionaler Farbe, Transparenz, Reflexion und ruhigen Wellen. Randflüsse laufen bis zur auslaufenden Senke weiter; Kartenwechsel und Abschaltung räumen Wasser zuverlässig. Bergstandplatten entfallen. Zusammenhängende M-Felder bilden höhere Terrain-Felshügel mit abgesenkten Außenrändern; begrenzte Voxelbelegung an den oberen Rändern und freie Randbelegung unter Null verhindern reale Mesher-Überhänge in flache Nachbarfelder. Terrain-Raycasts an M-Feldmitten liefern die Standhöhe, erhalten die Brücken-Overrides und gehen über die bestehende Snapshot-/Grid-Schnittstelle an Figuren, Overlays, Auswahlring und Schatten.

Klippen erhalten einen abgesenkten Terrainkern, senkrechte Slate-Wände bis zur Feldkante und deterministische Wedge-Grate mit unregelmäßiger Oberkante. Diese günstige, paketunabhängige Lösung verdeckt den Terrain-Mesher zuverlässig; `LANDSCAPE.cliffWalls.enabled` schaltet auf Terrain zurück. Wasserfallquellen bleiben frei von Graten. Fallfläche auf 0,76 Felder verbreitert und 0,35 Studs vor die Wand gelegt; Quelle bis zum äußeren Fallrand verlängert. Der Terrainkanal ist tiefer und enthält Voxelreserve. Fallende und Gischt schließen an die gemessene Wasseroberfläche an.

**Entscheidungen:** Alle neuen Optikwerte bleiben WIP in Config/Regionspaletten. D bleibt Schlamm/Pfützen, weil Terrain.WaterColor global wirkt. Klippen verwenden günstige Geometrie statt vieler großer runder Paketfelsen; Bergdetails bleiben Paketfelsen. Keine Änderung an Spielregeln, Generatorquote/-ausrichtung, Brückenmechanik, UI, Thronsaal oder nutzereigenem ColorGrading/Bloom. Wasserfallquote weiter 21,60 %. Rück-/Seitenrichtungen sind rechnerisch geprüft; Bildproben zeigen zwei zur Grundkamera gerichtete Fälle. Nutzer-/Handyprüfung bleibt erforderlich.

**Studio-Prüfweg:** Rojo-Synchronisation anhand Config.Source geprüft; ausschließlich im Play-Modus bauen. Tutorial überspringen, StartRun/ChooseLevel über Client-Remotes. Gezielt gebaute Karten verwenden separate Probe-Module mit `task.wait()` pro Terrainblock und nur einem Brettaufbau pro Aufruf. Kamera über Mausrad/WASD, Bilder über Studio-MCP. Schritt 1/2: helleres Brett, Terrainfluss mit Brücken/Ufern. Schritt 3 nach Studio-Neustart: Leon auf einem M-Cluster, echter Schatten, Berg-/Nachbaroverlay. Vorher Terrainüberhang bis 3,53 Studs im flachen Nachbarfeld; nachher Nachbaroverlay vollständig frei, Raycasts in allen flachen Feldern um den Cluster ohne Festterrain über Null (Maximum -3,05). Figurenfeld 6,75 Studs, äußerer Ausläufer 2,90. Schritt 4: gleicher Ausschnitt mit runder Kuppe vorher und senkrechter Wand nachher. Schritt 5: Seed 18 und Seed 59 vollständig sichtbare Fälle bis ins Wasser; jeweils 13 Raycasts über die Fallbreite ohne verdeckendes Festterrain. Abschluss: Leon/Schatten auf Paketbrücke, freie Ufer/Brückenenden, Wellen und beidseitige Flussfortsetzung. Brückenhöhe 3,081, Fußhöhe 3,181 (bestehender Abstand 0,1), innerer Schatten 3,109 Studs. Nach jeder Probe Play beendet, abschließend Edit bestätigt. Die Probe-UI enthält noch die vorherige Missionsbeschreibung; Fixtures prüfen die Darstellung, keinen vollständigen Spielablauf. Screenshots wurden im MCP betrachtet; keine lokalen Bildpfade geliefert, daher keine Screenshotdateien abgelegt.

**Messungen:** 100 Paket-Fixture-Seeds: C6 Teile Mittel/Max 1930,3/2119 → C7 1365,1/1567; geschätzte Modelldreiecke 302111/460324 → 301885/460216. Terrain-Dreiecke bleiben ungemessen. Acht C-Felder: Terrainkuppen 1664 Brettnachkommen/125696 Voxel → Wandlösung 1696/123648; +32 günstige Teile, +288 geschätzte Dreiecke, Terrainvolumen 33945044 → 33940948 Studs³. Gezielte Studioaufbauten mit Yield-Blöcken ca. 0,55–0,72 s; normaler Missionsstart zuletzt Brett 220 ms/Figuren 16 ms. Stub-Aufbau der 100 Paket-Seeds Mittel 163,06 ms; kein Handy-Leistungsnachweis.

**Probleme:** Der frühere Studio-Ausfall wurde von Claude durch Neustart behoben. Die Sandbox startet weiter keine Prozesse; nicht-destruktive Projektbefehle gemäß Nutzer-Dauerregel automatisch geprüft außerhalb ausgeführt. Terrain-Stubs simulieren den Mesher nicht: erst Studio-Bild/Raycast erkannte die verbliebene diagonale Bergkante. Abschlussregressionen prüfen zusätzlich räumliche Wandgrenzen, Terrain-Rückfallschalter und eine um 0,4 Studs abweichende gemessene Wasserhöhe. Fehlende Abschlusszeilenumbrüche der verketteten Testdateien korrigiert. Referenzdateien unter docs/referenz unberührt und nicht committet.

**Teststatus:** `check.ps1` OK (38 Dateien, Exit 0); `test-levelgen.ps1` OK (19000 Level-, 5000 Optionsprüfungen, 96 Landschaftskombinationen, 2400 Boss-/Minibosskarten, keine regulären Rückfälle); `test-run.ps1` OK (34458 Lauf-/Boss-/Lager-Stubs, 338242 Brett-/Kameraprüfungen plus Paket-/Fallback-, Landschafts-, Wasser-/Klippen-/Figurenhöhenregressionen); `test-tutorial.ps1` OK (168), `test-run-ui.ps1` OK (116); Rojo-Build nach TacticsGame.rbxlx OK. Alle Exit 0. Optik von Codex in Studio bildgeprüft; Nutzer-/Handytest und unabhängiges Claude-Review offen.

---
## Nächste Schritte (Plan)
**Stand 10.10.2026:** C7 automatisch und von Codex in Studio bildgeprüft; Nutzer-/Handytests und unabhängiges Claude-Review offen. C5 vom Nutzer getestet: Brett 263 ms/Figuren 16 ms, PC und Handy flüssig, Wald gut, Thronsaal unverändert. C4 vom Nutzer bestätigt: Thronsaal, Warnungen, Schatten, Brückenfüße und Samsung-S25+-Leistung ok. Grundtutorial (#30) vom Nutzer bestätigt (Willkommensfenster, beide Missionen, 150 Gold). Feinschliff (#31) vom Nutzer bestätigt (größere Tutorial-Hinweise, gelbe Zielfelder, PC-Skalierung, Level-Up wegtippen). Branch `feature/lauf-phase2` nach `main` zusammengeführt. Level-Optik (#24–#29) vom Nutzer auf dem Handy bestätigt („geht jetzt“): Banner/Hinweis/Gelände vollständig, Antippen funktioniert, Karten und Rundschatten ok, Seltenheits-Effekte aus. Branch `feature/level-optik` nach `main` zusammengeführt. Bei künftigen Darstellungsfehlern `Config.INPUT_DIAGNOSTICS` einschalten und `[Eingabe]`/`[UI-Diagnose]`-Zeilen liefern.

**Nächster Entwicklungsplan:** eigener 3D-Lagerplatz als Lichtung mit Lagerfeuer und Zelten, Helden sitzen ums Feuer. Notfall-Beschwörung bleibt bei Roguelike Phase 4. Vor Umsetzung neuen PLAN.md von Claude abwarten.

1. **Textur-Malen ausprobieren:** `docs/textur-malen.md` durchgehen; Mal-Datei öffnen, beide lokalen Pinsel auswählen, Vorder-/Rückschablone ausrichten, Pipette/Rückgängig prüfen, Bild und Datei speichern. Änderung im bemalten Gesichts-Prüfbild und nach Import von `leon_bemalt.fbx` in Studio bestätigen. Unklare Klickwege, Laptop-Navigation und Verständlichkeit der Anleitung melden.
2. **Seltenheits-Effekte und Handytexte in Studio/auf dem Handy testen:** Keine Waffen-/Aura-Partikel, Verzierungen erhalten; Hinweis, Gefahr/Rückblende/Tempo/Szenen/Zug beenden/Aufgeben, Phasenbanner/Untertitel, Ladebildschirm, Laufwahl/-Ergebnis, Tutorial, Kaserne und Rekrutierung anhand PLAN.md prüfen. Alle Textzeilen sichtbar oder erreichbar, keine Überlappung, nichts unter Leiste/Notch; vier Geräteauflösungen und Fensterwechsel prüfen. Rundschatten vom Nutzer grundsätzlich als „ok“ bestätigt; gezielte Bewegungs-/Todes-/Geländehöhen-/Kampfszenen-/Porträt-/Ghost-Prüfungen bleiben offen. Karten laut Nutzer „sehen gut aus“; gezielte Etappe-B-Prüfungen von Flüssen/Brücken/Startwegen und Handy-Leistung sowie Etappe-A2-Klick-/Raster-/Overlay-/Zug-Ring-Tests offen. Eigene Bodenbilder nach `docs/umgebung-assets.md` einbinden, erstes tree_1-Asset und reale Aufbauzeiten prüfen. Lauf auf dem Handy testen und Servergröße 1 setzen (PC-Lauf vom Nutzer bestätigt).
3. **Offene Tests:** neue Leon-FBX normal/Cel in Studio importieren, Textur, Haltung, Blickrichtung und Dreieckszahl prüfen, Avatar Auto Setup ausführen und Gesicht aus Brett-Entfernung auf PC/Handy vergleichen. Bevorzugte Variante erst danach als `assets/characters/leon.rbxm` speichern. Eigenes Waffenmodell (`leon_waffe`) importieren und prüfen; weitere Mesh-Modelle testen. Kampfszenen, Missionsstart, Umgebungsrand/Erstaufbau, Lade-/Retry-Pfade, Handy-Kamera und Tutorial/Terrain/Chibis sind noch nicht gezielt in Studio geprüft.
4. **Roguelike Phase 2 – Feinschliff testen/reviewen:** Claude-Review von #31; Tutorialtexte/Zielfeld auf PC und Handy, vergrößerte PC-HUDs/Menüs bei Fensterwechsel ohne Überlappung/Abschneiden, unveränderte Touch-Skalierung und Level-Up-Schließen per Klick/Tipp/Leertaste/Enter ohne Weltaktion gemäß PLAN.md prüfen. Grundtutorial bestätigt; zusätzliche Profil-/Skip-/Fehltipp-/Neustart-/Wiederholungstests und Laufzugang aus #30 bleiben sinnvoll. Starter-Magierin/-Ritter entwirft der Nutzer; IDs stehen in `docs/charakter-pipeline.md`.
5. **Roguelike Phase 3 testen/reviewen, danach Phase 4:** Claude-Review von #32 und manuelle PLAN.md-Tests in Studio/auf Handy: Laufabfolge, Hauptmann-Verstärkung, Garricks Bewegung/Kriegsschrei/angekündigte Randverstärkung, sofortiger Bosssieg, Lagerheilung/Tausch/Todeshistorie, beide Wiederbelebungswährungen und Wiederkommen im Lager. Hauptmann-Name/Entwurf vom Nutzer. Danach Waffenbeute, Händler, Rückblenden und Notfall-Beschwörung planen.
6. **Level-Optik C7 testen/reviewen:** Claude-Review von #39 und manuelle C7-Checkboxen in PLAN.md: helles Materialbrett/Raster, Terrain-Wasser und Randfluss, Brückenfiguren, Felshügel ohne Standplatten mit freien Nachbarfeldern, steile Klippen und sichtbare Wasserfälle. Beide Tutorials, Hub-Rückkehr, reale Aufbauzeit und Handy-Bildrate erneut prüfen. Codex-Bildtests und Messungen sind unter #39 dokumentiert; PC/Handy-Leistung für C7 vom Nutzer noch nicht bestätigt. Frühere gezielte C1–C6-Tests bleiben sinnvoll.
7. **Roguelike Phase 5–7:** Sumpf/Gefahren/Leveltypen, Eis/Vulkan, danach Punktzahl/Ränge/Bestenlisten. Detailentscheidungen vorher klären.
8. Sounds probehören, Output und Bildrate beobachten; gemeldete Avatar-/Asset-Ladefehler mit ID dokumentieren und gesondert beheben.
9. Ausrüstung/Items als reine Werte (Aussehen bleibt die eigene Waffe der Figur).
10. Beschwörungs-Show mit animierter Rekrutierung, Lichtsäule in Seltenheitsfarbe, Kamerafahrt und Pose.
11. Helden-Showcase mit großem drehbarem Modell in der Kaserne.
12. Eigene Angriffs-Effekte für ★4/★5.
13. Skins und Ausrüstungs-Stufen: Aussehen wächst mit Verschmelzen/Level, dazu kaufbare Skins.
14. Anime-R15-Modelle schrittweise gemäß `docs/charakter-pipeline.md` erstellen/importieren; der Figurenstil `mesh` ist vorbereitet, fehlende Modelle bleiben Chibi.
15. Belohnungen & Klassenwechsel.
16. Tägliche Belohnungen / Quests, Co-op-Raid, Saison-Pass und Rewarded Ads.
