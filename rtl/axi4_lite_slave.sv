
module axi4_lite_slave #(
    parameter int unsigned ADDR_WIDTH = 32,
    parameter int unsigned DATA_WIDTH = 32
)(
    input  logic                  aclk,
    input  logic                  aresetn,        // active-low synchronous reset

    // Write Address Channel
    input  logic [ADDR_WIDTH-1:0] awaddr,
    input  logic                  awvalid,
    output logic                  awready,

    // Write Data Channel
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [3:0]            wstrb,
    input  logic                  wvalid,
    output logic                  wready,

    // Write Response Channel
    output logic [1:0]            bresp,
    output logic                  bvalid,
    input  logic                  bready,

    // Read Address Channel
    input  logic [ADDR_WIDTH-1:0] araddr,
    input  logic                  arvalid,
    output logic                  arready,

    // Read Data Channel
    output logic [DATA_WIDTH-1:0] rdata,
    output logic [1:0]            rresp,
    output logic                  rvalid,
    input  logic                  rready
);

    localparam int unsigned NUM_REGS  = 16;
    localparam int unsigned REG_BYTES = NUM_REGS * 4;   // 64 bytes → 0x00..0x3C

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_SLVERR = 2'b01;

    // Register File
    logic [DATA_WIDTH-1:0] reg_file [0:NUM_REGS-1];

    // -------------------------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------------------------
    function automatic logic addr_ok(input logic [ADDR_WIDTH-1:0] a);
        addr_ok = (a[1:0] == 2'b00) &&
                  (a < ADDR_WIDTH'(REG_BYTES));
    endfunction

    function automatic int unsigned ridx(input logic [ADDR_WIDTH-1:0] a);
        ridx = int'(a[5:2]);
    endfunction

    // =========================================================================
    // WRITE PATH
    // =========================================================================

    logic                  aw_done;
    logic                  w_done;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [3:0]            wr_strb;
    logic [1:0]            wr_resp;

    logic wr_exec;
    assign wr_exec = aw_done & w_done;

    // ── Ready signals (combinational) ─────────────────────────────────────────
    assign awready = !aw_done;
    assign wready  = !w_done;

    // ── AW beat capture ───────────────────────────────────────────────────────
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            aw_done <= 1'b0;
            wr_addr <= '0;
            wr_resp <= RESP_OKAY;
        end else if (awvalid && awready) begin
            // Handshake successfully
            aw_done <= 1'b1;
            wr_addr <= awaddr;
            wr_resp <= addr_ok(awaddr) ? RESP_OKAY : RESP_SLVERR;
        end else if (bvalid && bready) begin
            // Response completed, good for next transaction
            aw_done <= 1'b0;
        end
    end

    // ── W beat capture ────────────────────────────────────────────────────────
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            w_done  <= 1'b0;
            wr_data <= '0;
            wr_strb <= '0;
        end else if (wvalid && wready) begin
            w_done  <= 1'b1;
            wr_data <= wdata;
            wr_strb <= wstrb;
        end else if (bvalid && bready) begin
            w_done <= 1'b0;
        end
    end

    // ── Write response channel ────────────────────────────────────────────────
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            bvalid <= 1'b0;
            bresp  <= RESP_OKAY;
        end else if (wr_exec && !bvalid) begin
            bvalid <= 1'b1;
            bresp  <= wr_resp;
        end else if (bvalid && bready) begin
            bvalid <= 1'b0;
        end
    end

    // ── Register file write ───────────────────────────────────────────────────
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            for (int i = 0; i < NUM_REGS; i++)
                reg_file[i] <= '0;
        end else if (wr_exec && !bvalid && addr_ok(wr_addr)) begin
            automatic int unsigned idx = ridx(wr_addr);
            if (wr_strb[0]) reg_file[idx][ 7: 0] <= wr_data[ 7: 0];
            if (wr_strb[1]) reg_file[idx][15: 8] <= wr_data[15: 8];
            if (wr_strb[2]) reg_file[idx][23:16] <= wr_data[23:16];
            if (wr_strb[3]) reg_file[idx][31:24] <= wr_data[31:24];
        end
    end

    // =========================================================================
    // READ PATH
    // =========================================================================

    assign arready = !rvalid;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            rvalid <= 1'b0;
            rdata  <= '0;
            rresp  <= RESP_OKAY;
        end else if (arvalid && arready) begin
            // AR handshake successfully
            rvalid <= 1'b1;
            if (addr_ok(araddr)) begin
                rdata <= reg_file[ridx(araddr)];
                rresp <= RESP_OKAY;
            end else begin
                rdata <= '0;
                rresp <= RESP_SLVERR;
            end
        end else if (rvalid && rready) begin
            // Master consumed the data; return to idle.
            rvalid <= 1'b0;
        end
    end

endmodule