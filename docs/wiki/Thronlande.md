---
tags: [system, grafik]
---
# Thronlande

Weltlook der Kampflevel (Devlog #43–#46, Aufbauoptimierung #48): das Brett liegt auf einer **schwebenden Insel über einem Wolkenmeer**. Alle Werte WIP in `Config.ISLAND`; `Config.ISLAND.enabled = false` schaltet zurück auf das Terrain-Tal (C-Etappen #33–#39).

## Aufbau
- `LandscapeBuilder`: kantiger Polygonumriss, 2–3 Felder Inselrand, Terrain-Kappe, Randflüsse bis zur Kante.
- `IslandBuilder`: senkrechte Erd-/Steinwand, verjüngte Steinstufen, Neon-Kristalle, Wasserfälle bis ins Wolkenmeer, Wolkenhaufen (Lila/Cyan), 0–4 kleine Nebeninseln.
- Randdeko aus zwölf eigenen Requisiten (`thronlande_pack`, aus 3D AI Studio): Gruppen aus Ruine/Lager/Kristall/Banner plus Begleiter, flächiges Gras/Blumen/Steine; vorne nur flache Objekte.
- Budgets: max. 450 Inselteile, Rand max. 140 Objekte und 90.000 geschätzte Dreiecke.
- Randaufbau prüft Platz und Dreiecksbudget vor dem Klonen; danach bleibt die Prüfung der echten Bounding-Box. Unvollständige Gruppen zerstören nur ihre eigenen Modelle.
- `Config.ISLAND.frontAllowed` erlaubt flache Vorderdeko; `rimGroups.frontCategories` wählt die Hauptobjekte vorderer Gruppen. Modellnamen stehen zentral in `Config.ENVIRONMENT.rimRock` und `bridge.referenceModel`.

## Import der Requisiten
Anleitung in [[umgebung-assets]] (Abschnitt „Thronlande D2“), Importskript `scripts/studio/thronlande-import.luau`.

## Prüfen
`scripts/test-run.ps1` enthält die Insel-/Randprüfungen (`tests/island.test.luau`, `tests/thronlande.test.luau`).

Verwandt: [[Levelgenerator]], [[Server-Module]], [[stil-guide]]
