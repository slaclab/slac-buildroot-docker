#!/usr/bin/env bash

set -e

TOP="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if docker container ls | grep -Eo "\sslac-buildroot-dev-container\$" > /dev/null; then
	exit 0
fi

cd "${TOP}"
if ! docker image ls | grep -Eo "^slac-buildroot-dev\s" > /dev/null; then
	echo "Building dev container image..."
	docker build -t slac-buildroot-dev -f ./Dockerfile.dev .
fi

docker run --rm -d -it -v "${TOP}:${TOP}" -e "PATH=/build/host/bin:/bin:/usr/bin:/usr/local/bin" -e "TERM=${TERM}" -e "COLORTERM=${COLORTERM}" -w "${TOP}" --name slac-buildroot-dev-container slac-buildroot-dev bash

