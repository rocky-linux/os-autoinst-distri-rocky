#!/bin/bash
set -e

## Usage: Posts ISOs to openQA for each of the universal, dvd-iso, package-set, minimal-iso, and boot-iso FLAVORs.
# scripts/run-all-flavors.sh
# Test a beta build with alternative repo URL
#   ROCKY_EXTRA_ARGS="GRUB=ip=dhcp GRUBADD=inst.repo=https://dl.rockylinux.org/stg/rocky/8.8-BETA/BaseOS/x86_64/os DNF_CONTENTDIR=stg CURRREL=8 IDENTIFICATION=false" scripts/run-all-flavors.sh

ROCKY_VERSION="9.5"

MAJOR_VERSION=${ROCKY_VERSION:0:1}
MINOR_VERSION=${ROCKY_VERSION:2:1}
ROCKY_ARCH="${ROCKY_ARCH:=x86_64}"
ROCKY_EXTRA_ARGS="${ROCKY_EXTRA_ARGS:-}"
BUILD_NAME="-$(date +%Y%m%d).0-$(git branch --show-current)-$ROCKY_VERSION"
ISO_PREFIX="Rocky-$ROCKY_VERSION-$ROCKY_ARCH"
DVD_ISOTYPE=dvd1

if [[ "$MAJOR_VERSION" -gt "8" ]]; then
    DVD_ISOTYPE=dvd
fi

# Update fif templates
./fifloader.py --clean --load templates.fif.json templates-updates.fif.json

# POST all the flavors
export PS4='# '
set -o xtrace
openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-$DVD_ISOTYPE.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR=universal \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_NAME" \
    ${ROCKY_EXTRA_ARGS}

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-$DVD_ISOTYPE.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR="dvd-iso" \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_NAME" \
    ${ROCKY_EXTRA_ARGS}

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-$DVD_ISOTYPE.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR=package-set \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_NAME" \
    ${ROCKY_EXTRA_ARGS}

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-minimal.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR=minimal-iso \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_NAME" \
    ${ROCKY_EXTRA_ARGS}

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-boot.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR=boot-iso \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_NAME" \
    ${ROCKY_EXTRA_ARGS}
