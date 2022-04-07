## Introduction

A set of shell scripts that will build GNU/Linux distribution rootfs image
for rockchip platform.

## Available Distro

* ubuntu 20.04 (Focal-X11)

```
sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f
```

## Usage for 32bit ubuntu 20.04

```
ARCH=armhf RELEASE=focal ./mk-base-ubuntu.sh
VERSION=debug ARCH=armhf ./mk-rootfs-focal.sh
./mk-image.sh
```

## Usage for 64bit ubuntu 20.04

```
ARCH=arm64 RELEASE=focal ./mk-base-ubuntu.sh
VERSION=debug ARCH=arm64 ./mk-rootfs-focal.sh
./mk-image.sh
```

## Cross Compile for ARM Debian

[Docker + Multiarch](http://opensource.rock-chips.com/wiki_Cross_Compile#Docker)
