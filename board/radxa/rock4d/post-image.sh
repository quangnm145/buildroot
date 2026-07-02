#!/bin/sh

BOARD_DIR="$(dirname "$0")"
BINARIES_DIR="$1"

cp /home/quangnm/workdir/raxda/u-boot/idblock.bin "$BINARIES_DIR/"
cp /home/quangnm/workdir/raxda/u-boot/uboot.img "$BINARIES_DIR/"
