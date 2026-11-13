#!/usr/bin/env bash
# Deploy stable Zenwolf Avatar styling in the EXISTING Kali XFCE/X11 session.
# Leaves Kali XFCE, LightDM, keyboard, Hyprland and research tools intact.
set -Eeuo pipefail
BRANCH="kali-xfce-avatar-workstation"
REPO_URL="https://github.com/heikojan2010/zenwolf-dotfiles.git"
ROOT="${ZENWOLF_XFCE_REPO:-$HOME/.cache/zenwolf-xfce-source}"
OUT="$HOME/.local/state/zenwolf"
mkdir -p "$OUT"
LOG="$OUT/xfce-avatar-install.log"
exec > >(tee -a "$LOG") 2>&1
[[ "$EUID" -ne 0 ]] || { echo "Run as normal Kali user, NOT with sudo."; exit 1; }
echo "=== Zenwolf Avatar XFCE workstation ==="
echo "Backup and log: $OUT"

# Download only sources from the pinned branch; no blind replacement of XFCE.
if [[ -d "$ROOT/.git" ]]; then
  git -C "$ROOT" fetch --depth=1 origin "$BRANCH"
  git -C "$ROOT" checkout -f --detach FETCH_HEAD
else
  mkdir -p "$(dirname "$ROOT")"
  git clone --depth 1 --single-branch --branch "$BRANCH" "$REPO_URL" "$ROOT"
fi
command -v xfconf-query >/dev/null || { echo "XFCE tools missing; log into Xfce Session first."; exit 1; }
if [[ "${XDG_SESSION_TYPE:-}" != "x11" ]]; then
  echo "NOTICE: This setup targets Xfce X11; log into Xfce Session for wallpaper and panel changes."
fi

# Preserve all current user-visible config and make restoration straightforward.
BACKUP="$OUT/xfce-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
for f in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/xfce4/terminal/terminalrc" "$HOME/.config/autostart/zenwolf-avatar-tui.desktop"; do
  if [[ -f "$f" ]]; then mkdir -p "$BACKUP/$(dirname "${f#$HOME/}")"; cp -a "$f" "$BACKUP/${f#$HOME/}"; fi
done
if command -v xfconf-query >/dev/null; then
  xfconf-query -c xfce4-desktop -lv > "$BACKUP/xfce4-desktop-before.txt" 2>/dev/null || true
  xfconf-query -c xfce4-panel -lv > "$BACKUP/xfce4-panel-before.txt" 2>/dev/null || true
  xfconf-query -c xsettings -lv > "$BACKUP/xsettings-before.txt" 2>/dev/null || true
fi
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/zenwolf/wallpapers" "$HOME/.config/gtk-3.0" "$HOME/.config/xfce4/terminal" "$HOME/.config/autostart"
install -m 755 "$ROOT/scripts/avatar-tui.py" "$HOME/.local/bin/zenwolf-avatar-tui"
install -m 755 "$ROOT/scripts/zenwolf-recolor-avatar.py" "$HOME/.local/bin/zenwolf-recolor-avatar"
cat > "$HOME/.local/bin/zenwolf-avatar-window" <<'TUI'
#!/usr/bin/env bash
if command -v xfce4-terminal >/dev/null 2>&1; then
  exec xfce4-terminal --title='AVATAR • FOUR ELEMENTS' --geometry=90x26 --command="$HOME/.local/bin/zenwolf-avatar-tui"
elif command -v kitty >/dev/null 2>&1; then
  exec kitty --title='AVATAR • FOUR ELEMENTS' "$HOME/.local/bin/zenwolf-avatar-tui"
else
  exec xterm -title 'AVATAR FOUR ELEMENTS' -e "$HOME/.local/bin/zenwolf-avatar-tui"
fi
TUI
chmod +x "$HOME/.local/bin/zenwolf-avatar-window"

# Source image is the same original artwork used in the Zenwolf reference.
source_image="$ROOT/assets/wallpapers/avatar-aang-dark.png"
if [[ ! -s "$source_image" ]]; then
  echo "ERROR: original Avatar image missing at $source_image"; exit 1
fi
install -m 644 "$source_image" "$HOME/.local/share/zenwolf/wallpapers/avatar-aang-original.png"
wall="$HOME/.local/share/zenwolf/wallpapers/avatar-aang-bubblegum-xfce.png"
if command -v python3 >/dev/null && python3 -c 'import PIL' 2>/dev/null; then
  python3 "$ROOT/scripts/zenwolf-recolor-avatar.py" "$source_image" "$wall" || cp "$source_image" "$wall"
else
  cp "$source_image" "$wall"
  echo "Pillow is not installed; using original artwork. To recolor: sudo apt install python3-pil; rerun."
fi

# Apply across existing monitors/workspaces; never reset panel layout.
count=0
while IFS= read -r prop; do
  if [[ "$prop" == */last-image || "$prop" == */image-path ]]; then
    xfconf-query -c xfce4-desktop -p "$prop" -s "$wall" 2>/dev/null && count=$((count+1)) || true
  fi
done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null || true)
if (( count == 0 )); then
  echo "Wallpaper settings not populated: set $wall manually in Desktop Settings if needed."
