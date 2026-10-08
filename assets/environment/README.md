# Umgebungsmodelle

Rojo lädt lokale `.rbxm`-Dateien nach `ServerStorage.EnvironmentModels`.
Eine Datei enthält genau ein Model oder einen BasePart. Dateiname und Wurzelname
müssen übereinstimmen: `<kategorie>_<nr>`, Nummer ab 1, etwa `tree_1.rbxm`,
`bush_2.rbxm`, `rock_1.rbxm`, `fortress_1.rbxm`, `bridge_1.rbxm` oder
`deco_flower_1.rbxm`. Pivot unten Mitte, vorne −Z, keine Bodenplatte.

Vorlagen werden serverseitig geklont und bereinigt: Skripte, Sounds,
Interaktionen und Partikeleffekte werden entfernt. Alle Teile sind verankert
und blockieren weder Figuren noch Feldklicks. Fehlende Kategorien zeigen
weiter die bisherigen Part-Objekte. Größen stehen in `Config.ENVIRONMENT`.

Herstellung, Größen und Liste: [Umgebungs-Assets](../../docs/umgebung-assets.md).
