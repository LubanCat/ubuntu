#!/bin/bash -e

if [ "$ARCH" == "armhf" ]; then
	ARCH='armhf'
elif [ "$ARCH" == "arm64" ]; then
	ARCH='arm64'
else
    echo -e "[ please input the os type,armhf or arm64...... ]"
fi

TARGET_ROOTFS_DIR="binary"

sudo rm -rf binary/

if [ ! -d $TARGET_ROOTFS_DIR ] ; then
    sudo mkdir -p $TARGET_ROOTFS_DIR

    if [ ! -e ubuntu-base-20.04.5-base-$ARCH.tar.gz ]; then
        echo "\033[36m wget ubuntu-base-20.04-base-x.tar.gz \033[0m"
        wget -c http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.5-base-$ARCH.tar.gz
    fi
    sudo tar -xzf ubuntu-base-20.04.5-base-$ARCH.tar.gz -C $TARGET_ROOTFS_DIR/
    sudo cp sources.list $TARGET_ROOTFS_DIR/etc/apt/sources.list
    sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf

    if [ "$ARCH" == "armhf" ]; then
	    sudo cp -b /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
    elif [ "$ARCH" == "arm64"  ]; then
	    sudo cp -b /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
    fi
fi


finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/

echo "export LC_ALL=C" >> ~/.bashrc
source ~/.bashrc

export APT_INSTALL="apt-get install -fy --allow-downgrades"

apt-get -y update
apt-get -f -y upgrade

##############   gnome  ###############
# DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop-minimal rsyslog sudo dialog apt-utils ntp evtest onboard

##############   xfce4  ###############
DEBIAN_FRONTEND=noninteractive apt install -y xubuntu-core onboard rsyslog sudo dialog apt-utils ntp evtest udev
mv /var/lib/dpkg/info/ /var/lib/dpkg/info_old/
mkdir /var/lib/dpkg/info/
apt-get update
DEBIAN_FRONTEND=noninteractive apt install -y xubuntu-core onboard rsyslog sudo dialog apt-utils ntp evtest udev
mv /var/lib/dpkg/info_old/* /var/lib/dpkg/info/

# apt install -y language-pack-zh-han* language-pack-en $(check-language-support) ibus-libpinyin language-pack-gnome-zh-hans gnome-getting-started-docs-zh-hk

apt install -y net-tools openssh-server ifupdown alsa-utils ntp \
                network-manager gdb inetutils-ping python libssl-dev \
                vsftpd tcpdump can-utils i2c-tools strace vim iperf3 \
                ethtool netplan.io acpid toilet htop pciutils usbutils \
                whiptail curl gnupg mpv

\${APT_INSTALL} ttf-wqy-zenhei xfonts-intl-chinese

HOST=lubancat

# Create User
useradd -G sudo -m -s /bin/bash cat
passwd cat <<IEOF
temppwd
temppwd
IEOF
gpasswd -a cat video
gpasswd -a cat audio
passwd root <<IEOF
root
root
IEOF

# allow root login
sed -i '/pam_securetty.so/s/^/# /g' /etc/pam.d/login

# hostname
echo lubancat > /etc/hostname

# set localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# workaround 90s delay
services=(NetworkManager systemd-networkd)
for service in ${services[@]}; do
  systemctl mask ${service}-wait-online.service
done

# disbale the wire/nl80211
systemctl mask wpa_supplicant-wired@
systemctl mask wpa_supplicant-nl80211@
systemctl mask wpa_supplicant@

# Make systemd less spammy

sed -i 's/#LogLevel=info/LogLevel=warning/' \
  /etc/systemd/system.conf

sed -i 's/#LogTarget=journal-or-kmsg/LogTarget=journal/' \
  /etc/systemd/system.conf

# check to make sure sudoers file has ref for the sudo group
SUDOEXISTS="$(awk '$1 == "%sudo" { print $1 }' /etc/sudoers)"
if [ -z "$SUDOEXISTS" ]; then
  # append sudo entry to sudoers
  echo "# Members of the sudo group may gain root privileges" >> /etc/sudoers
  echo "%sudo	ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# make sure that NOPASSWD is set for %sudo
# expecially in the case that we didn't add it to /etc/sudoers
# just blow the %sudo line away and force it to be NOPASSWD
sed -i -e '
/\%sudo/ c \
%sudo    ALL=(ALL) NOPASSWD: ALL
' /etc/sudoers

apt-get clean
rm -rf /var/lib/apt/lists/*

sync

EOF

sudo umount $TARGET_ROOTFS_DIR/dev

DATE=$(date +%Y%m%d)
echo -e "[ Run tar pack ubuntu-base-desktop-$ARCH-$DATE.tar.gz ]"
sudo tar zcf ubuntu-base-desktop-$ARCH-$DATE.tar.gz $TARGET_ROOTFS_DIR

# sudo rm $TARGET_ROOTFS_DIR -r

echo -e "normal exit"
