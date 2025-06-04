#!/bin/bash

# $1 = file
# $2 = output_dir
# $3 = crf
# $4 = bitrate_threshold
# $5 = max_height
# $6 = use_nvenc
# $7 = strip_tracks
# $8 = dry_run
# $9 = delete_original
# $10 = min_savings_pct
# $11 = log_file

file="$1"
filename=$(basename "$file") ; shift
output_dir="$1" ; shift
crf="$1" ; shift
bitrate_threshold="$1" ; shift
max_height="$1" ; shift
use_nvenc="$1" ; shift
strip_tracks="$1" ; shift
dry_run="$1" ; shift
delete_original="$1" ; shift
min_savings_pct="$1" ; shift
log_file="$1"

source "$(dirname "$0")/../optimize-lib.sh"

outfile="$output_dir/$filename"
info=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,bit_rate,height -of json "$file")
codec=$(echo "$info" | jq -r '.streams[0].codec_name')
bitrate=$(echo "$info" | jq -r '.streams[0].bit_rate // 0')
height=$(echo "$info" | jq -r '.streams[0].height // 0')

if [[ "$dry_run" == "true" ]]; then
    if [[ "$codec" == "hevc" || "$codec" == "h265" ]]; then
        echo "\"$filename\",\"Already in HEVC\",\"Skip\""
        exit 0
    elif (( bitrate < bitrate_threshold )); then
        echo "\"$filename\",\"Bitrate too low (${bitrate}bps)\",\"Skip\""
        exit 0
    elif (( height > max_height )); then
        echo "\"$filename\",\"Resolution too high (${height}px)\",\"Skip\""
        exit 0
    else
        echo "\"$filename\",\"Eligible for transcoding\",\"Transcode\""
        exit 0
    fi
fi

[[ "$codec" == "hevc" || "$codec" == "h265" || "$bitrate" -lt "$bitrate_threshold" || "$height" -gt "$max_height" ]] && exit 0

log "PROCESSING: $filename"

[[ "$use_nvenc" == "y" && $(ffmpeg -encoders | grep -c hevc_nvenc) -gt 0 ]] &&
    video_codec="hevc_nvenc -preset slow -rc vbr -cq $crf" ||
    video_codec="libx265 -preset medium -crf $crf"

[[ "$strip_tracks" == "y" ]] && {
    audio_map="-map 0:a:0? -c:a copy"
    subs_map=""
} || {
    audio_map="-map 0:a? -c:a copy"
    subs_map="-map 0:s? -c:s copy"
}

ffmpeg -hide_banner -y -i "$file" \
    -map 0:v:0 -c:v $video_codec $audio_map $subs_map "$outfile"

if [[ $? -eq 0 && -s "$outfile" ]]; then
    ffmpeg -v error -i "$outfile" -f null - 2>decode_check.log
    if [[ $? -eq 0 && ! -s decode_check.log ]]; then
        orig_size=$(stat -c %s "$file")
        new_size=$(stat -c %s "$outfile")
        savings=$(bc <<< "scale=2; 100 * ($orig_size - $new_size) / $orig_size")
        delete_allowed=$(bc <<< "$savings >= $min_savings_pct")

        log "SUCCESS: $filename — savings ${savings}%"
        if [[ "$delete_original" == "y" && "$delete_allowed" == "1" ]]; then
            rm -f "$file"
            log "DELETED: $filename"
        fi
    else
        log "ERROR: Validation failed — decode error"
        mv decode_check.log "$output_dir/$filename.decode_errors.log"
    fi
else
    log "ERROR: Transcode failed for $filename"
fi
