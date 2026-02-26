
//  Write protocol (drive_write)
//  ----------------------------
//   Use @(posedge vif.clk) — NOT @(vif.master_cb) — for time advancement.
//   Reason: @(vif.master_cb) called from within a @(posedge vif.clk) callback
//   re-triggers at the SAME clock edge (Verilator implementation detail), causing
//   awvalid<=1 and awvalid<=0 to race at the same 1-ns output skew slot.
//
//   Outputs are driven directly on vif (NBA at posedge, DUT sees them at next edge).
//   Inputs are read via vif.master_cb.X (clocking-block #1step Preponed sample).
//
//   Cycle 0  : assert awvalid+awaddr and wvalid+wdata+wstrb simultaneously.
//   Cycle 1  : both awready and wready seen → deassert awvalid & wvalid.
//   Cycle 2  : assert bready; wait for bvalid.
//   Cycle 3  : deassert bready; capture bresp into tr.resp.
//
//  Read protocol (drive_read)
//  --------------------------
//   Cycle 0  : assert arvalid + araddr.
//   Cycle 1  : arready seen → deassert arvalid + assert rready simultaneously.
//   Cycle 2  : rvalid seen → capture rdata + rresp; deassert rready.
// =============================================================================

class axi4_lite_driver extends uvm_driver #(axi4_lite_transaction);
    `uvm_component_utils(axi4_lite_driver)

    virtual axi4_lite_if vif;

    function new(string name = "axi4_lite_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual axi4_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG_DB", "Virtual interface 'vif' not found in uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        init_signals();
        wait_for_reset();

        forever begin
            seq_item_port.get_next_item(req);

            `uvm_info(get_type_name(), $sformatf("Driving: %s", req.convert2string()), UVM_HIGH)
            case (req.trans_type)
                WRITE : drive_write(req);
                READ  : drive_read(req);
                default: `uvm_error(get_type_name(), $sformatf("Unknown trans_type %0d", req.trans_type))
            endcase

            seq_item_port.item_done();
        end
    endtask

    task init_signals();
        vif.awaddr  <= '0;
        vif.awvalid <= 1'b0;
        vif.wdata   <= '0;
        vif.wstrb   <= 4'b0000;
        vif.wvalid  <= 1'b0;
        vif.bready  <= 1'b0;
        vif.araddr  <= '0;
        vif.arvalid <= 1'b0;
        vif.rready  <= 1'b0;
    endtask

    task wait_for_reset();
        if (!vif.rst_n) begin
            `uvm_info(get_type_name(), "Waiting for reset de-assertion ...", UVM_MEDIUM)
            @(posedge vif.rst_n);
            @(posedge vif.clk); // wait one extra cycle
            `uvm_info(get_type_name(), "Reset de-asserted – driver active", UVM_MEDIUM)
        end
    endtask

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Transaction
    // -------------------------------------------------------------------------
    task drive_write(axi4_lite_transaction tr);

        // Advance to a clean clock edge before driving.
        // Using @(posedge vif.clk) — not @(vif.master_cb) — avoids Verilator's
        // immediate re-trigger when the clocking-block event coincides with the
        // current @(posedge vif.clk) context from wait_for_reset / item_done.
        @(posedge vif.clk);

        // ── Step 1: Assert address + data channels
        vif.awaddr  <= tr.addr;
        vif.awvalid <= 1'b1;
        vif.wdata   <= tr.wdata;
        vif.wstrb   <= tr.wstrb;
        vif.wvalid  <= 1'b1;

        // ── Step 2: Wait for AW and W handshakes
        // Inputs are read via the clocking-block which samples them in the
        // Preponed region (before the posedge NBA updates aw_done/w_done),
        // giving the correct pre-handshake value of awready/wready.
        begin
            bit aw_done = 0;
            bit w_done  = 0;

            while (!aw_done || !w_done) begin
                @(posedge vif.clk);
                if (!aw_done && vif.master_cb.awready) begin
                    vif.awvalid <= 1'b0;
                    aw_done = 1;
                end
                if (!w_done && vif.master_cb.wready) begin
                    vif.wvalid <= 1'b0;
                    w_done = 1;
                end
            end
        end

        // ── Step 3: Assert bready, wait for bvalid
        @(posedge vif.clk);
        vif.bready <= 1'b1;

        while (!vif.master_cb.bvalid)
            @(posedge vif.clk);

        tr.resp = vif.master_cb.bresp; // capture response

        // ── Step 4: Deassert bready
        @(posedge vif.clk);
        vif.bready <= 1'b0;

        `uvm_info(get_type_name(), $sformatf("Write done: addr=0x%08h data=0x%08h strb=4'b%04b resp=2'b%02b",
                  tr.addr, tr.wdata, tr.wstrb, tr.resp), UVM_HIGH)
    endtask

    // -------------------------------------------------------------------------
    // AXI4-Lite Read Transaction
    // -------------------------------------------------------------------------
    task drive_read(axi4_lite_transaction tr);

        // Same reason as drive_write: use @(posedge vif.clk) for clean advance.
        @(posedge vif.clk);

        // ── Step 1: Assert AR channel
        vif.araddr  <= tr.addr;
        vif.arvalid <= 1'b1;

        // ── Step 2: Wait for arready, then deassert arvalid + assert rready
        // The slave has arready = !rvalid (combinational), usually 1 at idle.
        // The Preponed sample of arready (via clocking block) reflects
        // the pre-edge rvalid state, giving the correct handshake value.
        while (!vif.master_cb.arready)
            @(posedge vif.clk);

        @(posedge vif.clk);
        vif.arvalid <= 1'b0;
        vif.rready  <= 1'b1; // assert rready together with deassert of arvalid

        // ── Step 3: Wait for rvalid
        while (!vif.master_cb.rvalid)
            @(posedge vif.clk);

        tr.rdata = vif.master_cb.rdata;
        tr.resp  = vif.master_cb.rresp;

        // ── Step 4: Deassert rready
        @(posedge vif.clk);
        vif.rready <= 1'b0;

        `uvm_info(get_type_name(), $sformatf("Read  done: addr=0x%08h rdata=0x%08h resp=2'b%02b",
                  tr.addr, tr.rdata, tr.resp), UVM_HIGH)
    endtask
endclass
