# Avatar Aang Bubblegum Neon: palette and moving background

The Avatar Aang Dark profile uses a neon bubblegum-pink accent (`#ff4fd8`) throughout generated theme consumers while keeping the dark purple base and original Avatar artwork. `profile.json` is the palette source; the installer runs the theme builder to regenerate the consumer files.

## One-command install

From the Kali ARM64 guest in VMware Fusion, clone the default branch and run the installer:

```bash
git clone https://github.com/heikojan2010/zenwolf-dotfiles.git
cd zenwolf-dotfiles
bash scripts/install-kali-vmware.sh
```

The installer checks Kali ARM64, updates APT indexes, installs the guest utilities and common theme dependencies, and automatically includes Hyprland only if Kali offers the required package set at version 0.55 or newer. It also prepares an animated wallpaper when both `mpvpaper` and `ffmpeg` are available. It previews home-file deployment and asks before overwriting matching files. No system files are copied, no external repositories are added, and no compositor is started.

Use `--check` to inspect package availability without making changes, or `--minimal` to skip optional Hyprland and animated wallpaper packages. The installer cannot safely start or replace your display manager; if Hyprland was installed and validated, enter that session first.

## Apply the theme

After installation and from inside a supported Hyprland session:

```bash
~/.local/bin/zenwolf-theme avatar-aang-dark
```

The theme command applies its checked-in Avatar still wallpaper through hyprpaper and the generated bubblegum-neon palette across the desktop. To preview that theme without Hyprland, open the source art `assets/wallpapers/avatar-aang-dark.png` in the Kali desktop's image viewer.

## Optional animated Avatar background

The repository contains static Avatar artwork, not an animated show image. When Kali offers `mpvpaper` and `ffmpeg`, the installer generates a modest H.264 video by applying a gentle 15-second looping zoom to the existing artwork. This is a motion effect over the still image, not new ATLA animation or footage. It is generated locally and does not download copyrighted media.

After applying the theme in Hyprland, start the video wallpaper manually:

```bash
~/.local/bin/zenwolf-start-avatar-wallpaper
```

The command stops the static hyprpaper service and launches mpvpaper in the foreground; end that process to stop the animation, then select the theme again to restore the static wallpaper. A moving wallpaper consumes more resources than a still and can perform poorly with VMware's virtual GPU. The installer prepares the file but deliberately does not autostart the video wallpaper or compositor.

## Shader backgrounds and TUI effects

These are different kinds of tools:

- **Video wallpapers:** `mpvpaper` plays video behind Wayland windows. `linux-wallpaperengine` is a community option for some Wallpaper Engine content; verify compatibility and resource use first.
- **GLSL shader wallpapers:** `glpaper` renders shaders on Wayland. Compositor and virtual GPU support vary; it may be too demanding for a VMware guest.
- **Transitions between stills:** `swww` animates transitions, rather than continuously rendering a shader.
- **Terminal visualizers/effects:** Cava is an audio spectrum visualizer; `pipes.sh`, `cmatrix`, and UniMatrix (`unimatrix`) are terminal effects. They do not draw the desktop wallpaper.

For this Kali Fusion VM, begin with the static theme and use the generated mpvpaper loop only if the guest remains smooth.
