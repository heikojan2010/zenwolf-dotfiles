# Avatar Aang Bubblegum Neon: palette and moving background

The Avatar Aang Dark profile keeps its existing artwork and dark purple base while using a neon bubblegum-pink accent (`#ff4fd8`) throughout the generated theme consumers. The durable source is `home/.config/zenwolf/themes/avatar-aang-dark/profile.json`; generated CSS, terminal, lock-screen, Waybar, Rofi, Cava, btop, and browser palette files are rebuilt from it by `zenwolf-theme-build`.

## Apply the complete palette

After deploying the home files, rebuild and validate the generated consumers, then apply the theme from inside a supported Hyprland session:

```bash
zenwolf-theme-build build avatar-aang-dark
zenwolf-theme-build check avatar-aang-dark
zenwolf-theme avatar-aang-dark
```

This applies the static Avatar wallpaper through the theme's normal hyprpaper integration. The theme is not active merely because its files are installed; run the final command in the session.

## Optional animated Avatar wallpaper

The repository includes still art, not an animated ATLA image. The optional helper creates a small H.264 video from the included Avatar wallpaper using a subtle 15-second looping zoom. It preserves the original image, does not fetch external material, and is opt-in because video wallpapers use more VM resources than a still.

On Kali ARM64, check/install the packages through the installer:

```bash
bash scripts/install-kali-vmware.sh --animated-wallpaper
```

Or install `ffmpeg` and `mpvpaper` from the configured Kali repositories, deploy the dotfiles, then generate and start it from a working Hyprland session:

```bash
~/.local/bin/zenwolf-make-avatar-wallpaper
~/.local/bin/zenwolf-start-avatar-wallpaper
```

The first command writes `~/.local/share/zenwolf/wallpapers/avatar-aang-dark-animated.mp4`; the second stops the static hyprpaper service and launches the loop with mpvpaper. Select a theme again or end the mpvpaper process to return to the still wallpaper. The installer does not autostart the video wallpaper, alter the display manager, or start Hyprland.

## Shader backgrounds and TUI effects

These are separate categories:

- **Video/animated wallpapers:** `mpvpaper` plays a video behind Wayland windows; `linux-wallpaperengine` is a community project for running Wallpaper Engine content on Linux, but check compatibility and resource use before using it in a VM.
- **Shader-rendered backgrounds:** `glpaper` is a lightweight Wayland wallpaper program that renders GLSL shaders. Availability and compatibility depend on the compositor and graphics stack; VMware Fusion's virtual GPU may not support a smooth shader workload.
- **Animated wallpaper transitions:** `swww` provides animated transitions between still images; that is not the same as a continuously animated shader.
- **Terminal visualizers/effects:** Cava is an audio spectrum visualizer, while `pipes.sh`, `cmatrix`, and UniMatrix (`unimatrix`) are terminal effects. They do not draw the desktop wallpaper.

For this Kali Fusion VM, start with the generated mpvpaper loop or static hyprpaper. Treat live shaders as optional and test them only after the guest's Wayland graphics are stable.
