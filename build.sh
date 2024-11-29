#!/bin/sh
set -e
nasm -f bin bootmon.asm -o bootmon.bin
bytecount=$(xxd -p bootmon.bin |
    tr -d '\n' |
    sed -E 's/(00)*55aa$//g' |
    xxd -p -r |
    wc -c)
echo "$bytecount bytes used"
