
class axi4_lite_monitor extends uvm_monitor;
    `uvm_component_utils(axi4_lite_monitor)

    virtual axi4_lite_if vif;

    uvm_analysis_port #(axi4_lite_transaction) ap;

    function new(string name = "axi4_lite_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);
        if (!uvm_config_db #(virtual axi4_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG_DB", "Virtual interface 'vif' not found in uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Monitor started", UVM_MEDIUM)

        // two threads, one for read and the other for write, both run forever
        fork
            monitor_write();
            monitor_read();
        join
    endtask

    // -------------------------------------------------------------------------
    // monitor_write / monitor_read both use @(posedge vif.clk) for time
    // advancement — NOT @(vif.monitor_cb).  Verilator's clocking-block event
    // fires immediately when called from within a clocking-block callback
    // (same-edge re-trigger), which causes one-cycle handshake windows to be
    // consumed without being observed.  @(posedge vif.clk) does not have this
    // issue and correctly advances to the NEXT clock edge every time.
    //
    // Signal values are still read through vif.monitor_cb.X, which uses
    // `input #1step` and gives the Preponed (pre-edge) sample — the same
    // value the DUT's flip-flops use for their input evaluation.
    // -------------------------------------------------------------------------

    task monitor_write();

        axi4_lite_transaction tr;
        bit [31:0] cap_addr;
        bit [31:0] cap_wdata;
        bit [3:0]  cap_wstrb;
        bit        aw_seen;
        bit        w_seen;

        forever begin
            aw_seen   = 0;
            w_seen    = 0;
            cap_addr  = '0;
            cap_wdata = '0;
            cap_wstrb = '0;

            // Step 1: Capture AW and W handshakes (may occur same cycle)
            while (!aw_seen || !w_seen) begin
                @(posedge vif.clk);

                // AW handshake
                if (!aw_seen && vif.monitor_cb.awvalid && vif.monitor_cb.awready) begin
                    cap_addr = vif.monitor_cb.awaddr;
                    aw_seen  = 1;
                    `uvm_info(get_type_name(), $sformatf("MON WR – AW: addr=0x%08h", cap_addr), UVM_HIGH)
                end

                // W handshake
                if (!w_seen && vif.monitor_cb.wvalid && vif.monitor_cb.wready) begin
                    cap_wdata = vif.monitor_cb.wdata;
                    cap_wstrb = vif.monitor_cb.wstrb;
                    w_seen    = 1;
                    `uvm_info(get_type_name(), $sformatf("MON WR – W:  data=0x%08h strb=4'b%04b", cap_wdata, cap_wstrb), UVM_HIGH)
                end
            end

            // Step 2: Wait for write response
            while (!(vif.monitor_cb.bvalid && vif.monitor_cb.bready))
                @(posedge vif.clk);

            // Step 3: Build transaction and broadcast
            tr            = axi4_lite_transaction::type_id::create("wr_tr");
            tr.trans_type = WRITE;
            tr.addr       = cap_addr;
            tr.wdata      = cap_wdata;
            tr.wstrb      = cap_wstrb;
            tr.resp       = vif.monitor_cb.bresp;

            `uvm_info(get_type_name(), $sformatf("MON WR done: %s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

    task monitor_read();
        axi4_lite_transaction tr;
        bit [31:0] cap_addr;

        forever begin
            cap_addr = '0;

            // Step 1: AR handshake
            while (!(vif.monitor_cb.arvalid && vif.monitor_cb.arready))
                @(posedge vif.clk);

            cap_addr = vif.monitor_cb.araddr;
            `uvm_info(get_type_name(), $sformatf("MON RD – AR: addr=0x%08h", cap_addr), UVM_HIGH)

            // Step 2: R handshake
            while (!(vif.monitor_cb.rvalid && vif.monitor_cb.rready))
                @(posedge vif.clk);

            // Step 3: Build transaction and broadcast
            tr            = axi4_lite_transaction::type_id::create("rd_tr");
            tr.trans_type = READ;
            tr.addr       = cap_addr;
            tr.rdata      = vif.monitor_cb.rdata;
            tr.resp       = vif.monitor_cb.rresp;

            `uvm_info(get_type_name(), $sformatf("MON RD done: %s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask
endclass
