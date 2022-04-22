#!/bin/bash -e

if [ "$ARCH" == "armhf" ]; then
	ARCH='armhf'
elif [ "$ARCH" == "arm64" ]; then
	ARCH='arm64'
else
    echo -e "\033[36m please input the os type,armhf or arm64...... \033[0m"
fi

VERSION="debug"
TARGET_ROOTFS_DIR="binary"

if [ -e ubuntu-$RELEASE-base-*.tar.gz ]; then
	rm ubuntu-$RELEASE-base-*.tar.gz
fi

if [ ! -d $TARGET_ROOTFS_DIR ] ; then
    sudo mkdir -p $TARGET_ROOTFS_DIR

    if [ ! -e ubuntu-base-22.04-beta-base-$ARCH.tar.gz ]; then
        echo "\033[36m wget ubuntu-base-22.04-beta-base-x.tar.gz \033[0m"
        wget -c http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-$ARCH.tar.gz
    fi
    sudo tar -xzvf ubuntu-base-22.04-base-$ARCH.tar.gz -C $TARGET_ROOTFS_DIR/
    sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
#    sudo sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' $TARGET_ROOTFS_DIR/etc/apt/sources.list
#    sudo cp -b sources.list $TARGET_ROOTFS_DIR/etc/apt/
    if [ "$ARCH" == "armhf" ]; then
	    sudo cp -b /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
    elif [ "$ARCH" == "arm64"  ]; then
	    sudo cp -b /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
    fi

fi

finish() {
    ./ch-mount.sh -u $TARGET_ROOTFS_DIR
    echo -e "error exit"
    exit -1
}
trap finish ERR

echo "\033[36m Change root.....................\033[0m"

./ch-mount.sh -m $TARGET_ROOTFS_DIR

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/

export APT_INSTALL="apt-get install -fy --allow-downgrades"

apt-get -y update
apt-get -f -y upgrade

DEBIAN_FRONTEND=noninteractive apt install -y gnome-session gdm3 ubuntu-desktop
apt install -y rsyslog wget gdb net-tools inetutils-ping openssh-server ifupdown alsa-utils python vim ntp git libssl-dev vsftpd tcpdump can-utils i2c-tools strace network-manager onboard evtest
apt install -y language-pack-zh-han* language-pack-en $(check-language-support) ibus-libpinyin language-pack-gnome-zh-hans gnome-getting-started-docs-zh-hk
apt install -y blueman
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
apt install -y blueman
rm -f /usr/sbin/policy-rc.d

HOST=ubuntu

# Create User
useradd -G sudo -m -s /bin/bash ubuntu
passwd ubuntu <<IEOF
ubuntu
ubuntu
IEOF
gpasswd -a ubuntu video
gpasswd -a ubuntu audio
passwd root <<IEOF
root
root
IEOF

# Enable lightdm autologin for linaro user
if [ -e /etc/gdm3/custom.conf ]; then
  sed -i "s|^#AutomaticLogin=.*|AutomaticLogin=ubuntu|" /etc/gdm3/custom.conf
  sed -i "s|^#AutomaticLoginEnable=.*|AutomaticLoginEnable=true|" /etc/gdm3/custom.conf
fi

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
%sudo	ALL=(ALL) NOPASSWD: ALL
' /etc/sudoers

sync

EOF

./ch-mount.sh -u $TARGET_ROOTFS_DIR

sudo tar zcvf ubuntu-$RELEASE-base-$ARCH.tar.gz $TARGET_ROOTFS_DIR

sudo rm $TARGET_ROOTFS_DIR -r

echo -e "normal exit"
