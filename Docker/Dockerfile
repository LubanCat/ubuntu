#基础镜像
FROM ubuntu:22.04

#维护者
MAINTAINER hejiawen

RUN sed -i -r 's#http://(archive|security).ubuntu.com#http://mirrors.tuna.tsinghua.edu.cn#g' /etc/apt/sources.list \
  && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo 'Asia/Shanghai' >/etc/timezone

RUN apt update \
  && apt install --no-install-recommends -y locales apt-utils binfmt-support qemu-user-static \
     make sudo cpio bzip2 curl wget language-selector-common \
  && apt-get autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8

ENV LANG zh_CN.utf8