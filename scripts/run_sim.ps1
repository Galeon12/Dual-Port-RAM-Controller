$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $rootDir "build"

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$outputFile = Join-Path $buildDir "simple_dual_port_ram.out"
$rtlFile = Join-Path $rootDir "rtl/simple_dual_port_ram.sv"
$tbFile = Join-Path $rootDir "tb/tb_simple_dual_port_ram.sv"

Write-Host "==> Compiling simple_dual_port_ram"
& iverilog -g2012 -Wall -s tb_simple_dual_port_ram -o $outputFile $rtlFile $tbFile
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed: simple_dual_port_ram"
}

Write-Host "==> Running simulation"
& vvp $outputFile
if ($LASTEXITCODE -ne 0) {
    throw "Simulation failed: simple_dual_port_ram"
}
