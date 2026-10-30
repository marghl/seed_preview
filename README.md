# V7 Seed Preview

Dieses Werkzeug erzeugt mit Luantis echtem V7-Mapgen mehrere temporaere
Testwelten und schreibt fuer jede Welt eine farbige Hoehenkarte. Es veraendert
keine bestehende Serverwelt.

## Start

    chmod +x generate_previews.sh
    ./generate_previews.sh

Standardmaessig entstehen vier Vorschauen mit einem Radius von 256 Nodes unter
output/. Die zugehoerigen Seeds stehen in output/seeds.txt.

Eigene Seeds koennen nach dem Ausgabeordner angegeben werden:

    ./generate_previews.sh output 12345 987654321

Groessere Vorschauen:

    PREVIEW_RADIUS=512 SEED_COUNT=6 ./generate_previews.sh

Eine Atlasregion anschliessend detaillierter darstellen:

    PREVIEW_CENTER_X=14000 PREVIEW_CENTER_Z=-14000 PREVIEW_RADIUS=1000 \
        ./generate_previews.sh details 10017267819302006552

## Weltweiter Atlas

Ein Atlas aus 25 gleichmaessig ueber die Welt verteilten Ausschnitten:

    ./generate_atlas.sh 10017267819302006552

Die Kacheln decken standardmaessig Koordinaten von -28000 bis +28000 ab. Es
handelt sich um echte V7-Ausschnitte, aber nicht um eine lueckenlose Erzeugung
aller Milliarden Nodes. Dichte und Kachelgroesse lassen sich anpassen:

    ATLAS_GRID_SIZE=7 ATLAS_TILE_RADIUS=192 ./generate_atlas.sh SEED

Intern verwenden die Bilder PPM, damit keine zusaetzliche Grafiksoftware oder
minetestmapper-Abhaengigkeit erforderlich ist. Falls ImageMagick vorhanden ist,
entstehen zusaetzlich PNG-Dateien und eine uebersicht.png. Blau zeigt Wasser,
Gruen Tiefland, Braun Hochland und Weiss hohe Berge. Biome und Bauten werden
nicht dargestellt.
