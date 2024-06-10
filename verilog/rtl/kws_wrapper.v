// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module kws_wrapper (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif
    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o
);
    wire valid;
    wire write_enable;
    wire read_enable;
    reg wbs_ack_o_reg;

    assign valid = wbs_cyc_i && wbs_stb_i;
    assign write_enable = wbs_we_i && valid;
    assign read_enable = ~wbs_we_i && valid;

    // Instantiate the modules
    wire [31:0] cmvn_output_data;
    wire [4:0] cmvn_output_addr;
    wire cmvn_output_valid;
    wire [31:0] linear_output_data;
    wire [9:0] linear_output_addr;
    wire linear_output_valid;
    wire [31:0] relu_output_data;
    wire [4:0] relu_output_addr;
    wire relu_output_valid;

    cmvn cmvn_inst (
        .clk(wb_clk_i),
        .rst_n(!wb_rst_i),
        .cmvn_en(cmvn_en),
        .input_data(wbs_dat_i),
        .input_addr(wbs_adr_i[6:2]),
        .output_data(cmvn_output_data),
        .output_addr(cmvn_output_addr),
        .output_valid(cmvn_output_valid)
    );

    linear linear_inst (
        .clk(wb_clk_i),
        .rst_n(!wb_rst_i),
        .linear_en(linear_en),
        .input_data(cmvn_output_data),
        .input_addr({5'b00000, cmvn_output_addr}), 
        .output_data(linear_output_data),
        .output_addr(linear_output_addr),
        .output_valid(linear_output_valid)
    );

    relu relu_inst (
        .clk(wb_clk_i),
        .rst_n(!wb_rst_i),
        .relu_en(relu_en),
        .input_data(linear_output_data),
        .input_addr(linear_output_addr[4:0]),
        .output_data(relu_output_data),
        .output_addr(relu_output_addr),
        .output_valid(relu_output_valid)
    );

    // Instantiate the FSM module
    wire cmvn_en;
    wire linear_en;
    wire relu_en;
    wire padding_en;
    wire cnn_en;
    wire batch_norm_en;
    wire sigmoid_en;
    wire systolic_en;
    wire [1:0] systolic_op;
    wire done;

    kws_fsm fsm_inst (
        .clk(wb_clk_i),
        .rst_n(!wb_rst_i),
        .start(write_enable && wbs_adr_i[9:2] == 8'h00),
        .opcode(wbs_dat_i[3:0]),
        .cmvn_en(cmvn_en),
        .linear_en(linear_en),
        .relu_en(relu_en),
        .padding_en(padding_en),
        .cnn_en(cnn_en),
        .batch_norm_en(batch_norm_en),
        .sigmoid_en(sigmoid_en),
        .systolic_en(systolic_en),
        .systolic_op(systolic_op),
        .done(done)
    );

    // Instantiate the weights register file
    wire [31:0] weights_data_out;

    weights_reg_file weights_inst (
        .clk(wb_clk_i),
        .rst_n(!wb_rst_i),
        .row_addr(wbs_adr_i[8:4]),
        .col_addr({1'b0, wbs_adr_i[3:0]}),
        .data_out(weights_data_out)
    );

    // Ack logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            wbs_ack_o_reg <= 1'b0;
        else if (wbs_cyc_i && wbs_stb_i && ~wbs_ack_o_reg)
            wbs_ack_o_reg <= 1'b1;
        else
            wbs_ack_o_reg <= 1'b0;
    end
    assign wbs_ack_o = wbs_ack_o_reg;

    // Output data selection
    assign wbs_dat_o = (read_enable && wbs_adr_i[9:2] == 8'h00) ? {28'h0, done, sigmoid_en, batch_norm_en, cnn_en} :
                       (read_enable && wbs_adr_i[9:2] == 8'h01) ? relu_output_data :
                       (read_enable && wbs_adr_i[9:2] == 8'h02) ? weights_data_out :
                       32'h00000000;

endmodule

`default_nettype none
