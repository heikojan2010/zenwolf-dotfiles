#!/usr/bin/env bash

set -Eeuo pipefail

readonly input_image="${1:-$HOME/.local/share/zenwolf/wallpapers/avatar-aang-dark.png}"
readonly output_video="${2:-$HOME/.local/share/zenwolf/wallpapers/avatar-aang-dark-animated.mp4}"
readonly width=1920
readonly height=1080
readonly duration_seconds=15
readonly fps=30
readonly frames=$((duration_seconds * fps))

command -v ffmpeg >/dev/null 2>&1 || {
    printf 'ERROR: ffmpeg is required. Install it from your Kali repositories.\n' >&2
    exit 1
}
[[ -r "$input_image" ]] || {
    printf 'ERROR: Avatar wallpaper image not found: %s\n' "$input_image" >&2
    exit 1
}

install -d -m 755 "$(dirname -- "$output_video")"

# A restrained, seamless breathing zoom animates the existing Avatar artwork;
# it does not invent new animation frames or alter the source image.
ffmpeg -hide_banner -loglevel warning -y \
    -loop 1 -framerate "$fps" -i "$input_image" \
    -vf "scale=${width}:${height}:force_original_aspect_ratio=increase,crop=${width}:${height},zoompan=z='1.02+0.025*(1-cos(2*PI*on/${frames}))/2':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=${width}x${height}:fps=${fps},format=yuv420p" \
    -frames:v "$frames" -an \
    -c:v libx264 -preset veryfast -crf 24 -pix_fmt yuv420p \
    -movflags +faststart "$output_video"

printf 'Created %s (%s-second seamless breathing-zoom loop).\n' \
    "$output_video" "$duration_seconds"
