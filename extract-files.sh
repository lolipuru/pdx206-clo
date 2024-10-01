#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=pdx206
VENDOR=sony

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

export TARGET_ENABLE_CHECKELF=true

# If XML files don't have comments before the XML header, use this flag
# Can still be used with broken XML files by using blob_fixup
export TARGET_DISABLE_XML_FIXING=true

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    vendor/lib64/vendor.somc.camera*)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
        ;;
    vendor/lib64/vendor.semc.hardware.extlight-V1-ndk_platform.so)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --replace-needed "android.hardware.light-V1-ndk_platform.so" "android.hardware.light-V1-ndk.so" "${2}"
        ;;
    vendor/bin/hw/vendor.somc.hardware.camera.*)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        "${PATCHELF}" --remove-needed "libbinder.so" "${2}"
        "${PATCHELF}" --add-needed "libbinder-v32.so" "${2}"
        ;;
    vendor/lib/libiVptApi.so | vendor/lib64/libiVptApi.so)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --add-needed "libiVptLibC.so" "${2}"
        ;;
    vendor/lib/libiVptLibC.so | vendor/lib64/libiVptLibC.so | vendor/lib/libHpEqApi.so | vendor/lib64/libHpEqApi.so)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --add-needed "libcrypto.so" "${2}"
        "${PATCHELF}" --add-needed "libiVptHkiDec.so" "${2}"
        ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
