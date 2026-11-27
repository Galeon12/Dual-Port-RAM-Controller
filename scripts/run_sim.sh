#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"

mkdir -p "${BUILD_DIR}"

echo "==> Compiling simple_dual_port_ram"
iverilog -g2012 -Wall -s tb_simple_dual_port_ram \
  -o "${BUILD_DIR}/simple_dual_port_ram.out" \
  "${ROOT_DIR}/rtl/simple_dual_port_ram.sv" \
  "${ROOT_DIR}/tb/tb_simple_dual_port_ram.sv"

echo "==> Running simulation"
vvp "${BUILD_DIR}/simple_dual_port_ram.out"
