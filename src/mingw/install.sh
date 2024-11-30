#!/usr/bin/env sh

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

. /etc/os-release

export DEBIAN_FRONTEND=noninteractive

apt_get_update() {
    case "${ID}" in
        debian|ubuntu)
            if [ ! -d "/var/lib/apt/lists" ] || [ -z "$(ls -A /var/lib/apt/lists/)" ]; then
                echo "Running apt-get update..."
                apt-get update -y
            fi
            ;;
    esac
}

# Checks if packages are installed and installs them if not
check_packages() {
    case "${ID}" in
        debian|ubuntu)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                apt_get_update
                apt-get --no-install-recommends install -y "$@"
            fi
            ;;
        alpine)
            if ! apk -e info "$@" > /dev/null 2>&1; then
                apk add --no-cache "$@"
            fi
            ;;
    esac
}

# Install prerequisites
if [ "${ID}" = "debian" ] || [ "${ID}" = "ubuntu" ]; then
	check_packages mingw-w64
elif [ "${ID}" = "alpine" ]; then
	check_packages mingw-w64-gcc
fi
