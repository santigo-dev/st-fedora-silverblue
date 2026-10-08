# Custom Fedora Silverblue image

## Introduction

This is my daily driver, a custom [Fedora Kinoite](https://fedoraproject.org/atomic-desktops/kinoite/) image, which is an image based, atomic and immutable Linux distro made and maintained by the Fedora project. Long gone are the days where I used to rice my installations like I used to do with shell scripting and eventually Ansible for Arch Linux.

The reason for choosing a distro like this is that I want to make my Linux workstation as simple, stable and maintainable as possible. Here you'll see that I make use of other peoples infrastructure, and standard off-the-shelf tools to forget about a few things.

That means "modifying my Linux installation" can just mean writing a `Containerfile`: normal `dnf` install lines, run once at build time, that produce a new image. No dotfiles-and-setup-script routine, no drift between machines, no "wait, which post-install steps did I already run on this one", no lingering small files, etc.

This distro also forces you to strictly work containerized, which for some people it's a real problem, but if you take a look at the files, I don't really have a fancy config, and it's updated rarely, so it fits me. It's quite "declarative" too, without being NixOS.

## Description

The base here is `quay.io/fedora-ostree-desktops/kinoite:44`. On top of it:

- Everyday tools, `stow` for dotfile management, `just` as a command runner (I took inspiration from the [ublue project](https://github.com/ublue-os)), `zsh` as the shell.
- A few COPRs for packages missing from the the main repos: Ghostty as a terminal, Koi for theming KDE Plasma, and keyd for remapping some keys.

## How It Actually Gets Built

On a schedule the image/container/package is built by GitHub Actions, which spawns a worker to handle the build, so nothing has to happen on your local machine. Depending on the setup, either Podman with buildah or Docker with BuildKit does the actual work, pulling the base Fedora Kinoite image and building on top of it to produce a new OCI image based on the `Containerfile`, that's it.

On the machine itself, `bootc` takes over from there, it's not a package manager like dnf, but more like the tool that manages which full image you're booted into, handles rollbacks if something goes wrong, and keeps the system updated in the background through a systemd timer, that applies the update when you turn your computer off.

The one manual step is right after a fresh install: you have to switch over to this repo's image by yourself, and after that bootc takes care of staying up to date on its own:

```bash
sudo bootc switch ghcr.io/santigo-dev/fedora-kinoite-oci-image:latest
```

### Post-Install Setup

#### Docker
Docker CE is installed with socket activation (`docker.socket`), so the daemon only starts on-demand when called rather than running continuously in the background.

To use Docker without `sudo`, add your user to the `docker` group:

```bash
sudo usermod -aG docker $USER
```
*(Log out and back in for group changes to take effect).*

## References

- [Building your own Atomic (bootc) Desktop](https://fedoramagazine.org/building-your-own-atomic-bootc-desktop/)
- [KDE-BOOTC](https://github.com/sigulete/kde-bootc)
- [Bluefin](https://github.com/ublue-os/bluefin)

## License

GPL-3.0, see LICENSE.
