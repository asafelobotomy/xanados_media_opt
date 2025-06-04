#!/bin/bash

# Load shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../optimize-lib.sh"

echo "🔧 Running full interactive optimization"

read -rp "📁 Enter source media folder: " INPUT_DIR
read -rp "💾 Enter output folder: " OUTPUT_DIR
read -rp "🎚️ Enter CRF value (e.g., 23): " CRF
read -rp "📉 Minimum bitrate (kbps, e.g., 2500): " BITRATE_KBPS
read -rp "📐 Max resolution height (e.g., 1080): " MAX_HEIGHT
read -rp "⚙️ Use NVIDIA NVENC? (y/n): " USE_NVENC
read -rp "🎧 Strip extra audio/subtitles? (y/n): " STRIP_TRACKS
read -rp "🗑️ Delete original after compression? (y/n): " DELETE_ORIGINAL
read -rp "📉 Minimum % size savings to delete original (e.g., 20): " SIZE_SAVINGS_PCT

BITRATE_THRESHOLD=$((BITRATE_KBPS * 1000))
LOG_FILE="./media_optimize.log"

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" -type f \( \
  -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o \
  -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.ts" -o \
  -iname "*.m4v" \) | while read -r file; do
    bash "$SCRIPT_DIR/_process_file.sh" \
        "$file" "$OUTPUT_DIR" "$CRF" "$BITRATE_THRESHOLD" "$MAX_HEIGHT" \
        "$USE_NVENC" "$STRIP_TRACKS" "false" "$DELETE_ORIGINAL" "$SIZE_SAVINGS_PCT" "$LOG_FILE"
done
