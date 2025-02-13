# `bootmon`

`bootmon` is a wozmon-style monitor program that can be installed in the MBR.
It lets you:
- peek and poke at memory
- run machine code you type in
- perform disk I/O
- debug your code

## Basic usage

Each command consists of an address, the one-character command, and possibly
other parameters — in that order.

The address is optional — each command keeps track of the last address it was
used at, and if not provided with an address, it will continue where it left
off.

Note that only accesses to the first 64KB of memory are supported.

If at any point you decide that you want to discard what you typed in so far,
press Escape. The cursor will move to a new line and your command will not
be executed.

### Reading memory (peek)

The command character for reading memory is the end-of-line.
Type in a hexadecimal address and press enter. A 16-byte line of hexdump
will be printed. Continue pressing enter to see more data.

> [!TIP]
> Since the peek command leaves the cursor at the end of the line of
> hexdump it prints, you might want to press Escape when you're done,
> so that the next command you type in doesn't look messy.

### Writing memory (poke) `:`

Type in an address, `:`, and then your data. You can insert spaces into
the data you're typing for convenience — they will be skipped.

Example:

```
7000:c0ffee 2137
:acab
7000
7000 C0 FF EE 21 37 AC AB 00 00 00 00 00 00 00 00 00
```

### Executing code (go) `g`

Type in an address, then `g`. The code at this address will be called.

Example:

```
7000:b8680e 31db cd10 b069 cd10 c3
7000g
hi
g
hi
```

### Reading from disk `R`

> [!NOTE]
> All disk commands are uppercase, to make it harder to mix up "go" vs "run".

Type in the memory address, `R`, and then the LBA (in hexadecimal).
Only LBA up to 16-bit wide are supported, so you can only access the first
32MB of the drive. This shouldn't be a problem.

Example:

```
8000
8000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
8000R0
8000
8000 EA 05 7C 00 00 B8 00 70 8E D0 31 E4 8E DC 8E C4
```

If the disk operation fails, the contents of the BIOS
`AH` register will be printed out. For example:

```
8000R1000
01
```

This experiment was performed on a 1MB disk, so LBA 0x1000 is out of bounds.
Thus, the operation returned "AH=01 invalid function in AH or invalid parameter".

### Writing to disk `W`

Analogous to `R`.

Example:

```
8000:acab
8000W1
9000R1
9000
9000 AC AB 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

## Debugging

If, while executing a program, an `int3` (`CC`) breakpoint is encountered,
execution will be paused and the program state will be printed. For example:

```
7000: b8dead b9beef cc b8680e 31db cd10 b069 cd10 c3
7000g
FFE8 00 70 05 05 00 00 F8 FF 00 70 00 00 BE EF DE AD 07 70 00 00 02 02
```

In order, that's:
- the location of the saved execution state in memory
- the values of the general purpose registers: DI, SI, BP, SP, BX, DX, CX, AX
  (little endian)
  - this is the order in which `pusha` puts them on the stack
  - it is also the exact reverse of the order used in the internal register
    indices used by the instruction encoding, which you are no doubt intimately
    familiar with if you're using a programming environment that has you
    slinging raw machine code
- IP, CS, FLAGS

### Resuming execution `k`

> [!TIP]
> The `k` stands for "kontinue". For you see, `c` was taken by hexadecimal...

With program execution paused as above, type `k` to resume execution.

For example:

```
7000: b8dead b9beef cc b8680e 31db cd10 b069 cd10 c3
7000g
FFE8 00 70 05 05 00 00 F8 FF 00 70 00 00 BE EF DE AD 07 70 00 00 02 02
k
hi
```

> [!WARNING]
> Currently, providing this command with an address constitutes undefined
> behavior (i'm sorry, i have sinned)
>
> Moreover, executing this command while not currently paused in the middle
> of a program also constitutes undefined behavior (i don't feel bad about
> this one, this one is on you)

### Single-stepping `s`

Instead of simply resuming execution, you can also execute a single instruction.

For example:

```
7000: b8dead b9beef cc b8680e 31db cd10 b069 cd10 c3
7000g
FFE8 00 70 05 05 00 00 F8 FF 00 70 00 00 BE EF DE AD 07 70 00 00 02 02s
FFE8 00 70 05 05 00 00 F8 FF 00 70 00 00 BE EF 68 0E 0A 70 00 00 02 03s
FFE8 00 70 05 05 00 00 F8 FF 00 00 00 00 BE EF 68 0E 0C 70 00 00 46 03s
hFFE8 00 70 05 05 00 00 F8 FF 00 00 00 00 BE EF 69 0E 10 70 00 00 46 03s
iFFEA 00 70 05 05 00 00 FA FF 00 00 00 00 BE EF 69 0E 9D 7C 00 00 46 03s
FFEA 00 70 05 05 00 00 FA FF 00 00 00 00 BE EF 69 0E 9F 7C 00 00 46 03k
```

Things to note:
- executing an `int` instruction will step through both that instruction
  and the immediately following one. This is an expected behavior of the
  x86 Trap Flag.
- if your program returns to the monitor, you are now debugging the monitor.
  knock yourself out.
- the same warning as with `k` applies.

### Modifying program state

You are given the address of the saved state of the program. This is so that
you can poke it.

For example:

```
7000: b8dead b9beef cc b8680e 31db cd10 b069 cd10 c3
7000g
FFE8 00 70 05 05 00 00 F8 FF 00 70 00 00 BE EF DE AD 07 70 00 00 02 02s
FFE8 00 70 05 05 00 00 F8 FF 00 70 00 00 BE EF 68 0E 0A 70 00 00 02 03s
FFE8 00 70 05 05 00 00 F8 FF 00 00 00 00 BE EF 68 0E 0C 70 00 00 46 03s
hFFE8 00 70 05 05 00 00 F8 FF 00 00 00 00 BE EF 69 0E 10 70 00 00 46 03
FFF6
FFF6 69 0E 10 70 00 00 46 03 9D 7C 53 FF 00 F0 52 7C
FFF6:21
k
!
```
