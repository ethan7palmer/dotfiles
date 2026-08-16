#!/usr/bin/env bash
#
# Install Docker CE via Docker's official apt repository. This is the one
# approved exception to "always prefer plain apt" — Docker's own repo is the
# vendor-correct apt source, not a snap or a shell-script installer.
#
set -euo pipefail

PACKAGES=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

missing=()
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
        missing+=("${pkg}")
    fi
done

if [ ${#missing[@]} -eq 0 ]; then
    echo "Docker already installed — nothing to do."
else
    KEYRING="/etc/apt/keyrings/docker.asc"
    SOURCES_LIST="/etc/apt/sources.list.d/docker.list"
    CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
    ARCH="$(dpkg --print-architecture)"
    REPO_LINE="deb [arch=${ARCH} signed-by=${KEYRING}] https://download.docker.com/linux/ubuntu ${CODENAME} stable"

    sudo install -d -m 0755 /etc/apt/keyrings

    if [ ! -s "${KEYRING}" ]; then
        echo "Downloading the Docker signing key..."
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "${KEYRING}"
        sudo chmod a+r "${KEYRING}"
    fi

    if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
        echo "Registering the Docker apt repository..."
        echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
    fi

    echo "Installing: ${missing[*]}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
fi

if id -nG "${USER}" | grep -qw docker; then
    echo "${USER} already in the docker group — nothing to do."
else
    echo "Adding ${USER} to the docker group..."
    sudo usermod -aG docker "${USER}"
fi
