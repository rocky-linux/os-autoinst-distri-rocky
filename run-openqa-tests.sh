#!/bin/bash

set -e

ROCKY_FLAVOR="${ROCKY_FLAVOR:-boot-iso}"
ROCKY_VERSION="${ROCKY_VERSION:-8.6}"
ROCKY_ARCH="${ROCKY_ARCH:=x86_64}"
ROCKY_PACKAGE_SET="${ROCKY_PACKAGE_SET:=minimal}"
ROCKY_EXTRA_ARGS="${ROCKY_EXTRA_ARGS:-}"
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

export PS4='# '
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
    IDENTIFICATION=false \
    "${ROCKY_EXTRA_ARGS}"
