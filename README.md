# slac-buildroot-docker

This repository contains dockerized build infrastructure for SLAC's buildroot images and their associated toolchains.

## Pulling Pre-built Containers

Prebuilt containers can be obtained from GitHub's package registry as follows:

```
docker pull ghcr.io/jjl772/slac-buildroot:2019.08-x86_64
```

Replace the final bit (2019.08-x86_64) with any of the available versions and architectures:

| Container Tag | Buildroot Version | Architecture | Notes |
|---|---|---|---|
| 2019.08-x86_64 | buildroot-2019.08 | x86_64 | ATCA, Dell servers |
| 2019.08-i686 | buildroot-2019.08 | i686 (x86) | EMCOR magnet power supplies |
| 2019.08-zynq | buildroot-2019.08 | ARM | Test system on someone's desk, many years ago. |

NOTE: buildroot-2016.11.1 unsupported right now

### Extracting Images from Pre-built Containers

Use `./get-images.sh` to extract pre-built images from the containers.

For example, to extract buildroot-2019.08 x86_64 image from the pre-built container:
```sh
./get-images.sh -r -v 2019.08 -t 2019.08-x86_64
```

## Building

To build the images locally from scratch, follow this guide.

First, create the container (i.e. for i686):
```
./create-container.sh -a i686
```

After the build is complete, use `get-images.sh` to extract the images from the container:
```
./get-images.sh -t 2025.02 -t 2025.02-i686
```

The resulting images will be in `images/buildroot-2025.02-i686`.

### Development

`Dockerfile.dev` defines a development container that can be used to compile the buildroot images for iterative development. 
Due to the age of these images, they generally will not compile on modern Linux distros, but they will build in this container (which is based on Rocky 9).

To bootstrap a development container, run `./start-dev-container.sh`. 
This will build the docker image and launch the container under the name slac-buildroot-dev-container. 

The container mounts this directory as a volume, and the resulting build will be in the buildroot directory.

To run commands in this container, run `./run-docker-cmd.sh mycommand and stuff`.

Example:
```sh
# Bootstrap buildroot; download the tarball, apply patches and build
./run-docker-cmd.sh ./buildroot/setup.sh -v 2025.02 -a i686

# After that, you can run make directly to rebuild the container as you need
./run-docker-cmd.sh make -C buildroot/buildroot-2025.02-i686
```

## Using the Containerized Toolchains

The buildroot paths within the container match what's found on S3DF. Thus, most SLAC software should be able to build out of the box regardless if there's hardcoded paths.

The top of the buildroot directory is located at `/sdf/sw/epics/package/linuxRT/buildroot-<version>`

For buildroot-2025.02 and x86_64, GCC would be at: `/sdf/sw/epics/package/linuxRT/buildroot-2025.02/host/linux-x86_64/x86_64/bin/x86_64-buildroot-linux-gnu-gcc`

## How It Works

buildroot/site-top is a submodule pointing at https://github.com/slaclab/buildroot-site.git

This repository contains a set of patches applied to buildroot and a rootfs that will be included with the image. 
**If you want to make modifications to the image, modify that submodule.**

During the build process, the appropriate buildroot distribution tarball is downloaded from buildroot.org and extracted.
In the newly extracted directory, a symlink called `site` is created, pointing to site-top, and the script `./site/br-installconf.sh -a <arch>` is run.
This script applies all necessary patches to buildroot and generates the .config.

Next, `make` is run, kicking off the build.

After the build is complete, the contents of the `output` directory is copied into `/sdf/sw/epics/package/linuxRT/buildroot-<ver>` and
`/build` is deleted to reduce the overall container size.
