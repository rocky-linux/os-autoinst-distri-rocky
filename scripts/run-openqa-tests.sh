#!/bin/bash
set -e

## Usage: Post an ISO for the specified FLAVOR. Defaults to boot-iso.
#
## Run the boot-iso FLAVOR
# scripts/run-openqa-tests.sh
#
## Run the package-set FLAVOR
# ROCKY_FLAVOR=package-set scripts/run-openqa-tests.sh
#
## Run the localization test suites
# ROCKY_FLAVOR ROCKY_EXTRA_ARGS=TEST=install_arabic_language,install_asian_language,install_european_language,install_cyrillic_language scripts/run-openqa-tests.sh

ROCKY_VERSION="9.2"

MAJOR_VERSION=${ROCKY_VERSION:0:1}
MINOR_VERSION=${ROCKY_VERSION:2:1}
ROCKY_FLAVOR="${ROCKY_FLAVOR:-boot-iso}"
ROCKY_ARCH="${ROCKY_ARCH:=x86_64}"
ROCKY_EXTRA_ARGS="${ROCKY_EXTRA_ARGS:-}"
BUILD_NAME="-$(date +%Y%m%d).0-$(git branch --show-current)-$ROCKY_VERSION"
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
