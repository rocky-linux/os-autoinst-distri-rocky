#!/bin/bash
set -e

MAJOR_VERSION=9
MINOR_VERSION=0

ROCKY_VERSION="$MAJOR_VERSION.$MINOR_VERSION"
ROCKY_ARCH="${ROCKY_ARCH:=x86_64}"
ROCKY_EXTRA_ARGS="${ROCKY_EXTRA_ARGS:-}"
BUILD_PREFIX="-$(date +%Y%m%d.%H%M%S).0-$(git branch --show-current)"
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
    BUILD="$BUILD_PREFIX-universal-$ROCKY_VERSION" \
    "${ROCKY_EXTRA_ARGS}"

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-$DVD_ISOTYPE.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR="dvd-iso" \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_PREFIX-dvd-$ROCKY_VERSION" \
    "${ROCKY_EXTRA_ARGS}"

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-$DVD_ISOTYPE.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR=package-set \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_PREFIX-packageset-$ROCKY_VERSION" \
    "${ROCKY_EXTRA_ARGS}"

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-minimal.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR=minimal-iso \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_PREFIX-minimal-$ROCKY_VERSION" \
    "${ROCKY_EXTRA_ARGS}"

openqa-cli api \
    -X POST isos \
    ISO="$ISO_PREFIX-boot.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR=boot-iso \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_PREFIX-boot-$ROCKY_VERSION" \
    "${ROCKY_EXTRA_ARGS}"
