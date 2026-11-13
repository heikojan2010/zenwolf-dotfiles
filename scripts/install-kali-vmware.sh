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

assume_yes=0
check_only=0
with_hyprland=0
deploy=1

usage() {
    cat <<'EOF'
Usage: scripts/install-kali-vmware.sh [OPTIONS]

Safely install available Kali guest utilities and optionally deploy Zenwolf's
home configuration. It never installs system/ files or starts Hyprland.

Options:
  --check           Check Kali ARM64 and package candidates; make no changes.
  --with-hyprland   Also install the experimental Hyprland desktop packages,
                    but only if Kali offers Hyprland 0.55 or newer.
  --no-deploy       Install packages only; do not copy home configuration.
  --yes             Do not prompt before apt install or configuration deploy.
  -h, --help        Show this help.

Default: update APT indexes, install available guest/utilities packages, then
preview and ask before deploying the home configuration.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

while (($#)); do
    case "$1" in
        --check) check_only=1 ;;
        --with-hyprland) with_hyprland=1 ;;
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
    [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]
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
    command -v rsync >/dev/null || {
        # rsync is installed in the package stage, but required for deployment.
        ((check_only)) || true
    }
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

check_candidates() {
    local missing=() package version
    for package in "${required_packages[@]}"; do
        if ! has_candidate "$package"; then
            missing+=("$package")
        fi
    done
    ((${#missing[@]} == 0)) || fail "Required package candidates unavailable: ${missing[*]}. Check Kali repositories/network."

    printf 'Required package candidates are available.\n'
    for package in "${common_packages[@]}"; do
        if has_candidate "$package"; then
            printf '  available: %s\n' "$package"
        else
            printf '  optional package unavailable (will skip): %s\n' "$package"
        fi
    done

    if ((with_hyprland)); then
        for package in "${hyprland_packages[@]}"; do
            has_candidate "$package" || fail "Hyprland package candidate unavailable: $package"
        done
        version="$(candidate_version hyprland)"
        dpkg --compare-versions "$version" ge '0.55' \
            || fail "Kali candidate Hyprland $version is older than required 0.55; refusing to install this config."
        printf 'Hyprland candidate %s meets the repository config version floor.\n' "$version"
    fi
}

run_sudo() {
    sudo "$@"
}

install_packages() {
    local packages=() apt_args=(install --no-install-recommends)
    local package
    for package in "${required_packages[@]}" "${common_packages[@]}"; do
        has_candidate "$package" && packages+=("$package")
    done
    if ((with_hyprland)); then
        packages+=("${hyprland_packages[@]}")
    fi

    printf '\nAPT will install these packages (no full system upgrade):\n  %s\n' "${packages[*]}"
    confirm "Continue with APT installation?" || fail "Package installation cancelled."
    ((assume_yes)) && apt_args+=(--yes)
    run_sudo apt-get "${apt_args[@]}" "${packages[@]}"
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
    install -d -m 755 "$HOME/.local/share/zenwolf/wallpapers"
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
    printf '\nHome configuration deployed. No compositor was started.\n'
    printf 'Next: log out/in if needed, then run zenwolf-theme-build check.\n'
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
modify the Kali login/display manager, or start Hyprland. If you selected
--with-hyprland, validate the config from a VM console before attempting a
session; keep Kali's original desktop available for recovery.
EOF
