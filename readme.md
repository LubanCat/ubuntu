## Introduction

A set of shell scripts that will build GNU/Linux distribution rootfs image
for rockchip platform.

## Available Distro

* ubuntu 18.04 (Bionic-X11)

```
# 安装编译依赖的软件包
sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f
```

## Usage for 64bit ubuntu 18.04

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
# 2.b
VERSION=debug ARCH=arm64 ./mk-desktop-rootfs.sh

# 3 打包ubuntu-rootfs镜像
./mk-image.sh
```
