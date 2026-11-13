# Kali Linux on VMware Fusion (Apple silicon)

This is an **instructions-only adaptation** for this fork, not a conversion of Zenwolf's Arch-specific system modules or a tested Kali image. It focuses on Kali ARM64 in VMware Fusion on an Apple-silicon Mac. Keep the original [Arch build guide](build-guide.md) for the upstream setup; do not run its Pacman or hardware-specific instructions in Kali.

## Compatibility and safety

- Use a Kali **ARM64/aarch64** installer image and create an ARM virtual machine in Fusion. An amd64 image is not the right guest architecture for Apple silicon.
- The tracked compositor config uses Hyprland's Lua API and requires **Hyprland 0.55 or newer**. Kali's candidate version may be older or some packages may be unavailable. Check before installing; if the requirement is not met, use Kali's supported desktop and do not launch the tracked Hyprland config.
- VMware's virtual graphics device is not the AMD/NVIDIA hybrid hardware this setup was designed for. Do not install Zenwolf's NVIDIA, GPU lifecycle, suspend, or ESP modules in this VM.
- Hyprland under Fusion is experimental. 3D acceleration and display behavior depend on Fusion, guest tools, and the Kali release. Prefer Kali's supported desktop (commonly Xfce) if Wayland or the virtual display is unreliable.
- Back up the VM before changing desktop or display settings. Commands below affect the Kali guest only.

## Automated setup

Create a Kali ARM64 VM in Fusion, install Kali, create a non-root user, and confirm networking. Clone this fork and run the interactive installer:

```bash
git clone --branch kali-vmware-m4 \
  https://github.com/heikojan2010/zenwolf-dotfiles.git
cd zenwolf-dotfiles
bash scripts/install-kali-vmware.sh
```

The installer checks Kali and the ARM64 architecture, updates APT indexes, installs available guest utilities, previews the home-directory copy, and asks before deployment. It regenerates and validates the **Avatar Aang Dark — Bubblegum Neon** theme from `profile.json`. It does not install `system/`, change the display manager, or start Hyprland.

Options:

```bash
bash scripts/install-kali-vmware.sh --check
bash scripts/install-kali-vmware.sh --with-hyprland
bash scripts/install-kali-vmware.sh --no-deploy
```

`--check` only checks package candidates after platform validation. `--with-hyprland` opts in to the experimental desktop package set and refuses to proceed unless Kali offers Hyprland 0.55 or newer and all listed package candidates. `--no-deploy` installs packages only. The installer remains interactive; `--yes` suppresses prompts and should only be used after reviewing the script and actions.

The installer applies the theme only if it detects an already-running Hyprland session. Otherwise, after Hyprland is installed, compatible, and started, apply it with:

```bash
~/.local/bin/zenwolf-theme avatar-aang-dark
```

The hot-pink accent is `#ff4fd8`; generated consumers are rebuilt from the profile. The Aang wallpaper and dark purple background are retained.

## Manual guest-tools setup

If you prefer manual setup, install basic tools and VMware guest utilities:

```bash
sudo apt update
sudo apt install --no-install-recommends \
  git rsync python3 python3-pygame jq ripgrep nano pciutils \
  open-vm-tools open-vm-tools-desktop
```

Reboot after guest-tools installation. In Fusion, enable the available display acceleration and guest display resizing options. Names and availability vary by Fusion version. Confirm window resizing, pointer movement, clipboard, and networking from Kali before trying another desktop.

## Check Kali Hyprland availability

Check configured Kali repositories and candidate versions first:

```bash
apt-cache policy hyprland hyprpaper hyprlock waybar rofi \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

Proceed only if `hyprland` has a candidate version of **0.55 or newer**, and the required companion packages have candidates. If a package is unavailable or the version is too old, stop here; do not add a random Debian repository or install packages from a different Kali/Debian release to force the setup. Prefer Kali's supported desktop, or separately adapt and test the configuration for your Kali release.

## VMware/Kali troubleshooting

- **No resize or unexpected resolution:** shut down the guest and review Fusion's display/resize options; verify `open-vm-tools-desktop` is installed and the guest was rebooted. Test using Kali's default desktop before debugging Hyprland.
- **Black screen, compositor crash, or broken redraw:** return to Kali's default desktop from the VM console. Disable the Fusion graphics acceleration option if available, or abandon Hyprland in this VM. Do not change system modules to address virtual graphics problems.
- **Config verification fails or Hyprland is too old:** do not launch Zenwolf's compositor config. Check `apt-cache policy hyprland`; use the supported Kali desktop or independently port the config to a compatible release.
- **Missing app or integration:** check the package with `apt-cache policy <package>` and command with `command -v <program>`. Disable or adapt only that integration; do not mix packages from unrelated releases.
- **No audio or clipboard integration:** verify VMware guest tools, Kali's audio service, and Fusion's guest settings from the default desktop first. These features are not guaranteed by the dotfiles.

Kali is intended for authorized security work. Keep it updated through its configured Kali repositories and use it only in environments where you have permission.
