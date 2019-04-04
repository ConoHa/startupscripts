#!/bin/bash

readonly EXT_STORAGE_DEV="/dev/vdb"
readonly MOUNT_POINT="$MOUNT_POINT"

if [ ! -e "${EXT_STORAGE_DEV}" ]; then
    logger -t "SampleStartupScript" "External storage device is not found"
    exit 1
fi

if [ ! -e  "${MOUNT_POINT}" ]; then
    mkdir -p ${MOUNT_POINT}
fi

if [ ! -d "${MOUNT_POINT}" ]; then
    logger -t "SampleStartupScript" "Mount point is not a directory."
    exit 1
fi

parted ${EXT_STORAGE_DEV} -s 'mktable gpt'
parted ${EXT_STORAGE_DEV} -s 'mkpart primary 0 -1'

sleep 5

mkfs.ext4 ${EXT_STORAGE_DEV}1

echo "${EXT_STORAGE_DEV}1  ${MOUNT_POINT}  ext4  noatime  0 1" >> /etc/fstab

mount ${EXT_STORAGE_DEV}1 ${MOUNT_POINT}
