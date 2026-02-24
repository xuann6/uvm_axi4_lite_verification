
class axi4_lite_env extends uvm_env;
    `uvm_component_utils(axi4_lite_env)

    axi4_lite_agent       agent;
    axi4_lite_scoreboard  scoreboard;
    axi4_lite_coverage    coverage;

    function new(string name = "axi4_lite_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent      = axi4_lite_agent::type_id::create("agent", this);
        scoreboard = axi4_lite_scoreboard::type_id::create("scoreboard", this);
        coverage   = axi4_lite_coverage::type_id::create("coverage", this);

        uvm_config_db #(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.analysis_imp);
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction

endclass
