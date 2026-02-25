
class axi4_lite_coverage extends uvm_subscriber #(axi4_lite_transaction);
    `uvm_component_utils(axi4_lite_coverage)

    // =========================================================================
    // Coverage bin indices
    // =========================================================================

    // ── trans_type_cp ─────────────────────────────────────────────────────────
    // Index 0 = WRITE
    // Index 1 = READ
    localparam int TRANS_BINS = 2;
    int unsigned trans_type_hits [TRANS_BINS];

    // ── addr_cp ───────────────────────────────────────────────────────────────
    // Index 0 = low  (0x00–0x0C, regs 0-3)
    // Index 1 = mid  (0x10–0x1C, regs 4-7)
    // Index 2 = high (0x20–0x3C, regs 8-15)
    localparam int ADDR_BINS = 3;
    int unsigned addr_hits [ADDR_BINS];

    // ── wstrb_cp ──────────────────────────────────────────────────────────────
    // Index 0 = 4'b0001
    // Index 1 = 4'b0010
    // Index 2 = 4'b0100
    // Index 3 = 4'b1000
    // Index 4 = 4'b0011
    // Index 5 = 4'b1100
    // Index 6 = 4'b1111
    localparam int STRB_BINS = 7;
    int unsigned wstrb_hits [STRB_BINS];

    // ── resp_cp ───────────────────────────────────────────────────────────────
    // Index 0 = OKAY (2'b00)
    // Index 1 = SLVERR (2'b01)
    localparam int RESP_BINS = 2;
    int unsigned resp_hits [RESP_BINS];

    // ── Cross: trans_type × addr  ─────────────────────────────────────────────
    localparam int CROSS_TYPE_ADDR_BINS = TRANS_BINS * ADDR_BINS;
    int unsigned cross_type_addr_hits [CROSS_TYPE_ADDR_BINS];

    // ── Cross: trans_type × wstrb ─────────────────────────────────────────────
    localparam int CROSS_TYPE_STRB_BINS = TRANS_BINS * STRB_BINS;
    int unsigned cross_type_strb_hits [CROSS_TYPE_STRB_BINS];

    // Total
    localparam int TOTAL_BINS = TRANS_BINS
                              + ADDR_BINS
                              + STRB_BINS
                              + RESP_BINS
                              + CROSS_TYPE_ADDR_BINS
                              + CROSS_TYPE_STRB_BINS;

    function new(string name = "axi4_lite_coverage", uvm_component parent = null);
        super.new(name, parent);

        foreach (trans_type_hits[i])     trans_type_hits[i]     = 0;
        foreach (addr_hits[i])           addr_hits[i]           = 0;
        foreach (wstrb_hits[i])          wstrb_hits[i]          = 0;
        foreach (resp_hits[i])           resp_hits[i]           = 0;
        foreach (cross_type_addr_hits[i])cross_type_addr_hits[i]= 0;
        foreach (cross_type_strb_hits[i])cross_type_strb_hits[i]= 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void write(axi4_lite_transaction t);
        int type_idx;
        int addr_idx;
        int strb_idx;
        int resp_idx;

        // ── 1. trans_type_cp
        type_idx = (t.trans_type == WRITE) ? 0 : 1;
        trans_type_hits[type_idx]++;

        // ── 2. addr_cp
        if      (t.addr <= 32'h0C) addr_idx = 0;
        else if (t.addr <= 32'h1C) addr_idx = 1;
        else                       addr_idx = 2;
        addr_hits[addr_idx]++;

        // ── 3. wstrb_cp
        strb_idx = -1;
        if (t.trans_type == WRITE) begin
            case (t.wstrb)
                4'b0001: strb_idx = 0;
                4'b0010: strb_idx = 1;
                4'b0100: strb_idx = 2;
                4'b1000: strb_idx = 3;
                4'b0011: strb_idx = 4;
                4'b1100: strb_idx = 5;
                4'b1111: strb_idx = 6;
                default:  strb_idx = -1;   // other patterns not explicitly tracked
            endcase
            if (strb_idx >= 0)
                wstrb_hits[strb_idx]++;
        end

        // ── 4. resp_cp
        case (t.resp)
            2'b00: resp_idx = 0;   // OKAY
            2'b01: resp_idx = 1;   // SLVERR
            default: resp_idx = -1;
        endcase
        if (resp_idx >= 0)
            resp_hits[resp_idx]++;

        // ── 5. Cross: trans_type × addr
        // Bin index = type_idx * ADDR_BINS + addr_idx
        cross_type_addr_hits[type_idx * ADDR_BINS + addr_idx]++;

        // ── 6. Cross: trans_type × wstrb (writes only) 
        if (t.trans_type == WRITE && strb_idx >= 0)
            cross_type_strb_hits[type_idx * STRB_BINS + strb_idx]++;

    endfunction

    // Helper function for percentage
    function real coverage_pct(int unsigned hits[], int total);
        int hit_count = 0;

        foreach (hits[i]) begin
            if (hits[i] > 0) hit_count++;
        end
        return (real'(hit_count) / real'(total)) * 100.0;
    endfunction

    function void report_phase(uvm_phase phase);
        real cp_trans, cp_addr, cp_strb, cp_resp;
        real cx_type_addr, cx_type_strb;
        real overall;
        int  total_hit;

        cp_trans      = coverage_pct(trans_type_hits,     TRANS_BINS);
        cp_addr       = coverage_pct(addr_hits,           ADDR_BINS);
        cp_strb       = coverage_pct(wstrb_hits,          STRB_BINS);
        cp_resp       = coverage_pct(resp_hits,           RESP_BINS);
        cx_type_addr  = coverage_pct(cross_type_addr_hits, CROSS_TYPE_ADDR_BINS);
        cx_type_strb  = coverage_pct(cross_type_strb_hits, CROSS_TYPE_STRB_BINS);

        total_hit = 0;
        foreach (trans_type_hits[i])      if (trans_type_hits[i]     > 0) total_hit++;
        foreach (addr_hits[i])            if (addr_hits[i]           > 0) total_hit++;
        foreach (wstrb_hits[i])           if (wstrb_hits[i]          > 0) total_hit++;
        foreach (resp_hits[i])            if (resp_hits[i]           > 0) total_hit++;
        foreach (cross_type_addr_hits[i]) if (cross_type_addr_hits[i]> 0) total_hit++;
        foreach (cross_type_strb_hits[i]) if (cross_type_strb_hits[i]> 0) total_hit++;
        overall = (real'(total_hit) / real'(TOTAL_BINS)) * 100.0;

        `uvm_info(get_type_name(), "\n\
╔══════════════════════════════════════════════════════════════╗\n\
║             AXI4-Lite Functional Coverage Report             ║\n\
╠══════════════════════════════════════════════════════════════╣\n\
║  Coverpoint          Bins  Hit   Coverage                    ║\n\
╠══════════════════════════════════════════════════════════════╣",
            UVM_NONE)

        // trans_type_cp
        `uvm_info(get_type_name(),
            $sformatf("║  trans_type_cp       %3d   %3d   %6.2f%%\n\
║    [0] WRITE  : %0d hits\n\
║    [1] READ   : %0d hits",
                TRANS_BINS, count_hits(trans_type_hits), cp_trans,
                trans_type_hits[0], trans_type_hits[1]), UVM_NONE)

        // addr_cp
        `uvm_info(get_type_name(),
            $sformatf("║  addr_cp             %3d   %3d   %6.2f%%\n\
║    [0] low  (0x00-0x0C): %0d hits\n\
║    [1] mid  (0x10-0x1C): %0d hits\n\
║    [2] high (0x20-0x3C): %0d hits",
                ADDR_BINS, count_hits(addr_hits), cp_addr,
                addr_hits[0], addr_hits[1], addr_hits[2]), UVM_NONE)

        // wstrb_cp
        `uvm_info(get_type_name(),
            $sformatf("║  wstrb_cp            %3d   %3d   %6.2f%%\n\
║    [0] byte0  (4'b0001): %0d hits\n\
║    [1] byte1  (4'b0010): %0d hits\n\
║    [2] byte2  (4'b0100): %0d hits\n\
║    [3] byte3  (4'b1000): %0d hits\n\
║    [4] lo_hw  (4'b0011): %0d hits\n\
║    [5] hi_hw  (4'b1100): %0d hits\n\
║    [6] full   (4'b1111): %0d hits",
                STRB_BINS, count_hits(wstrb_hits), cp_strb,
                wstrb_hits[0], wstrb_hits[1], wstrb_hits[2],
                wstrb_hits[3], wstrb_hits[4], wstrb_hits[5],
                wstrb_hits[6]), UVM_NONE)

        // resp_cp
        `uvm_info(get_type_name(),
            $sformatf("║  resp_cp             %3d   %3d   %6.2f%%\n\
║    [0] OKAY   (2'b00): %0d hits\n\
║    [1] SLVERR (2'b01): %0d hits",
                RESP_BINS, count_hits(resp_hits), cp_resp,
                resp_hits[0], resp_hits[1]), UVM_NONE)

        // Cross: type × addr
        `uvm_info(get_type_name(),
            $sformatf("║  cross type×addr     %3d   %3d   %6.2f%%\n\
║    WRITE×low=%0d  WRITE×mid=%0d  WRITE×high=%0d\n\
║    READ×low =%0d  READ×mid =%0d  READ×high =%0d",
                CROSS_TYPE_ADDR_BINS, count_hits(cross_type_addr_hits), cx_type_addr,
                cross_type_addr_hits[0], cross_type_addr_hits[1], cross_type_addr_hits[2],
                cross_type_addr_hits[3], cross_type_addr_hits[4], cross_type_addr_hits[5]), UVM_NONE)

        // Cross: type × wstrb
        `uvm_info(get_type_name(),
            $sformatf("║  cross type×wstrb    %3d   %3d   %6.2f%%",
                CROSS_TYPE_STRB_BINS, count_hits(cross_type_strb_hits), cx_type_strb), UVM_NONE)

        // Overall
        `uvm_info(get_type_name(),
            $sformatf("
╠══════════════════════════════════════════════════════════════╣\n\
║  OVERALL COVERAGE     %3d   %3d   %6.2f%%                    ║\n\
╚══════════════════════════════════════════════════════════════╝",
                TOTAL_BINS, total_hit, overall), UVM_NONE)
    endfunction
 
    function int count_hits(int unsigned hits[]);
        count_hits = 0;
        foreach (hits[i]) if (hits[i] > 0) count_hits++;
    endfunction
endclass
