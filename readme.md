## Introduction

A set of shell scripts that will build GNU/Linux distribution rootfs image
for rockchip platform.

## Available Distro

* ubuntu 22.04 (Jammy-X11)

```
sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f
```

## Usage for 32bit ubuntu 22.04

```
ARCH=armhf RELEASE=jammy ./mk-base-ubuntu.sh
VERSION=debug ARCH=armhf ./mk-rootfs-jammy.sh
./mk-image.sh
```

## Usage for 64bit ubuntu 22.04

```
ARCH=arm64 RELEASE=jammy ./mk-base-ubuntu.sh
VERSION=debug ARCH=arm64 ./mk-rootfs-jammy.sh
./mk-image.sh
```

## Cross Compile for ARM Debian

[Docker + Multiarch](http://opensource.rock-chips.com/wiki_Cross_Compile#Docker)

## History

- Focal/20.04 with Gnome X11 working on rk3588

- GPU/RGA hardware accelerated for graphic display

- With gdm3 serivce and autologin

- QT+Gstreamer and MPV+ffmpeg video encode/decode working

- Add rockchip-test for stressing tests
