---
tags: [system, server, daten]
---
# Profil und Speichern

`src/server/ProfileStore.luau` speichert per DataStore. Ohne API-Zugriff (z. B. unveröffentlichter Ort in Studio) läuft alles im Speicher weiter.

## Schema (v4)
```lua
{
  gold, gems,
  stars = {},            -- nur Altdaten, im Spiel unbenutzt
  heroes = { [heroId] = { level, xp, merges, stats? } },
  pity = { since4, since5 },
  settings = { battleScenes = true },
  tutorial = { state = "new" | "done" | "skipped" },
  run = { ... },         -- laufender Roguelike-Lauf
}
```

> [!warning] Schema ändern
> Fehlende Felder in `ProfileStore.normalize` ergänzen – alte Profile dürfen nie kaputtgehen.

Verwandt: [[Tutorial]], [[Roguelike-Läufe]], [[Rekrutierung]]
