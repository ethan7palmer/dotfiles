#!/usr/bin/env bash
#
# Install a JDK (25, the current LTS - also what Ubuntu's own
# default-jdk meta-package already points to) and Maven via apt. OpenJDK
# is well-packaged directly by Ubuntu, no vendor repo needed the way
# Node/Chrome/Docker/Claude Code/gh need one.
#
# Gradle deliberately isn't installed system-wide: most projects vendor
# their own Gradle Wrapper (./gradlew) pinned to the exact version that
# project needs, so a system Gradle would just be a second, likely-
# mismatched version sitting on PATH unused.
#
# JAVA_HOME also isn't set anywhere - Debian's update-alternatives
# already puts java/javac/mvn on PATH without it, and most tooling
# doesn't need it explicitly set. Add it later if something specific
# turns out to require it.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

PACKAGES=(
    openjdk-25-jdk
    maven
)

missing=()
for pkg in "${PACKAGES[@]}"; do
    dpkg -s "${pkg}" >/dev/null 2>&1 || missing+=("${pkg}")
done

if [ ${#missing[@]} -eq 0 ]; then
    ok "Java already installed — nothing to do."
else
    change "Installing: ${missing[*]}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
fi
