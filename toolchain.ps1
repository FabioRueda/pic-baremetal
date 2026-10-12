# toolchain.ps1 - toolchain version paths, in one place.
# Loaded by build.ps1, flash.ps1 and hexconfig.ps1. When you update a tool, change it here only.

$MPLABX = 'C:\Program Files\Microchip\MPLABX\v6.25'   # ipecmd and device packs come from here
$XC8    = 'C:\Program Files\Microchip\xc8\v3.10\bin\xc8-cc.exe'
$XC16   = 'C:\Program Files\Microchip\xc16\v2.10\bin\xc16-gcc.exe'
$XCDSC  = 'C:\Program Files\Microchip\xc-dsc\v3.30\bin\xc-dsc-gcc.exe'
$XC32   = 'C:\Program Files\Microchip\xc32\v4.60\bin\xc32-gcc.exe'

$IPECMD = "$MPLABX\mplab_platform\mplab_ipe\ipecmd.exe"
# Device pack (DFP) folders; build and CONFIG reading use the newest version found in them.
$PACKS = @(
    "$MPLABX\packs",
    "$env:USERPROFILE\.mchp_packs"
)
