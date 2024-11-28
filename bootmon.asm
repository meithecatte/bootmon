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
    jz start
    mov ah, 0x0e
    xor bx, bx
    int 0x10
    cmp al, 0x0d
    jz .end
    cmp al, 0x08
    jnz .loop
    mov al, " "
    int 0x10
    mov al, 0x08
    int 0x10
    dec di
    cmp di, cmdbuf
    je .loop
    dec di
    jmp .loop
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
    je foundcmd
    jno .find
    
parsehexdigit:
    cmp al, 0x39
    jbe .ok
    add al, 9
.ok:
    and al, 0x0f
    shl bx, 4
    or bl, al
    jmp parsecmd

foundcmd:
    mov di, [di]
    cmp si, cmdbuf + 1
    je .noaddr
    mov [di+1], bx
.noaddr:
    jmp di

cmd_poke:
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
    jmp readline

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

cmdtable:
    db ":"
    dw cmd_poke
    db 0
    dw cmd_peek
    db 0xff

    times 446 - ($ - $$) db 0
    times 64 db 0
    db 0x55, 0xaa
