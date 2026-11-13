# Kali Linux on VMware Fusion (Apple silicon)

This is an instructions-only adaptation for Kali ARM64 in VMware Fusion on Apple silicon. It does not convert the Arch-specific system modules or claim that Hyprland works on every VMware virtual graphics setup. Back up the VM before changing desktop or display settings.

## One-command setup

Create a Kali ARM64 VM in Fusion, install Kali and create a normal user with `sudo`, and confirm networking. Then run:

```bash
git clone https://github.com/heikojan2010/zenwolf-dotfiles.git
cd zenwolf-dotfiles
bash scripts/install-kali-vmware.sh
```

The installer checks Kali ARM64, updates APT indexes, installs guest utilities and available theme dependencies, and deploys the user configuration after showing a preview and asking for confirmation. It automatically adds the Hyprland package set only if all packages are available and the candidate version is 0.55 or newer; it automatically prepares the video wallpaper only if both `mpvpaper` and `ffmpeg` are available. If either optional set is unavailable, it skips it and continues with the Kali desktop/static wallpaper path.

Options:

```bash
bash scripts/install-kali-vmware.sh --check    # inspect candidates; no changes
bash scripts/install-kali-vmware.sh --minimal  # skip Hyprland/video extras
bash scripts/install-kali-vmware.sh --no-deploy # packages only
```

The installer does not perform a full system upgrade, add external repositories, copy `system/`, modify the display manager, or launch a compositor. It builds and validates the Avatar Aang Bubblegum Neon theme. See [the Avatar theme and wallpaper guide](avatar-bubblegum-wallpaper.md) for applying the theme and optional animated background.

## VMware guest tools and display

The installer includes `open-vm-tools` and the desktop guest tools if the Kali repositories provide them. Reboot after installation. In VMware Fusion, enable the available display acceleration and resizing options. Exact controls depend on Fusion and Kali versions. Verify pointer, window resizing, clipboard, and networking from Kali's supported desktop before trying Hyprland.

## Hyprland compatibility

The tracked config uses Hyprland's Lua API and requires version 0.55 or newer. Check the configured Kali candidates with:

```bash
apt-cache policy hyprland hyprpaper hyprlock waybar rofi \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

The installer declines to add Hyprland if the version floor or dependency set is unavailable. Do not mix packages from unrelated Debian/Kali releases or add an unreviewed repository to force compatibility. Use Kali's supported desktop if the compositor version or virtual graphics is unsuitable.

Once a compatible Hyprland session is running, validate and apply:

```bash
Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
zenwolf-theme-build check
zenwolf-theme avatar-aang-dark
```

To start the generated motion wallpaper, use `~/.local/bin/zenwolf-start-avatar-wallpaper` from inside that session. Return to the still wallpaper by stopping mpvpaper and selecting the theme again.

## Safety boundaries

Do not install Zenwolf's Arch GPU/NVIDIA lifecycle, suspend, SSH, or ESP examples in this VM. The VMware virtual graphics adapter is not the physical AMD/NVIDIA setup those modules were made for. Keep Kali updated through configured Kali repositories and use it only in authorized security environments.
