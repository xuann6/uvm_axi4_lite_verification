`timescale 1ns/1ps

module axi4_lite_tb_top;

    logic clk;
    logic rst_n;

    // 10 ns period → 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Assert reset for 20 ns then release
    initial begin
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
    end

    axi4_lite_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) vif (
        .clk   (clk),
        .rst_n (rst_n)
    );

    axi4_lite_slave #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) dut (
        .aclk    (vif.clk),
        .aresetn (vif.rst_n),

        // Write Address Channel
        .awaddr  (vif.awaddr),
        .awvalid (vif.awvalid),
        .awready (vif.awready),

        // Write Data Channel
        .wdata   (vif.wdata),
        .wstrb   (vif.wstrb),
        .wvalid  (vif.wvalid),
        .wready  (vif.wready),

        // Write Response Channel
        .bresp   (vif.bresp),
        .bvalid  (vif.bvalid),
        .bready  (vif.bready),

        // Read Address Channel
        .araddr  (vif.araddr),
        .arvalid (vif.arvalid),
        .arready (vif.arready),

        // Read Data Channel
        .rdata   (vif.rdata),
        .rresp   (vif.rresp),
        .rvalid  (vif.rvalid),
        .rready  (vif.rready)
    );

    axi4_lite_assertions assertions (
        .clk     (clk),
        .rst_n   (rst_n),

        // Write Address Channel
        .awvalid (vif.awvalid),
        .awready (vif.awready),
        .awaddr  (vif.awaddr),

        // Write Data Channel
        .wvalid  (vif.wvalid),
        .wready  (vif.wready),

        // Write Response Channel
        .bvalid  (vif.bvalid),
        .bready  (vif.bready),
        .bresp   (vif.bresp),

        // Read Address Channel
        .arvalid (vif.arvalid),
        .arready (vif.arready),
        .araddr  (vif.araddr),

        // Read Data Channel
        .rvalid  (vif.rvalid),
        .rready  (vif.rready),
        .rresp   (vif.rresp)
    );

    initial begin
        uvm_pkg::uvm_config_db #(virtual axi4_lite_if)::set(
            null,           // context  = root
            "uvm_test_top", // instance path of the test
            "vif",          // key
            vif             // value
        );

        uvm_pkg::run_test();
    end

    initial begin
        #5000;
        $display("[TB_TOP] TIMEOUT: simulation exceeded 5000 ns — forcing finish");
        $finish;
    end
endmodule
