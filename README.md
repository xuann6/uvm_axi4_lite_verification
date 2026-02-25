# AXI4-Lite UVM Verification Project

A complete UVM verification environment for an AXI4-Lite slave DUT.

---

## Project Structure

```
uvm_axi4_lite/
├── rtl/
│   └── axi4_lite_slave.sv            DUT – 16×32-bit register slave
│
├── tb/
│   ├── interfaces/
│   │   └── axi4_lite_if.sv
│   │
│   ├── sequences/
│   │   ├── axi4_lite_transaction.sv
│   │   └── axi4_lite_sequences.sv
│   │
│   ├── agents/
│   │   ├── axi4_lite_driver.sv
│   │   ├── axi4_lite_monitor.sv
│   │   ├── axi4_lite_scoreboard.sv
│   │   ├── axi4_lite_coverage.sv
│   │   └── axi4_lite_agent.sv
│   │
│   ├── tests/
│   │   └── axi4_lite_test.sv
│   │
│   ├── axi4_lite_pkg.sv
│   ├── axi4_lite_env.sv
│   ├── axi4_lite_assertions.sv
│   └── axi4_lite_tb_top.sv
│
└── sim/
    └── Makefile
```

---

## DUT — Register Map

| Byte Offset | Register | Reset Value |
|-------------|----------|-------------|
| 0x00        | REG0     | 0x00000000  |
| 0x04        | REG1     | 0x00000000  |
| ...         | ...      | ...         |
| 0x3C        | REG15    | 0x00000000  |

- Addresses outside `0x00–0x3C` or unaligned → **SLVERR** (`2'b01`)
- `wstrb` byte-lane masking is fully supported

---

## UVM Architecture

```
axi4_lite_tb_top
└── axi4_lite_random_test / axi4_lite_wr_rd_test
     └── axi4_lite_env
          ├── axi4_lite_agent  (UVM_ACTIVE)
          │    ├── axi4_lite_sequencer
          │    ├── axi4_lite_driver
          │    └── axi4_lite_monitor
          │         └── ap (analysis_port)
          │              ├──────────────────► axi4_lite_scoreboard.analysis_imp
          │              └──────────────────► axi4_lite_coverage.analysis_export
          ├── axi4_lite_scoreboard
          └── axi4_lite_coverage
```

---

## How to Run (Makefile only suppors Verilator for now)

```bash
cd sim/

# Compile only
make compile

# Compile + run the random test (20 random R/W transactions)
make run_random

# Compile + run the write-read-back test (10 WR pairs)
make run_wr_rd

# Generate coverage report (HTML + text)
make coverage

# Remove all build artefacts
make clean
```

Test selection via `+UVM_TESTNAME`:
```bash
./simv +UVM_TESTNAME=axi4_lite_random_test +UVM_VERBOSITY=UVM_HIGH
./simv +UVM_TESTNAME=axi4_lite_wr_rd_test
```

---

## Coverage Report Format

The functional coverage collector (`axi4_lite_coverage`) reports is as following. Notice that Verilator is a 2-state simulator and does not support covergroup as VCS. 

```
╔══════════════════════════════════════════════════════════════╗
║             AXI4-Lite Functional Coverage Report             ║
╠══════════════════════════════════════════════════════════════╣
║  Coverpoint          Bins  Hit   Coverage                    ║
╠══════════════════════════════════════════════════════════════╣
║  trans_type_cp          2     2   100.00%
║    [0] WRITE  : N hits
║    [1] READ   : N hits
║  addr_cp                3     3   100.00%
║    [0] low  (0x00-0x0C): N hits
║    [1] mid  (0x10-0x1C): N hits
║    [2] high (0x20-0x3C): N hits
║  wstrb_cp               7     7   100.00%
║  resp_cp                2     2   100.00%
║  cross type×addr        6     6   100.00%
║  cross type×wstrb      14    14   100.00%
╠══════════════════════════════════════════════════════════════╣
║  OVERALL COVERAGE      34    34   100.00%                    ║
╚══════════════════════════════════════════════════════════════╝
```

---

## SVA Assertions (`axi4_lite_assertions.sv`)

| Label | Check |
|---|---|
| `AW_VALID_STABLE` | awvalid held until awready |
| `W_VALID_STABLE`  | wvalid held until wready |
| `AR_VALID_STABLE` | arvalid held until arready |
| `B_VALID_STABLE`  | bvalid held until bready |
| `R_VALID_STABLE`  | rvalid held until rready |
| `AW_ADDR_ALIGNED` | awaddr word-aligned when awvalid |
| `AR_ADDR_ALIGNED` | araddr word-aligned when arvalid |
| `VALID_BRESP`     | bresp ∈ {OKAY, SLVERR} when bvalid |
| `VALID_RRESP`     | rresp ∈ {OKAY, SLVERR} when rvalid |
| `NO_X_ON_*`       | No X/Z on any control signal when valid asserted |

---

## AXI4-Lite Protocol Note

- **Handshake rule:** Once `valid` is asserted it must not be de-asserted until
`ready` is seen.