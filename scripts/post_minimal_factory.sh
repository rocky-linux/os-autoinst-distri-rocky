#!/usr/bin/env bash

set -x

ARCHES=("x86_64" "aarch64")
VERSIONS=("8.10" "9.5")
ISO_URL_BASE="https://download.rockylinux.org/pub/rocky"
FACTORY_ISO_FIXED_DIR=/var/tmp/openqa/share/factory/iso/fixed

get_latest_iso() {
  curl -s "${ISO_URL_BASE}/${1}/isos/${2}/" | \
    sed 's/"/ /g' | \
    grep "${3}.iso" | \
    grep -Ev "CHECKSUM|manifest|torrent" | \
    awk '{printf("%s %s-%s\n",$3,$5,$6)}' | \
    grep "${1}-${2}-${3}" | \
    sort -k1,1V -k2,2dr | \
    head -n 1 | \
    grep -E "^Rocky-${1}" | \
    awk '{print $1}'
}

for arch in "${ARCHES[@]}";
do
  for version in "${VERSIONS[@]}";
  do
    # Using the same BUILD message for all test suites will group all jobs into a single item
    build_msg="$(date +%Y%m%d)-Rocky-${version}-${arch}.0"
    version_major=$(printf "%s\n" "${version}" | cut -d\. -f1)

    flavor="minimal"
    latest_iso=$(get_latest_iso "${version}" "${arch}" "${flavor}")
    test -f "${FACTORY_ISO_FIXED_DIR}/${latest_iso}" || \
        (cd "${FACTORY_ISO_FIXED_DIR}" || exit; curl -LOR "${ISO_URL_BASE}/${version_major}/isos/${arch}/${latest_iso}")

    if [ "${version_major}" == "8" ]; then
      openqa-cli api -X POST isos \
          ISO="${latest_iso}" \
          ARCH="${arch}" \
          DISTRI=rocky \
          FLAVOR="${flavor}-iso" \
          VERSION="${version}" \
          CURRREL="${version_major}" \
          GRUB="ip=dhcp" \
          BUILD="${build_msg}"  \
          TESTS=install_default "$@"
    else
      openqa-cli api -X POST isos \
          ISO="${latest_iso}" \
          ARCH="${arch}" \
          DISTRI=rocky \
          FLAVOR="${flavor}-iso" \
          VERSION="${version}" \
          CURRREL="${version_major}" \
          BUILD="${build_msg}" \
          TESTS=install_default "$@"
    fi
  done
done
