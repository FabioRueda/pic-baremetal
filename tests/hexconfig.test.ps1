# Test for hexconfig.ps1. Run: .\tests\hexconfig.test.ps1  (exits with code 1 on failure)
. "$PSScriptRoot\..\hexconfig.ps1"
$tmp = Join-Path ([IO.Path]::GetTempPath()) "hexconfig-test-$PID.hex"
$fail = 0
function Check($name, $cond) { if ($cond) { "ok   $name" } else { "FAIL $name"; $script:fail++ } }

# PIC18: code at 0x0000 (must be ignored) + 10 CONFIG bytes at 0x300000 (from the real blink build)
Set-Content $tmp ':04000000FEEFFFF020', ':020000040030CA', ':0A0000008CDFFFFF9FFFFFFFFFFFF3', ':00000001FF'
$r = Format-HexConfig '18F47Q10' $tmp
Check 'PIC18 reads 10 bytes' ($r.Count -eq 10)
Check 'PIC18 CONFIG1L' ($r[0] -eq '0x300000 = 0x8C')
Check 'PIC18 CONFIG3L' ($r[4] -eq '0x300004 = 0x9F')
Check 'PIC prefix accepted' ((Format-HexConfig 'PIC18F47Q10' $tmp).Count -eq 10)

# PIC16: word 0x8007 = 0x3FEC (bytes EC 3F at .hex address 0x1000E)
Set-Content $tmp ':020000040001F9', ':02000E00EC3FC5', ':00000001FF'
$r = Format-HexConfig '16F18446' $tmp
Check 'PIC16 word 0x8007' ($r -eq '0x8007 = 0x3FEC')

# No CONFIG in the .hex: empty list (not $null)
Set-Content $tmp ':04000000FEEFFFF020', ':00000001FF'
$r = Format-HexConfig '18F47Q10' $tmp
Check 'no CONFIG -> empty' ($null -ne $r -and $r.Count -eq 0)

# PIC24/dsPIC/PIC32: addresses and names come from the DFP (requires the packs installed). Lines from the built examples.
Set-Content $tmp ':020000040002f8', ':04aff8009f7800003e', ':04affc007f3f000093', ':00000001FF'
$r = Format-HexConfig '24FJ128GA010' $tmp
Check 'PIC24 CONFIG2' ($r[0] -match '^CONFIG2 +0x0157FC = 0x789F$')
Check 'PIC24 CONFIG1' ($r[1] -match '^CONFIG1 +0x0157FE = 0x3F7F$')

Set-Content $tmp ':020000040005f5', ':047e5000dfffff0051', ':00000001FF'
$r = Format-HexConfig '33CK256MP508' $tmp
Check 'dsPIC shows only what the .hex writes' ($r.Count -eq 1 -and $r[0] -match '^FICD +0x02BF28 = 0xFFFFDF$')

Set-Content $tmp ':020000041fc01b', ':042ff80058cf7fff30', ':042ffc00ffffff7f55', ':00000001FF'
$r = Format-HexConfig '32MX795F512L' $tmp
Check 'PIC32 DEVCFG1 (nzwidth in hex in the DFP)' ($r[0] -match '^DEVCFG1 +0x1FC02FF8 = 0xFF7FCF58$')
Check 'PIC32 DEVCFG0' ($r[1] -match '^DEVCFG0 +0x1FC02FFC = 0x7FFFFFFF$')

# Device without a DFP: $null
Check 'unknown device -> $null' ($null -eq (Format-HexConfig 'XYZ123' $tmp))

# Bad checksum: throws
Set-Content $tmp ':0A0000008CDFFFFF9FFFFFFFFFFFF4', ':00000001FF'
$threw = $false; try { Format-HexConfig '18F47Q10' $tmp | Out-Null } catch { $threw = $true }
Check 'bad checksum throws' $threw

Remove-Item $tmp
if ($fail) { exit 1 }
