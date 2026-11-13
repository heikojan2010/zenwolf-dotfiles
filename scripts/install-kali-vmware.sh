#!/usr/bin/env bash

set -Eeuo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly repo_root="$(cd -- "$script_dir/.." && pwd -P)"
readonly required_packages=(git rsync python3 open-vm-tools)
readonly common_packages=(
    python3-pygame jq ripgrep nano pciutils open-vm-tools-desktop
    xdg-user-dirs desktop-file-utils fonts-noto fonts-noto-color-emoji
    fonts-font-awesome
)
readonly hyprland_packages=(
    hyprland hyprpaper hyprlock waybar rofi
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    pipewire pipewire-audio pipewire-pulse wireplumber pavucontrol
    grim slurp wl-clipboard libnotify
)
readonly animated_wallpaper_packages=(mpvpaper ffmpeg)
# Optional desktop utilities: install only when Kali has an APT candidate.
# Arch-only names are intentionally not used (bluez-utils -> bluez;
# zathura-pdf-mupdf -> zathura-pdf-poppler).
readonly optional_app_packages=(bluez firefox-esr libnotify-bin kitty zathura zathura-pdf-poppler)

assume_yes=0
check_only=0
auto_optional=1
with_hyprland=0
animated_wallpaper=0
deploy=1

usage() {
    cat <<'EOF'
Usage: scripts/install-kali-vmware.sh [OPTIONS]

One-command, interactive setup for Kali ARM64 in VMware Fusion. Installs the
available guest utilities and, when Kali offers compatible packages, the
Hyprland desktop and animated Avatar wallpaper. Deploys the custom Avatar
Aang Bubblegum Neon palette. Never installs system/ or starts a compositor.

Options:
  --check                Check platform and available packages; make no changes.
  --minimal              Skip optional Hyprland and animated-wallpaper packages.
  --with-hyprland        Require and install compatible Hyprland 0.55+ packages.
  --animated-wallpaper   Require and install mpvpaper/ffmpeg.
  --no-deploy            Install packages only; do not copy home configuration.
  --yes                  Do not prompt before apt install or configuration deploy.
  -h, --help             Show this help.

Default: update APT indexes, install the available safe package set, show a
home-directory preview, and ask before overwriting any matching files.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

while (($#)); do
    case "$1" in
        --check) check_only=1 ;;
        --minimal) auto_optional=0 ;;
        --with-hyprland) with_hyprland=1; auto_optional=0 ;;
        --animated-wallpaper) animated_wallpaper=1; auto_optional=0 ;;
        --no-deploy) deploy=0 ;;
        --yes) assume_yes=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; fail "Unknown option: $1" ;;
    esac
    shift
done

confirm() {
    local prompt="$1" reply
    ((assume_yes)) && return 0
    [[ -t 0 ]] || fail "Cannot prompt in non-interactive mode. Re-run with --yes only if you reviewed the actions."
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]]
}

check_platform() {
    [[ "$EUID" -ne 0 ]] || fail "Run as your normal Kali user, not root. The script uses sudo for APT."
    [[ -r /etc/os-release ]] || fail "Cannot identify this operating system."
    # shellcheck source=/dev/null
    source /etc/os-release
    [[ "${ID:-}" == kali ]] || fail "This installer targets Kali Linux only (detected ID=${ID:-unknown})."
    [[ "$(dpkg --print-architecture)" == arm64 ]] || fail "Expected an ARM64 Kali guest (dpkg architecture arm64)."
    command -v sudo >/dev/null || fail "Install/configure sudo for your Kali user first."
    command -v apt-get >/dev/null && command -v apt-cache >/dev/null \
        || fail "APT tools are required."
    printf 'Platform check passed: Kali %s, arm64, user %s.\n' "${VERSION_ID:-unknown}" "$USER"
}

candidate_version() {
    apt-cache policy "$1" 2>/dev/null \
        | awk '/Candidate:/ { print $2; exit }'
}

has_candidate() {
    local version
    version="$(candidate_version "$1")"
    [[ -n "$version" && "$version" != '(none)' ]]
}

hyprland_candidates_ok() {
    local package version
    for package in "${hyprland_packages[@]}"; do
        has_candidate "$package" || return 1
    done
    version="$(candidate_version hyprland)"
    dpkg --compare-versions "$version" ge '0.55'
}

animated_candidates_ok() {
    local package
    for package in "${animated_wallpaper_packages[@]}"; do
        has_candidate "$package" || return 1
    done
}

