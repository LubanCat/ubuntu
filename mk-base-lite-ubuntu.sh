#!/bin/bash -e

if [ "$ARCH" == "armhf" ]; then
	ARCH='armhf'
elif [ "$ARCH" == "arm64" ]; then
	ARCH='arm64'
else
    echo -e "[ please input the os type,armhf or arm64...... ]"
fi

VERSION="debug"
TARGET_ROOTFS_DIR="binary"

sudo rm -rf binary/

if [ ! -d $TARGET_ROOTFS_DIR ] ; then
    sudo mkdir -p $TARGET_ROOTFS_DIR

    if [ ! -e ubuntu-base-18.04.5-base-$ARCH.tar.gz ]; then
        echo "[ wget ubuntu-base-18.04-base-arm64.tar.gz ]"
        wget -c http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.5-base-arm64.tar.gz
    fi
    sudo tar -xzf ubuntu-base-18.04.5-base-$ARCH.tar.gz -C $TARGET_ROOTFS_DIR/
    sudo cp sources.list $TARGET_ROOTFS_DIR/etc/apt/sources.list
    sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf

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

echo "[ Change root.....................]"

./ch-mount.sh -m $TARGET_ROOTFS_DIR

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/

echo "export LC_ALL=C" >> ~/.bashrc
source ~/.bashrc

export APT_INSTALL="apt-get install -fy --allow-downgrades"

apt-get -y update
apt-get -f -y upgrade

DEBIAN_FRONTEND=noninteractive apt install -y sudo ntp apt-utils evtest
	  
apt install -y rsyslog network-manager net-tools inetutils-ping \
    openssh-server libssl-dev vsftpd tcpdump i2c-tools udev netplan.io \
    bash-completion alsa-utils usbutils pciutils toilet bsdmainutils \
    vim iperf3 ethtool toilet htop pciutils

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

./ch-mount.sh -u $TARGET_ROOTFS_DIR

sudo tar zcf ubuntu-base-lite-$ARCH.tar.gz $TARGET_ROOTFS_DIR

sudo rm -rf binary/

echo -e "normal exit"
