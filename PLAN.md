# PLAN: Figurenstil „mesh" – eigene 3D-Modelle (Anime-Stil) mit Chibi-Rückfall

Ziel: Das Spiel kann pro Held/Gegnerklasse ein fertiges **R15-3D-Modell** aus `assets/characters/<id>.rbxm` verwenden (Anime-Stil nach Nutzer-Design). Fehlt ein Modell, wird automatisch die Chibi-Figur gebaut. Animationen, Waffen in der Hand, Seltenheits-Effekte, Zug-Ring, Kampfszene, Porträts und Brett-Skalierung funktionieren mit den Modellen.
Branch: `feature/mesh-figuren` – abzweigen von `feature/kampfszene`
Kontext: Nutzerziel: „alle Figuren den gleichen Artstyle wie in dem Bild" (Leon-Design, Anime, realistische Proportionen, T-Pose vorne/hinten). Grafik-Weg für den Nutzer steht in `docs/charakter-pipeline.md` (Bild → Bild-zu-3D → Roblox Avatar Auto Setup → R15 → `.rbxm`). Noch **keine** Modelldateien vorhanden – der Code muss ohne sie fehlerfrei laufen (alles Chibi).

**Allgemein**
- Bestehende Bausteine wiederverwenden: Der R15-Avatar-Pfad in `src/shared/CharacterBuilder.luau` (`avatar()` + Nachbearbeitung in `CharacterBuilder.build`: Wurzel verankern, Kollision aus, `GroundOffset`, Waffen an `RightHand`/`LeftHand`, Seltenheits-Effekte, Pferd, `HeadY`/`TopY`) ist genau das, was ein importiertes R15-Modell braucht. `UnitAnimator` unterstützt R15-Gelenke und Standard-Idle/Walk bereits.
- Nach jedem Schritt `scripts/check.ps1` = `OK`; ein Commit pro Schritt. Nur erlaubte Symbole.

## Schritte

- [x] 1. **Modellordner über Rojo** – Dateien: `default.project.json`, neuer Ordner `assets/characters/`
  - `ReplicatedStorage.CharacterModels` ← `assets/characters` (`$path`). Der Ordner muss ohne Modelle bauen: eine Platzhalterdatei anlegen, die Rojo akzeptiert bzw. ignoriert (prüfen mit `tools/rojo.exe build`; z. B. `README.md` mit Kurzverweis auf `docs/charakter-pipeline.md` – falls Rojo das als Instanz anlegt, im Code Nicht-Model-Kinder ignorieren).
  - Fertig, wenn: Build ohne Fehler, `ReplicatedStorage.CharacterModels` existiert im Spiel.

- [x] 2. **Stil `"mesh"` im CharacterBuilder** – Datei: `src/shared/CharacterBuilder.luau`, `src/shared/Config.luau`
  - `Config.CHARACTER_STYLE` erlaubt `"mesh"`; Standard bleibt `"chibi"` (Nutzer schaltet um, sobald Modelle da sind – Kommentar).
  - Bei `"mesh"`: Vorlage suchen in `ReplicatedStorage.CharacterModels` nach `unit.heroId`, sonst nach `unit.class`. **Keine Vorlage → `ChibiBuilder.build(unit)`** (stiller Rückfall, höchstens eine Warnung pro ID im Output).
  - Vorlage gefunden → `Clone()`, dann **dieselbe Nachbearbeitung wie der Avatar-Pfad** (die vorhandene Logik nach `avatar(unit)` in eine Funktion auslagern, z. B. `prepareRig(model, unit)`, und von beiden Pfaden nutzen): Pflichtteile prüfen (`HumanoidRootPart`, `Humanoid`, `Head`, `UpperTorso`, `LowerTorso`, `RightHand`, `LeftHand`, `LeftFoot`, `RightFoot`); fehlt etwas → Warnung + Chibi-Rückfall. Skripte entfernen, Wurzel verankern, `PrimaryPart`, Kollision/Touch aus, `Massless`, Humanoid-Anzeige aus, `GroundOffset` aus der Fußhöhe, Waffen in die Hand, Seltenheits-Effekte, Pferd bei Kavalier, `HeadY`/`TopY`.
  - Darf auf Server **und** Client laufen (Porträts) – im Gegensatz zum HumanoidDescription-Pfad keine Netzaufrufe; `assert(IsServer)` nur für den Avatar-Pfad behalten.
  - Teamfarbe: Bei Mesh-Modellen **nicht** einfärben (eigene Texturen). `Tint`-Attribute nur an Teilen, die das Spiel selbst hinzufügt (z. B. Pferdesattel).
  - Vorlagen-Cache wie im ChibiBuilder (Schlüssel: Modell-ID + Klasse + Team + Waffe + Seltenheit + isLord), damit gleiche Gegner geklont statt neu aufbereitet werden.
  - Fertig, wenn: ohne Modelldateien verhält sich `"mesh"` exakt wie `"chibi"`; mit einem Test-R15-Modell (siehe Schritt 4) erscheint es im Spiel.

