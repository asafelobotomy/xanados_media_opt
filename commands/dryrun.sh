#!/bin/bash

# Load shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../optimize-lib.sh"

echo "🔍 Running dry-run simulation"

read -rp "📁 Enter source media folder: " INPUT_DIR
read -rp "💾 Enter output folder (still needed): " OUTPUT_DIR
read -rp "🎚️ Enter CRF value (e.g., 23): " CRF
read -rp "📉 Minimum bitrate (kbps, e.g., 2500): " BITRATE_KBPS
read -rp "📐 Max resolution height (e.g., 1080): " MAX_HEIGHT
read -rp "📉 Minimum % size savings to delete original (e.g., 20): " SIZE_SAVINGS_PCT

BITRATE_THRESHOLD=$((BITRATE_KBPS * 1000))
REPORT_FILE="./dry_run_report.csv"
LOG_FILE="/dev/null"

echo "filename,reason,action" > "$REPORT_FILE"

TOTAL_FILES=0
SKIPPED_FILES=0
TRANSCODE_CANDIDATES=0

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" -type f \( \
  -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o \
  -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.ts" -o \
  -iname "*.m4v" \) | while read -r file; do
    result=$(bash "$SCRIPT_DIR/_process_file.sh" \
        "$file" "$OUTPUT_DIR" "$CRF" "$BITRATE_THRESHOLD" "$MAX_HEIGHT" \
        "n" "n" "true" "n" "$SIZE_SAVINGS_PCT" "$LOG_FILE")

    echo "$result" >> "$REPORT_FILE"
    [[ "$result" == *"Skip"* ]] && ((SKIPPED_FILES++))
    [[ "$result" == *"Transcode"* ]] && ((TRANSCODE_CANDIDATES++))
    ((TOTAL_FILES++))
done

echo -e "\n📊 Dry-Run Summary"
echo "------------------------------"
printf " Total files scanned       : %d\n" "$TOTAL_FILES"
printf " Skipped (no action needed): %d\n" "$SKIPPED_FILES"
printf " Eligible for transcoding  : %d\n" "$TRANSCODE_CANDIDATES"
echo -e "\n📝 Report saved to: \033[1;34mfile://$(realpath "$REPORT_FILE")\033[0m"
