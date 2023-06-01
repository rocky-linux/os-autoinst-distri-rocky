#!/bin/bash

set -x

ARCHES=(x86_64)
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
  for version in "9.2" "8.8";
  do
    # Using the same BUILD message for all test suites will group all jobs into a single item
    build_msg="$(date +%Y%m%d)-Rocky-${version}-${arch}.0"

    for media in boot minimal;
    do
      latest_iso=$(get_latest_iso "${version}" "${arch}" "${media}")
      test -f "${FACTORY_ISO_FIXED_DIR}/${latest_iso}" || \
          (cd "${FACTORY_ISO_FIXED_DIR}" || exit; curl -LOR "${ISO_URL_BASE}/${version:0:1}/isos/${arch}/${latest_iso}")
      openqa-cli api -X POST isos \
        ISO="${latest_iso}" \
        ARCH="${arch}" \
        DISTRI=rocky \
        FLAVOR="${media}-iso" \
        VERSION="${version}" \
        CURRREL="${version:0:1}" \
        BUILD="${build_msg}"
    done

    case ${version:0:1} in
      8)
        media=dvd1
        ;;
      *)
        media=dvd
        ;;
    esac

    # Flavor dvd-iso, univeral and package-set are with DVD ISO media
    for flavor in "dvd-iso" universal "package-set";
    do
      latest_iso=$(get_latest_iso "${version}" "${arch}" "${media}")
      test -f "${FACTORY_ISO_FIXED_DIR}/${latest_iso}" || \
          (cd "${FACTORY_ISO_FIXED_DIR}" || exit; curl -LOR "${ISO_URL_BASE}/${version:0:1}/isos/${arch}/${latest_iso}")
      case ${flavor} in
        universal)
          # universal will boot with DVD ISO but perform a network install from LOCATION
          # NOTE: In Rocky 8 there may be network available on boot issue
          openqa-cli api -X POST isos \
            ISO="${latest_iso}" \
            ARCH="${arch}" \
            DISTRI=rocky \
            FLAVOR="${flavor}" \
            LOCATION="${ISO_URL_BASE}/${version}/BaseOS" \
            NICTYPE_USER_OPTIONS="net=172.16.2.0/24" \
            QEMU_HOST_IP="172.16.2.2" \
            VERSION="${version}" \
            CURRREL="${version:0:1}" \
            BUILD="${build_msg}"
          ;;
        dvd-iso)
          # dvd-iso FLAVOR needs NIC_TYPE_USER_OPTIONS and QEMU_HOST_IP for multi-worker tests
          # and LOCATION for various repository variations and support_server
          openqa-cli api -X POST isos \
            ISO="${latest_iso}" \
            ARCH="${arch}" \
            DISTRI=rocky \
            FLAVOR="${flavor}" \
            LOCATION="${ISO_URL_BASE}/${version}/BaseOS" \
            NICTYPE_USER_OPTIONS="net=172.16.2.0/24" \
            QEMU_HOST_IP="172.16.2.2" \
            VERSION="${version}" \
            CURRREL="${version:0:1}" \
            BUILD="${build_msg}"
          ;;
        package-set)
          # package-set FLAVOR is media only
          openqa-cli api -X POST isos \
            ISO="${latest_iso}" \
            ARCH="${arch}" \
            DISTRI=rocky \
            FLAVOR="${flavor}" \
            VERSION="${version}" \
            CURRREL="${version:0:1}" \
            BUILD="${build_msg}"
          ;;
        *)
          ;;
        esac
    done
  done
done
