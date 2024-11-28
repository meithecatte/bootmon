#!/bin/sh
nasm -f bin bootmon.asm -o bootmon.bin
bytecount=$(xxd -ps bootmon.bin |
    tr -d '\n' |
    sed -E 's/(00)*55aa$//g' |
    xxd -ps -r |
    wc -c)
echo "$bytecount bytes used"
