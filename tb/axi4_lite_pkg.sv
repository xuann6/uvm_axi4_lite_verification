
package axi4_lite_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter int unsigned ADDR_WIDTH = 32;
    parameter int unsigned DATA_WIDTH = 32;

    parameter int unsigned NUM_REGS  = 16;
    parameter int unsigned REG_BYTES = NUM_REGS * 4;      // 64 = 0x40
    parameter logic [ADDR_WIDTH-1:0] REG_BASE = 32'h0000_0000;
    parameter logic [ADDR_WIDTH-1:0] REG_HIGH = 32'h0000_003C;  // last valid addr

    // =========================================================================
    // Enumerations
    // =========================================================================

    // Transaction type
    typedef enum logic {
        WRITE = 1'b0,
        READ  = 1'b1
    } trans_type_e;

    // DUT response codes.
    // This slave only generates OKAY (2'b00) or SLVERR (2'b01).
    // SLVERR is returned for out-of-range or unaligned addresses.
    typedef enum logic [1:0] {
        RESP_OKAY   = 2'b00,   // Normal successful completion
        RESP_SLVERR = 2'b01    // Slave error (out-of-range / unaligned address)
    } axi_resp_e;

    // =========================================================================
    // TB source file includes (bottom-up)
    // =========================================================================
    `include "sequences/axi4_lite_transaction.sv"
    `include "sequences/axi4_lite_sequences.sv"
    `include "agents/axi4_lite_driver.sv"
    `include "agents/axi4_lite_monitor.sv"
    `include "agents/axi4_lite_scoreboard.sv"
    `include "agents/axi4_lite_coverage.sv"
    `include "agents/axi4_lite_agent.sv"
    `include "axi4_lite_env.sv"
    `include "tests/axi4_lite_test.sv"

endpackage : axi4_lite_pkg
