#!/bin/sh
./build.sh
qemu-system-i386 -enable-kvm -display curses -hda bootmon.bin
