#!/usr/bin/env bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

function usage {
    echo "USAGE: setup.sh -v VERSION -a ARCH [--git REPO] [-b BRANCH] [--download-only]"
	echo "  -v <version>      - Version to build (i.e. 2019.08)"
	echo "  -a <arch>         - Arch to build for (i686, x86_64, zynq)"
	echo "  --download-only   - Only download and do basic setup, don't build"
	echo "  --git <repo>      - Clone GIT repository instead"
	echo "  -b <branch>       - If cloning a git repo, checkout this ref after the fact"
	echo "Examples:"
	echo "  $0 -v 2019.08 -a x86_64"
	echo "  $0 -v 2019.08 -a i686"
    exit 1
}

while test $# -gt 0; do
    case "$1" in 
    -v)
        VERSION="$2"
        shift 2
        ;;
    -a)
        ARCH="$2"
        shift 2
        ;;
    --download-only)
        DOWNLOADONLY=1
        shift
        ;;
	--git)
		REPO="$2"
		shift 2
		;;
	--toolchain-only)
		TOOLCHAIN="$2"
		shift 2
		;;
	-b)
		REF="$2"
		shift 2
		;;
	-h|--help)
		usage
		;;
    *)
        echo "Invalid option $a"
		usage
        ;;
    esac
done

if [ -z $VERSION ]; then
	usage
fi

if [ "$ARCH" != "zynq" ] && [ "$ARCH" != "i686" ] && [ "$ARCH" != "x86_64" ]; then
    echo "$ARCH is not a valid arch choice, valid options are i686, x86_64, zynq"
	usage
    exit 1
fi

case $VERSION in
    2019.08)
        FILE="buildroot-2019.08.1"
        ;;
    2016.11.1)
        FILE="buildroot-2016.11.1"
        ;;
    *)
        echo "Unsupported version $VERSION"
        exit 1
        ;;
esac
DIR="buildroot-$VERSION-$ARCH"

mkdir -p download
if [ ! -f download/$FILE.tar.bz2 ] && [ -z $REPO ]; then
    wget -O "download/$FILE.tar.bz2" "https://buildroot.org/downloads/$FILE.tar.bz2"
fi

# Extract our tarball or clone our GIT repo
if [ ! -d "$DIR" ]; then
	if [ -z $REPO ]; then
	    tar -xf "download/$FILE.tar.bz2"
    	mv "$FILE" "$DIR"
	else
		git clone -b "$REF" "$REPO" "$DIR" 
	fi
fi

# Make required symlinks for our buildroot-site
if [ ! -h "$DIR/site" ]; then
    pushd "$DIR" > /dev/null
    ln -s ../site-top site
    popd > /dev/null
fi

if [ "$DOWNLOADONLY" == "1" ]; then
    exit 0
fi

export FORCE_UNSAFE_CONFIGURE=1

pushd "$DIR" > /dev/null

# HACK! first call to print-version fails, after which it generates the required files. Eat the error and continue
make print-version 2> /dev/null || true
make defconfig

./site/scripts/br-installconf.sh -a $ARCH -f

# Undo a hack we did earlier. Re-order such that make is out of path
export PATH="/usr/bin:/bin:/sbin:$PATH"

# Really stupid hack for patch. Sometimes it gives us too many open files
ulimit -n 8192 || true

if [ "$TOOLCHAIN" == "1" ]; then
	# Build the toolchain *only*. That's what we care about :)
	make toolchain -j$(nproc)
else
	# Build everything
	make -j$(nproc)
fi

popd > /dev/null