check_candidates() {
    local missing=() package version
    for package in "${required_packages[@]}"; do
        has_candidate "$package" || missing+=("$package")
    done
    ((${#missing[@]} == 0)) || fail "Required package candidates unavailable: ${missing[*]}. Check Kali repositories/network."

    printf 'Required package candidates are available.\n'
    for package in "${common_packages[@]}" "${optional_app_packages[@]}"; do
        if has_candidate "$package"; then
            printf '  available: %s\n' "$package"
        else
            printf '  optional package unavailable (will skip): %s\n' "$package"
        fi
    done

    if ((auto_optional)); then
        if hyprland_candidates_ok; then
            with_hyprland=1
            version="$(candidate_version hyprland)"
            printf '  compatible Hyprland %s found; will include desktop packages.\n' "$version"
        else
            printf '  compatible Hyprland package set not found; will keep Kali desktop and skip Hyprland.\n'
        fi
        if animated_candidates_ok; then
            animated_wallpaper=1
            printf '  mpvpaper and ffmpeg found; will prepare the animated Avatar wallpaper.\n'
        else
            printf '  mpvpaper/ffmpeg package set not found; will keep the included static wallpaper.\n'
        fi
    fi

    if ((with_hyprland)); then
        for package in "${hyprland_packages[@]}"; do
            has_candidate "$package" || fail "Hyprland package candidate unavailable: $package"
        done
        version="$(candidate_version hyprland)"
        dpkg --compare-versions "$version" ge '0.55' \
            || fail "Kali candidate Hyprland $version is older than required 0.55; refusing to install this config."
        printf 'Hyprland candidate %s meets the repository config version floor.\n' "$version"
    fi

    if ((animated_wallpaper)) && ! animated_candidates_ok; then
        fail "Animated wallpaper requested, but mpvpaper and ffmpeg candidates are not both available."
    fi
}

run_sudo() {
    sudo "$@"
}

install_packages() {
    local packages=() apt_args=(install --no-install-recommends)
    local package
    for package in "${required_packages[@]}" "${common_packages[@]}" "${optional_app_packages[@]}"; do
        has_candidate "$package" && packages+=("$package")
    done
    if ((with_hyprland)); then
        packages+=("${hyprland_packages[@]}")
    fi
    if ((animated_wallpaper)); then
        packages+=("${animated_wallpaper_packages[@]}")
    fi

    printf '\nAPT will install these packages (no full system upgrade):\n  %s\n' "${packages[*]}"
    confirm "Continue with APT installation?" || fail "Package installation cancelled."
    ((assume_yes)) && apt_args+=(--yes)
    run_sudo apt-get "${apt_args[@]}" "${packages[@]}"
}

setup_animated_wallpaper() {
    local wallpaper_dir="$HOME/.local/share/zenwolf/wallpapers"
    local wallpaper_video="$wallpaper_dir/avatar-aang-dark-animated.mp4"
    local user_bin="$HOME/.local/bin"

    install -d -m 755 "$wallpaper_dir" "$user_bin"
    install -m 755 "$script_dir/make-avatar-wallpaper.sh" \
        "$user_bin/zenwolf-make-avatar-wallpaper"
    install -m 755 "$script_dir/start-avatar-wallpaper.sh" \
        "$user_bin/zenwolf-start-avatar-wallpaper"
    "$user_bin/zenwolf-make-avatar-wallpaper" \
        "$wallpaper_dir/avatar-aang-dark.png" "$wallpaper_video"
}

deploy_home() {
    local -a wallpaper_files=()
    printf '\nPreview of home configuration deployment (no deletion):\n'
    rsync -avni "$repo_root/home/" "$HOME/"
    printf '\nThis can overwrite matching files in your home directory. Back up or edit any files you want to keep.\n'
    confirm "Deploy the complete home/ tree?" || {
        printf 'Configuration deployment skipped. Repository and installed packages are unchanged.\n'
        return 0
    }

    rsync -avi "$repo_root/home/" "$HOME/"
    install -d -m 755 "$HOME/.local/share/zenwolf/wallpapers" "$HOME/.local/bin"
    install -m 755 "$script_dir/avatar-tui.py" "$HOME/.local/bin/zenwolf-avatar-tui"
    shopt -s nullglob
    wallpaper_files=("$repo_root"/assets/wallpapers/*)
    shopt -u nullglob
    if ((${#wallpaper_files[@]})); then
        install -m 644 "${wallpaper_files[@]}" "$HOME/.local/share/zenwolf/wallpapers/"
    else
        printf 'WARNING: no wallpaper files found; skipping wallpaper copy.\n' >&2
    fi

    command -v xdg-user-dirs-update >/dev/null && xdg-user-dirs-update || true
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    if command -v systemctl >/dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
    fi

    "$HOME/.local/bin/zenwolf-theme-build" build avatar-aang-dark
    "$HOME/.local/bin/zenwolf-theme-build" check avatar-aang-dark

    if ((animated_wallpaper)); then
        setup_animated_wallpaper
    fi

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && pgrep -x Hyprland >/dev/null; then
        "$HOME/.local/bin/zenwolf-theme" avatar-aang-dark
        printf 'Applied Avatar Aang Dark — Bubblegum Neon to the running Hyprland session.\n'
    else
        printf '\nAvatar Aang Dark — Bubblegum Neon is generated and ready.\n'
        printf 'Launch the animated terminal visualizer any time with:\n'
        printf '  ~/.local/bin/zenwolf-avatar-tui\n'
        printf 'After starting a supported Hyprland session, apply it with:\n'
        printf '  ~/.local/bin/zenwolf-theme avatar-aang-dark\n'
        if ((animated_wallpaper)); then
            printf 'Then launch the optional animated wallpaper with:\n'
            printf '  ~/.local/bin/zenwolf-start-avatar-wallpaper\n'
        fi
    fi
    printf 'No compositor was started by this installer.\n'
}

check_platform
if ((check_only)); then
    check_candidates
    printf '\nCheck complete; no files or packages were changed.\n'
    exit 0
fi

confirm "Refresh Kali APT package indexes?" || fail "APT update cancelled."
run_sudo apt-get update
check_candidates
install_packages

if ((deploy)); then
    deploy_home
fi

cat <<'EOF'

Finished. This script did not install anything from system/, configure NVIDIA,
modify the Kali login/display manager, or start Hyprland. Keep Kali's original
desktop available for recovery when testing a compositor in the VM.
EOF
