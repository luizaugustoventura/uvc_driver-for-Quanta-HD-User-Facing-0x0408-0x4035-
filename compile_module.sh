#!/bin/bash 

# test linux distribution and version
source /etc/os-release
if [ "$ID" != "ubuntu" ]; then 
	echo "Sorry, this script works only for Ubuntu distribution"
	exit
fi

if [ "$VERSION_ID" != "22.04" ]; then 
	echo "Sorry, this script works only for Ubuntu 22.04 LTS"
	exit
fi

# update the packages list
sudo apt update
# upgrade your packages
sudo apt upgrade
# install necessary tools for module compilation
sudo apt install build-essential -y


# get driver code to compile a patch it

# change to your home directory
cd ~
# download in your home, the kernel source file version that match your used kernel
wget https://archive.ubuntu.com/ubuntu/pool/main/l/linux-hwe-6.8/linux-hwe-6.8_6.8.0.orig.tar.gz && \
	tar -xzf linux-hwe-6.8_6.8.0.orig.tar.gz
# change to the currently created uvc directory
cd ~/linux-*/drivers/media/usb/uvc
# backup the uvc driver source file, that need to be updated
mv uvc_driver.c uvc_driver.old 
# download the updated driver source file
wget https://raw.githubusercontent.com/luizaugustoventura/uvc_driver-for-Quanta-HD-User-Facing-0x0408-0x4035-/main/uvc_driver.c


# compile and install

# compile the updated video modules for your kernel version
make -j4 -C /lib/modules/$(uname -r)/build M=$(pwd) modules
# install the video driver module in the system
sudo cp uvcvideo.ko /lib/modules/$(uname -r)/kernel/drivers/media/usb/uvc/
# reboot to check your camera is working
sudo rmmod uvcvideo && sudo modprobe uvcvideo
