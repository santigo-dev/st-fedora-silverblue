# Custom Fedora Silverblue image

## Introduction

This is my daily driver: a custom [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) image, an atomic desktop maintained by the Fedora project. I got bored of modifying Arch with Bash scripts or Ansible handbooks.

The reason for choosing a distro like this is that I want to make my Linux workstation as simple, stable, and maintainable as possible. Here you'll see that I make use of cheap/free infrastructure, and standard off-the-shelf tools to simplify my setup.

So modifying my Linux installation today means simply writing a `Containerfile`, this means dotfiles-and-setup-script routine, no drift between machines, no lingering scripts, etc.

Silverblue's image-based model keeps the base system read-only, so I manage system-level changes in the `Containerfile`. Applications and development environments can still be installed and managed separately, for example with Flatpak and Distrobox. The configuration here is intentionally simple and changes rarely; it's quite "declarative" too, without being NixOS.

## Description

The base is [`quay.io/fedora-ostree-desktops/silverblue`](https://quay.io/repository/fedora-ostree-desktops/silverblue), with the Fedora version set by `FEDORA_VERSION` in the `Containerfile` (currently `45`). On top of it:

**Added:**
- `just` as a command runner, `stow` for dotfile management.
- `distrobox` for running other Linux environments in containers.
- `ghostty` (via COPR) as the terminal emulator.
- `keyd` (via COPR) for keyboard remapping.
- `code` (Visual Studio Code, via Microsoft repo).
- Docker CE (`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin`) with socket activation.
- `fcitx5` and related plugins for input method support.
- `gnome-browser-connector` for GNOME Shell extensions.
- GPaste clipboard history, its graphical settings UI, and GNOME Shell extension.
- `ydotool` for host-side Wayland input automation.

**Removed:**
- `firefox` and `firefox-langpacks` (use a containerized or Flatpak browser instead).
- `gnome-initial-setup`, `gnome-tour`, `yelp` (unneeded GNOME onboarding tools).

## How It Actually Gets Built

On a schedule the image is built by GitHub Actions, which spawns a worker to handle the build — nothing has to happen on your local machine. It pulls the base Silverblue image, runs `scripts/build.sh` inside the container, and produces a new OCI image pushed to the [GitHub Container Registry](https://github.com/santigo-dev/st-fedora-silverblue/pkgs/container/st-fedora-silverblue) (`ghcr.io`).

On the machine itself, `bootc` takes over from there. It's not a package manager like `dnf`, but more like the tool that manages which full image you're booted into, handles rollbacks if something goes wrong, and keeps the system updated in the background through a systemd timer.

The one manual step is right after a fresh install: switch over to this repo's image, and after that `bootc` takes care of staying up to date on its own:

```bash
sudo bootc switch ghcr.io/santigo-dev/st-fedora-silverblue:latest
```

### Automatic Updates

The `bootc-fetch.timer` systemd unit runs `bootc upgrade` automatically:

- **15 minutes** after boot.
- Every **24 hours** thereafter.

This fetches and stages an update for the next reboot. It does not reboot the machine immediately like the built-in timer `bootc-fetch-apply-updates.timer`, which applies updates and reboots when one is available. On a desktop, updates should not interrupt work or restart the machine without the user's choice.

### Post-Install Setup

#### Docker
Docker CE is installed with socket activation (`docker.socket`), so the daemon only starts on-demand when called rather than running continuously in the background.

To use Docker without `sudo`, add your user to the `docker` group:

```bash
sudo usermod -aG docker $USER
```
*(Log out and back in for group changes to take effect.)*

#### Vocalinux
Install Vocalinux as a Flatpak for a self-contained speech engine that is independent of the host Python version:

```bash
flatpak install https://vocahq.github.io/vocalinux-flatpak/com.vocalinux.Vocalinux.flatpakref
```

The Flatpak includes its own `ydotool` tools and uses the desktop RemoteDesktop portal for text injection when available. Host-side `ydotool` installation and daemon configuration below are not needed for Vocalinux’s Flatpak injection path. The app may request microphone or RemoteDesktop portal access on first use.

#### Host-side ydotool
The image includes `ydotool`. To use the host package directly, `/dev/uinput` must be available, the `ydotoold` system service must run, and the service socket must be accessible to your login user.

Run these commands after switching to the image. The `input` group grants access to keyboard devices and the ydotool socket, so only add trusted local users:

```bash
# Load uinput now and on future boots.
sudo modprobe uinput
echo uinput | sudo tee /etc/modules-load.d/uinput.conf

# Let your user access the ydotool service socket.
sudo usermod -aG input "$USER"
sudo mkdir -p /etc/systemd/system/ydotool.service.d
sudo tee /etc/systemd/system/ydotool.service.d/override.conf >/dev/null <<'EOF'
[Service]
Group=input
RuntimeDirectory=%p
ExecStart=
ExecStart=/usr/bin/ydotoold -p %t/%p/socket -P 660
EOF

# Point graphical apps and command-line clients at the shared service socket.
sudo sed -i '/^YDOTOOL_SOCKET=/d' /etc/environment
echo 'YDOTOOL_SOCKET=/run/ydotool/socket' | sudo tee -a /etc/environment

sudo systemctl daemon-reload
sudo systemctl enable --now ydotool.service
sudo systemctl restart ydotool.service
```

Log out and back in so your session picks up the `input` group and socket environment variable. Check the daemon with `systemctl status ydotool.service`, then run `ydotool type 'ydotool is working'` with a text field focused.

## Repository Layout

```
.
├── Containerfile              # Defines the base image and build steps
├── scripts/
│   └── build.sh               # DNF installs, repo setup, and cleanup — runs at build time
├── systemd/
│   ├── bootc-fetch.service    # Runs `bootc upgrade`
│   └── bootc-fetch.timer      # Triggers the service 15min after boot, then daily
├── LICENSE
└── README.md
```

## References

- [Building your own Atomic (bootc) Desktop](https://fedoramagazine.org/building-your-own-atomic-bootc-desktop/)
- [Bluefin](https://github.com/ublue-os/bluefin)

## License

GPL-3.0, see LICENSE.
