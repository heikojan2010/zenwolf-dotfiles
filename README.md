# Zenwolf dotfiles

Zenwolf is a keyboard-first Arch and Hyprland desktop. Nine coordinated
themes, a visual wallpaper picker, floating and tiled workspaces, a deliberate
hybrid-GPU gaming lifecycle, and a bunch of small quality-of-life details.

Browse around and copy whatever you find useful. You don't need to adopt the
entire setup.

![Zenwolf desktop with the Avatar Aang Dark theme](assets/screenshots/01-avatar-aang-dark-desktop.png)

[Watch the 55-second Zenwolf tour](assets/videos/01-zenwolf-tour.mp4)

## Start here

- [`home/`](home/) maps the user configuration below your home directory.
- [`games/`](games/) contains five standalone Python games.
- [`docs/build-guide.md`](docs/build-guide.md) is the original Arch build guide.
- [`docs/kali-vmware-apple-silicon.md`](docs/kali-vmware-apple-silicon.md) covers Kali ARM64 in VMware Fusion on Apple silicon.
- [`docs/avatar-bubblegum-wallpaper.md`](docs/avatar-bubblegum-wallpaper.md) covers the neon pink Avatar palette and optional animated wallpaper.
- [`docs/cheatsheet.md`](docs/cheatsheet.md) collects the shortcuts and everyday commands.

The complete desktop and hardware layer were built for Arch, with an AMD display GPU and optional NVIDIA GPU. The Kali guide preserves the Kali desktop as a fallback and does not install Arch-specific hardware modules. If you only want a theme, script, or Rofi layout, take that piece and make it yours.

![Swordsman theme with the Rofi application launcher](assets/screenshots/02-swordsman-rofi-launcher.png)

## Kali ARM64 full research workstation

For the complete Kali ARM64 VMware Fusion deployment, use the dedicated
branch and installer:

```bash
git clone https://github.com/heikojan2010/zenwolf-dotfiles.git
cd zenwolf-dotfiles
git switch kali-full-research-workstation
bash scripts/install-kali-research-workstation.sh
```

This installs the Zenwolf Hyprland desktop, research and security utilities,
Kitty terminal, Avatar Aang Bubblegum Neon theme, animated terminal
visualizer, and generated video wallpaper when the required packages/build
dependencies are available. It preserves Kali's original desktop and never
changes the display manager or starts Hyprland automatically. Launch the
desktop manually from a text TTY with `~/.local/bin/start-zenwolf-kali`.

See the [full Kali research workstation guide](docs/kali-full-research-workstation.md)
for package handling, first launch, fallback, and troubleshooting.

## Original Arch install

For the original Arch setup, follow the [build guide](docs/build-guide.md). Do not use its Pacman or hardware-specific system-module instructions in Kali.

## Games

The five small games can run independently of the desktop:

```bash
python3 games/number_guessing_game.py
python3 games/rock_paper_scissors.py
python3 games/snake.py
python3 games/tetris.py
python3 games/tetris_pygame.py
```

<p align="center">
  <img src="assets/screenshots/04-tetris-gameplay.png" width="49%" alt="Tetris gameplay">
  <img src="assets/screenshots/05-snake-tetris-gameplay.png" width="49%" alt="Snake and Tetris gameplay">
</p>

<p align="center">
  <img src="assets/screenshots/06-rock-paper-scissors-gameplay.png" width="99%" alt="Rock Paper Scissors gameplay">
</p>

## Credits

Zenwolf pulled ideas and inspiration from some really cool dotfile repos:

- [LierB/dotfiles](https://github.com/LierB/dotfiles)
- [maxhu08/dotfiles-old](https://github.com/maxhu08/dotfiles-old)
- [dilanrojas/dotfiles](https://github.com/dilanrojas/dotfiles)
- [Frewacom/pywalfox](https://github.com/Frewacom/pywalfox)
- [binnewbs/arch-hyprland](https://github.com/binnewbs/arch-hyprland)
- [x0d7x/dot](https://github.com/x0d7x/dot)
- [naveen-og/gilded-noir](https://github.com/naveen-og/gilded-noir)
