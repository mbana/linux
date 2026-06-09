#!/usr/bin/env bash
sudo apt install -y device-tree-compiler build-essential flex bison dwarves libssl-dev libelf-dev

make clean

# Safer alternative: make olddefconfig. Instead of saying plain no to everything, it takes the default value. I still take the time of going through things manually. There are usually 2-3 interesting questions before it gets to the obscure device drivers, and for the rest you can just keep the <enter> key pressed.
cp -v ./configs/config-6.19.10-300.fc44.aarch64 .config
make olddefconfig
make dtbs

sudo mkdir -pv /mnt/fedora/boot/dtbs/8380_ROM_2036
sudo cp -v arch/arm64/boot/dts/qcom/x1e80100-microsoft-romulus13.dtb /mnt/fedora/boot/dtbs/8380_ROM_2036/
sudo cp -v arch/arm64/boot/dts/qcom/x1e80100-microsoft-romulus13-el2.dtb /mnt/fedora/boot/dtbs/8380_ROM_2036/
