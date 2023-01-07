#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

if [ ! $SOC ]; then
	SOC="rk3568"
fi

install_packages() {
    case $SOC in
        rk3399|rk3399pro)
		MALI=midgard-t86x-r18p0
		ISP=rkisp
		RGA=rga
		;;
        rk3328)
		MALI=utgard-450
		ISP=rkisp
		RGA=rga
		;;
        rk356x|rk3566|rk3568)
		MALI=bifrost-g52-g2p0
		ISP=rkaiq_rk3568
		RGA=rga
		;;
        rk3588|rk3588s)
		ISP=rkaiq_rk3588
		MALI=valhall-g610-g6p0
		RGA=rga2
		;;
    esac
}

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

#GPU/RGA/CAMERA packages folder
install_packages
sudo mkdir -p $TARGET_ROOTFS_DIR/packages/install_packages
sudo cp -rpf packages/$ARCH/libmali/libmali-*$MALI*-x11*.deb $TARGET_ROOTFS_DIR/packages/install_packages
sudo cp -rpf packages/$ARCH/camera_engine/camera_engine_$ISP*.deb $TARGET_ROOTFS_DIR/packages/install_packages
sudo cp -rpf packages/$ARCH/$RGA/*.deb $TARGET_ROOTFS_DIR/packages/install_packages

# overlay folder
sudo cp -rpf overlay/* $TARGET_ROOTFS_DIR/

# overlay-firmware folder
sudo cp -rpf overlay-firmware/* $TARGET_ROOTFS_DIR/

# overlay-debug folder
# adb, video, camera  test file
if [ "$VERSION" == "debug" ]; then
	sudo cp -rf overlay-debug/* $TARGET_ROOTFS_DIR/
fi
## hack the serial
sudo cp -f overlay/usr/lib/systemd/system/serial-getty@.service $TARGET_ROOTFS_DIR/lib/systemd/system/serial-getty@.service

# adb
if [[ "$ARCH" == "armhf" && "$VERSION" == "debug" ]]; then
	sudo cp -f overlay-debug/usr/local/share/adb/adbd-32 $TARGET_ROOTFS_DIR/usr/bin/adbd
elif [[ "$ARCH" == "arm64" && "$VERSION" == "debug" ]]; then
	sudo cp -f overlay-debug/usr/local/share/adb/adbd-64 $TARGET_ROOTFS_DIR/usr/bin/adbd
fi

echo -e "\033[36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
	sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi

sudo cp -f /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

mkdir -p /etc/apt/keyrings
curl -fsSL https://Embedfire.github.io/keyfile | gpg --dearmor -o /etc/apt/keyrings/embedfire.gpg
chmod a+r /etc/apt/keyrings/embedfire.gpg
echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/embedfire.gpg] https://cloud.embedfire.com/mirrors/ebf-debian carp-rk356x main" | tee /etc/apt/sources.list.d/embedfire.list > /dev/null

apt-get update
apt-get upgrade -y

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

export APT_INSTALL="apt-get install -fy --allow-downgrades"

#------------- LubanCat ------------
\apt-get remove -y gnome-bluetooth
\${APT_INSTALL} gdisk parted bluez* blueman fire-config

#Desktop background picture
ln -sf /usr/share/xfce4/backdrops/lubancat-wallpaper.png /usr/share/xfce4/backdrops/xubuntu-wallpaper.png

#---------------power management --------------
\${APT_INSTALL} pm-utils triggerhappy bsdmainutils
cp /etc/Powermanager/triggerhappy.service  /lib/systemd/system/triggerhappy.service

#---------------Rga--------------
\${APT_INSTALL} /packages/rga/*.deb

echo -e "\033[36m Setup Video.................... \033[0m"
\${APT_INSTALL} gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-alsa \
gstreamer1.0-plugins-base-apps qtmultimedia5-examples

\${APT_INSTALL} /packages/mpp/*
\${APT_INSTALL} /packages/gst-rkmpp/*.deb
\${APT_INSTALL} /packages/gstreamer/*.deb
\${APT_INSTALL} /packages/gst-plugins-base1.0/*.deb
# \${APT_INSTALL} /packages/gst-plugins-bad1.0/*.deb
# \${APT_INSTALL} /packages/gst-plugins-good1.0/*.deb

#---------Camera---------
echo -e "\033[36m Install camera.................... \033[0m"
\${APT_INSTALL} cheese v4l-utils
\${APT_INSTALL} /packages/libv4l/*.deb

#---------Xserver---------
echo -e "\033[36m Install Xserver.................... \033[0m"
\${APT_INSTALL} /packages/xserver/*.deb

apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy

#---------update chromium-----
# \${APT_INSTALL} /packages/chromium/*.deb

#------------------libdrm------------
# echo -e "\033[36m Install libdrm.................... \033[0m"
# \${APT_INSTALL} /packages/libdrm/*.deb

#------------------libdrm-cursor------------
echo -e "\033[36m Install libdrm-cursor.................... \033[0m"
\${APT_INSTALL} /packages/libdrm-cursor/*.deb

# Only preload libdrm-cursor for X
sed -i "/libdrm-cursor.so/d" /etc/ld.so.preload
sed -i "1aexport LD_PRELOAD=libdrm-cursor.so.1" /usr/bin/X

# #------------------blueman------------
# echo -e "\033[36m Install blueman.................... \033[0m"
# #\${APT_INSTALL} /packages/blueman/*.deb

# #------------------rkwifibt------------
# echo -e "\033[36m Install rkwifibt.................... \033[0m"
# \${APT_INSTALL} /packages/rkwifibt/*.deb
# ln -s /system/etc/firmware /vendor/etc/

if [ "$VERSION" == "debug" ]; then
#------------------glmark2------------
echo -e "\033[36m Install glmark2.................... \033[0m"
\${APT_INSTALL} glmark2-es2
fi

#------------------rknpu2------------
echo -e "\033[36m Install rknpu2.................... \033[0m"
tar xvf /packages/rknpu2/*.tar -C /

#------------------rktoolkit------------
echo -e "\033[36m Install rktoolkit.................... \033[0m"
\${APT_INSTALL} /packages/rktoolkit/*.deb

# # echo -e "\033[36m Install Chinese fonts.................... \033[0m"
# # # Uncomment zh_CN.UTF-8 for inclusion in generation
# # sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen
# # echo "LANG=zh_CN.UTF-8" >> /etc/default/locale

# # # Generate locale
# # locale-gen

# # # Export env vars
# # echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc
# # echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc
# # echo "export LANGUAGE=zh_CN.UTF-8" >> ~/.bashrc

# # source ~/.bashrc

# # \${APT_INSTALL} ttf-wqy-zenhei fonts-aenigma xfonts-intl-chinese

# #ln -sf /usr/bin/startxfce4 /etc/alternatives/x-session-manager

# # mark package to hold
# apt list --installed | grep -v oldstable | cut -d/ -f1 | xargs apt-mark hold

#------------------ffmpeg------------
echo -e "\033[36m Install ffmpeg .................... \033[0m"
\${APT_INSTALL} ffmpeg
# \${APT_INSTALL} /packages/ffmpeg/*.deb

#------------------mpv------------
echo -e "\033[36m Install mpv .................... \033[0m"
\apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y mpv
# \${APT_INSTALL} /packages/mpv/*.deb

# HACK to disable the kernel logo on bootup
sed -i "/exit 0/i \ echo 3 > /sys/class/graphics/fb0/blank" /etc/rc.local

apt install -fy --allow-downgrades /packages/install_packages/*.deb

#---------------Custom Script--------------
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

#---------------Clean--------------
if [ -e "/usr/lib/arm-linux-gnueabihf/dri" ] ;
then
        cd /usr/lib/arm-linux-gnueabihf/dri/
        cp kms_swrast_dri.so swrast_dri.so /
        rm /usr/lib/arm-linux-gnueabihf/dri/*.so
        mv /*.so /usr/lib/arm-linux-gnueabihf/dri/
elif [ -e "/usr/lib/aarch64-linux-gnu/dri" ];
then
        cd /usr/lib/aarch64-linux-gnu/dri/
        cp kms_swrast_dri.so swrast_dri.so /
        rm /usr/lib/aarch64-linux-gnu/dri/*.so
        mv /*.so /usr/lib/aarch64-linux-gnu/dri/
        rm /etc/profile.d/qt.sh
fi
cd -

#---------------Clean--------------
echo -e "\033[36m  Clean Packages or Cache .................... \033[0m"
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/

EOF

sudo umount $TARGET_ROOTFS_DIR/dev
