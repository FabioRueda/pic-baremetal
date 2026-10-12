# build.ps1 - compiles a single .c file into a .hex.
# Usage: .\build.ps1 -Family xc8 -Device 18F47Q10 -Source .\examples\blink\main.c [-OutDir .\build]
#
# xc8 (PIC16F/PIC18F): the simple path, produces the .hex directly.
# xc16/xcdsc/xc32: the gcc driver needs the device linker script and startup code.
# The script passes the DFP's default linker script; tested with the examples in examples\blink-*.
# Single-file builds may fail outside that; if so, use a VS Code (MPLAB extensions) or MPLAB X project.
param(
    [Parameter(Mandatory)][ValidateSet('xc8', 'xc16', 'xcdsc', 'xc32')][string]$Family,
    [Parameter(Mandatory)][string]$Device,
    [Parameter(Mandatory)][string]$Source,
    [string]$OutDir = '.\build'
)

. "$PSScriptRoot\toolchain.ps1"  # $XC8, $XC16, $XCDSC, $XC32, $PACKS

$cc = @{ xc8 = $XC8; xc16 = $XC16; xcdsc = $XCDSC; xc32 = $XC32 }[$Family]
if (-not (Test-Path $cc)) { Write-Error "Compiler not found: $cc"; exit 1 }
if (-not (Test-Path $Source -PathType Leaf)) { Write-Error "Source not found: $Source"; exit 1 }

# Pack layout: <packs>\Microchip\<DFP_Name>\<version>\edc\<PART>.PIC
$dfp = Get-ChildItem ($PACKS | Where-Object { Test-Path $_ } | ForEach-Object { "$_\Microchip\*\*\edc\*$Device.PIC" }) -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Directory.Parent } |
    Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } -Descending |
    Select-Object -First 1
if (-not $dfp) { Write-Error "No DFP for $Device in: $($PACKS -join '; ')"; exit 1 }
# XC8 wants <pack>\xc8; XC16/XC-DSC want <pack>\xc16; XC32 uses the pack root.
$sub = @{ xc8 = 'xc8'; xc16 = 'xc16'; xcdsc = 'xc16'; xc32 = '' }[$Family]
$dfpPath = if ($sub -and (Test-Path (Join-Path $dfp.FullName $sub))) { Join-Path $dfp.FullName $sub } else { $dfp.FullName }
$dfpPath = $dfpPath -replace '\\', '/'  # XC32 cannot find the pack files with '\' in the path

New-Item -ItemType Directory -Force $OutDir | Out-Null
$name = [IO.Path]::GetFileNameWithoutExtension($Source)

if ($Family -eq 'xc8') {
    $out = Join-Path $OutDir $name    # xc8-cc writes <out>.hex next to it
    $hex = "$out.hex"
} else {
    Write-Host "WARNING: single-file build with $Family may fail without a linker script/startup. If it does, use a VS Code or MPLAB X project." -ForegroundColor Yellow
    $out = Join-Path $OutDir "$name.elf"
    $hex = Join-Path $OutDir "$name.hex"
}

# XC32 selects the chip with -mprocessor (there, -mcpu is the MIPS core).
$cpuFlag = if ($Family -eq 'xc32') { "-mprocessor=$Device" } else { "-mcpu=$Device" }
$ccArgs = @($cpuFlag, "-mdfp=$dfpPath", $Source, '-o', $out)
# XC16/XC-DSC: without the chip linker script the link cannot find the SFRs (or falls back to dsPIC30F).
if ($Family -in 'xc16', 'xcdsc') { $ccArgs += "-Wl,--script=p$Device.gld" }
Remove-Item $hex -ErrorAction SilentlyContinue  # never let an old .hex pass for a new one
Write-Host "> `"$cc`" $($ccArgs -join ' ')"
& $cc @ccArgs
$code = $LASTEXITCODE
if ($code -ne 0) { Write-Host "Build failed (exit code $code)." -ForegroundColor Red; exit $code }

if ($Family -ne 'xc8') {
    # gcc produces an .elf; the toolchain's own bin2hex converts it to .hex.
    $bin2hex = Get-ChildItem (Split-Path $cc) -Filter '*bin2hex.exe' | Select-Object -First 1
    if (-not $bin2hex) { Write-Host "bin2hex not found next to $cc; .elf is at $out" -ForegroundColor Red; exit 1 }
    # XC16/XC-DSC: without -mdfp, bin2hex leaves the interrupt vector table out of the .hex.
    $b2hArgs = @($out) + $(if ($Family -in 'xc16', 'xcdsc') { "-mdfp=$dfpPath" } else { @() })
    & $bin2hex.FullName @b2hArgs
    if ($LASTEXITCODE -ne 0) { Write-Host "bin2hex failed (exit code $LASTEXITCODE)." -ForegroundColor Red; exit $LASTEXITCODE }
}

if (Test-Path $hex) { Write-Host "OK: $((Resolve-Path $hex).Path)" -ForegroundColor Green; exit 0 }
Write-Host "Build succeeded, but no .hex appeared at $hex" -ForegroundColor Red
exit 1
