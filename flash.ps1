# flash.ps1 - safe .hex programming with PICkit 4 or PICkit 5 via ipecmd.
# Usage: .\flash.ps1 -Device 18F47Q10 -Hex .\build\main.hex [-Power ext|3v3|5v] [-Tool pk4|pk5]
param(
    [Parameter(Mandatory)][string]$Device,
    [Parameter(Mandatory)][string]$Hex,
    [ValidateSet('ext', '3v3', '5v')][string]$Power = 'ext',
    [ValidateSet('pk4', 'pk5')][string]$Tool = 'pk4'  # ipecmd code: -TPPK4 / -TPPK5
)

. "$PSScriptRoot\toolchain.ps1"  # $IPECMD

if (-not (Test-Path $IPECMD)) { Write-Error "ipecmd not found: $IPECMD"; exit 1 }
if (-not (Test-Path $Hex -PathType Leaf)) { Write-Error ".hex file not found: $Hex"; exit 1 }
$Hex = (Resolve-Path $Hex).Path

$ipeArgs = @("-P$Device", "-TP$($Tool.ToUpper())", "-F$Hex", '-M', '-OL')
switch ($Power) {
    '3v3' { $ipeArgs += '-W3.3' }
    '5v'  { $ipeArgs += '-W5' }
}

$powerText = @{ ext = 'external supply (no -W)'; '3v3' = 'PICkit supplies 3.3 V (-W3.3)'; '5v' = 'PICkit supplies 5 V (-W5)' }[$Power]
Write-Host ''
Write-Host "Device     : $Device"
Write-Host "Programmer : $(@{ pk4 = 'PICkit 4'; pk5 = 'PICkit 5' }[$Tool])"
Write-Host "File       : $Hex"
Write-Host "Power      : $powerText"
Write-Host "Command    : & `"$IPECMD`" $($ipeArgs[0]) $($ipeArgs[1]) -F`"$Hex`" $($ipeArgs[3..($ipeArgs.Count-1)] -join ' ')"
Write-Host ''

# CONFIG is what can brick the chip: show what the .hex will write into it.
. "$PSScriptRoot\hexconfig.ps1"
try { $cfgLines = Format-HexConfig $Device $Hex }
catch { Write-Host "Aborted: corrupted .hex. $_" -ForegroundColor Red; exit 1 }
if ($null -eq $cfgLines) {
    Write-Host "CONFIG     : DFP for $Device not found, cannot read CONFIG. Check it in MPLAB X (Configuration Bits) before programming." -ForegroundColor Yellow
} elseif ($cfgLines.Count -eq 0) {
    Write-Host 'CONFIG     : the .hex has NO CONFIG. The chip will keep the erased values (factory default).' -ForegroundColor Yellow
} else {
    Write-Host 'CONFIG to be programmed (check against the datasheet or MPLAB X Config Bits):' -ForegroundColor Cyan
    $cfgLines | ForEach-Object { Write-Host "  $_" }
}
Write-Host ''

if ($Power -ne 'ext') {
    Write-Host '!!! Risk of double power supply. Only use this if the board has NO external supply. !!!' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ''
}

Write-Host 'Programming is irreversible. A wrong CONFIG can brick the chip.' -ForegroundColor Red
$answer = Read-Host "Type the device name ($Device) to confirm"
if ($answer.Trim() -ne $Device) {
    Write-Host 'Confirmation did not match. Aborted, nothing was programmed.' -ForegroundColor Yellow
    exit 2
}

& $IPECMD @ipeArgs
$code = $LASTEXITCODE
if ($code -eq 0) { Write-Host "ipecmd finished with exit code 0 (success)." -ForegroundColor Green }
else { Write-Host "ipecmd finished with exit code $code (failure)." -ForegroundColor Red }
exit $code
