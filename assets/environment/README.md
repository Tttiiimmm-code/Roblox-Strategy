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

## Eigene Thronlande-Requisiten

`thronlande_pack.rbxm`: zwölf vom Nutzer mit **3D AI Studio, Modell P2** erstellte
Modelle, lokal aufbereitet (512-Pixel-Texturen, matte Materialien). Sieben
`rim_*_1`-Vorlagen, `deco_grass_2`, `deco_flower_4`, `deco_stone_1`, `rock_50`
und `archbridge_2`; insgesamt 15.890 Dreiecke vor Platzierung.
Gras/Blumen/Steine bevorzugen die eigenen Vorlagen, fehlendes Paket erhält
die bisherigen Varianten. `rock_50` wird nur am Inselrand eingesetzt.
Die eigene Brücke verläuft in der Vorlage längs Z; ihre Spieloptik wird auf
die bestehende Spannweite, 5,2 Studs Breite und 4,8 Studs Gesamthöhe angepasst.
Uferhöhen stammen weiterhin aus `archbridge_1`; bei fehlender Vorlage oder
ungeeigneten Deckübergängen bleibt diese Brücke erhalten. Ohne alte Referenz
bleibt die bisherige Part-Brücke. Alle Größen sind WIP.

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
