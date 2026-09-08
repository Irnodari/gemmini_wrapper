`timescale 1ns / 1ps

module rocc_fifo #(
    parameter integer DEPTH = 7  //The longest CISC instruction
) (
    input clk,
    rst_ni,

    input logic [31:0] cmd_i,
    input logic [63:0] rs1_i,
    rs2_i,

    input  logic valid_i,
    output logic ready_o,

    output logic [31:0] cmd_o,
    output logic [63:0] rs1_o,
    rs2_o,
    output logic valid_o,
    input logic ready_i,

    input logic empty,

    output logic busy
);

  logic [159:0] packed_inst_i, packed_inst_o;

  assign packed_inst_i[31:0] = cmd_i;
  assign packed_inst_i[95:32] = rs1_i;
  assign packed_inst_i[159:96] = rs2_i;

  assign cmd_o = packed_inst_o[31:0];
  assign rs1_o = packed_inst_o[95:32];
  assign rs2_o = packed_inst_o[159:96];

  logic cmd_accept, cmd_emptying;

  assign busy = cmd_emptying;

  logic [DEPTH-1:0][159:0] data;
  logic [$clog2(DEPTH)-1:0] ptr_i, ptr_o;

  always_comb begin
    ready_o = (ptr_i != DEPTH) && !cmd_emptying;
    valid_o = (ptr_o != ptr_i) && cmd_emptying;
    packed_inst_o = data[ptr_o];
  end

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      ptr_i <= 0;
      ptr_o <= 0;
      cmd_accept <= 0;
      cmd_emptying <= 0;
    end else if (cmd_accept == 1) begin
      if (valid_i == 0) cmd_accept <= 0;
    end else if (cmd_emptying == 1) begin
      if (ptr_i == ptr_o) begin
        ptr_i <= 0;
        ptr_o <= 0;
        cmd_emptying <= 0;
      end else if (valid_o && ready_i) begin
        ptr_o <= ptr_o + 1;
      end
    end else if (empty == 1) begin
      cmd_emptying <= 1;
    end else if (valid_i && ready_o) begin
      data[ptr_i] <= packed_inst_i;
      ptr_i <= ptr_i + 1;
      cmd_accept <= '1;
    end
  end

endmodule
