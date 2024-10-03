#!/usr/bin/env sh

VIM_VERSION=${VERSION}
VIM_ENABLE_GUI="${ENABLE_GUI}"
VIM_ENABLE_SOUND="${ENABLE_SOUND}"
VIM_ENABLE_PERL="${ENABLE_PERL}"
VIM_ENABLE_PYTHON="${ENABLE_PYTHON}"
VIM_ENABLE_PYTHON3="${ENABLE_PYTHON3}"
VIM_ENABLE_RUBY="${ENABLE_RUBY}"
VIM_ENABLE_LUA="${ENABLE_LUA}"
VIM_ENABLE_TCL="${ENABLE_TCL}"
VIM_ENABLE_MZSCHEME="${ENABLE_MZSCHEME}"

LUA_VERSION="jit"
RACKET_VERSION="8.5"

set -e

unset_false_variables() {
    if [ "${VIM_ENABLE_GUI}" = "false" ]; then
        unset VIM_ENABLE_GUI
    fi
    if [ "${VIM_ENABLE_SOUND}" = "false" ]; then
        unset VIM_ENABLE_SOUND
    fi
    if [ "${VIM_ENABLE_PERL}" = "false" ]; then
        unset VIM_ENABLE_PERL
    fi
    if [ "${VIM_ENABLE_PYTHON}" = "false" ]; then
        unset VIM_ENABLE_PYTHON
    fi
    if [ "${VIM_ENABLE_PYTHON3}" = "false" ]; then
        unset VIM_ENABLE_PYTHON3
    fi
    if [ "${VIM_ENABLE_RUBY}" = "false" ]; then
        unset VIM_ENABLE_RUBY
    fi
    if [ "${VIM_ENABLE_LUA}" = "false" ]; then
        unset VIM_ENABLE_LUA
    fi
    if [ "${VIM_ENABLE_TCL}" = "false" ]; then
        unset VIM_ENABLE_TCL
    fi
    if [ "${VIM_ENABLE_MZSCHEME}" = "false" ]; then
        unset VIM_ENABLE_MZSCHEME
    fi
}

unset_false_variables

echo "Download, build and install VIM"

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

