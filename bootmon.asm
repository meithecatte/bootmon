org 0x7c00
bits 16

cmdbuf equ 0x500

    jmp 0:start
start:
    mov ax, 0x7000
    mov ss, ax
    xor sp, sp
    mov ds, sp
    mov es, sp

    mov [int13+1], dl
    jmp short restart

cmd_peek:
    mov si, 0
    mov dx, si
    call putword
    mov cx, 16
.loop:
    mov al, " "
    int 0x10
    lodsb
    mov dh, al
    call putbyte
    loop .loop
    mov [cmd_peek+1], si
    jmp short readline

cmd_poke:
    mov di, 0
.loop:
    lodsb
    or al, al
    jz short readline
    cmp al, " "
    jbe short .loop
    call parsebyte
    xchg ax, bx ; mov ax, bx
    stosb
    mov [cmd_poke+1], di
    jmp short .loop

cmd_go:
    mov di, 0
    call di
    ; fallthrough
restart:
    xor bx, bx
    mov ax, 0x0e0d
    int 0x10
    mov al, 0x0a
    int 0x10

readline:
    cld
    mov di, cmdbuf
    mov si, di
.loop:
    mov ah, 0
    int 0x16
    stosb
    cmp al, 0x1b
    jz restart
    mov ah, 0x0e
    xor bx, bx
    int 0x10
    cmp al, 0x0d
    jz short .end
    cmp al, 0x08
    jnz short .loop
    mov al, " "
    int 0x10
    mov al, 0x08
    int 0x10
    dec di
    cmp di, cmdbuf
    je short .loop
    dec di
    jmp short .loop
.end:
    mov al, 0x0a
    int 0x10
    mov [di-1], bl ; bl = 0 here because of the xor bx, bx above

    ; bx is zero here. accumulate the address we're parsing into bx
parsecmd:
    mov di, cmdtable - 2
    lodsb
.find:
    scasw
    scasb
    je short foundcmd
    jno short .find

    call convnibble
    jmp short parsecmd

foundcmd:
    mov di, [di]
    cmp si, cmdbuf + 1
    je short .noaddr
    mov [di+1], bx
.noaddr:
    jmp di

putword: ; DX
    call putbyte
putbyte: ; DH
    call putnibble_shift
putnibble_shift:
    rol dx, 4
    mov al, dl
putnibble:
    and al, 0x0f
    add al, 0x90
    daa
    adc al, 0x40
    daa
    mov ah, 0x0e
    xor bx, bx
    int 0x10
    ret

parsebyte: ; assumes first character is in AL
    xor bx, bx
    call convnibble
    lodsb
convnibble:
    cmp al, 0x39
    jbe short .ok
    add al, 9
.ok:
    and al, 0x0f
    shl bx, 4
    or bl, al
    ret

int13:
    mov dl, 0
    int 0x13

cmdtable:
    db ":"
    dw cmd_poke
    db 0
    dw cmd_peek
    db "g"
    dw cmd_go
    db 0x80

    times 446 - ($ - $$) db 0
    times 64 db 0
    db 0x55, 0xaa
