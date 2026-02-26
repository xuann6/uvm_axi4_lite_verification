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

# Compile + run the random test (200 random R/W transactions)
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

The functional coverage collector (`axi4_lite_coverage`) reports is as following. Notice that Verilator is a 2-state simulator and does not support covergroup as VCS. For randomized stimulus generation I use 200 transactions to hit 100% coverage rate.

```
╔══════════════════════════════════════════════════════════════╗
║             AXI4-Lite Functional Coverage Report             ║
╠══════════════════════════════════════════════════════════════╣
║  Coverpoint          Bins  Hit   Coverage                    ║
╠══════════════════════════════════════════════════════════════╣
║    [0] WRITE  : 148 hits
║    [1] READ   : 52 hits
║    [0] low  (0x00-0x0C): 3 hits
║    [1] mid  (0x10-0x1C): 8 hits
║    [2] high (0x20-0x3C): 189 hits
║    [0] byte0  (4'b0001): 10 hits
║    [1] byte1  (4'b0010): 10 hits
║    [2] byte2  (4'b0100): 10 hits
║    [3] byte3  (4'b1000): 16 hits
║    [4] lo_hw  (4'b0011): 5 hits
║    [5] hi_hw  (4'b1100): 15 hits
║    [6] full   (4'b1111): 11 hits
║    [0] OKAY   (2'b00): 32 hits
║    [1] SLVERR (2'b01): 168 hits
║    WRITE×low=2  WRITE×mid=6  WRITE×high=140
║    READ×low =1  READ×mid =2  READ×high =49
║    WR×byte0=10  WR×byte1=10  WR×byte2=10  WR×byte3=16
║    WR×lo_hw=5  WR×hi_hw=15  WR×full =11
╠══════════════════════════════════════════════════════════════╣
║  OVERALL COVERAGE      27    27   100.00%                    ║
╚══════════════════════════════════════════════════════════════╝

╔══════════════════════════════════════════╗
║       AXI4-Lite Scoreboard Summary       ║
╠══════════════════════════════════════════╣
║  Writes           :    148               ║
║  Reads            :     52               ║
║  SLVERR writes    :    125               ║
║  SLVERR reads     :     43               ║
║  Errors           :      0               ║
╠══════════════════════════════════════════╣
║  Result  : *** TEST PASSED ***           ║
╚══════════════════════════════════════════╝
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

---

## AXI4-Lite Protocol Note

- **Handshake rule:** Once `valid` is asserted it must not be de-asserted until
`ready` is seen.