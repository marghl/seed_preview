#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SEED="${1:-}"
OUTPUT_DIR="${2:-$SCRIPT_DIR/atlas_$SEED}"
GRID_SIZE="${ATLAS_GRID_SIZE:-5}"
EXTENT="${ATLAS_EXTENT:-28000}"
RADIUS="${ATLAS_TILE_RADIUS:-160}"
Y_MIN="${PREVIEW_Y_MIN:--32}"
Y_MAX="${PREVIEW_Y_MAX:-192}"
GAME_ID="${LUANTI_GAME_ID:-minetest}"
LUANTI_BIN="${LUANTI_BIN:-luanti}"

if [[ ! "$SEED" =~ ^[0-9]+$ ]]; then
	echo "Aufruf: $0 SEED [AUSGABEORDNER]" >&2
	exit 2
fi
if (( GRID_SIZE < 2 )); then
	echo "ATLAS_GRID_SIZE muss mindestens 2 sein." >&2
	exit 2
fi
if [[ -e "$OUTPUT_DIR" ]]; then
	echo "Der Ausgabeordner existiert bereits: $OUTPUT_DIR" >&2
	exit 2
fi

mkdir -p "$OUTPUT_DIR/work"
MANIFEST="$OUTPUT_DIR/kacheln.txt"
: > "$MANIFEST"
IMAGES=()

for ((row = 0; row < GRID_SIZE; row++)); do
	z=$(( -EXTENT + (2 * EXTENT * row) / (GRID_SIZE - 1) ))
	for ((column = 0; column < GRID_SIZE; column++)); do
		x=$(( -EXTENT + (2 * EXTENT * column) / (GRID_SIZE - 1) ))
		name="x_${x}_z_${z}"
		world="$OUTPUT_DIR/work/$name"
		mkdir -p "$world/worldmods"
		cp -R "$SCRIPT_DIR/preview_mod" "$world/worldmods/seed_preview"

		printf '%s\n' \
			"gameid = $GAME_ID" \
			"world_name = Atlas $SEED $x $z" \
			"backend = dummy" \
			"player_backend = dummy" \
			"auth_backend = dummy" > "$world/world.mt"

		config="$world/preview.conf"
		printf '%s\n' \
			"mg_name = v7" \
			"fixed_map_seed = $SEED" \
			"seed_preview.center_x = $x" \
			"seed_preview.center_z = $z" \
			"seed_preview.radius = $RADIUS" \
			"seed_preview.y_min = $Y_MIN" \
			"seed_preview.y_max = $Y_MAX" \
			"seed_preview.output = preview.ppm" \
			"server_announce = false" > "$config"

		echo "Kachel $((row * GRID_SIZE + column + 1))/$((GRID_SIZE * GRID_SIZE)): X=$x Z=$z"
		"$LUANTI_BIN" --server --quiet --world "$world" --gameid "$GAME_ID" \
			--config "$config" --logfile "$world/debug.txt"
		if [[ ! -s "$world/preview.ppm" ]]; then
			echo "Keine Vorschau erzeugt; Details: $world/debug.txt" >&2
			exit 1
		fi

		image="$OUTPUT_DIR/$name.ppm"
		cp "$world/preview.ppm" "$image"
		if command -v magick >/dev/null 2>&1; then
			image="$OUTPUT_DIR/$name.png"
			magick "$world/preview.ppm" "$image"
		fi
		IMAGES+=("$image")
		printf '%s\t%s\t%s\n' "$x" "$z" "$image" >> "$MANIFEST"
	done
done

if command -v magick >/dev/null 2>&1; then
	magick montage "${IMAGES[@]}" -set label '%t' -thumbnail 320x320 \
		-tile "${GRID_SIZE}x${GRID_SIZE}" -geometry +8+22 "$OUTPUT_DIR/atlas.png"
fi

echo
echo "Atlas fertig: $OUTPUT_DIR/atlas.png"
echo "Koordinatenliste: $MANIFEST"

