#!/bin/bash -e

TARGET_ROOTFS_DIR=./binary

if [ $RK_ROOTFS_IMAGE ]; then
	ROOTFSIMAGE=$RK_ROOTFS_IMAGE
else
	ROOTFSIMAGE=ubuntu-$TARGET-rootfs.img
fi

echo Making rootfs!

if [ -e ${ROOTFSIMAGE} ]; then
	rm ${ROOTFSIMAGE}
fi

# for script in ./post-build.sh ../device/rockchip/common/post-build.sh; do
# 	[ -x $script ] || continue
# 	sudo $script "$(realpath "$TARGET_ROOTFS_DIR")"
# done

sudo ./add-build-info.sh ${TARGET_ROOTFS_DIR}

# Apparent size + maxium alignment(file_count * block_size) + maxium journal size
IMAGE_SIZE_MB=$(( $(sudo du --apparent-size -sm ${TARGET_ROOTFS_DIR} | cut -f1) + $(sudo find ${TARGET_ROOTFS_DIR} | wc -l) * 4 / 1024 + 64 ))

# Extra 10%
IMAGE_SIZE_MB=$(( $IMAGE_SIZE_MB * 110 / 100 ))

sudo mkfs.ext4 -d ${TARGET_ROOTFS_DIR} ${ROOTFSIMAGE} ${IMAGE_SIZE_MB}M

echo Rootfs Image: ${ROOTFSIMAGE}