else
  echo "Applied Avatar wallpaper to $count XFCE wallpaper properties."
fi
# Set GTK dark styling without changing global GTK CSS not owned by Zenwolf.
if ! grep -q 'ZENWOLF_AVATAR_BEGIN' "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null; then
  cat >> "$HOME/.config/gtk-3.0/gtk.css" <<'GTK'

/* ZENWOLF_AVATAR_BEGIN: remove this block to undo */
@define-color theme_bg_color #0b0712;
@define-color theme_fg_color #eee8f7;
@define-color theme_selected_bg_color #ff4fd8;
@define-color theme_selected_fg_color #140b1d;
@define-color theme_tooltip_bg_color #160d21;
@define-color theme_tooltip_fg_color #fff8ff;
.xfce4-panel { background-color: rgba(11,7,18,0.94); color: #eee8f7; }
.xfce4-panel button:hover { background-color: rgba(255,79,216,0.20); }
.xfce4-panel button:checked { background-color: rgba(255,79,216,0.38); }
selection { background-color: #ff4fd8; color: #140b1d; }
/* ZENWOLF_AVATAR_END */
GTK
fi
# Existing GTK theme stays intact; just prefer dark variants where honored.
xfconf-query -c xsettings -p /Net/ThemeName -s Adwaita-dark 2>/dev/null || true

# Xfce Terminal scheme. If a file existed, preserve settings and add only
# missing properties, so user's command history/cursor settings are untouched.
terminal="$HOME/.config/xfce4/terminal/terminalrc"
touch "$terminal"
if ! grep -q 'ZENWOLF_AVATAR_TERMINAL' "$terminal"; then
cat >> "$terminal" <<'TERMINAL'

# ZENWOLF_AVATAR_TERMINAL
ColorForeground=#EEE8F7
ColorBackground=#0B0712
ColorCursor=#FF8BE5
ColorSelection=#5A1F52
ColorPalette=#0B0712;#B54865;#5D9A7A;#C49A4B;#7155A2;#C448A8;#668FB5;#D9CFDF;#695B75;#DC718C;#82C29B;#E5BC6B;#9A7BD2;#FF79DF;#8EB9DB;#FFF8FF
TERMINAL
fi

# The visualizer will open on every XFCE login. Disable in Startup Apps
# if preferred. It does not capture keyboard input from other windows.
cat > "$HOME/.config/autostart/zenwolf-avatar-tui.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Zenwolf Avatar Visualizer
Comment=Animated bubblegum-neon four-elements terminal display
Exec=$HOME/.local/bin/zenwolf-avatar-window
OnlyShowIn=XFCE;
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
if pgrep -x xfdesktop >/dev/null; then xfdesktop --reload || true; fi
echo "=== Installed XFCE Avatar theme (static wallpaper + TUI autostart) ==="
echo "The Kali session selector and XFCE panel layout were NOT replaced."
echo "Open visualizer: ~/.local/bin/zenwolf-avatar-window"
echo "Wallpaper: $wall"
echo "Settings backup: $BACKUP"
echo "Log: $LOG"
echo "Sign out and back into Xfce Session to refresh GTK/panel styling."
