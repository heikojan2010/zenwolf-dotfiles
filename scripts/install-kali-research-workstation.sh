#!/usr/bin/env bash
# Full Zenwolf research workstation for Kali ARM64 in VMware Fusion.
# Never deploys system/, edits the display manager, configures GPU drivers,
# changes APT sources, or starts Hyprland automatically.
set -Eeuo pipefail

readonly ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly HOME_TREE="$ROOT/home"
readonly REQUIRED=(git rsync python3 sudo)
readonly DESKTOP=(hyprland hyprpaper hyprlock waybar rofi kitty xwayland
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  pipewire pipewire-audio pipewire-pulse wireplumber pavucontrol
  grim slurp wl-clipboard libnotify-bin dbus-user-session)
readonly RESEARCH=(firefox-esr zathura zathura-pdf-poppler
  thunar gvfs file-roller ffmpegthumbnailer
  btop htop fastfetch ripgrep fd-find fzf jq yq
  python3-pip python3-venv python3-dev build-essential
  git curl wget ca-certificates gnupg unzip zip p7zip-full
  nmap whois dnsutils traceroute net-tools tcpdump
  wireshark tshark netcat-openbsd socat
  mitmproxy sqlmap nikto gobuster feroxbuster
  ffmpeg mpv swayimg imagemagick
  cava playerctl brightnessctl bluez blueman
  network-manager open-vm-tools open-vm-tools-desktop
  xdg-user-dirs desktop-file-utils fonts-noto fonts-noto-color-emoji
  fonts-font-awesome fonts-jetbrains-mono)
readonly OPTIONAL=(mpvpaper satty yazi ghostty wf-recorder
  python3-pygame cloudflare-speed-cli unimatrix glpaper)
declare -a install_list=() missing_required=() missing_optional=()
YES=0
NO_DEPLOY=0
NO_HYPRLAND=0

usage() {
  cat <<'EOF'
Usage: bash scripts/install-kali-research-workstation.sh [--yes] [--no-deploy] [--no-hyprland]
  --yes          Do not prompt (APT installs still use normal package checks).
  --no-deploy    Install packages only; do not copy Zenwolf user files.
  --no-hyprland  Install research tools and theme assets, but skip Hyprland.
EOF
}
while (($#)); do
  case "$1" in
    --yes) YES=1 ;;
    --no-deploy) NO_DEPLOY=1 ;;
    --no-hyprland) NO_HYPRLAND=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
confirm() {
  ((YES)) && return 0
  [[ -t 0 ]] || die "Non-interactive run. Review the script and rerun with --yes."
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]]
}
candidate() {
  local c
  c="$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
  [[ -n "$c" && "$c" != '(none)' ]]
}
[[ "$EUID" -ne 0 ]] || die "Run as your normal Kali user, not root."
[[ -r /etc/os-release ]] || die "Cannot read /etc/os-release."
# shellcheck source=/dev/null
source /etc/os-release
[[ "${ID:-}" == kali ]] || die "This script targets Kali Linux only (detected ${ID:-unknown})."
[[ "$(dpkg --print-architecture)" == arm64 ]] || die "Expected Kali ARM64 (dpkg architecture arm64)."
command -v sudo >/dev/null || die "Install sudo for your normal user first."
command -v apt-get >/dev/null && command -v apt-cache >/dev/null || die "APT is unavailable."

printf 'Zenwolf Kali ARM64 research workstation\n'
printf '  user: %s | release: %s | architecture: arm64\n' "$USER" "${VERSION_ID:-unknown}"
printf '\nThis will install packages from your configured Kali repositories only.\n'
printf 'It will not run apt full-upgrade, add repositories, touch system/,\n'
printf 'change the display manager, configure NVIDIA, or start Hyprland.\n\n'
confirm "Refresh APT package indexes?" || die "Cancelled."
sudo apt-get update

for p in "${REQUIRED[@]}"; do
  candidate "$p" || missing_required+=("$p")
