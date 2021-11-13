#!/bin/bash
set -e

ROCKY_FLAVOR=$1
ROCKY_VERSION=8.5
ROCKY_ARCH=x86_64
ROCKY_PACKAGE_SET=minimal
BUILD_PREFIX="${ROCKY_VERSION}_${ROCKY_FLAVOR}"
BUILD_NAME="${BUILD_PREFIX}_$(date +%Y%m%d.%H%M%S).0"

if [[ "$ROCKY_FLAVOR" == "dvd-iso" || "$ROCKY_FLAVOR" == "universal" ]]; then
    ISO_TYPE=dvd1
elif [[ "$ROCKY_FLAVOR" == "minimal-iso" ]]; then
    ISO_TYPE=minimal
elif [[ "$ROCKY_FLAVOR" == "boot-iso" ]]; then
    ISO_TYPE=boot
else
    echo "Usage: $0 [universal|dvd-iso|minimal-iso|boot-iso]"
    exit 1
fi

set -o xtrace
openqa-cli api \
    -X POST isos \
    ISO="Rocky-$ROCKY_VERSION-$ROCKY_ARCH-$ISO_TYPE.iso" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR="$ROCKY_FLAVOR" \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_NAME" \
    PACKAGE_SET="$ROCKY_PACKAGE_SET" \
    IDENTIFICATION=false
