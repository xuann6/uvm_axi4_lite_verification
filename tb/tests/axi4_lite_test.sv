
class axi4_lite_base_test extends uvm_test;
    `uvm_component_utils(axi4_lite_base_test)

    axi4_lite_env env;

    function new(string name = "axi4_lite_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = axi4_lite_env::type_id::create("env", this);

        begin
            virtual axi4_lite_if vif;
            if (!uvm_config_db #(virtual axi4_lite_if)::get(this, "", "vif", vif))
                `uvm_fatal("CFG_DB", "Virtual interface 'vif' not found – set it in tb_top")

            uvm_config_db #(virtual axi4_lite_if)::set(this, "env.agent.*", "vif", vif);
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Base test does nothing
    endtask
endclass

class axi4_lite_random_test extends axi4_lite_base_test;
    `uvm_component_utils(axi4_lite_random_test)

    function new(string name = "axi4_lite_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_random_seq seq;

        phase.raise_objection(this, "random_test running");

        seq = axi4_lite_random_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);

        // Small drain time so the monitor catches the last response
        #50;

        phase.drop_objection(this, "random_test done");
    endtask

endclass

class axi4_lite_wr_rd_test extends axi4_lite_base_test;
    `uvm_component_utils(axi4_lite_wr_rd_test)

    function new(string name = "axi4_lite_wr_rd_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_lite_wr_rd_seq seq;

        phase.raise_objection(this, "wr_rd_test running");

        seq = axi4_lite_wr_rd_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);

        #50;

        phase.drop_objection(this, "wr_rd_test done");
    endtask
endclass
