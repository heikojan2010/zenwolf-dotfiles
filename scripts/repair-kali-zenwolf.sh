#!/usr/bin/env bash
# Restore incomplete Zenwolf deployment without repeating APT installation.
set -Eeuo pipefail
BRANCH="kali-full-research-workstation"
REPO="${ZENWOLF_REPO:-$HOME/zenwolf-dotfiles}"
LOG="$HOME/zenwolf-repair.log"
exec > >(tee -a "$LOG") 2>&1
echo "== Zenwolf Kali deployment repair =="

[[ "${EUID}" -ne 0 ]] || { echo "ERROR: Run as your normal Kali user, never sudo bash." >&2; exit 1; }
command -v git >/dev/null || { echo "ERROR: git not installed." >&2; exit 1; }
command -v rsync >/dev/null || { echo "ERROR: rsync not installed." >&2; exit 1; }
[[ -d "$REPO/.git" ]] || { echo "ERROR: Git repo not found at $REPO" >&2; exit 1; }
[[ "$(git -C "$REPO" config --get remote.origin.url)" == *"heikojan2010/zenwolf-dotfiles"* ]] || {
  echo "ERROR: Unexpected Git origin, refusing deployment." >&2; exit 1;
}
stage="$(mktemp -d)"
trap 'rm -rf -- "$stage"' EXIT
echo "Fetching latest branch..."
git -C "$REPO" fetch origin "$BRANCH"
git -C "$REPO" archive "origin/$BRANCH" home assets/wallpapers scripts/avatar-tui.py scripts/make-avatar-wallpaper.sh scripts/start-avatar-wallpaper.sh | tar -x -C "$stage"
backup="$HOME/.local/state/zenwolf/repair-$(date +%Y%m%d-%H%M%S)"
install -d -m 700 "$backup"
echo "Backing up replaced user files to $backup"

# Deploy desktop configuration and user services without replacing .bashrc,
# browser accounts, or the existing Kali desktop.
for part in .config/zenwolf .config/hypr .config/waybar .config/rofi .config/kitty .config/btop .config/systemd/user; do
  src="$stage/home/$part"
  [[ -d "$src" ]] || continue
  install -d "$HOME/$part"
  rsync -a --backup --backup-dir="$backup" "$src/" "$HOME/$part/"
done
install -d "$HOME/.local/bin" "$HOME/.local/share/zenwolf/wallpapers"
# Only the specific Zenwolf helpers; omit Arch/NVIDIA GPU wrappers.
for name in zenwolf-theme zenwolf-theme-build zenwolf-waybar zenwolf-cava zenwolf-btop zenwolf-lock zenwolf-power zenwolf-session zenwolf-exit-desktop zenwolf-theme-select zenwolf-avatar-tui-window start-zenwolf-kali; do
  if [[ -f "$stage/home/.local/bin/$name" ]]; then
    install -m 755 "$stage/home/.local/bin/$name" "$HOME/.local/bin/$name"
  fi
done
install -m 755 "$stage/scripts/avatar-tui.py" "$HOME/.local/bin/zenwolf-avatar-tui"
install -m 755 "$stage/scripts/make-avatar-wallpaper.sh" "$HOME/.local/bin/zenwolf-make-avatar-wallpaper"
install -m 755 "$stage/scripts/start-avatar-wallpaper.sh" "$HOME/.local/bin/zenwolf-start-avatar-wallpaper"
rsync -a --backup --backup-dir="$backup" "$stage/assets/wallpapers/" "$HOME/.local/share/zenwolf/wallpapers/"

# Generated themes require template files AND a readable wallpaper.
echo "Building Avatar Aang Bubblegum Neon theme..."
"$HOME/.local/bin/zenwolf-theme-build" build avatar-aang-dark
"$HOME/.local/bin/zenwolf-theme-build" check avatar-aang-dark
ln -sfn "$HOME/.config/zenwolf/themes/avatar-aang-dark" "$HOME/.config/zenwolf/current"
if [[ -f "$HOME/.config/zenwolf/themes/avatar-aang-dark/hyprlock.conf" ]]; then
  install -m 644 "$HOME/.config/zenwolf/themes/avatar-aang-dark/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
fi
echo "Reloading user service definitions..."
systemctl --user daemon-reload
for unit in zenwolf-waybar.service zenwolf-hyprpaper.service zenwolf-avatar-wallpaper.service zenwolf-avatar-tui.service; do
  systemctl --user cat "$unit" >/dev/null || { echo "ERROR: Missing user service $unit" >&2; exit 1; }
  echo "  verified: $unit"
done
if command -v ffmpeg >/dev/null && [[ -r "$HOME/.local/share/zenwolf/wallpapers/avatar-aang-dark.png" ]]; then
  echo "Generating animated wallpaper..."
  if ! "$HOME/.local/bin/zenwolf-make-avatar-wallpaper"; then
    echo "WARNING: Video generation failed; still wallpaper and TUI remain available." >&2
  fi
fi
echo
echo "== Repair complete =="
printf 'Theme: %s\n' "$HOME/.config/zenwolf/current"
printf 'Launcher: %s\n' "$HOME/.local/bin/start-zenwolf-kali"
printf 'Log: %s\n' "$LOG"
echo "Start Zenwolf from a text console with ~/.local/bin/start-zenwolf-kali"
