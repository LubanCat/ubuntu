#!/bin/sh

echo "Start RKNN_DEMO Camera Preview!"
echo performance | tee $(find /sys/ -name *governor)
sudo service gdm3 stop
/usr/bin/npu_transfer_proxy&
rknn_demo
