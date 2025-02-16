This fork is intended to solve the same problem for newer kernel versions, since the original script from [Giuliano69](https://github.com/Giuliano69) gave me the following output:

```
make: Entering directory '/usr/src/linux-headers-6.8.0-47-generic'
warning: the compiler differs from the one used to build the kernel
  The kernel was built by: x86_64-linux-gnu-gcc-12 (Ubuntu 12.3.0-1ubuntu1~22.04) 12.3.0
  You are using:           gcc-12 (Ubuntu 12.3.0-1ubuntu1~22.04) 12.3.0
scripts/Makefile.build:41: /root/Makefile: No such file or directory
make[2]: *** No rule to make target '/root/Makefile'.  Stop.
make[1]: *** [/usr/src/linux-headers-6.8.0-47-generic/Makefile:1925: /root] Error 2
make: *** [Makefile:240: __sub-make] Error 2
make: Leaving directory '/usr/src/linux-headers-6.8.0-47-generic'
cp: cannot stat 'uvcvideo.ko': No such file or directory
```

In this case, I am focusing on `6.8.0-52-generic`, but this tutorial can easily be applied to other kernels.


## First things first

1. Check your camera device. If you don't get any output, do not proceed with the tutorial as you either have a different camera device, or the operating system is not recognizing your camera at the hardware level.
```
lsusb | grep "0408:4035 Quanta Computer, Inc. ACER HD User Facing"
```

2. If you're running an Ubuntu-based distribution and know it is compatible (it should work perfectly for distros that are based on Ubuntu 22 or 24) with the provided `uvcdriver`, you can delete the following lines from [compile_module.sh](./compile_module.sh):
```sh
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
```

3. Check your kernel using `uname -r`
  3.1. Get the **kernel version** and the **major revision** numbers. For example, as I am running `6.8.0-52-generic`, it will be **6.8**.
  3.2. Navigate to the Ubuntu Archive's Hardware Enablement page. Just change the *6.8* to your version at the end of the following link: https://archive.ubuntu.com/ubuntu/pool/main/l/linux-hwe-6.8.
  3.3. Locate the `linux-hwe-YOUR_VERSION_YOUR_VERSION.0.orig.tar.gz` file and copy its link.
  3.4. Replace the link and change the name of the file in [compile_module.sh](./compile_module.sh).
  ```sh
  wget https://archive.ubuntu.com/ubuntu/pool/main/l/linux-hwe-6.8/linux-hwe-6.8_6.8.0.orig.tar.gz && \ # change this link to the one you've found
	tar -xzf linux-hwe-6.8_6.8.0.orig.tar.gz # change the name of the file to the one you're downloading
  ```

4. You're ready!

## Applying the patch

1. Clone this repository to your computer.
2. Give **compile_module.sh** the necessary permissions to execute: `sudo chmod +x compile_module.sh`.
3. Execute **compile_module.sh**: `sudo ./compile_module.sh`.

You're done. Now your camera should be working!

## Applying the patch with Secure Boot enabled

If **Secure Boot** is enabled, the new driver will not be loaded automatically. You need to sign it manually. This happens because Secure Boot prevents unsigned modules from being inserted into the kernel. Since you compiled a new **uvcvideo module**, it is unsigned, and Secure Boot will block it from loading. So you're likely to get an output like this when executing **compile_module.sh**:

```
modprobe: ERROR: could not insert 'uvcvideo': Key was rejected by service
```

If you don´t want to disable Secure Boot, you can do the following:

1. Generate a pair of keys to sign the module:
```sh
sudo apt install mokutil openssl
openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -nodes -days 36500 -subj "/CN=My UVC Video Module/"

```

2. Subscribe the key in Secure Boot using the MOK Manager:
```sh
sudo mokutil --import MOK.der
```

This step will ask you to create a password. You must take care of it because it will be requested in the next boot.

3. Reboot your computer. In the boot process, you'll see **MOK Manager's** blue screen:
* Choose **"Enroll MOK"**
* Select **"Continue"** and then **"Yes"** to confirm
* Input that password you've created

4. Now that the key was registered, you need to sign the `uvcvideo.ko` module:
```sh
sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 MOK.priv MOK.der /lib/modules/$(uname -r)/kernel/drivers/media/usb/uvc/uvcvideo.ko
```
If this path doesn't exist, try this:
```sh
sudo /lib/modules/$(uname -r)/build/scripts/sign-file sha256 MOK.priv MOK.der /lib/modules/$(uname -r)/kernel/drivers/media/usb/uvc/uvcvideo.ko
```

5. Update the kernel modules:
```sh
sudo depmod -a
```

6. Reload the `uvcvideo` module:
```sh
sudo modprobe uvcvideo
```
If it doesn't work, try this:
```sh
sudo modprobe -r uvcvideo && sudo modprobe uvcvideo
```

You're done. Now you camera should be working!