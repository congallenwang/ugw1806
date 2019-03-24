#!/bin/sh
set -x

[ -d /root/mtlk/images/ ] && {
    IMAGE=/root/mtlk/images
    MODULE=/lib/modules/*/net/
} || {
    IMAGE=/opt/intel/wave/images
    MODULE=/opt/intel/lib/modules/*/net/
}

cd /tmp
cp -s $IMAGE/* /lib/firmware 
#cp -s /lib/firmware/mtlk/images/fw_scd_file.scd /tmp/
#cp -s /lib/firmware/mtlk/images/hw_scd_file.scd /tmp/
cp -s $MODULE/mtlk*.ko /tmp/

read_img wlanconfig /tmp/eeprom.tar.gz
tar zxf eeprom.tar.gz

echo /opt/lantiq/sbin/hotplug > /proc/sys/kernel/hotplug

export COUNTRY=00
crda

mkdir /tmp/wlan_wave
touch /tmp/wlan_wave/crda_executed

insmod mtlkroot.ko
#cp -s /bin/logserver /tmp/
#/tmp/logserver -f /tmp/dev/mtlkroot0 -s /tmp/fw_scd_file.scd &

insmod mtlk.ko ap=1,1  fastpath=1,1 ahb_off=1

cp -s /opt/intel/bin/hostapd /tmp/hostapd_wlan0
cp -s /opt/intel/bin/hostapd /tmp/hostapd_wlan2

cd - > /dev/null
