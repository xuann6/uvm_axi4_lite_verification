
class axi4_lite_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi4_lite_scoreboard)

    uvm_analysis_imp #(axi4_lite_transaction, axi4_lite_scoreboard) analysis_imp;

    bit [31:0] ref_mem [bit [31:0]];

    int unsigned write_count;
    int unsigned read_count;
    int unsigned error_count;
    int unsigned slverr_write_count;   // expected SLVERR writes (out-of-range)
    int unsigned slverr_read_count;    // expected SLVERR reads  (out-of-range)

    function new(string name = "axi4_lite_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_imp = new("analysis_imp", this);
    endfunction

    function void write(axi4_lite_transaction tr);
        case (tr.trans_type)
            WRITE : check_write(tr);
            READ  : check_read(tr);
            default: `uvm_error(get_type_name(), $sformatf("Unknown trans_type in scoreboard: %0d", tr.trans_type))
        endcase
    endfunction

    function void check_write(axi4_lite_transaction tr);
        write_count++;

        `uvm_info(get_type_name(), $sformatf("Write addr=0x%08h data=0x%08h strb=4'b%04b resp=2'b%02b", tr.addr, tr.wdata, tr.wstrb, tr.resp), UVM_MEDIUM)

        if (tr.resp == 2'b01) begin
            slverr_write_count++;
            `uvm_info(get_type_name(), $sformatf("  SLVERR write (expected) at addr=0x%08h", tr.addr), UVM_MEDIUM)
            return;
        end

        if (tr.resp !== 2'b00) begin
            `uvm_error(get_type_name(), $sformatf("Unexpected write response 2'b%02b at addr=0x%08h", tr.resp, tr.addr))
            error_count++;
            return;
        end

        // Initialize if not exist
        if (!ref_mem.exists(tr.addr)) begin
            ref_mem[tr.addr] = 32'h0000_0000;
        end

        if (tr.wstrb[0]) ref_mem[tr.addr][ 7: 0] = tr.wdata[ 7: 0];
        if (tr.wstrb[1]) ref_mem[tr.addr][15: 8] = tr.wdata[15: 8];
        if (tr.wstrb[2]) ref_mem[tr.addr][23:16] = tr.wdata[23:16];
        if (tr.wstrb[3]) ref_mem[tr.addr][31:24] = tr.wdata[31:24];

        `uvm_info(get_type_name(), $sformatf("  ref_mem[0x%08h] updated → 0x%08h", tr.addr, ref_mem[tr.addr]), UVM_HIGH)
    endfunction

    function void check_read(axi4_lite_transaction tr);
        bit [31:0] expected;
        read_count++;

        `uvm_info(get_type_name(), $sformatf("Read  addr=0x%08h rdata=0x%08h resp=2'b%02b", tr.addr, tr.rdata, tr.resp), UVM_MEDIUM)

        if (tr.resp == 2'b01) begin
            slverr_read_count++;
            `uvm_info(get_type_name(), $sformatf("  SLVERR read (expected) at addr=0x%08h", tr.addr), UVM_MEDIUM)
            return;
        end

        if (tr.resp !== 2'b00) begin
            `uvm_error(get_type_name(), $sformatf("Unexpected read response 2'b%02b at addr=0x%08h", tr.resp, tr.addr))
            error_count++;
            return;
        end

        // check read data against reference model
        expected = ref_mem.exists(tr.addr) ? ref_mem[tr.addr] : 32'h0000_0000;
        if (tr.rdata !== expected) begin
            `uvm_error(get_type_name(), $sformatf("READ MISMATCH at addr=0x%08h | expected=0x%08h | got=0x%08h", tr.addr, expected, tr.rdata))
            error_count++;
        end else begin
            `uvm_info(get_type_name(), $sformatf("  Read addr=0x%08h expected=0x%08h got=0x%08h  [OK]", tr.addr, expected, tr.rdata), UVM_HIGH)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        string summary;
        summary = {"\n",
            "╔══════════════════════════════════════════╗\n",
            "║       AXI4-Lite Scoreboard Summary       ║\n",
            "╠══════════════════════════════════════════╣\n",
            $sformatf("║  Writes           : %6d                ║\n", write_count),
            $sformatf("║  Reads            : %6d                ║\n", read_count),
            $sformatf("║  SLVERR writes    : %6d                ║\n", slverr_write_count),
            $sformatf("║  SLVERR reads     : %6d                ║\n", slverr_read_count),
            $sformatf("║  Errors           : %6d                ║\n", error_count),
            "╠══════════════════════════════════════════╣\n"
        };

        if (error_count == 0)
            summary = {summary,
                "║  Result  : *** TEST PASSED ***           ║\n",
                "╚══════════════════════════════════════════╝\n"};
        else
            summary = {summary,
                $sformatf("║  Result  : *** TEST FAILED (%0d errors) ***\n",
                          error_count),
                "╚══════════════════════════════════════════╝\n"};

        `uvm_info(get_type_name(), summary, UVM_NONE)

        if (error_count > 0)
            `uvm_error(get_type_name(), $sformatf("Scoreboard detected %0d error(s)", error_count))
    endfunction
endclass
