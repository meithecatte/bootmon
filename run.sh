#!/bin/sh
./build.sh
qemu-system-i386 -enable-kvm -display curses -drive format=raw,file=bootmon.bin