# Removes packages
remove_packages() {
    case "${ID}" in
        debian|ubuntu)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                apt-get remove -y "$@"
                apt-get autoremove -y
                rm -rf /var/lib/apt/lists/*
            fi
            ;;
        alpine)
            if ! apk -e info "$@" > /dev/null 2>&1; then
                apk del "$@"
                rm -rf /var/cache/apk/*
            fi
            ;;
    esac
}

# Install prerequisites
echo "Install prerequisites"
if [ "${ID}" = "debian" ] || [ "${ID}" = "ubuntu" ]; then
    check_packages curl ca-certificates build-essential gettext libtinfo-dev \
        ${VIM_ENABLE_GUI:+libgtk-3-dev libxmu-dev libxpm-dev libgtk-3-0 libxmu6 libxpm4} \
        ${VIM_ENABLE_SOUND:+libcanberra-dev libcanberra0} \
        ${VIM_ENABLE_PERL:+libperl-dev perl} \
        ${VIM_ENABLE_PYTHON:+python2-dev} \
        ${VIM_ENABLE_PYTHON3:+python3-dev} \
        ${VIM_ENABLE_RUBY:+ruby-dev ruby} \
        ${VIM_ENABLE_LUA:+$([ "${LUA_VERSION}" = 'jit' ] && echo libluajit-5.1-dev || echo liblua${LUA_VERSION}-dev) lua${LUA_VERSION}} \
        ${VIM_ENABLE_TCL:+tcl-dev tcl} \
        ${VIM_ENABLE_MZSCHEME:+libsqlite3-dev}
            if [ -n "${VIM_ENABLE_LUA}" ]; then
                rm -f /usr/lib/x86_64-linux-gnu/liblua*.so
                lua_dir="$(ls -d /usr/include/lua* 2>/dev/null | sort -V | tail -n1)"
                if [ -n "${lua_dir}" ]; then
                    ln -sfn "${lua_dir}" /usr/include/lua
                fi
            fi
        elif [ "${ID}" = "alpine" ]; then
            echo "Download and install prequisites..."
                check_packages curl tar build-base ncurses-dev ncurses acl diffutils libintl ca-certificates \
                    ${VIM_ENABLE_GUI:+gtk+3.0 libxmu libxpm} \
                    ${VIM_ENABLE_SOUND:+libcanberra} \
                    ${VIM_ENABLE_PERL:+perl} \
                    ${VIM_ENABLE_PYTHON:+python2 python2-dev} \
                    ${VIM_ENABLE_PYTHON3:+python3 python3-dev} \
                    ${VIM_ENABLE_RUBY:+ruby libc6-compat} \
                    ${VIM_ENABLE_LUA:+lua${LUA_VERSION} lua${LUA_VERSION}-dev} \
                    ${VIM_ENABLE_TCL:+tcl} \
                    ${VIM_ENABLE_MZSCHEME:+libffi-dev libc-dev sqlite-dev}

                if [ -z "${SKIP_ICONV}" ]; then
                    echo "Download, build and install iconv..."
                    mkdir -p /usr/src/iconv
                    cd /usr/src/iconv
                    curl -sL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz | tar -xz --strip-components=1
                    ./configure
                    make -j$(nproc)
                    make install
                fi

                if [ -z "${SKIP_GETTEXT}" ]; then
                    echo "Download, build and install getttext..."
                    mkdir -p /usr/src/gettext
                    cd /usr/src/gettext
                    curl -sL https://ftp.gnu.org/pub/gnu/gettext/gettext-0.22.tar.gz | tar -xz --strip-components=1
                    ./configure
                    make -j$(nproc)
                    make install
                fi
            fi

if [ -n "${VIM_ENABLE_MZSCHEME}" ]; then
    echo "Download, build and install Racket..."
    mkdir -p /usr/src/racket/
    curl -sL "https://mirror.racket-lang.org/installers/${RACKET_VERSION}/racket-${RACKET_VERSION}-src-builtpkgs.tgz" | tar xz --directory=/usr/src/racket --strip-components=1
    cd /usr/src/racket/src
    ./configure --prefix "/usr/local" --enable-dynlib --enable-bcdefault --disable-features --disable-places --disable-gracket --disable-docs
    make -j$(nproc)
    make install
fi

echo "Download and extract VIM source"

requested_version="${VIM_VERSION}"
version_list="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/vim/vim/tags" | grep -o '"name": "v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"' | sed 's/"name": "v//;s/"//g' | sort -rV)"
if [ "${requested_version}" = "latest" ]; then
    VIM_VERSION="$(echo "${version_list}" | head -n 1)"
fi

echo "Downloading source for ${VIM_VERSION}..."
mkdir -p /usr/src/vim
curl -sL https://github.com/vim/vim/archive/v${VIM_VERSION}.tar.gz | tar -xz --directory=/usr/src/vim --strip-components=1 2>&1
echo "Building..."
if [ "${ID}" = "alpine" ]; then
    if [ -n "${VIM_ENABLE_LUA}" ]; then
        ln -s "lua${LUA_VERSION}" "/usr/bin/lua"
        ln -s "lua${LUA_VERSION}/liblua.a" "/usr/lib/liblua${LUA_VERSION}.a"
    fi
fi
cd /usr/src/vim
./configure \
    --with-features=huge \
    ${VIM_COMPILEDBY:+--with-compiledby="${VIM_COMPILEDBY}"} \
    ${VIM_ENABLE_GUI:+--enable-gui=gtk3} \
    ${VIM_ENABLE_PERL:+--enable-perlinterp} \
    ${VIM_ENABLE_PYTHON:+--enable-pythoninterp} \
    ${VIM_ENABLE_PYTHON3:+--enable-python3interp} \
    ${VIM_ENABLE_RUBY:+--enable-rubyinterp} \
    ${VIM_ENABLE_LUA:+--enable-luainterp $([ "${LUA_VERSION}" = 'jit' ] && echo --with-luajit)} \
    ${VIM_ENABLE_TCL:+--enable-tclinterp} \
    ${VIM_ENABLE_MZSCHEME:+--enable-mzschemeinterp} \
    --enable-fail-if-missing

make -j$(nproc)
make install

# Clean up, remove files that should no longer be needed and uninstall packages that was only used for compilation.
rm -rf /usr/local/include/*

if [ "${ID}" = "debian" ] || [ "${ID}" = "ubuntu" ]; then
    remove_packages curl ca-certificates build-essential gettext libtinfo-dev \
        ${VIM_ENABLE_GUI:+libgtk-3-dev libxmu-dev libxpm-dev} \
        ${VIM_ENABLE_SOUND:+libcanberra-dev} \
        ${VIM_ENABLE_PERL:+libperl-dev} \
        ${VIM_ENABLE_RUBY:+ruby-dev} \
        ${VIM_ENABLE_LUA:+$([ "${LUA_VERSION}" = 'jit' ] && echo libluajit-5.1-dev || echo liblua${LUA_VERSION}-dev) lua${LUA_VERSION}} \
        ${VIM_ENABLE_TCL:+tcl-dev}
elif [ "${ID}" = "alpine" ]; then
        remove_packages curl tar build-base ncurses-dev \
            ${VIM_ENABLE_PYTHON:+python2-dev} \
            ${VIM_ENABLE_PYTHON3:+python3-dev} \
            ${VIM_ENABLE_LUA:+lua${LUA_VERSION}-dev}
fi

rm -rf /usr/src

