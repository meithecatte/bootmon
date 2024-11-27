org 0x7c00
bits 16

cmdbuf equ 0x500

    jmp 0:start
start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    ; ...

readline:
    cld
    mov di, cmdbuf
.loop:
    mov ah, 0
    int 0x16
    stosb
    mov ah, 0x0e
    xor bx, bx
    int 0x10
    cmp al, 0x08
    jnz .not_backspace
    mov al, " "
    int 0x10
    mov al, 0x08
    int 0x10
    dec di
    cmp di, cmdbuf
    je .loop
    dec di
.not_backspace:
    jmp .loop

    times 446 - ($ - $$) db 0x69
    times 64 db 0
    db 0x55, 0xaa
