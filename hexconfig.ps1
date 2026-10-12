# hexconfig.ps1 - reads the CONFIG words from a .hex (Intel HEX) so flash.ps1 can show them before programming.
# PIC18 and PIC10/12/16: fixed range. PIC24/dsPIC/PIC32: the address varies per chip, so it comes from the DFP .PIC file.

. "$PSScriptRoot\toolchain.ps1"  # $PACKS

# CONFIG registers (name, address, bits) read from the newest DFP .PIC file, or $null if not found.
function Get-DfpConfigRegs([string]$Device) {
    $part = $Device -replace '^(DS)?PIC', ''
    $edc = Get-ChildItem ($PACKS | Where-Object { Test-Path $_ } | ForEach-Object { "$_\Microchip\*\*\edc\*$part.PIC" }) -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -match "^(DS)?(PIC)?$part$" } |  # skip AC..._AS_ (header boards)
        Sort-Object { try { [version]$_.Directory.Parent.Name } catch { [version]'0.0' } } -Descending |
        Select-Object -First 1
    if (-not $edc) { return $null }
    $text = [IO.File]::ReadAllText($edc.FullName)
    $regs = foreach ($m in [regex]::Matches($text, '<edc:DCRDef [^>]*>')) {
        $t = $m.Value
        [pscustomobject]@{
            Name = [regex]::Match($t, 'edc:cname="([^"]*)"').Groups[1].Value
            Addr = [Convert]::ToInt64([regex]::Match($t, 'edc:_addr="0x([0-9A-Fa-f]+)"').Groups[1].Value, 16)
            Bits = [int][regex]::Match($t, 'edc:nzwidth="((0x)?[0-9A-Fa-f]+)"').Groups[1].Value  # comes as "32" or "0x20"
        }
    }
    , @($regs)
}

function Get-ConfigRange([string]$Device) {
    switch -Regex ($Device) {
        '^(PIC)?18F'     { return @(0x300000, 0x30FFFF) }
        '^(PIC)?1[026]F' { return @(0x1000E, 0x1001F) }  # words 0x8007-0x800F; the .hex uses address x2
    }
    return $null
}

# Returns address -> byte for everything the .hex writes inside [Lo, Hi]. Throws on a corrupted line.
function Read-HexRange([string]$Path, [long]$Lo, [long]$Hi) {
    $out = [Collections.Generic.SortedDictionary[long, byte]]::new()
    $base = 0L
    $n = 0
    foreach ($line in Get-Content $Path) {
        $n++
        $line = $line.Trim()
        if (-not $line) { continue }
        if ($line[0] -ne ':' -or $line.Length % 2 -ne 1) { throw "Invalid .hex line $n`: $line" }
        $raw = for ($i = 1; $i -lt $line.Length; $i += 2) { [Convert]::ToByte($line.Substring($i, 2), 16) }
        if (($raw | Measure-Object -Sum).Sum % 256 -ne 0) { throw "Bad checksum on .hex line $n`: $line" }
        $len = $raw[0]; $addr = $raw[1] * 256 + $raw[2]; $type = $raw[3]
        if ($raw.Count -ne $len + 5) { throw "Bad length on .hex line $n`: $line" }
        switch ($type) {
            0 { for ($k = 0; $k -lt $len; $k++) { $a = $base + $addr + $k; if ($a -ge $Lo -and $a -le $Hi) { $out[$a] = $raw[4 + $k] } } }
            1 { return ,$out }  # comma: return the dictionary without unrolling it
            2 { $base = ([long]$raw[4] * 256 + $raw[5]) * 16 }
            4 { $base = ([long]$raw[4] * 256 + $raw[5]) * 65536 }
        }
    }
    ,$out
}

# Text lines with the .hex CONFIG, or $null if the family is not supported / the DFP was not found.
function Format-HexConfig([string]$Device, [string]$Hex) {
    $range = Get-ConfigRange $Device
    if (-not $range) { return Format-DfpConfig $Device $Hex }
    $cfg = Read-HexRange $Hex $range[0] $range[1]
    if ($cfg.Count -eq 0) { return ,@() }  # empty, but distinct from $null (unsupported family)
    if ($Device -match '^(PIC)?18F') {
        # PIC18: one byte per address (CONFIG1L at 0x300000, CONFIG1H at 0x300001, ...)
        return $cfg.Keys | ForEach-Object { '0x{0:X6} = 0x{1:X2}' -f $_, $cfg[$_] }
    }
    # PIC10/12/16: 14-bit word, little-endian, word address = .hex address / 2
    return $cfg.Keys | Where-Object { $_ % 2 -eq 0 } | ForEach-Object {
        '0x{0:X4} = 0x{1:X4}' -f ($_ / 2), ($cfg[$_] + 256 * ($(if ($cfg.ContainsKey($_ + 1)) { $cfg[$_ + 1] } else { 0 })))
    }
}

# PIC24/dsPIC/PIC32: one register per line, with the DFP name. Only shows the ones the .hex writes
# (dsPIC33C lists the same CONFIG in three places, one per flash partition mode).
function Format-DfpConfig([string]$Device, [string]$Hex) {
    $regs = Get-DfpConfigRegs $Device
    if (-not $regs) { return $null }
    # PIC18/PIC32: byte addresses. PIC10/12/16/24/dsPIC: word addresses, which are x2 in the .hex.
    $scale = if ($Device -match '^(PIC)?(18|32)') { 1 } else { 2 }
    $lo = ($regs | Measure-Object Addr -Minimum).Minimum * $scale
    $hi = ($regs | Measure-Object Addr -Maximum).Maximum * $scale + 3
    $cfg = Read-HexRange $Hex $lo $hi
    $lines = foreach ($r in $regs | Sort-Object Addr) {
        $n = [math]::Ceiling($r.Bits / 8)
        $a = $r.Addr * $scale
        if ($n -gt 0 -and -not (0..($n - 1) | Where-Object { -not $cfg.ContainsKey($a + $_) })) {
            $v = 0L; for ($k = $n - 1; $k -ge 0; $k--) { $v = $v * 256 + $cfg[$a + $k] }  # little-endian
            "{0,-9} 0x{1:X6} = 0x{2}" -f $r.Name, $r.Addr, $v.ToString("X$($n * 2)")
        }
    }
    , @($lines)
}
