#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

case "${ARCH:-$1}" in
	arm|arm32|armhf)
		ARCH=armhf
		;;
	*)
		ARCH=arm64
		;;
esac

echo -e "\033[36m Building for $ARCH \033[0m"

if [ ! $VERSION ]; then
	VERSION="release"
fi

if [ ! -e ubuntu-base-desktop-$ARCH.tar.gz ]; then
	echo "\033[36m Run mk-base-ubuntu.sh first \033[0m"
	exit -1
fi

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

echo -e "\033[36m Extract image \033[0m"
sudo rm -rf $TARGET_ROOTFS_DIR
sudo tar -xpf ubuntu-base-desktop-$ARCH.tar.gz

# packages folder
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rpf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

# overlay folder
sudo cp -rpf overlay/* $TARGET_ROOTFS_DIR/

# overlay-firmware folder
sudo cp -rpf overlay-firmware/* $TARGET_ROOTFS_DIR/

# overlay-debug folder
# adb, video, camera  test file
if [ "$VERSION" == "debug" ]; then
	sudo cp -rf overlay-debug/* $TARGET_ROOTFS_DIR/
fi

# adb
if [[ "$ARCH" == "armhf" && "$VERSION" == "debug" ]]; then
	sudo cp -f overlay-debug/usr/local/share/adb/adbd-32 $TARGET_ROOTFS_DIR/usr/bin/adbd
elif [[ "$ARCH" == "arm64" && "$VERSION" == "debug" ]]; then
	sudo cp -f overlay-debug/usr/local/share/adb/adbd-64 $TARGET_ROOTFS_DIR/usr/bin/adbd
fi

# bt/wifi firmware
sudo mkdir -p $TARGET_ROOTFS_DIR/system/lib/modules/
sudo mkdir -p $TARGET_ROOTFS_DIR/vendor/etc
sudo find ../kernel/drivers/net/wireless/rockchip_wlan/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} $TARGET_ROOTFS_DIR/system/lib/modules/

echo -e "\033[36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
	sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi

sudo cp -f /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

apt-get update
apt-get install -y dpkg-dev
apt-get upgrade -y

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

export APT_INSTALL="apt-get install -fy --allow-downgrades"

#------------- LubanCat ------------
\${APT_INSTALL} toilet htop pciutils gdisk parted

#---------------Rga--------------
\${APT_INSTALL} /packages/rga/*.deb

echo -e "\033[36m Setup Video.................... \033[0m"
\${APT_INSTALL} gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-plugins-base-apps

\${APT_INSTALL} /packages/mpp/*
\${APT_INSTALL} /packages/gst-rkmpp/*.deb
apt-mark hold gstreamer1.0-x

#---------Camera---------
echo -e "\033[36m Install camera.................... \033[0m"
\${APT_INSTALL} cheese v4l-utils
\${APT_INSTALL} /packages/others/camera/*.deb
if [ "$ARCH" == "armhf" ]; then
       cp /packages/others/camera/libv4l-mplane.so /usr/lib/arm-linux-gnueabihf/libv4l/plugins/
elif [ "$ARCH" == "arm64" ]; then
       cp /packages/others/camera/libv4l-mplane.so /usr/lib/aarch64-linux-gnu/libv4l/plugins/
fi

#---------Xserver---------
echo -e "\033[36m Install Xserver.................... \033[0m"
\${APT_INSTALL} /packages/xserver/*.deb

apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy

#------------------libdrm------------
echo -e "\033[36m Install libdrm.................... \033[0m"
\${APT_INSTALL} /packages/libdrm/*.deb

if [ "$VERSION" == "debug" ]; then
#------------------glmark2------------
echo -e "\033[36m Install glmark2.................... \033[0m"
\${APT_INSTALL} glmark2-es2
fi

#------------------ffmpeg------------
echo -e "\033[36m Install ffmpeg .................... \033[0m"
# \${APT_INSTALL} ffmpeg
\${APT_INSTALL} /packages/ffmpeg/*.deb

#------------------mpv------------
echo -e "\033[36m Install mpv .................... \033[0m"
# \apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y mpv
\${APT_INSTALL} /packages/mpv/*.deb

apt-mark hold libegl-mesa0 libgbm1 libgles1 alsa-utils

# HACK to disable the kernel logo on bootup
sed -i "/exit 0/i \ echo 3 > /sys/class/graphics/fb0/blank" /etc/rc.local

#---------------Custom Script--------------
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

#---------------Clean--------------
echo -e "\033[36m  Clean Packages or Cache .................... \033[0m"
rm -rf /var/lib/apt/lists/*

EOF

sudo umount $TARGET_ROOTFS_DIR/dev