- [x] 3. **Anschlüsse prüfen** – Dateien nach Bedarf: `src/client/UnitAnimator.luau`, `src/client/BattleScene.luau`, `src/client/UIKit.luau`, `src/server/UnitVisuals.luau`
  - Mesh-Modelle durchlaufen alle bestehenden Wege: Brett-Skalierung (`boardUnitScale`), Laufen (Standard-Walk über `Animator`), Idle, Angriffe/Treffer/Tod (`playStrike`/`playDeath` mit R15-Gelenken), Zug-Ring (`GroundOffset`), Kampfszene (Klon, `ScaleTo(1)`), Porträts (`HeadY`), Ghost-Vorschau. Fehlende Unterstützung ergänzen – ohne das Chibi-Verhalten zu ändern.
  - Porträt-Kamera: realistisch proportionierte Figuren sind größer als Chibis – Kameraabstand aus `TopY`/`HeadY` ableiten statt fester Werte, damit Kopf und Oberkörper im Bild sind.
  - Fertig, wenn: statische Prüfung aller Pfade ohne Fund; Ergebnis in den Notizen.

- [x] 4. **Test-Modell zur Prüfung** – nur lokal, **nicht committen**
  - Mit einer lokalen Prüfhilfe unter `.handoff/` (API-Stubs wie bei früheren Reviews) simulieren: vollständiges R15-Modell → wird aufbereitet; fehlende Pflichtteile → Warnung + Chibi-Rückfall; keine Vorlage → Chibi. Ergebnis in den Notizen. Echte Modelle liefert der Nutzer.

- [x] 5. `scripts/check.ps1` = `OK`; `tools/rojo.exe build default.project.json -o TacticsGame.rbxlx` ohne Fehler.
- [x] 6. Devlog-Eintrag #19 „Figurenstil mesh" (Teststatus „ungetestet", Verweis auf `docs/charakter-pipeline.md`), committen und pushen, dann `.handoff/status` = `fertig`.

## Manueller Test (Nutzer)
- [ ] Mit `CHARACTER_STYLE = "mesh"` und **ohne** Modelldateien: Spiel sieht aus wie bisher (Chibis), Output höchstens gelbe Hinweise „kein Modell für …"
- [ ] Sobald `assets/characters/leon.rbxm` existiert: Leon erscheint als 3D-Modell auf dem Brett, in Kaserne, Rekrutierung, Info-Porträt und Kampfszene; läuft, greift mit Schwert in der Hand an, hat ★5-Aura und Zug-Ring
- [ ] Kein roter Fehler im Output

## Nicht anfassen
- Spielregeln, Kartendaten, `ProfileStore`, Server-Befehlsvalidierung
- Chibi-Aussehen und -Verhalten

## Offene Fragen
- (Codex: hier eintragen, `.handoff/status` = `frage` schreiben und stoppen, falls etwas unklar ist)

