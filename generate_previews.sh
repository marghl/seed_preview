#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-$SCRIPT_DIR/output}"
COUNT="${SEED_COUNT:-4}"
RADIUS="${PREVIEW_RADIUS:-256}"
Y_MIN="${PREVIEW_Y_MIN:--32}"
Y_MAX="${PREVIEW_Y_MAX:-192}"
CENTER_X="${PREVIEW_CENTER_X:-0}"
CENTER_Z="${PREVIEW_CENTER_Z:-0}"
GAME_ID="${LUANTI_GAME_ID:-minetest}"
LUANTI_BIN="${LUANTI_BIN:-luanti}"

mkdir -p "$OUTPUT_DIR"
SUMMARY="$OUTPUT_DIR/seeds.txt"
: > "$SUMMARY"
PREVIEW_FILES=()

if (( $# > 1 )); then
	SEEDS=("${@:2}")
else
	SEEDS=()
	for ((i = 0; i < COUNT; i++)); do
		SEEDS+=("$(od -An -N8 -tu8 /dev/urandom | tr -d ' ')")
	done
fi

for seed in "${SEEDS[@]}"; do
	if [[ ! "$seed" =~ ^[0-9]+$ ]]; then
		echo "Ungueltiger Seed: $seed" >&2
		exit 2
	fi

	world="$OUTPUT_DIR/world_$seed"
	if [[ -e "$world" ]]; then
		echo "Ziel existiert bereits, Seed wird ausgelassen: $world" >&2
		continue
	fi
	mkdir -p "$world/worldmods"
	cp -R "$SCRIPT_DIR/preview_mod" "$world/worldmods/seed_preview"

	printf '%s\n' \
		"gameid = $GAME_ID" \
		"world_name = Seed $seed" \
		"backend = sqlite3" \
		"player_backend = sqlite3" \
		"auth_backend = sqlite3" > "$world/world.mt"

	config="$world/preview.conf"
	printf '%s\n' \
		"mg_name = v7" \
		"fixed_map_seed = $seed" \
		"seed_preview.center_x = $CENTER_X" \
		"seed_preview.center_z = $CENTER_Z" \
		"seed_preview.radius = $RADIUS" \
		"seed_preview.y_min = $Y_MIN" \
		"seed_preview.y_max = $Y_MAX" \
		"seed_preview.output = preview.ppm" \
		"enable_damage = false" \
		"creative_mode = true" \
		"server_announce = false" > "$config"

	echo "Erzeuge V7-Vorschau fuer Seed $seed ..."
	"$LUANTI_BIN" --server --world "$world" --gameid "$GAME_ID" \
		--config "$config" --logfile "$world/debug.txt"
	if [[ ! -s "$world/preview.ppm" ]]; then
		echo "Keine Vorschau erzeugt; Details: $world/debug.txt" >&2
		exit 1
	fi
	preview="$world/preview.ppm"
	if command -v magick >/dev/null 2>&1; then
		preview="$OUTPUT_DIR/seed_$seed.png"
		magick "$world/preview.ppm" "$preview"
	fi
	PREVIEW_FILES+=("$preview")
	printf '%s\t%s\n' "$seed" "$preview" >> "$SUMMARY"
done

if command -v magick >/dev/null 2>&1 && (( ${#PREVIEW_FILES[@]} > 1 )); then
	magick montage "${PREVIEW_FILES[@]}" -set label '%t' -thumbnail 512x512 \
		-tile 2x -geometry +12+24 "$OUTPUT_DIR/uebersicht.png"
fi

echo
echo "Fertig. Seed-Liste: $SUMMARY"
if [[ -f "$OUTPUT_DIR/uebersicht.png" ]]; then
	echo "Uebersicht: $OUTPUT_DIR/uebersicht.png"
fi
