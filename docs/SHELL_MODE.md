# SHELL_MODE Commands, Parser, & Environment
Orchid's _SHELL_MODE_ feature ~~is~~ _will be_ used as a fall-back on computers that are not compatible with the video mode that the OS requests.

It is loaded by default until the more basic features of the graphical operating system are handled. This is likely to be the case for the foreseeable future.

## Environment
### Video Mode / Graphics
By default, orchid is set to load into _SHELL_MODE_, VGA BIOS mode 03h (80*25 text), if it cannot obtain a proper VESA signature, or find a supported video mode.
### Graphical Mode
Orchid _tentatively_ chooses a graphical mode from a selection of standards, mainly seeking support for video mode **0x118**, which is a widely-supported **1024x768** mode, with 24bpp/32bpp support. This works on 90% of tested systems for drawing primitive shapes. If you're interested in testing it, check out the **BOOT_ST2.asm** file and search for the single line to _uncomment_ to access the VESA mode on your PC, if it's not already done in the current repo.

## Parser
### Arguments
Arguments are held to a rather strict standard by the kernel. They are stored in memory at _PARSER_ARG(N)_, where _N = 1 to 3_.
Their lengths are measured as well and stored into _PARSER_ARGN_LENGTH_ for further checks by the called command.

Argument Restrictions:
- No more than **3 arguments** are allowed through the parser.
- No more than **64 characters each**, including those in double-quotes.
- No more than one space between arguments. This has to do with ASCII processing in the arguments themselves.

Upon error, the parser will let the user know that there was an error, and to check the documentation here. **The parser will allow more arguments in the future.**

## Commands
All commands are _case-insensitive_, because all capitalized characters the user enters are automatically taken to lowercase behind-the-scenes, although the proper case will always display.
A quick syntax reference:
- **%N** implies the **N-th argument** in the command sequence.
- Arguments are separated by **one** space.
- Arguments in double-quotes are treated as one argument from quote to quote, regardless of spacing.
- _[]_ around an argument implies that the argument is optional. _Note_: If the brackets fall around multiple arguments without breaking (i.e. [%1 %2]), then those arguments are contingent upon each other and will require both to be present.

### CLS
Clears the console screen.

### COLOR %1
Changes the color of the user's input. Both the foreground and background colors are changeable.
The two digits of the 4-bit colors cannot be the same.

### CONN [%1]
Show an enumerated list of PCI devices. No support for PCIe (but those should be backwards-compatible).
The argument is an _optional argument_ to allow detailed information on a specific device number (device numbers are listed when calling CONN itself).

**Information offered when calling CONN (no args)**
- Device & Vendor IDs
- Location on the PCI bus (Bus#, Slot#, & Function)
- Description with revision

**Extra information listed with specific device:**
- All regular CONN info
- Status & Command register states
- BIST (Built-In Self Test) capability
- Header, Latency, Cache-capable
- Specific hardware codes (Class->Subclass->Programming Interface)

### DUMP
Dump the states of all general-purpose registers, stack pointer, segments, and indices.
Mostly a debugging tool, that can be inserted anywhere in the source code (past the kernel) to show register states at a certain time.

### MEMD %1 %2 [%3]
Perform a hex-dump of memory at the specified location, for the specified length.
- **%1** is the physical address to start the hex-dump from.
- **%2** is the length of the dump in hex. This is always _16-byte-aligned_ (meaning rounded to the nearest 0x10).
- **%3** is an optional flag. Set this to _1_ to output the hex data in ASCII instead. Setting it to _0_ will explicitly tell it _not_ to output in ASCII mode.

### REBOOT
Reboot the system by forcing a null IDT and calling a software interruption. This command is safeguarded by the parser, which only forces a reboot after the command is entered twice, _consecutively_.

### SHUTDOWN
Shutdown the system by using ACPI. Error-checks to make sure ACPI is enabled before trying a port output to PM1a.
Just like *REBOOT*, this command is also protected by the same parser safeguard.

### SYS
Tell the user information about the system they're running on.
