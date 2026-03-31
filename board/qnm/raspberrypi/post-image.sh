#!/bin/bash

set -e

echo "=== Running post-image script for Raspberry Pi 4B 64-bit (U-Boot) ==="

BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage-raspberrypi4b_64.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Tạo thư mục tạm
ROOTPATH_TMP="$(mktemp -d)"
trap 'rm -rf "${ROOTPATH_TMP}"' EXIT

rm -rf "${GENIMAGE_TMP}"

echo "Generating SD card image with genimage..."
genimage \
    --rootpath "${ROOTPATH_TMP}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

echo "=== Image generated successfully: ${BINARIES_DIR}/sdcard.img ==="
echo "Flash command: sudo dd if=${BINARIES_DIR}/sdcard.img of=/dev/sdX bs=4M conv=fsync status=progress"
