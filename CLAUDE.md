# Notes for AI agents

Read [README.md](README.md) first. Background on how this repo was built with AI tools: [docs/ai-assisted-development.md](docs/ai-assisted-development.md).

## Rules

- **Do not run graphify here** and do not offer graph updates or "questions to trace". The repo is about a dozen files; read them directly. A previous graphify loop cost about 323k tokens for no gain.
- **Never program a chip** (`flash.ps1` / `ipecmd`) unless the user explicitly asks in that turn. When testing `flash.ps1`, feed a wrong confirmation so it aborts (exit code 2).
- **Keep the safety defaults:** external power (`-Power ext`) by default and the typed device-name confirmation before programming.
- **Version paths live only in `toolchain.ps1`.** Do not hard-code `C:\Program Files\Microchip\...` anywhere else.
- **Keep `.ps1` files plain ASCII** (or UTF-8 with BOM). Windows PowerShell 5.1 misreads UTF-8 without BOM.
- **Do not guess CONFIG bit names.** Check them in the DFP (`xc8\docs\chips\<device>.html`, `xc16\docs\config_docs\`, or `xc32\docs\config_docs\` in the compiler folder).

## Before finishing a change

```powershell
.\tests\hexconfig.test.ps1                       # in PowerShell 7 and, ideally, 5.1
.\build.ps1 -Family xc8   -Device 18F47Q10     -Source examples\blink\main.c         -OutDir .\build\pic18
.\build.ps1 -Family xc16  -Device 24FJ128GA010 -Source examples\blink-pic24\main.c   -OutDir .\build\pic24
.\build.ps1 -Family xcdsc -Device 33CK256MP508 -Source examples\blink-dspic33\main.c -OutDir .\build\dspic33
.\build.ps1 -Family xc32  -Device 32MX795F512L -Source examples\blink-pic32\main.c   -OutDir .\build\pic32
```
