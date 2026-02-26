class axi4_lite_transaction extends uvm_sequence_item;

    `uvm_object_utils_begin(axi4_lite_transaction)
        `uvm_field_enum (trans_type_e, trans_type, UVM_ALL_ON)
        `uvm_field_int  (addr,                     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int  (wdata,                    UVM_ALL_ON | UVM_HEX)
        `uvm_field_int  (wstrb,                    UVM_ALL_ON | UVM_BIN)
        `uvm_field_int  (rdata,                    UVM_ALL_ON | UVM_HEX)
        `uvm_field_int  (resp,                     UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    // random to send to DUT
    rand trans_type_e trans_type;
    rand bit [31:0]   addr;
    rand bit [31:0]   wdata;
    rand bit [3:0]    wstrb;

    // internal knob: 1 = generate an out-of-range address (triggers SLVERR) for coverage tracking
    rand bit use_oob;

    // non-random to capture from DUT 
    bit [31:0] rdata;
    bit [1:0]  resp;

    // -------------------------------------------------------------------------
    // Constraints
    // -------------------------------------------------------------------------

    // word-aligned
    constraint addr_alignment_c {
        addr[1:0] == 2'b00;
    }

    // 10% chance of out-of-range address
    constraint oob_weight_c {
        use_oob dist { 1'b0 := 90, 1'b1 := 10 };
    }

    constraint valid_addr_c {
        if (use_oob)
            addr inside {[32'h0000_0040 : 32'h0000_00FC]};
        else
            addr inside {[32'h0000_0000 : 32'h0000_003C]};
    }

    // at least one byte lane must be active on writes
    constraint valid_strb_c {
        wstrb != 4'b0000;
    }

    function new(string name = "axi4_lite_transaction");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        axi4_lite_transaction rhs_t;
        super.do_copy(rhs);

        if (!$cast(rhs_t, rhs))
            `uvm_fatal("do_copy", "Cast failed – rhs is not axi4_lite_transaction")

        trans_type = rhs_t.trans_type;
        addr       = rhs_t.addr;
        wdata      = rhs_t.wdata;
        wstrb      = rhs_t.wstrb;
        rdata      = rhs_t.rdata;
        resp       = rhs_t.resp;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        axi4_lite_transaction rhs_t;
        bit result;
        result = super.do_compare(rhs, comparer);

        if (!$cast(rhs_t, rhs))
            `uvm_fatal("do_compare", "Cast failed – rhs is not axi4_lite_transaction")

        result &= comparer.compare_field_int("trans_type", trans_type, rhs_t.trans_type,  1);
        result &= comparer.compare_field_int("addr",       addr,       rhs_t.addr,       32);
        result &= comparer.compare_field_int("wdata",      wdata,      rhs_t.wdata,      32);
        result &= comparer.compare_field_int("wstrb",      wstrb,      rhs_t.wstrb,       4);
        result &= comparer.compare_field_int("rdata",      rdata,      rhs_t.rdata,      32);
        result &= comparer.compare_field_int("resp",       resp,       rhs_t.resp,        2);
        return result;
    endfunction

    function void do_print(uvm_printer printer);
        super.do_print(printer);
        
        printer.print_string ("trans_type", trans_type.name());
        printer.print_field_int("addr",    addr,  32, UVM_HEX);
        if (trans_type == WRITE) begin
            printer.print_field_int("wdata", wdata, 32, UVM_HEX);
            printer.print_field_int("wstrb", wstrb,  4, UVM_BIN);
        end else begin
            printer.print_field_int("rdata", rdata, 32, UVM_HEX);
        end
        printer.print_field_int("resp",  resp,   2, UVM_BIN);
    endfunction

    function string convert2string();
        if (trans_type == WRITE)
            return $sformatf("WRITE addr=0x%08h wdata=0x%08h wstrb=4'b%04b resp=2'b%02b",
                             addr, wdata, wstrb, resp);
        else
            return $sformatf("READ  addr=0x%08h rdata=0x%08h resp=2'b%02b",
                             addr, rdata, resp);
    endfunction

endclass 
