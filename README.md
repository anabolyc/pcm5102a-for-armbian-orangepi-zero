# PCM5102a DAC running Armbian on OrangePi-Zero

[Writeup](https://hackaday.io/project/162373-orangepi-zero-pulse-music-server-using-i2s-dac)

This repository contains the device tree layer and source for pcm5102a kernel module for OrangePi Zero running under Armbian. All this to be able to run Sabre es9023 I2S sound card on OrangePi Zero.

Since Armbian 5.30 it switched to device tree to set up device peripherals. Along with this change somehow a lot of features lost their support, therefore it is not as straightforward to enable I2S.

I prepared this repo to do it quickly

Install build requirements

```bash
$ sudo apt install git build-essential linux-headers-current-sunxi -y
```

Pull this repo from GitHub (you may want to create some folder for that first)

```
$ git clone https://github.com/anabolyc/pcm5102a-for-armbian-orangepi-zero && cd pcm5102a-for-armbian-orangepi-zero
```

We need to add user overlays to enable I2S  (disabled by default) and enable a sound card on that port

```
$ sudo armbian-add-overlay i2s-sound.dts
```

this will compile the overlay script, put the compiled file under `/boot/overlay-user` and add to `/boot/armbianEnv.txt` line

```
user_overlays=i2s-sound
```

You need to reboot for changes to take effect, but this will not work just yet. The problem is we are referencing the `pcm5102a` kernel module there, and this one is not included in Armbian for some reason. Therefore we will build it on the same board using current kernel sources. So please check if you have built symlink

```bash
$ ls -al /lib/modules/$(uname -r)/build
lrwxrwxrwx 1 root root 43 Feb 29 18:08 /lib/modules/6.6.16-current-sunxi/build -> /usr/src/linux-headers-6.6.16-current-sunxi
```

If it is missing  - just create it manually by running 

```bash
$ sudo ln -s /usr/src/linux-headers-$(uname -r) /lib/modules/$(uname -r)/build
```

Now you are ready to build. The first command produces `pcm5102a.ko` file among others. Second will copy it to the appropriate kernel modules folder.

```bash
$ make all
make -C /lib/modules/6.6.16-current-sunxi/build M=/home/dronische/dev/pcm5102a-for-armbian-orangepi-zero modules
make[1]: Entering directory '/usr/src/linux-headers-6.6.16-current-sunxi'
  CC [M]  /home/dronische/dev/pcm5102a-for-armbian-orangepi-zero/pcm5102a.o
  MODPOST /home/dronische/dev/pcm5102a-for-armbian-orangepi-zero/Module.symvers
  CC [M]  /home/dronische/dev/pcm5102a-for-armbian-orangepi-zero/pcm5102a.mod.o
  LD [M]  /home/dronische/dev/pcm5102a-for-armbian-orangepi-zero/pcm5102a.ko
make[1]: Leaving directory '/usr/src/linux-headers-6.6.16-current-sunxi'
$
$ sudo make install
sudo cp pcm5102a.ko /lib/modules/6.6.16-current-sunxi
sudo depmod -a
```

Now we are ready to reboot and check if we have a sound card listed

```
$ aplay -l
**** List of PLAYBACK Hardware Devices ****
card 0: I2Smaster [I2S-master], device 0: 1c22000.i2s-pcm5102a-hifi pcm5102a-hifi-0 []
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

Check if the new module is correctly loaded

```
$ lsmod | grep snd_soc_pcm5102a

snd_soc_pcm5102a       16384 1

snd_soc_core          118784 5 sun4i_i2s,sun8i_codec_analog,snd_soc_simple_card_utils,snd_soc_pcm5102a,snd_soc_simple_card
```

Note: this will work even if the card is not connected, the board will output to appropriate pins and it doesn't really care if someone listens or not. So now let's check if audio will produce

```
speaker-test -t sine -f 2500 -c 2
```

And finally, I can hear a beeping sound in both speakers. Hooray!
