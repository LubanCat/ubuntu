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

如果需要构建lite版本（控制台版，无桌面），执行1.a、2.a、3。

如果需要构建desktop版本（带桌面），执行1.b、2.b、3。

```
# 1.a 构建 lite 版本基础镜像
ARCH=arm64 ./mk-base-lite-ubuntu.sh

# 1.b 构建 desktop 版本基础镜像
ARCH=arm64  ./mk-base-desktop-ubuntu.sh

# 添加 rk overlay 层
# 2.a
VERSION=debug ARCH=arm64 ./mk-lite-rootfs.sh
# 2.b SOC参数根据实际情况选择，如rk356x、rk3588
VERSION=debug ARCH=arm64 SOC=rk356x ./mk-desktop-rootfs.sh

# 3 打包ubuntu-rootfs镜像
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
