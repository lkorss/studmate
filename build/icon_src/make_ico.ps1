# Сборка ICO (PNG-внутри-ICO, Vista+) из PNG 256x256.
$ErrorActionPreference = "Stop"
$pngPath = "build\icon_src\_windows_icon_256.png"
$icoPath = "windows\runner\resources\app_icon.ico"

if (!(Test-Path $pngPath)) { throw "PNG not found: $pngPath" }
$png = [IO.File]::ReadAllBytes((Resolve-Path $pngPath).Path)

$ico = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ico)

# ICONDIR: reserved=0, type=1 (icon), count=1
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]1)
# ICONDIRENTRY: width=0 (256), height=0 (256), colors=0, reserved=0,
# planes=1, bitcount=32, size, offset=22
$bw.Write([Byte]0); $bw.Write([Byte]0); $bw.Write([Byte]0); $bw.Write([Byte]0)
$bw.Write([UInt16]1); $bw.Write([UInt16]32)
$bw.Write([UInt32]$png.Length); $bw.Write([UInt32]22)
$bw.Write($png)
$bw.Flush()

$target = Join-Path (Get-Location) $icoPath
[System.IO.File]::WriteAllBytes($target, $ico.ToArray())
Write-Output ("ICO written: " + $target + " (" + (Get-Item $target).Length + " bytes)")
