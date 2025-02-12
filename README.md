# `bootmon`

`bootmon` is a wozmon-style monitor program that can be installed in the MBR.

## Usage

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

All disk commands are uppercase, to make it harder to mix up "go" vs "run".

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
