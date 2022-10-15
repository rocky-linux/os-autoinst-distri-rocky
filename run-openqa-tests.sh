#!/bin/bash
set -e

MAJOR_VERSION=8
MINOR_VERSION=6

ROCKY_FLAVOR="${ROCKY_FLAVOR:-boot-iso}"
ROCKY_VERSION="$MAJOR_VERSION.$MINOR_VERSION"
ROCKY_ARCH="${ROCKY_ARCH:=x86_64}"
ROCKY_EXTRA_ARGS="${ROCKY_EXTRA_ARGS:-}"
BUILD_PREFIX="-$(date +%Y%m%d.%H%M%S).0-$(git branch --show-current)"
BUILD_NAME="$BUILD_PREFIX-$ROCKY_FLAVOR-$ROCKY_VERSION"

ISO_PREFIX="Rocky-$ROCKY_VERSION-$ROCKY_ARCH"

if [[ "$ROCKY_FLAVOR" == "dvd-iso" || "$ROCKY_FLAVOR" == "universal" ]]; then
    if [[ "$MAJOR_VERSION" -gt "8" ]]; then
        ISO_TYPE=dvd
    else
        ISO_TYPE=dvd1
    fi
elif [[ "$ROCKY_FLAVOR" == "minimal-iso" ]]; then
    ISO_TYPE=minimal
elif [[ "$ROCKY_FLAVOR" == "boot-iso" || "$ROCKY_FLAVOR" == "package-set" ]]; then
    # package-set also works with dvd image
    ISO_TYPE=boot
else
    echo "Usage: $0 [universal|dvd-iso|minimal-iso|package-set|boot-iso]"
    exit 1
fi

ROCKY_ISO="$ISO_PREFIX-$ISO_TYPE.iso"

# Update fif templates
./fifloader.py --clean --load templates.fif.json templates-updates.fif.json

# Run the tests
export PS4='# '
set -o xtrace
openqa-cli api \
    -X POST isos \
    ISO="$ROCKY_ISO" \
    ARCH="$ROCKY_ARCH" \
    DISTRI=rocky \
    FLAVOR="$ROCKY_FLAVOR" \
    VERSION="$ROCKY_VERSION" \
    BUILD="$BUILD_NAME" \
    "$ROCKY_EXTRA_ARGS"
