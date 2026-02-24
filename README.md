# AXI4-Lite UVM Verification Project

A complete UVM-1.2 verification environment for an AXI4-Lite slave DUT,
targeting VCS for full-featured simulation and Verilator for 2-state lint/sim.

---

## Project Structure

```
uvm_axi4_lite/
├── rtl/
│   └── axi4_lite_slave.sv          DUT – 16×32-bit register slave
│
├── tb/
│   ├── interfaces/
│   │   └── axi4_lite_if.sv         SV interface + master_cb + monitor_cb
│   │
│   ├── sequences/
│   │   ├── axi4_lite_transaction.sv  UVM sequence item (rand addr/data/strb)
│   │   └── axi4_lite_sequences.sv    base_seq / random_seq / wr_rd_seq
│   │
│   ├── agents/
│   │   ├── axi4_lite_driver.sv       UVM driver  (master clocking block)
│   │   ├── axi4_lite_monitor.sv      UVM monitor (monitor clocking block)
│   │   ├── axi4_lite_scoreboard.sv   Reference model + checker
│   │   ├── axi4_lite_coverage.sv     Functional coverage (int arrays)
│   │   └── axi4_lite_agent.sv        Agent + sequencer
│   │
│   ├── tests/
│   │   └── axi4_lite_test.sv         base_test / random_test / wr_rd_test
│   │
│   ├── axi4_lite_pkg.sv              Central package (all `include chains)
│   ├── axi4_lite_env.sv              UVM environment (agent+scoreboard+coverage)
│   ├── axi4_lite_assertions.sv       SVA protocol checker module
│   └── axi4_lite_tb_top.sv           Top-level TB (clk/rst, DUT, UVM kickoff)
│
└── sim/
    └── Makefile                      VCS compile + run + coverage targets
```

---

## DUT — Register Map

| Byte Offset | Register | Reset Value |
|-------------|----------|-------------|
| 0x00        | REG0     | 0x00000000  |
| 0x04        | REG1     | 0x00000000  |
| ...         | ...      | ...         |
| 0x3C        | REG15    | 0x00000000  |

- Addresses outside `0x00–0x3C` or unaligned → **SLVERR** (`2'b10`)
- `wstrb` byte-lane masking is fully supported

---

## UVM Architecture

```
axi4_lite_tb_top
 └── uvm_root
      └── axi4_lite_random_test / axi4_lite_wr_rd_test
           └── axi4_lite_env
                ├── axi4_lite_agent  (UVM_ACTIVE)
                │    ├── axi4_lite_sequencer
                │    ├── axi4_lite_driver   ──drives──► DUT via master_cb
                │    └── axi4_lite_monitor  ──observes─► DUT via monitor_cb
                │         └── ap (analysis_port)
                │              ├──────────────────► axi4_lite_scoreboard.analysis_imp
                │              └──────────────────► axi4_lite_coverage.analysis_export
                ├── axi4_lite_scoreboard
                └── axi4_lite_coverage
```

---

## How to Run (VCS)

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

The functional coverage collector (`axi4_lite_coverage`) reports at end-of-sim:

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

> **Note:** Verilator does not support SystemVerilog `covergroup`. Coverage is
> implemented using plain `int` arrays incremented in the `write()` function,
> which is 2-state compatible and fully portable.

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

All assertions use `disable iff (!rst_n)` to suppress spurious failures during reset.

---

## AXI4-Lite Protocol Overview

AXI4-Lite uses five independent channels, each with a valid/ready handshake.
A transaction completes when both `valid` and `ready` are simultaneously high.

```
WRITE transaction             READ transaction
─────────────────             ────────────────
Master → Slave: AW channel    Master → Slave: AR channel
Master → Slave: W  channel    Slave  → Master: R  channel
Slave  → Master: B  channel
```

**Handshake rule:** Once `valid` is asserted it must not be de-asserted until
`ready` is seen (AXI4 spec §A3.2.1). This is checked by the SVA module.

**Ready signals in this DUT:**
- `awready`, `wready` — combinational (`!aw_done`, `!w_done`)
- `arready`           — combinational (`!rvalid`)

This means handshakes always complete in one cycle under normal conditions,
giving single-cycle write address/data acceptance and single-cycle read
address acceptance.
