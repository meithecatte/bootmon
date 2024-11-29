#!/bin/sh
./build.sh
truncate -s 1M disk.img
dd if=bootmon.bin of=disk.img conv=notrunc
qemu-system-i386 -enable-kvm -display curses -drive format=raw,file=disk.img
