# Dual-Port RAM Controller (`simple_dual_port_ram`)

A parameterized, synthesizable SystemVerilog **Simple Dual-Port RAM** (1 synchronous write port, 1 asynchronous read port) with a self-checking testbench.

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Architecture & Behavior](#architecture--behavior)
- [Parameters](#parameters)
- [Port Interface](#port-interface)
- [Verification & Testbench](#verification--testbench)
- [Running Simulation](#running-simulation)
- [Design & Synthesis Notes](#design--synthesis-notes)
- [License](#license)

---

## Overview

`simple_dual_port_ram` implements a dual-port memory block with decoupled write and read ports:

- **Write Port (`clk`, `write_en`, `write_address`, `write_data`)**: Synchronous write on the rising edge of `clk` when `write_en` is asserted.
- **Read Port (`read_address`, `read_data`)**: Asynchronous (combinational) read that immediately reflects `memory[read_address]`.

Because the two ports use independent address buses (`write_address` and `read_address`), one location can be read continuously while another location is being written on the clock edge.

---

## Repository Structure

```text
Dual-Port-RAM-Controller/
├── .github/
│   └── workflows/
│       └── simulate.yml          # GitHub Actions CI workflow (Icarus Verilog)
├── .gitignore                    # Ignores build/ and simulation artifacts (*.out, *.vcd, *.fst)
├── LICENSE                       # MIT License
├── README.md                     # Project documentation
├── rtl/
│   └── simple_dual_port_ram.sv   # Parameterized Simple Dual-Port RAM RTL module
├── scripts/
│   ├── run_sim.ps1               # Windows PowerShell simulation script
│   └── run_sim.sh                # Linux/macOS Bash simulation script
└── tb/
    └── tb_simple_dual_port_ram.sv # Self-checking SystemVerilog testbench
```

---

## Architecture & Behavior

```text
                 +-------------------------------+
  clk ---------->|                               |
  write_en ----->|                               |
  write_address >|    simple_dual_port_ram       |
  write_data --->|    memory[0 : (1<<ADDR)-1]    |---> read_data
  read_address ->|                               |
                 +-------------------------------+
```

1. **Synchronous Write (`always_ff @(posedge clk)`)**:
   - On every rising edge of `clk`, if `write_en == 1'b1`, `write_data` is stored at `memory[write_address]`.
   - Before the rising clock edge, pending write inputs do not alter stored memory contents.
2. **Asynchronous Read (`assign read_data = memory[read_address]`)**:
   - Any change on `read_address` propagates combinationally to `read_data` without requiring a clock edge.
   - Reading an address while writing to a different address keeps `read_data` stable and unaffected.
   - Reading the same address currently targeted by `write_address` returns the previous stored word until the rising clock edge completes the write, after which `read_data` reflects the newly written word.

---

## Parameters

| Parameter    | Type  | Default | Derived / Constraint     | Description                                       |
|--------------|-------|---------|--------------------------|---------------------------------------------------|
| `DATA_WIDTH` | `int` | `8`     | `>= 1`                   | Bit width of each memory word                     |
| `ADDR_WIDTH` | `int` | `3`     | `>= 1`                   | Bit width of `write_address` and `read_address`   |
| `DEPTH`      | `int` | `8`     | `localparam = 1 << ADDR_WIDTH` | Total number of addressable words in memory |

---

## Port Interface

| Port            | Direction | Width            | Clocking / Domain | Description                                      |
|-----------------|-----------|------------------|-------------------|--------------------------------------------------|
| `clk`           | `input`   | `1`              | Clock             | Rising-edge clock governing write operations     |
| `write_en`      | `input`   | `1`              | Synchronous       | Active-high write enable                         |
| `write_address` | `input`   | `ADDR_WIDTH`     | Synchronous       | Destination address for write operations         |
| `write_data`    | `input`   | `DATA_WIDTH`     | Synchronous       | Data word written into memory on `posedge clk`   |
| `read_address`  | `input`   | `ADDR_WIDTH`     | Combinational     | Source address for asynchronous read operations  |
| `read_data`     | `output`  | `DATA_WIDTH`     | Combinational     | Data word read from `memory[read_address]`       |

---

## Verification & Testbench

The self-checking testbench [`tb/tb_simple_dual_port_ram.sv`](tb/tb_simple_dual_port_ram.sv) instantiates `simple_dual_port_ram #(.DATA_WIDTH(8), .ADDR_WIDTH(3))` with a 10 ns clock (`always #5 clk = ~clk;`) and verifies:

1. **Asynchronous Read After Write**:
   - Writes `8'h3c` to address `3'd1` and `8'ha5` to address `3'd6`.
   - Switches `read_address` between `3'd1` and `3'd6` without a clock edge and verifies `read_data` returns `8'h3c` and `8'ha5`.
2. **Simultaneous Read and Write to Different Addresses**:
   - Holds `read_address = 3'd1` while asserting `write_en` to overwrite `3'd6` with `8'h5a`.
   - Confirms `read_data` remains `8'h3c` before and after the write clock edge, and then reads `3'd6` to verify `8'h5a` was written.
3. **Same-Address Write Timing**:
   - Drives `write_address = 3'd1`, `write_data = 8'hc3`, `read_address = 3'd1`, and `write_en = 1'b1`.
   - Confirms `read_data` stays `8'h3c` prior to `posedge clk` and updates to `8'hc3` immediately after `posedge clk`.

On success, the simulation prints:

```text
PASS: simple_dual_port_ram
```

Any mismatch terminates simulation immediately via `$fatal`.

---

## Running Simulation

### Prerequisites

- [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog` and `vvp`) with SystemVerilog (`-g2012`) support.

### Using Helper Scripts

**Windows PowerShell:**

```powershell
.\scripts\run_sim.ps1
```

**Linux / macOS:**

```bash
bash scripts/run_sim.sh
```

### Direct Command Line

```bash
mkdir -p build
iverilog -g2012 -Wall -s tb_simple_dual_port_ram \
  -o build/simple_dual_port_ram.out \
  rtl/simple_dual_port_ram.sv \
  tb/tb_simple_dual_port_ram.sv
vvp build/simple_dual_port_ram.out
```

### Continuous Integration

GitHub Actions is configured in [`.github/workflows/simulate.yml`](.github/workflows/simulate.yml) to automatically compile and run `tb_simple_dual_port_ram` with Icarus Verilog on every push and pull request to `main`.

---

## Design & Synthesis Notes

- **No Reset / Memory Initialization**: Memory contents are uninitialized at power-up/reset. Always write to an address before reading from it.
- **FPGA Synthesis Consideration**: Because `read_data` is driven combinationally (`assign read_data = memory[read_address];`), FPGA synthesis tools typically infer **distributed (LUT) RAM** or registers rather than synchronous **Block RAM (BRAM)**, which normally requires a clocked output register.

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
