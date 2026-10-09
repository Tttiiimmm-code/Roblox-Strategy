# Umgebungsmodelle

Rojo lädt lokale `.rbxm`-Dateien nach `ServerStorage.EnvironmentModels`.
Eine Datei enthält genau ein Model oder einen BasePart. Dateiname und Wurzelname
müssen übereinstimmen: `<kategorie>_<nr>`, Nummer ab 1, etwa `tree_1.rbxm`,
`bush_2.rbxm`, `rock_1.rbxm`, `fortress_1.rbxm`, `bridge_1.rbxm` oder
`deco_flower_1.rbxm`. Pivot unten Mitte, vorne −Z, keine Bodenplatte.

Alternativ darf eine Datei einen **Ordner** mit mehreren Vorlagen enthalten
(z. B. `grasland_pack.rbxm`); jede Vorlage darin heißt `<kategorie>_<nr>`.
MaterialVariants im Paket kopiert der Lader in den MaterialService.
Ein solches Paket erzeugt `scripts/studio/umgebung-import.luau` (Befehlsleiste in Studio).

Vorlagen werden serverseitig geklont und bereinigt: Skripte, Sounds,
Interaktionen und Partikeleffekte werden entfernt. Alle Teile sind verankert
und blockieren weder Figuren noch Feldklicks. Fehlende Kategorien zeigen
weiter die bisherigen Part-Objekte. Größen stehen in `Config.ENVIRONMENT`.

Herstellung, Größen und Liste: [Umgebungs-Assets](../../docs/umgebung-assets.md).

## Credits (Roblox Creator Store, kostenlos, ohne Skripte)

| Paket-Kategorie | Modell | Urheber | Asset-ID |
|---|---|---|---|
| tree, bush, deco_root | Yasu's Stylized Tree Pack | mvyasu | 79689531752352 |
| rock | Stylized Rock Pack | nizendo | 139056934028989 |
| deco_flower | Blue / Red / Yellow Flowers | Galaxy_girl644YT | 7874817366, 7874807261, 7874815586 |
| deco_grass | Grass | Mistertitanic44 | 284474671 |
| deco_fence | Wooden Fence | Eikezan | 3630530894 |
| archbridge | Wooden Bridge | Justinnk231 | 5239084052 |

Spätere Credits-Anzeige im Spiel sollte diese Liste übernehmen.
