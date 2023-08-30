#!/bin/bash -e
### BEGIN INIT INFO
# Provides:          rockchip
# Required-Start:
# Required-Stop:
# Default-Start:
# Default-Stop:
# Short-Description:
# Description:       Setup rockchip platform environment
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

install_packages() {
    case $1 in
        rk3288)
		MALI=midgard-t76x-r18p0-r0p0
		ISP=rkisp
		# 3288w
		cat /sys/devices/platform/*gpu/gpuinfo | grep -q r1p0 && \
		MALI=midgard-t76x-r18p0-r1p0
		;;
        rk3399|rk3399pro)
		MALI=midgard-t86x-r18p0
		ISP=rkisp
		;;
        rk3328)
		MALI=utgard-450
		ISP=rkisp
		;;
        rk3326|px30)
		MALI=bifrost-g31-g2p0
		ISP=rkisp
		;;
        rk3128|rk3036)
		MALI=utgard-400
		ISP=rkisp
		;;
        rk3568|rk3566)
		MALI=bifrost-g52-g13p0
		ISP=rkaiq_rk3568
		[ -e /usr/lib/aarch64-linux-gnu/ ] && tar xvf /rknpu2-*.tar -C /
		;;
        rk3588|rk3588s)
		ISP=rkaiq_rk3588
		MALI=valhall-g610-g13p0
		[ -e /usr/lib/aarch64-linux-gnu/ ] && tar xvf /rknpu2-*.tar -C /
		;;
    esac
}

function update_npu_fw() {
    /usr/bin/npu-image.sh
    sleep 1
    /usr/bin/npu_transfer_proxy&
}

COMPATIBLE=$(cat /proc/device-tree/compatible)
if [[ $COMPATIBLE =~ "rk3288" ]];
then
    CHIPNAME="rk3288"
elif [[ $COMPATIBLE =~ "rk3328" ]]; then
    CHIPNAME="rk3328"
elif [[ $COMPATIBLE =~ "rk3399" && $COMPATIBLE =~ "rk3399pro" ]]; then
    CHIPNAME="rk3399pro"
    update_npu_fw
elif [[ $COMPATIBLE =~ "rk3399" ]]; then
    CHIPNAME="rk3399"
elif [[ $COMPATIBLE =~ "rk3326" ]]; then
    CHIPNAME="rk3326"
elif [[ $COMPATIBLE =~ "px30" ]]; then
    CHIPNAME="px30"
elif [[ $COMPATIBLE =~ "rk3128" ]]; then
    CHIPNAME="rk3128"
elif [[ $COMPATIBLE =~ "rk3566" ]]; then
    CHIPNAME="rk3566"
elif [[ $COMPATIBLE =~ "rk3568" ]]; then
    CHIPNAME="rk3568"
elif [[ $COMPATIBLE =~ "rk3588" ]]; then
    CHIPNAME="rk3588"
else
    CHIPNAME="rk3036"
fi
COMPATIBLE=${COMPATIBLE#rockchip,}

/etc/init.d/boot_init.sh

sleep 3s

# first boot configure
if [ ! -e "/usr/local/first_boot_flag" ] ;
then
    echo "It's the first time booting."
    echo "The rootfs will be configured."

    Mem_Size=$(free -m | grep Mem | awk '{print $2}')
    if [ '1500' -gt $Mem_Size  ] ;
    then
        echo 'Mem_Size =' $Mem_Size 'MB , make swap memory '
        swapoff -a
        dd if=/dev/zero of=/var/swapfile bs=1M count=1024
        mkswap /var/swapfile
        swapon /var/swapfile
        echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    # Force rootfs synced
    mount -o remount,sync /

    install_packages ${CHIPNAME}

    if [ -e /usr/bin/gst-launch-1.0 ]; then
        setcap CAP_SYS_ADMIN+ep /usr/bin/gst-launch-1.0

        # Cannot open pixbuf loader module file
        if [ -e "/usr/lib/arm-linux-gnueabihf" ] ; then
            /usr/lib/arm-linux-gnueabihf/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders > /usr/lib/arm-linux-gnueabihf/gdk-pixbuf-2.0/2.10.0/loaders.cache
            update-mime-database /usr/share/mime/
        elif [ -e "/usr/lib/aarch64-linux-gnu" ]; then
            /usr/lib/aarch64-linux-gnu/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders > /usr/lib/aarch64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders.cache
        fi
    fi

    if [ -e "/dev/rfkill" ] ; then
       rm /dev/rfkill
    fi

    rm -rf /*.deb
    rm -rf /*.tar

    # The base target does not come with lightdm/rkaiq_3A
    if [ -e /etc/gdm3/daemon.conf ]; then
        systemctl restart gdm3.service || true
    elif [ -e /etc/lightdm/lightdm.conf ]; then
        systemctl restart lightdm.service || true
    fi

    systemctl restart rkaiq_3A.service || true
    touch /usr/local/first_boot_flag
fi

#usb configfs reset
/usr/bin/usbdevice restart

# support power management
if [ -e "/usr/sbin/pm-suspend" -a -e /etc/Powermanager ] ;
then
    mv /etc/Powermanager/power-key.sh /usr/bin/
    mv /etc/Powermanager/power-key.conf /etc/triggerhappy/triggers.d/
    if [[ "$CHIPNAME" == "rk3399pro" ]];
    then
        mv /etc/Powermanager/01npu /usr/lib/pm-utils/sleep.d/
        mv /etc/Powermanager/02npu /lib/systemd/system-sleep/
    fi
    mv /etc/Powermanager/triggerhappy /etc/init.d/triggerhappy

    rm /etc/Powermanager -rf
    service triggerhappy restart
fi

# Create dummy video node for chromium V4L2 VDA/VEA with rkmpp plugin
echo dec > /dev/video-dec0
echo enc > /dev/video-enc0
chmod 660 /dev/video-*
chown root:video /dev/video-*

# The chromium using fixed pathes for libv4l2.so
ln -rsf /usr/lib/*/libv4l2.so /usr/lib/
[ -e /usr/lib/aarch64-linux-gnu/ ] && ln -Tsf lib /usr/lib64

# sync system time
hwclock --systohc
