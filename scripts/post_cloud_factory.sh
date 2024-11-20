#!/usr/bin/env bash

set -x

ARCHES=("x86_64")
VERSIONS=("8.10" "9.5")
IMAGE_URL_BASE="https://dl.rockylinux.org/pub/rocky"
FACTORY_HDD_FIXED_DIR=/var/tmp/openqa/share/factory/hdd/fixed

get_latest_image() {
  curl -s "${IMAGE_URL_BASE}/${1}/images/${2}/" | \
    sed 's/"/ /g' | \
    grep -E "Rocky-${1}-*${3}\.latest\." | \
    grep -v CHECKSUM | \
    awk '{printf("%s\n",$3)}' | \
    sort -k1,1Vr | \
    head -n 1 | \
    grep -E "^Rocky-${1}-" | \
    awk '{print $1}'
}

for arch in "${ARCHES[@]}";
do
  for version in "${VERSIONS[@]}";
  do
    # Using the same BUILD message for all test suites will group all jobs into a single item
    build_msg="$(date +%Y%m%d)-Rocky-${version}-GenericCloud-${arch}.0"
    version_major=$(printf "%s\n" "${version}" | cut -d\. -f1)

    # GenericCloud and GenericCloud-Base are identical
    for image_class in "GenericCloud-Base" "GenericCloud-LVM";
    do
      latest_image=$(get_latest_image "${version_major}" "${arch}" "${image_class}")
      test -f "${FACTORY_HDD_FIXED_DIR}/${latest_image}" || \
          (cd "${FACTORY_HDD_FIXED_DIR}" || exit; curl -LOR "${IMAGE_URL_BASE}/${version_major}/images/${arch}/${latest_image}")

      flavor=$(printf "%s\n" "${image_class}" | tr '-' '_')
      openqa-cli api -X POST isos \
        HDD_2="${latest_image}" \
        ARCH="${arch}" \
        DISTRI=rocky \
        DESKTOP=false \
        FLAVOR="${flavor}-qcow2-qcow2" \
        VERSION="${version}" \
        CURRREL="${version_major}" \
        USER_LOGIN=rocky \
        USER_PASSWORD=weakpassword \
        BUILD="${build_msg}" "$@"
    done
  done
done
