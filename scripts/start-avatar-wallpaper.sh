#!/usr/bin/env bash

set -Eeuo pipefail

readonly video="${1:-$HOME/.local/share/zenwolf/wallpapers/avatar-aang-dark-animated.mp4}"

command -v mpvpaper >/dev/null 2>&1 || {
    printf 'ERROR: mpvpaper is not installed.\n' >&2
    exit 1
}
[[ -r "$video" ]] || {
    printf 'ERROR: animated wallpaper video not found: %s\n' "$video" >&2
    printf 'Generate it with ~/.local/bin/zenwolf-make-avatar-wallpaper first.\n' >&2
    exit 1
}
[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || {
    printf 'ERROR: start this from inside a Hyprland session.\n' >&2
    exit 1
}

# Stop the static wallpaper service so the video wallpaper is visible. Selecting
# a theme again restores the regular hyprpaper-managed still image.
systemctl --user stop zenwolf-hyprpaper.service 2>/dev/null || true
exec mpvpaper -o 'no-audio loop-file=inf' ALL "$video"
