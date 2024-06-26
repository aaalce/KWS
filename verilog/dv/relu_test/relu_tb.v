`timescale 1 ns / 1 ps

module relu_tb;
    reg clk;
    reg rst_n;
    reg wbs_stb_i;
    reg wbs_cyc_i;
    reg wbs_we_i;
    reg [3:0] wbs_sel_i;
    reg [31:0] wbs_dat_i;
    reg [31:0] wbs_adr_i;
    wire wbs_ack_o;
    wire [31:0] wbs_dat_o;

    // Instantiate the User Project Wrapper
    user_project_wrapper uut (
        .wb_clk_i(clk),
        .wb_rst_i(!rst_n),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o)
    );

    // Clock generation
    always #12.5 clk = ~clk; // 40MHz clock (25ns period)

    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        wbs_stb_i = 0;
        wbs_cyc_i = 0;
        wbs_we_i = 0;
        wbs_sel_i = 4'b1111;
        wbs_dat_i = 0;
        wbs_adr_i = 0;

        // Reset
        #100 rst_n = 1;

        // Test data
        int test_data[5] = '{-5, -1, 0, 1, 5};

        for (int i = 0; i < 5; i++) begin
            // Write input data
            wb_write(32'h30000004, test_data[i]);

            // Trigger ReLU operation (opcode 0101)
            wb_write(32'h30000000, 32'h5);

            // Wait for processing to complete
            #100;

            // Read output data
            wb_read(32'h30000008);
        end

        // End simulation
        #100 $finish;
    end

    task wb_write;
        input [31:0] address;
        input [31:0] data;
        begin
            wbs_stb_i = 1;
            wbs_cyc_i = 1;
            wbs_we_i = 1;
            wbs_adr_i = address;
            wbs_dat_i = data;
            @(posedge clk);
            while (!wbs_ack_o) @(posedge clk);
            wbs_stb_i = 0;
            wbs_cyc_i = 0;
            wbs_we_i = 0;
        end
    endtask

    task wb_read;
        input [31:0] address;
        begin
            wbs_stb_i = 1;
            wbs_cyc_i = 1;
            wbs_we_i = 0;
            wbs_adr_i = address;
            @(posedge clk);
            while (!wbs_ack_o) @(posedge clk);
            $display("Address %h: %h", address, wbs_dat_o);
            wbs_stb_i = 0;
            wbs_cyc_i = 0;
        end
    endtask

endmodule