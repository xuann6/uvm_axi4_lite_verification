
interface axi4_lite_if #(
    parameter int unsigned ADDR_WIDTH = 32,
    parameter int unsigned DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n
);

    // -------------------------------------------------------------------------
    // AXI4-Lite signals
    // -------------------------------------------------------------------------

    // Write Address Channel
    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;

    // Write Data Channel
    logic [DATA_WIDTH-1:0] wdata;
    logic [3:0]            wstrb;
    logic                  wvalid;
    logic                  wready;

    // Write Response Channel
    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;

    // Read Address Channel
    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;

    // Read Data Channel
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rvalid;
    logic                  rready;

    clocking master_cb @(posedge clk); // for UVM driver
        default input  #1step // sample inputs 1step after the clock edge
                output #1ns; // drive outputs 1ns before the clock edge

        // ── Outputs (master → slave / DUT inputs) ────────────────────────────
        // Write address channel
        output awaddr;
        output awvalid;

        // Write data channel
        output wdata;
        output wstrb;
        output wvalid;

        // Write response channel
        output bready;

        // Read address channel
        output araddr;
        output arvalid;

        // Read data channel
        output rready;

        // ── Inputs (slave → master / DUT outputs) ────────────────────────────
        // Write address channel
        input  awready;

        // Write data channel
        input  wready;

        // Write response channel
        input  bvalid;
        input  bresp;

        // Read address channel
        input  arready;

        // Read data channel
        input  rdata;
        input  rvalid;
        input  rresp;
    endclocking

    
    clocking monitor_cb @(posedge clk);
        default input #1step; // sample inputs 1step after the clock edge

        // Write Address Channel
        input awaddr;
        input awvalid;
        input awready;

        // Write Data Channel
        input wdata;
        input wstrb;
        input wvalid;
        input wready;

        // Write Response Channel
        input bresp;
        input bvalid;
        input bready;

        // Read Address Channel
        input araddr;
        input arvalid;
        input arready;

        // Read Data Channel
        input rdata;
        input rresp;
        input rvalid;
        input rready;
    endclocking

    modport master_mp (
        clocking master_cb,
        input    clk,
        input    rst_n
    );

    modport monitor_mp (
        clocking monitor_cb,
        input    clk,
        input    rst_n
    );

endinterface
