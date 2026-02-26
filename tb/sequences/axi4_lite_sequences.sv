
class axi4_lite_base_seq extends uvm_sequence #(axi4_lite_transaction);
    `uvm_object_utils(axi4_lite_base_seq)

    function new(string name = "axi4_lite_base_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_fatal(get_type_name(), "body() not implemented – use a derived sequence")
    endtask
endclass


// 200 fully-random read/write transactions
class axi4_lite_random_seq extends axi4_lite_base_seq;
    `uvm_object_utils(axi4_lite_random_seq)

    int unsigned num_transactions =200;

    function new(string name = "axi4_lite_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi4_lite_transaction req;

        `uvm_info(get_type_name(),
                  $sformatf("Starting random sequence: %0d transactions",
                            num_transactions),
                  UVM_MEDIUM)

        repeat (num_transactions) begin
            `uvm_do(req)
            `uvm_info(get_type_name(),
                      $sformatf("  Sent: %s", req.convert2string()),
                      UVM_HIGH)
        end

        `uvm_info(get_type_name(), "Random sequence complete", UVM_MEDIUM)
    endtask
endclass


// 10 write-then-read-back pairs to the same address
class axi4_lite_wr_rd_seq extends axi4_lite_base_seq;
    `uvm_object_utils(axi4_lite_wr_rd_seq)

    int unsigned num_pairs = 10;

    function new(string name = "axi4_lite_wr_rd_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi4_lite_transaction req;

        bit [31:0] wr_addr;
        bit [31:0] wr_data;
        bit [3:0]  wr_strb;

        `uvm_info(get_type_name(),
                  $sformatf("Starting write-read-back sequence: %0d pairs",
                            num_pairs),
                  UVM_MEDIUM)

        repeat (num_pairs) begin

            // ── Write transaction ──────────────────────────────────────────
            // uvm_do_with with multi-line constraints is not resolved by the
            // preprocessor under Verilator; using start_item/finish_item instead.
            req = axi4_lite_transaction::type_id::create("req");
            start_item(req);
            if (!req.randomize() with { trans_type == WRITE; })
                `uvm_fatal(get_type_name(), "Randomization failed for write transaction")
            finish_item(req);

            wr_addr = req.addr;
            wr_data = req.wdata;
            wr_strb = req.wstrb;

            `uvm_info(get_type_name(),
                      $sformatf("  WR: %s", req.convert2string()),
                      UVM_HIGH)

            // ── Read transaction (same address) ────────────────────────────
            req = axi4_lite_transaction::type_id::create("req");
            start_item(req);
            if (!req.randomize() with { trans_type == READ; addr == wr_addr; })
                `uvm_fatal(get_type_name(), "Randomization failed for read transaction")
            finish_item(req);

            `uvm_info(get_type_name(),
                      $sformatf("  RD: %s", req.convert2string()),
                      UVM_HIGH)
        end

        `uvm_info(get_type_name(), "Write-read-back sequence complete", UVM_MEDIUM)
    endtask
endclass
