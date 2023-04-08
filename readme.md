## 简介

A set of shell scripts that will build GNU/Linux distribution rootfs image
for rockchip platform.

## 适用板卡

- 使用RK3566处理器的LubanCat板卡
- 使用RK3568处理器的LubanCat板卡
- 使用RK3588处理器的LubanCat板卡

## 安装依赖

* ubuntu 20.04 (Focal-X11)

```
sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f
```

## 构建 Ubuntu20.04镜像（仅支持64bit）

如果需要构建lite版本（控制台版，无桌面），执行1.a、2.a。

如果需要构建desktop版本（带桌面），执行1.b、2.b。

```
######### step 1 #########
# 1.a 构建 lite 版本基础镜像
./mk-base-lite-ubuntu.sh

# 1.b 构建 desktop 版本基础镜像（默认xfce）
./mk-base-desktop-ubuntu.sh

# 1.c 构建指定桌面套件的基础镜像
./mk-base-gnome-ubuntu.sh
./mk-base-xfce-ubuntu.sh

######### step 2 #########
# 添加 rk overlay 层,并打包ubuntu-rootfs镜像
# 2.a
VERSION=debug ./mk-lite-rootfs.sh

# 2.b SOC参数根据实际情况选择，如rk356x、rk3588
VERSION=debug TARGET=desktop ./mk-desktop-rootfs.sh

# 2.c 构建镜像，与step1指定的桌面套件版本相同
VERSION=debug ./mk-gnome-rootfs.sh
VERSION=debug ./mk-xfce-rootfs.sh

```
