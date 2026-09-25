#!/usr/bin/env bash
set -e
TOP="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

function usage {
    echo "USAGE: $0 -v version -t tag [-r|--remote]"
    echo "  -v version           : The buildroot version (i.e. 2025.02)"
    echo "  -t tag               : The docker image tag (i.e. 2025.02-x86_64)"
    echo "  -r --remote          : Use remote docker container"
    exit 1
}

IMAGE=slac-buildroot
for a in $@; do
	case $a in
	--remote|-r)
		IMAGE=ghcr.io/jjl772/slac-buildroot
		shift
		;;
	-v)
		VER="$2"
		shift 2
		;;
	-t)
		TAG="$2"
		shift 2
		;;
    -h|--help)
		usage
        ;;
	*)
		;;
	esac
done

if [ -z "$VER" ] || [ -z "$TAG" ]; then
	usage
fi

mkdir -p "$TOP/images/buildroot-$TAG"
docker run --rm -v "$TOP":"$TOP" -w "/sdf/sw/epics/package/linuxRT/buildroot-$VER/buildroot-$TAG/output/images" "$IMAGE:$TAG" bash -c "ls -la && pwd && cp -rfv ./* $TOP/images/buildroot-$TAG/"
