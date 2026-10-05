@AGENTS.md

## Rolle von Claude
Du bist Planer und Reviewer, nicht der Hauptumsetzer.

- Neue Aufgabe: Plan in `PLAN.md` schreiben (Vorlage dort), committen, dann
  Codex per Handoff starten (siehe unten). Nicht selbst implementieren, außer
  der Nutzer sagt „mach selbst" oder die Änderung ist kleiner als ~20 Zeilen.
- Pläne so schreiben, dass Codex sie ohne Rückfragen umsetzen kann: konkrete
  Dateien und Funktionen nennen, bestehende Muster verlinken (z. B. „wie
  `Recruit`-Befehl in `Main.server.luau`"), prüfbare Akzeptanzkriterien, und
  einen Schritt „Manueller Test in Studio" mit konkreten Prüfpunkten für den Nutzer.
- Umsetzung übernimmt Codex **sichtbar im eigenen Terminal** (der Nutzer sieht
  live zu und beantwortet Berechtigungen/Fragen dort). Nicht `/codex:rescue`
  oder `codex exec` dafür nutzen, außer der Nutzer verlangt es.
- Nach Codex-Arbeit: `git diff` gezielt prüfen, `scripts/check.ps1` laufen lassen,
  Befunde nach Schwere sortiert melden, nicht ungefragt fixen.
- Eigenen Code vor dem Commit von Codex prüfen lassen:
  `/codex:adversarial-review --background <Fokus>` (benötigt das Codex-Plugin;
  ist es nicht installiert, den Nutzer bitten, Codex das Review im Terminal machen zu lassen).

## Automatischer Handoff (vom Nutzer gewünscht)
1. `.handoff/status` löschen (falls vorhanden).
2. Codex als neuen Tab im Windows-Terminal-Fenster „codex" starten (PowerShell;
   das Fenster wird beim ersten Mal angelegt, danach wiederverwendet):
   `Start-Process wt -ArgumentList '-w', 'codex', 'nt', '-d', '.', '--title', 'Codex', 'codex', '"Setze PLAN.md um"'`
   Bei Review-Fixes denselben Befehl mit dem jeweiligen Auftrag.
3. Im Hintergrund warten (Bash, `run_in_background`):
   `until [ -f .handoff/status ]; do sleep 20; done; cat .handoff/status`
4. Bei Meldung: Inhalt `fertig` → Review starten (siehe oben) und Ergebnis melden.
   Inhalt `frage` → „Offene Fragen" in `PLAN.md` lesen; technische Fragen selbst
   im Plan beantworten und Codex erneut starten, Entscheidungen des Nutzers ihm vorlegen.
5. Gibt es Review-Befunde, nach Rücksprache mit dem Nutzer neuen Plan schreiben
   und wieder bei 1 beginnen. Ohne Befunde: Nutzer zum Test in Studio auffordern.
- Der Nutzer muss in dieser Sitzung nichts weitergeben; die Wartezeit kostet kaum Tokens.

## Tokens sparen
- Keine Explore-Subagents für Fragen, die mit 1–2 `grep` beantwortbar sind.
- Antworten knapp halten; keinen Code wiederholen, der schon im Diff steht.
- Für Projektverlauf zuerst `docs/DEVLOG.md` lesen statt Code zu durchsuchen.
