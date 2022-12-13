#!/bin/bash -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
board_info() {
    case $1 in
        0000)
            BOARD_NAME='LubanCat1'
            BOARD_DTB='rk3566-lubancat1.dtb'
            ;;
        0100)
            BOARD_NAME='LubanCat1N'
            BOARD_DTB='rk3566-lubancat1-n.dtb'
            ;;
        0200)
            BOARD_NAME='LubanCat Zero N'
            BOARD_DTB='rk3566-lubancat-zero.dtb'
            ;;
        0300)
            BOARD_NAME='LubanCat Zero W'
            BOARD_DTB='rk3566-lubancat-zero.dtb'
            ;;
        0400)
            BOARD_NAME='LubanCat2'
            BOARD_DTB='rk3568-lubancat2.dtb'
            ;;
        0500 |\
        0600)
            BOARD_NAME='LubanCat2N'
            BOARD_DTB='rk3568-lubancat2-n.dtb'
            ;;
        0700)
            BOARD_NAME='LubanCat2IO'
            BOARD_DTB='rk3568-lubancat2-io.dtb'
            ;;
    esac

    echo "BOARD_NAME:"$BOARD_NAME

    echo "BOARD_DTB:"$BOARD_DTB

}

get_index(){
    ADC_RAW=$1
    INDEX=0xff
    declare -a ADC_INDEX=(229 344 460 595 732 858 975 1024)

    for i in 00 01 02 03 04 05 06 07; do
        if [ $ADC_RAW -lt ${ADC_INDEX[$i]} ]; then
            INDEX=$i
            break
        fi	
    done 
}

board_id() {
    ADC_CH2_RAW=$(cat /sys/bus/iio/devices/iio\:device0/in_voltage2_raw)
    echo "ADC_CH2_RAW:"$ADC_CH2_RAW
    ADC_CH3_RAW=$(cat /sys/bus/iio/devices/iio\:device0/in_voltage3_raw)
    echo "ADC_CH3_RAW:"$ADC_CH3_RAW

    get_index $ADC_CH2_RAW
    ADC_CH2_INDEX=$INDEX

    get_index $ADC_CH3_RAW
    ADC_CH3_INDEX=$INDEX

    BOARD_ID=$ADC_CH2_INDEX$ADC_CH3_INDEX
    echo "BOARD_ID:"$BOARD_ID

}

board_id
board_info ${BOARD_ID}

# first boot configure

until [ -e "/dev/disk/by-partlabel/boot" ]
do
    echo "wait /dev/disk/by-partlabel/boot"
    sleep 0.1
done

if [ ! -e "/boot/boot_init" ] ;
then

    if [ ! -e "/dev/disk/by-partlabel/userdata" ] ;
    then

        if [ ! -e "/boot/rk-kernel.dtb" ] ; then
            mount /dev/disk/by-partlabel/boot /boot
            echo "PARTLABEL=boot  /boot  auto  defaults  0 2" >> /etc/fstab
        fi	

        apt install -fy --allow-downgrades /boot/kerneldeb/*
        # rm -f /boot/kerneldeb/*
        ln -sf dtb/$BOARD_DTB /boot/rk-kernel.dtb
    
        touch /boot/boot_init
        reboot
    else
        echo "PARTLABEL=oem  /oem  ext2  defaults  0 2" >> /etc/fstab
        echo "PARTLABEL=userdata  /userdata  ext2  defaults  0 2" >> /etc/fstab
        touch /boot/boot_init
    fi
fi

