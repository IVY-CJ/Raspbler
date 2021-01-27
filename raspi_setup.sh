#!/bin/bash
#
# Automatic setup script for Raspberry  Pi devices
#

#----------------#
#-- Variables  --#
#----------------#
MOUNT_DIR="/mnt"
PI_IMAGE_PATH="" # Insert image path
SD_NAME="mmcblk0"
SD_PATH="/dev/${SD_NAME}"

# Usually no need to change
SD_PARTITIONS="p1 p2"

function abnormal_exit(){
    echo "Raspberry Pi script ran into an error."
    exit 1
}

read -p "Please enter system hostname: " SYS_NAME

if [ -z SYS_NAME ]; then
    echo "Please input a hostname for the system"
    abnormal_exit
else
    echo "System with hostname: ${SYS_NAME}, will be flashed"
fi

for i in ${SD_PARTITIONS}; do
    if [ ! -d "${MOUNT_DIR}/${i}" ]; then
        echo "Creating directory ${MOUNT_DIR}/${i}"
        sudo mkdir "${MOUNT_DIR}/${i}"
    fi
done

if ls /dev | grep -q "^${SD_NAME}$"; then
    if [ -f ${PI_IMAGE_PATH} ]; then
        echo "Flashing file onto SD Card"
        sudo dd bs=4M if=${PI_IMAGE_PATH} of=${SD_PATH} conv=fsync status=progress
        sleep 2
    else
        abnormal_exit
    fi
fi

for i in ${SD_PARTITIONS}; do
    if ls /dev | grep -q "^${SD_NAME}${i}$"; then
        echo "Mounting device /dev/${SD_NAME}${i} on to ${MOUNT_DIR}/${i}"
        sudo mount "/dev/${SD_NAME}${i}" "${MOUNT_DIR}/${i}" || abnormal_exit
    else
        abnormal_exit
    fi
done

echo "Setting headless SSH file"
sudo touch "${MOUNT_DIR}/p1/ssh"

if [ ! -f "${MOUNT_DIR}/p1/ssh" ]; then
    echo "SSH file could not be created"
    abnormal_exit
fi

echo "Changing system hostname raspberrypi to ${SYS_NAME}"
for file in hostname hosts; do
    if [ -f ${MOUNT_DIR}/p2/etc/${file} ]; then
        sudo sed -i "s/raspberrypi/${SYS_NAME}/g" ${MOUNT_DIR}/p2/etc/${file}
    else
        abnormal_exit
    fi
done

echo "Unmounting and removing mnt folders"
for i in ${SD_PARTITIONS}; do
    sudo umount "${MOUNT_DIR}/${i}"
    sudo rmdir "${MOUNT_DIR}/${i}"
done