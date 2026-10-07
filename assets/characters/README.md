# Figurenmodelle

Fertige R15-Modelle als `<helden-id>.rbxm` oder `<klasse>.rbxm` hier ablegen.
Die Anleitung steht in [charakter-pipeline.md](../../docs/charakter-pipeline.md).
Ohne Modelle verwendet der Figurenstil `mesh` automatisch die Chibi-Figuren.

Heruntergeladene FBX/GLB und zugehörige 4K-Texturen zuerst unter `assets/raw/<id>/` ablegen. Aus dem Projektordner aufbereiten, zum Beispiel:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/cleanup.ps1 -In assets/raw/leon/leon_meshy.fbx -Name leon
```

Unter `assets/raw/leon/clean/` die Vorder-/Rückansicht und das Gesicht mit `leon_gesicht_original_1k.png` vergleichen; bei falscher Blickrichtung `-Front` anpassen. Dann in Studio **Avatar → 3D importieren → `leon_clean.fbx`**, Textur/Haltung prüfen und **Avatar Auto Setup** ausführen. Erst das fertige R15-Modell als `leon.rbxm` hier speichern. Das bisherige Modell bleibt bis dahin bestehen.

Optional eine Vergleichsvariante mit `-Name leon_cel -Cel -CelColors 16` erzeugen und `leon_cel_clean.fbx` importieren. Exporte enthalten die Textur; Rohdaten, Prüfbilder, PNG-, FBX- und GLB-Ausgaben bleiben im ignorierten `assets/raw/`. Details zu Parametern, Gesichtsschutz und Bericht stehen in der Pipeline-Anleitung oben. Studio-Test der neuen Exporte noch offen.
