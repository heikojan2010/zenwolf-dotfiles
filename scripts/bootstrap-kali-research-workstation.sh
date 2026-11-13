#!/usr/bin/env bash
# One-command bootstrap for the full Zenwolf Kali ARM64 workstation.
# Run from an existing checkout, or from anywhere to clone into ~/zenwolf-dotfiles.
set -Eeuo pipefail

readonly REPO_URL="https://github.com/heikojan2010/zenwolf-dotfiles.git"
readonly BRANCH="kali-full-research-workstation"
readonly DEST="$HOME/zenwolf-dotfiles"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if git rev-parse --show-toplevel >/dev/null 2>&1; then
  ROOT="$(git rev-parse --show-toplevel)"
else
  if [[ -e "$DEST" ]]; then
    [[ -d "$DEST/.git" ]] || die "$DEST exists but is not a Git checkout; move it aside or run from your repository."
  else
    git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$DEST"
  fi
  ROOT="$DEST"
fi

cd "$ROOT"
[[ -f .git/config || -f .git ]] || die "Could not identify a Git working tree."
if [[ -n "$(git status --porcelain)" ]]; then
  die "Your checkout has uncommitted changes. Commit/stash them first; bootstrap will not overwrite local work."
fi

printf 'Fetching the latest %s branch...\n' "$BRANCH"
git fetch origin "$BRANCH"
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git switch "$BRANCH"
else
  git switch --create "$BRANCH" --track "origin/$BRANCH"
fi
git pull --ff-only origin "$BRANCH"

[[ -x /usr/bin/bash ]] || die "Bash is required."
printf '\nLaunching the full Kali workstation installer.\n'
bash scripts/install-kali-research-workstation.sh --yes

# If bootstrap was run from a text console, start the new desktop immediately.
# From an existing graphical Kali session, leave it untouched and let the user
# choose Hyprland at the next login or start it from a TTY.
if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && -t 0 && -t 1 ]]; then
  exec "$HOME/.local/bin/start-zenwolf-kali"
fi

printf '\\nInstallation finished. Sign out of Kali and choose the Hyprland session,\\n'
printf 'or switch to a text console (Ctrl+Alt+F3) and run:\\n'
printf '  ~/.local/bin/start-zenwolf-kali\\n'
