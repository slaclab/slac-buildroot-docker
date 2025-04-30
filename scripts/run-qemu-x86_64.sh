#!/usr/bin/env bash

function usage {
    echo "USAGE: $0 -v version "
    echo "  -v version           : The buildroot version (i.e. 2025.02)"
    exit 1
}

for a in $@; do
	case $a in
	-v)
		VER="$2"
		shift 2
		;;
    -h|--help)
		usage
        ;;
	*)
		;;
	esac
done

if [ -z "$VER" ]; then
	usage
fi

cd "$(dirname "${BASH_SOURCE}")/../buildroot/buildroot-$VER-x86_64/output/images"
qemu-system-x86_64 -m size=2048 -no-reboot -nographic -kernel ./bzImage -initrd ./rootfs.ext2 -append "console=ttyS0 init=/linuxrc root=/dev/ram0" \
	-nic user,hostfwd=tcp::8022-:22
