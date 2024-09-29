#!/usr/bin/env bash

SMLNJ_VERSION=${VERSION}

set -e

echo "Installing SMLNJ"

source /etc/os-release

export DEBIAN_FRONTEND=noninteractive

# Clean up
cleanup() {
    apt remove make g++ -y
    apt autoremove -y
    rm -rf /var/lib/apt/lists/*
}

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get --no-install-recommends install "$@" -y
    fi
}

echo "Installing SMLNJ..."

check_packages curl g++ make rlwrap

mkdir /usr/local/smlnj

curl -sL http://smlnj.cs.uchicago.edu/dist/working/${SMLNJ_VERSION}/config.tgz | tar -xzC /usr/local/smlnj 2>&1

cd /usr/local/smlnj

./config/install.sh

cleanup

echo "Done!"

