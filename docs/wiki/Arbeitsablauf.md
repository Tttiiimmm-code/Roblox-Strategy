---
tags: [workflow]
---
# Arbeitsablauf

| Rolle | Wer | Aufgabe |
|---|---|---|
| Planer/Reviewer | Claude | Architektur, [[PLAN]] schreiben, Review |
| Umsetzer | Codex (Fleißarbeit) bzw. Claude (Look-Probestücke) | Schritte aus dem Plan umsetzen, Check laufen lassen |
| Tester | Nutzer | Spielt in Studio und auf dem Handy |

```mermaid
flowchart LR
  A[Claude schreibt PLAN.md] --> B[Codex setzt um]
  B -- .handoff/status = frage --> A
  B -- fertig --> C[Claude reviewt]
  C -- Befunde --> A
  C -- ok --> D[Nutzer testet in Studio]
  D --> E[Devlog-Eintrag]
```

## Regeln
- Wer umsetzt, entscheidet Claude: klar spezifizierbare Fleißarbeit → Codex per Handoff; geschmackslastige Arbeit mit vielen Sicht-Iterationen → Claude selbst, danach Review durch Codex.
- Wer den Code geschrieben hat, reviewt ihn nicht selbst.
- Vor jedem Abschluss: `scripts/check.ps1` muss `OK` melden.
- Grüner Check ersetzt **nicht** den Test in Studio – Teststatus ehrlich angeben.
- Nach jedem Plan ein Eintrag in [[DEVLOG]].
- Commits auf Deutsch mit `feat:`, `fix:`, `docs:` …; Arbeit auf Feature-Branches.

Details: [[AGENTS]], [[CLAUDE]]
