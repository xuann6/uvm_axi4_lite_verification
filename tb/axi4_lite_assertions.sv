
module axi4_lite_assertions (
    input logic        clk,
    input logic        rst_n,

    // Write Address Channel
    input logic        awvalid,
    input logic        awready,
    input logic [31:0] awaddr,

    // Write Data Channel
    input logic        wvalid,
    input logic        wready,

    // Write Response Channel
    input logic        bvalid,
    input logic        bready,
    input logic [1:0]  bresp,

    // Read Address Channel
    input logic        arvalid,
    input logic        arready,
    input logic [31:0] araddr,

    // Read Data Channel
    input logic        rvalid,
    input logic        rready,
    input logic [1:0]  rresp
);

    // =========================================================================
    // 1. AW valid stability 
    // =========================================================================
    property aw_valid_stable_p;
        @(posedge clk) disable iff (!rst_n)
        (awvalid && !awready) |=> awvalid;
    endproperty

    AW_VALID_STABLE: assert property (aw_valid_stable_p)
        else $error("[AXI ASSERT] awvalid de-asserted before awready handshake");

    // =========================================================================
    // 2. W valid stability
    // =========================================================================
    property w_valid_stable_p;
        @(posedge clk) disable iff (!rst_n)
        (wvalid && !wready) |=> wvalid;
    endproperty

    W_VALID_STABLE: assert property (w_valid_stable_p)
        else $error("[AXI ASSERT] wvalid de-asserted before wready handshake");

    // =========================================================================
    // 3. AR valid stability
    // =========================================================================
    property ar_valid_stable_p;
        @(posedge clk) disable iff (!rst_n)
        (arvalid && !arready) |=> arvalid;
    endproperty

    AR_VALID_STABLE: assert property (ar_valid_stable_p)
        else $error("[AXI ASSERT] arvalid de-asserted before arready handshake");

    // =========================================================================
    // 4. B valid stability
    // =========================================================================
    property b_valid_stable_p;
        @(posedge clk) disable iff (!rst_n)
        (bvalid && !bready) |=> bvalid;
    endproperty

    B_VALID_STABLE: assert property (b_valid_stable_p)
        else $error("[AXI ASSERT] bvalid de-asserted before bready handshake");

    // =========================================================================
    // 5. R valid stability
    // =========================================================================
    property r_valid_stable_p;
        @(posedge clk) disable iff (!rst_n)
        (rvalid && !rready) |=> rvalid;
    endproperty

    R_VALID_STABLE: assert property (r_valid_stable_p)
        else $error("[AXI ASSERT] rvalid de-asserted before rready handshake");

    // =========================================================================
    // 6. Write address alignment (word-aligned)
    // =========================================================================
    property aw_addr_aligned_p;
        @(posedge clk) disable iff (!rst_n)
        awvalid |-> (awaddr[1:0] == 2'b00);
    endproperty

    AW_ADDR_ALIGNED: assert property (aw_addr_aligned_p)
        else $error("[AXI ASSERT] awaddr=0x%08h is not word-aligned when awvalid", awaddr);

    // =========================================================================
    // 7. Read address alignment (word-aligned)
    // =========================================================================
    property ar_addr_aligned_p;
        @(posedge clk) disable iff (!rst_n)
        arvalid |-> (araddr[1:0] == 2'b00);
    endproperty

    AR_ADDR_ALIGNED: assert property (ar_addr_aligned_p)
        else $error("[AXI ASSERT] araddr=0x%08h is not word-aligned when arvalid", araddr);

    // =========================================================================
    // 8. Valid bresp values
    //   - This slave only generates OKAY (2'b00) or SLVERR (2'b01).
    // =========================================================================
    property valid_bresp_p;
        @(posedge clk) disable iff (!rst_n)
        bvalid |-> (bresp inside {2'b00, 2'b01});
    endproperty

    VALID_BRESP: assert property (valid_bresp_p)
        else $error("[AXI ASSERT] Illegal bresp=2'b%02b when bvalid", bresp);

    // =========================================================================
    // 9. Valid rresp values
    // =========================================================================
    property valid_rresp_p;
        @(posedge clk) disable iff (!rst_n)
        rvalid |-> (rresp inside {2'b00, 2'b01});
    endproperty

    VALID_RRESP: assert property (valid_rresp_p)
        else $error("[AXI ASSERT] Illegal rresp=2'b%02b when rvalid", rresp);

endmodule
