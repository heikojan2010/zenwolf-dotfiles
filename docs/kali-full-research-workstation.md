# Full Kali ARM64 research workstation

This is the full user-space Zenwolf desktop and research-tool deployment for
Kali ARM64 in VMware Fusion. It is separate from the Arch-only hardware
lifecycle. It does not install or copy `system/`, add APT repositories, perform
a full distribution upgrade, change the display manager, configure NVIDIA, or
start Hyprland automatically.

## Install

From the existing repository checkout:

```bash
git fetch origin
git switch kali-full-research-workstation
bash scripts/install-kali-research-workstation.sh
```

The installer refreshes APT indexes, checks package candidates, installs
available desktop and research tools, previews the home-directory deployment,
backs up overwritten files, deploys the Zenwolf user configuration, builds the
Avatar Aang Bubblegum Neon theme, and generates a looping wallpaper video.
Unavailable optional packages are skipped and reported. If Kali does not offer
mpvpaper, the installer attempts an ARM64 source build from the upstream
project when all documented build dependencies are available.

## First launch

Do not change the Kali login manager or its default session. Switch to a text
console (for example Ctrl+Alt+F3), log in as your ordinary user, and run:

```bash
~/.local/bin/start-zenwolf-kali
```

The launcher verifies the tracked Hyprland Lua configuration and starts it
without forcing an AMD or NVIDIA renderer. The original Kali desktop remains
available through the existing login screen or another TTY. Exit Zenwolf with
Super+Shift+Q, or switch back to the original desktop TTY.

## Included workstation

- Hyprland 0.55+ Lua desktop, Hyprpaper, Hyprlock, Waybar, Rofi and portals
- Kitty terminal with the Bubblegum Neon palette; Ghostty calls are routed to
  Kitty if Ghostty is not installed
- Firefox ESR, Zathura/Poppler, Thunar and image/video tools
- btop, htop, Fastfetch, Cava, screenshot and screen-recording helpers
- Python, venv/build tooling, Git, ripgrep, fd-find, fzf, jq and yq
- Network and security research utilities where Kali APT has candidates:
  Nmap, Wireshark/TShark, tcpdump, mitmproxy, sqlmap, Nikto, Gobuster and
  Feroxbuster
- BlueZ/Blueman, NetworkManager, PipeWire and VMware guest tools
- Avatar Aang Bubblegum Neon theme, animated terminal visualizer, and
  generated looping video wallpaper

The Hyprland startup hook selects the Avatar theme, opens the animated Avatar
terminal visualizer, and starts the video wallpaper when mpvpaper and the
generated video are present. The wallpaper is a gentle animated treatment of
the repository's existing Avatar still art, not animated footage from the
series.

## Troubleshooting

Check the package candidates before retrying:

```bash
apt-cache policy hyprland kitty mpvpaper ffmpeg zathura zathura-pdf-poppler
```

Inspect the compositor and user services:

```bash
journalctl --user -b -u zenwolf-hyprpaper.service -u zenwolf-waybar.service
journalctl --user -b -u zenwolf-avatar-wallpaper.service
journalctl --user -b -u zenwolf-avatar-tui.service
```

If the VM's virtual GPU cannot run Hyprland reliably, exit it and return to the
original Kali desktop. The script intentionally does not make Hyprland the
default login session.
