#!/usr/bin/env bash
set -e

ARCHES="x86_64 i686 arm"
VER="2025.02"
TCO=0

while test $# -gt 0; do
    case $1 in
        -v|--version)
            VER="$2"
            shift 2
            ;;
        -a|--arch)
            ARCH="$ARCH $2"
            shift 2
            ;;
        -t|--toolchain-only)
            TCO=1
            ;;
        -h|--help)
            echo "USAGE: $0 -v version -a arch"
            echo "  -v version       : buildroot version"
            echo "  -a arch          : Target arch (i686, arm, x86_64)"
            echo "Examples:"
            echo "  $0 -v 2025.02 -a x86_64"
            echo "  $0 -v 2025.02 -a x86_64 -a i686"
            exit 0
            ;;
        *)
            echo "Unknown arg $1"
            exit 1
            ;;
    esac
done

if [ ! -f  buildroot/site-top/.git ]; then
    echo "buildroot/site-top is empty; Did you init submodules with git submodule update --init --recursive ??"
    exit 1
fi

if [ -z "$ARCH" ]; then
    ARCH="$ARCHES"
fi

function do_build {
    docker build . -f Dockerfile.buildroot -t "slac-buildroot:${1}-${2}" --build-arg="BUILDROOT_VERSION=${1}" --build-arg="BUILDROOT_ARCH=${2}" --build-arg="TOOLCHAIN_ONLY=${3}" \
        --build-arg="USER=$(id -u)" --build-arg="GROUP=$(id -g)"
}

for a in $ARCH; do
    echo "Building for $VER-$a"
    do_build "$VER" $a $TCO
done
