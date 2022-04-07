#!/bin/bash

export DISPLAY=:0.0
#export GST_DEBUG=*:5
#test_camera-uvc.sh > /tmp/1.txt 2>&1
#export GST_DEBUG_FILE=/tmp/2.txt
#echo 600000000 > /sys/kernel/debug/clk/aclk_vcodec/clk_rate
#export GST_MPP_JPEGDEC_DEFAULT_FORMAT=NV12

echo "Start UVC Camera M-JPEG Preview!"
gst-launch-1.0 v4l2src device=/dev/video17 ! image/jpeg, width=1280, height=720, framerate=30/1 ! jpegparse ! mppjpegdec ! xvimagesink sync=false

#     gst-launch-1.0 v4l2src device=/dev/video17 ! video/x-raw,format=YUY2,width=640,height=480, framerate=30/1 ! videoconvert ! autovideosink
#"
# Fpr spefic size :

# v4l2-ctl --list-formats-ext -d /dev/video17