## Notizen (Codex)
- Schritt 1: `README.md` wird von Rojo ignoriert; der leere Ordner erscheint als `ReplicatedStorage.CharacterModels` im gebauten Spiel. Pflichtcheck und Rojo-Build erfolgreich.
- Schritt 2: Mesh-Vorlagen werden nach Helden-ID/Klasse gesucht, typgeprüft und nach Modell-ID/Klasse/Team/Waffe/Seltenheit/isLord zwischengespeichert. Gemeinsame R15-Aufbereitung läuft ohne Netzaufrufe auf Client und Server. Keine Färbung importierter Teile; zusätzliche Avatar-Kleidung (Surcoat/Umhang) wird bei Mesh ausgelassen, damit das Nutzerdesign sichtbar bleibt. Waffen folgen beim Mesh der Handposition/-ausrichtung. Fehlende/ungültige Vorlagen fallen mit höchstens einer Warnung je ID auf Chibi zurück. Pflichtcheck grün; lokale Verhaltensprüfung folgt in Schritt 4.
- Schritt 3: Statische Anschlussprüfung durchgeführt: UnitVisuals skaliert Modell und HeadY/TopY/GroundOffset; UnitAnimator nutzt Humanoid/Animator für Idle/Walk sowie R15-Motor6D-Namen für Angriffe/Treffer, modellunabhängiges Kippen/Ausblenden für Tod und GroundOffset für Zug-Ring. BattleScene erhält den Klon, setzt ScaleTo(1) und berücksichtigt GroundOffset/Quellmaßstab; Ghost-Vorschau klont und versetzt dieselbe Figur mit GroundOffset. Keine fehlenden Mesh-Abzweigungen gefunden. Porträts verwenden für MeshRig Kopf-/Oberkörperspanne aus TopY/HeadY/GroundOffset, Sichtfeld und Seitenverhältnis; Chibi-Kamera bleibt unverändert. Pflichtcheck grün. Dies ist die geforderte technische Anschlussprüfung; unabhängiger Review erfolgt durch Claude.
- Schritt 4: Lokale Prüfhilfe `.handoff/generate-mesh-test.ps1` erzeugt `.handoff/mesh-test.luau` aus den aktuellen Originalmodulen und API-Stubs. **175 Prüfungen erfolgreich**: vollständiges R15, jeder fehlende Pflichtteil einzeln, falscher Teiltyp, nicht klonbare Vorlage, ignorierte Nicht-Model-Kinder, Klassenmodell als Ersatz, Warnung nur einmal pro ID, Skriptentfernung, Physik/Humanoid/Animator, Fuß-/Kopfhöhe, alle Waffentypen, Aura, Pferd/Sattel-Tint, Texturerhalt, Cache-Trennung und Klonisolation. Alle 11 Helden und 7 Gegnertypen liefern ohne Vorlagen dieselbe Teile-/Farbsignatur wie Chibi. Mesh auf Client/Server ohne Netzaufruf, Avatar-Client vor Netzaufruf blockiert. Anfangs fehlte im Stub der Roblox-Standardwert Anchored=false; Stub korrigiert, kein Produktionsfehler. Prüfhilfen bleiben lokal/uncommittet. Keine Rendering-, Rotations-, Animations- oder Replikationssimulation; Studio/Handy weiterhin ungetestet. Pflichtcheck grün.
- Schritt 5: Abschlussprüfung `scripts/check.ps1`: **OK, 26 Dateien, Exit 0**; Rojo-Build von `TacticsGame.rbxlx` erfolgreich. Standard bleibt `chibi`; echte R15-Modelle liefert der Nutzer gemäß `docs/charakter-pipeline.md`.
- Schritt 6: Devlog #19 ergänzt und nächste Schritte auf Claude-Review/Modellimport/manuelle Tests aktualisiert. Änderungen werden als sechs Schritt-Commits auf `feature/mesh-figuren` gepusht; anschließend erfolgt das letzte Übergabesignal `.handoff/status` = `fertig`. Studio/Handy ungetestet.
