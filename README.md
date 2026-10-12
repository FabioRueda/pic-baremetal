# pic-baremetal

A command-line workbench for bare-metal C on Microchip PIC under Windows (PowerShell): it compiles a single `.c` into a `.hex` for all four families (PIC16/18, PIC24, dsPIC, PIC32) and programs it with a PICkit 4 or 5, showing the CONFIG and asking for confirmation first.

## What it is for

Day-to-day development happens in **VS Code with the MPLAB extensions** (multi-file projects, Code Configurator, debugging). This repository does not replace that. It is the workbench next to it:

1. **Test a new board before opening a project.** Take the blink example for the family, change the device and the LED pin, build and program. If the LED blinks, the compiler, DFP, programmer, power and board all work, so the next problem you hit is in your code, not in the setup.
2. **Program with a safety gate.** The IDE's program button does not ask for confirmation. `flash.ps1` shows the CONFIG that will go into the chip, requires you to type the device name, and only powers the target from the PICkit if you ask. Use it for the programming runs that matter (final board, expensive chip, first programming) with the `.hex` your VS Code project produced.
3. **Check the generated CONFIG.** The examples have a safe CONFIG, checked against each family's DFP. Compare it with the CONFIG Code Configurator generates for your project.
4. **Reference for how each compiler works from the command line.** The pitfalls already solved are in `build.ps1` and in the [build.ps1](#buildps1) section below.

### Suggested flow for a new project

1. Test the board with the family's blink example:
   ```powershell
   .\build.ps1 -Family xc16 -Device 24FJ256GA705 -Source examples\blink-pic24\main.c
   .\flash.ps1 -Device 24FJ256GA705 -Hex .\build\main.hex -Tool pk5
   ```
2. Create the project **in another folder**, in VS Code, and set up CONFIG and peripherals in Code Configurator. Do not copy this repository into the project.
3. Develop and debug in VS Code.
4. For the programming runs that matter, program through `flash.ps1`, passing the project's `.hex`.

**Note:** the VS Code extension picks the compiler and DFP from its own settings and does not read `toolchain.ps1`. When you update MPLAB X or a compiler, check both sides. The path of the `.hex` produced by a VS Code project has not been verified here; check its output folder the first time.

## Status

| | Status |
|---|---|
| Build of the 4 examples (XC8, XC16, XC-DSC, XC32) | tested; produces a `.hex` with CONFIG |
| Reading CONFIG from the `.hex` (all families) | tested (`tests\hexconfig.test.ps1`, 13 checks, PowerShell 7 and 5.1) |
| `flash.ps1` up to the confirmation prompt (PICkit 4 and 5) | tested: shows the command and CONFIG, then aborts without programming |
| **Actually programming a chip** | **never tested**. The first real programming run is the first real test |
| LED pins and ICS/ICESEL channel in the examples | follow common evaluation boards; check yours |

## Requirements

- Windows with PowerShell 7 or Windows PowerShell 5.1.
- MPLAB X (provides `ipecmd` and the device packs) and the XC compilers for the families you use.
- A PICkit 4 or PICkit 5 for programming.

| Tool | Default path (edit in `toolchain.ps1`) |
|---|---|
| ipecmd (MPLAB X v6.25) | `C:\Program Files\Microchip\MPLABX\v6.25\mplab_platform\mplab_ipe\ipecmd.exe` |
| XC8 v3.10 (PIC16F/PIC18F) | `C:\Program Files\Microchip\xc8\v3.10\bin\xc8-cc.exe` |
| XC16 v2.10 (PIC24) | `C:\Program Files\Microchip\xc16\v2.10\bin\xc16-gcc.exe` |
| XC-DSC v3.30 (dsPIC) | `C:\Program Files\Microchip\xc-dsc\v3.30\bin\xc-dsc-gcc.exe` |
| XC32 v4.60 (PIC32) | `C:\Program Files\Microchip\xc32\v4.60\bin\xc32-gcc.exe` |
| Device packs (DFP) | `C:\Program Files\Microchip\MPLABX\v6.25\packs` and `%USERPROFILE%\.mchp_packs` |

Programmers: PICkit 4 (`-TPPK4`, default) and PICkit 5 (`-TPPK5`). All these paths live in `toolchain.ps1`, which the other scripts load. When you update a tool, change it there only. ipecmd and the device packs come from the MPLAB X folder (`$MPLABX`), so changing the MPLAB X version updates both.

## Layout

```
toolchain.ps1                  toolchain version paths (MPLAB X and compilers), in one place
build.ps1                      compiles a .c into a .hex
flash.ps1                      programs a .hex with PICkit 4 or 5 (asks for confirmation)
hexconfig.ps1                  reads the CONFIG out of the .hex (used by flash.ps1)
tests\                         test for hexconfig.ps1
examples\blink\main.c          test blink for PIC18F47Q10 (XC8)
examples\blink-pic24\main.c    test blink for PIC24FJ128GA010 (XC16)
examples\blink-dspic33\main.c  test blink for dsPIC33CK256MP508 (XC-DSC)
examples\blink-pic32\main.c    test blink for PIC32MX795F512L (XC32)
build\                         outputs (ignored by git)
```

Keep the `.ps1` files in plain ASCII (or UTF-8 with BOM): Windows PowerShell 5.1 misreads UTF-8 without BOM. If PowerShell blocks script execution, run them with `powershell -ExecutionPolicy Bypass -File .\build.ps1 ...`.

## build.ps1

```powershell
.\build.ps1 -Family xc8 -Device 18F47Q10 -Source examples\blink\main.c
# output: .\build\main.hex

.\build.ps1 -Family xc8 -Device 16F18446 -Source src\main.c -OutDir .\build\f18446

# Examples for the other families (all tested and producing a .hex)
.\build.ps1 -Family xc16  -Device 24FJ128GA010 -Source examples\blink-pic24\main.c   -OutDir .\build\pic24
.\build.ps1 -Family xcdsc -Device 33CK256MP508 -Source examples\blink-dspic33\main.c -OutDir .\build\dspic33
.\build.ps1 -Family xc32  -Device 32MX795F512L -Source examples\blink-pic32\main.c   -OutDir .\build\pic32
```

- `-Family`: `xc8` | `xc16` | `xcdsc` | `xc32`. The device goes without the "PIC" prefix (e.g. `18F47Q10`, `33CK256MP508`, `32MX795F512L`).
- The script finds the device's DFP by itself (newest version across both pack folders) and passes `-mdfp`, which XC8 v3.x requires.
- `xc8` is the simple path. For `xc16`, `xcdsc` and `xc32`, the script does what MPLAB X does under the hood:
  - XC16/XC-DSC: passes the chip linker script (`p<Device>.gld`) and runs `bin2hex` with `-mdfp`. Without that, the `.hex` comes out without the interrupt vector table.
  - XC32: selects the chip with `-mprocessor` (there, `-mcpu` is the MIPS core).
  - All: the DFP path uses `/`, because XC32 cannot find the pack files with `\`.
- The four examples build and their `.hex` contains the CONFIG. Multi-file projects, custom startup code or bootloaders are out of the script's scope. For those, create a project in VS Code (MPLAB extensions) or MPLAB X: its `.hex` programs the same way through `flash.ps1`.

## flash.ps1

```powershell
# Board with its own supply (default, no -W)
.\flash.ps1 -Device 18F47Q10 -Hex .\build\main.hex

# Board WITHOUT a supply, powered by the PICkit at 3.3 V
.\flash.ps1 -Device 18F47Q10 -Hex .\build\main.hex -Power 3v3

# With a PICkit 5 instead of the PICkit 4 (default)
.\flash.ps1 -Device 18F47Q10 -Hex .\build\main.hex -Tool pk5
```

The script shows the device, the programmer, the file, the power mode, the full command and the CONFIG the `.hex` will write. On PIC18 the CONFIG is shown byte by byte from 0x300000; on PIC10/12/16, word by word from 0x8007. On PIC24, dsPIC and PIC32 the address varies per chip, so the script reads each register's name and address from the chip file inside the DFP (`edc\<chip>.PIC`) and shows only the ones the `.hex` writes (e.g. `FOSCSEL 0x02BF18 = 0xFFFF78`). Registers that do not appear keep their erased value. If the chip's DFP is not found, it tells you to check in MPLAB X. If the `.hex` is corrupted (bad checksum), it stops without programming. Then it asks you to type the device name; if the text does not match, it stops without programming. At the end it shows ipecmd's exit code (0 = success).

CONFIG reader test: `.\tests\hexconfig.test.ps1` (exits with code 1 if anything fails).

Command it builds: `ipecmd.exe -P<Device> -TPPK4 -F"<Hex>" -M -OL` (or `-TPPK5` with `-Tool pk5`), plus `-W3.3` or `-W5` only when you ask for it.

## SAFETY - read before programming

1. **Programming is irreversible.** The previous flash content is erased and replaced. It cannot be undone.
2. **A wrong CONFIG can brick the chip.** The CONFIG bits set the oscillator, watchdog, MCLR pin, LVP and code protection. With an oscillator that does not exist on the board, the chip has no clock. With MCLR and LVP both disabled, or with code protection on, reprogramming can become hard or impossible. Check the names in MPLAB X Config Bits or in `xc8\docs\chips\<device>.html` inside the DFP. Do not guess.
3. **Never use `-W` (`-Power 3v3` or `5v`) while the board's external supply is on.** Two supplies at once can damage the board, the PICkit or the USB port. The `ext` default exists for that reason.
4. **Before programming, confirm three things:** the right device, the right `.hex` file and the right power mode. The script shows all three; read them before typing the confirmation.

## Contributing

Issues and pull requests are welcome. Useful directions:

- Reports from real programming runs (the most important missing test), with chip, programmer and ipecmd output.
- Support for other programmers (PICkit 3, MPLAB SNAP, ICD 4/5) in `flash.ps1`.
- Decoding CONFIG bits into names (oscillator, watchdog, protection) instead of raw hex.
- Examples for more chips and boards.

Before opening a pull request:

- Run `.\tests\hexconfig.test.ps1` (ideally in both PowerShell 7 and 5.1) and build the four examples.
- Keep the safety defaults: external power by default and the typed confirmation before programming.
- Keep version paths in `toolchain.ps1` only.

## License

[MIT](LICENSE)