done
( ${#missing_required[@]} == 0 ) || die "Required packages have no APT candidate: ${missing_required[*]}"

for p in "${DESKTOP[@]}" "${RESEARCH[@]}" "${OPTIONAL[@]}"; do
  if ((NO_HYPRLAND)) && [[ "$p" == hyprland || "$p" == hyprpaper || "$p" == hyprlock || "$p" == waybar || "$p" == rofi || "$p" == xdg-desktop-portal-hyprland ]]; then
    continue
  fi
  if candidate "$p"; then
    install_list+=("$p")
  else
    missing_optional+=("$p")
  fi
done

if (( ! NO_HYPRLAND )); then
  if ! candidate hyprland; then
    die "Hyprland is not available from configured Kali sources. Check apt-cache policy hyprland, or rerun with --no-hyprland to install research tools and keep Kali's desktop."
  fi
  hv="$(apt-cache policy hyprland | awk '/Candidate:/ {print $2; exit}')"
  dpkg --compare-versions "$hv" ge '0.55' || die "Hyprland $hv is older than the Lua config requires (0.55+)."
fi

# Keep the default Kali desktop as an independent recovery session. Install
# XFCE if absent, but never select it as the default display-manager session.
if ! command -v xfce4-session >/dev/null 2>&1 && candidate xfce4; then
  install_list+=(xfce4 xfce4-terminal)
fi

# De-duplicate while preserving order.
declare -A seen=()
declare -a unique=()
for p in "${install_list[@]}"; do
  [[ -n "${seen[$p]:-}" ]] && continue
  seen[$p]=1
  unique+=("$p")
done
install_list=("${unique[@]}")

printf '\nAvailable packages to install (%s):\n' "${#install_list[@]}"
printf '  %s\n' "${install_list[@]}"
if ( ${#missing_optional[@]} > 0 ); then
  printf '\nUnavailable optional packages (skipped):\n  %s\n' "${missing_optional[*]}"
fi
confirm "Install this package set?" || die "Package installation cancelled."
sudo apt-get install --no-install-recommends "${install_list[@]}"
if ! command -v kitty >/dev/null 2>&1 && ! command -v ghostty >/dev/null 2>&1; then
  die "Neither Kitty nor Ghostty was installed. The Zenwolf desktop requires a terminal emulator."
fi

if ((NO_DEPLOY)); then
  printf '\nPackage installation complete. User configuration was not deployed (--no-deploy).\n'
  exit 0
fi

printf '\nPreviewing home configuration deployment (no deletions):\n'
rsync -avni "$HOME_TREE/" "$HOME/"
printf '\nThis copies the repository home/ tree into your home directory and may overwrite matching files.\n'
confirm "Deploy Zenwolf user configuration?" || die "Deployment cancelled after package install."

# Back up only the paths that this deployment will overwrite.
backup="$HOME/.local/state/zenwolf/preinstall-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
rsync -a --backup --backup-dir="$backup" "$HOME_TREE/" "$HOME/"

mkdir -p "$HOME/.local/share/zenwolf/wallpapers" "$HOME/.local/bin"
if compgen -G "$ROOT/assets/wallpapers/*" >/dev/null; then
  install -m 644 "$ROOT"/assets/wallpapers/* "$HOME/.local/share/zenwolf/wallpapers/"
fi
install -m 755 "$ROOT/scripts/avatar-tui.py" "$HOME/.local/bin/zenwolf-avatar-tui"
install -m 755 "$ROOT/scripts/make-avatar-wallpaper.sh" "$HOME/.local/bin/zenwolf-make-avatar-wallpaper"
install -m 755 "$ROOT/scripts/start-avatar-wallpaper.sh" "$HOME/.local/bin/zenwolf-start-avatar-wallpaper"
chmod 755 "$HOME/.local/bin/start-zenwolf-kali" "$HOME/.local/bin/zenwolf-avatar-tui-window"

# The upstream config expects Ghostty. Use it when installed; otherwise the
# compatibility command translates the existing Ghostty launch calls to Kitty.
if ! command -v ghostty >/dev/null 2>&1; then
  cat >"$HOME/.local/bin/ghostty" <<'WRAPPER'
#!/usr/bin/env bash
exec kitty "$@"
WRAPPER
  chmod 755 "$HOME/.local/bin/ghostty"
fi

# Build and validate all theme consumers from the checked-in Avatar palette.
"$HOME/.local/bin/zenwolf-theme-build" build avatar-aang-dark
"$HOME/.local/bin/zenwolf-theme-build" check avatar-aang-dark
install -d -m 755 "$HOME/.config/kitty"
ln -sfn "$HOME/.config/zenwolf/themes/avatar-aang-dark" "$HOME/.config/zenwolf/current"

# Generate the moving wallpaper when the VM has the required playback stack.
if command -v ffmpeg >/dev/null 2>&1 && [[ -r "$HOME/.local/share/zenwolf/wallpapers/avatar-aang-dark.png" ]]; then
  "$HOME/.local/bin/zenwolf-make-avatar-wallpaper" \
    "$HOME/.local/share/zenwolf/wallpapers/avatar-aang-dark.png" \
    "$HOME/.local/share/zenwolf/wallpapers/avatar-aang-dark-animated.mp4"
fi

# Add the selected theme to the user's session environment. No display manager
# defaults are changed; launch Hyprland manually from a TTY when ready.
if command -v xdg-user-dirs-update >/dev/null 2>&1; then xdg-user-dirs-update || true; fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi
systemctl --user daemon-reload 2>/dev/null || true

# Ensure Kitty is available to scripts and the shell. Add a single managed PATH
# block rather than replacing the user's existing shell configuration.
if ! grep -q 'ZENWOLF LOCAL BIN' "$HOME/.bashrc" 2>/dev/null; then
  cat >>"$HOME/.bashrc" <<'EOF'

# ZENWOLF LOCAL BIN
export PATH="$HOME/.local/bin:$PATH"
EOF
fi

printf '\nZenwolf research workstation files are deployed.\n'
printf 'Theme: Avatar Aang Dark — Bubblegum Neon (#ff4fd8)\n'
printf 'Hyprland launcher: ~/.local/bin/start-zenwolf-kali\n'
printf 'Avatar TUI: ~/.local/bin/zenwolf-avatar-tui\n'
printf 'Animated wallpaper: ~/.local/bin/zenwolf-start-avatar-wallpaper (from a Hyprland session)\n'
printf 'Backup of overwritten home files: %s\n' "$backup"
printf '\nDo not replace Kali's login session. Test Hyprland from a text TTY:\n'
printf '  Ctrl+Alt+F3, log in, then run: start-zenwolf-kali\n'
printf 'Return to Kali desktop by exiting Hyprland or switching back to its TTY.\n'
printf '\nUnavailable optional packages skipped: %s\n' "${missing_optional[*]:-none}"
