#!/bin/bash

# Successfully detects
# ubuntu-14.04.1-desktop-amd64.iso
# ubuntu-gnome-15.04-desktop-amd64.iso
# xubuntu-15.10-core-amd64.i

detect_casper() {

HERE=$(dirname $(readlink -f $0))

MOUNTPOINT="$1"

#
# Make sure this ISO is one that this script understands - otherwise return asap
#

find "$MOUNTPOINT"/casper 2>/dev/null || return
ls "$MOUNTPOINT"/boot/grub/loopback.cfg 2>/dev/null && CFG="$MOUNTPOINT"/boot/grub/loopback.cfg # Hopefully all newer casper ISOs
ls "$MOUNTPOINT"/boot/grub/grub.cfg 2>/dev/null && CFG="$MOUNTPOINT"/boot/grub/grub.cfg # pop-os_19.04_amd64_nvidia_7.iso
# In elementary OS 5.1 /boot/grub/loopback.cfg contains just "source /boot/grub/grub.cfg" hence that one must be last
if [ -z $CFG ] ; then return ; fi

#
# Parse the required information out of the ISO
#

LIVETOOL="casper"
LIVETOOLVERSION=$(grep -e "^casper" "$MOUNTPOINT"/casper/filesystem.manifest | head -n 1 | awk '{ print $2; }')

# The following is needed for xubuntu-15.10-core-amd64.iso
if [ "x$LIVETOOLVERSION" == "x" ] ; then
  LIVETOOLVERSION=0
fi

LINUX=$(cat $CFG | grep "linux" | head -n 1 | sed -e 's|linux\t||g' | sed -e 's|linux ||g' | xargs | sed -e 's|.efi||g')
echo "* LINUX $LINUX"

INITRD=$(cat $CFG | grep "initrd" | head -n 1 | sed -e 's|initrd\t||g' | sed -e 's|initrd ||g' | xargs)
echo "* INITRD $INITRD"

APPEND=" " # Don't use this because it's already in the LINUX line

#
# Put together a grub entry
#

read -r -d '' GRUBENTRY << EOM

menuentry "$ISONAME - $LIVETOOL $LIVETOOLVERSION" --class ubuntu {
        iso_path="$ISOPATH"
        search --no-floppy --file \${iso_path} --set
        live_args="for-casper --> iso-scan/filename=\${iso_path} console-setup/layoutcode=$KEYBOARD locale=$LANGUAGE timezone=$TIMEZONE username=$USERNAME hostname=$HOSTNAME noprompt init=/isodevice/boot/customize/init max_loop=256"
        custom_args=""
        iso_args="$APPEND"
        loopback loop ($ISODRIVE)\${iso_path}
        linux (loop)$LINUX \${live_args} \${custom_args} \${iso_args}
        initrd (loop)$INITRD ($INITRAMFSDRIVE)$INITRAMFSPATH
}
EOM

}
