#!/usr/bin/env bash
set -euo pipefail

# Configure DNF
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf

# 1. Repositories
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat <<'EOF' > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# COPR repositories, and other tools
dnf -y copr enable alternateved/keyd
dnf -y copr enable scottames/ghostty
dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo

# 2. Package Removals
dnf -y remove \
    firefox \
    firefox-langpacks \
    gnome-initial-setup \
    gnome-tour \
    yelp

# 3. Package Installations
dnf -y install \
    cava \
    code \
    containerd.io \
    distrobox \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    fcitx5 \
    fcitx5-configtool \
    fcitx5-gtk \
    fcitx5-qt \
    ghostty \
    gnome-browser-connector \
    just \
    keyd \
    stow

# 4. Cleanup
dnf clean all
