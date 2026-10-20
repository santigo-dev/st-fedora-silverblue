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
    fuse \
    fuse-libs \
    ghostty \
    gnome-browser-connector \
    gnome-shell-extension-gpaste \
    gpaste \
    gpaste-ui \
    iw \
    just \
    keyd \
    ydotool \
    stow

# 4. Declarative system configuration
# Satisfy bootc declarative sysusers requirement for the docker group installed by docker-ce
echo "g docker - -" > /usr/lib/sysusers.d/docker.conf
sed -i '/^docker:/d' /etc/group

# 5. Cleanup
dnf clean all
rm -rf /run/dnf \
       /var/log/dnf5.log \
       /var/lib/dnf \
       /var/cache/libdnf5 \
       /var/cache/ldconfig/*
