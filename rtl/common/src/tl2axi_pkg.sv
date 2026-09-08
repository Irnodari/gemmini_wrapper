package tl2axi_pkg;
  parameter integer unsigned opcode_width = 32'h3;
  parameter integer unsigned a_param_width = 32'd3;
  parameter integer unsigned d_param_width = 32'd2;
  parameter integer unsigned size_width = 32'd4;
  //  parameter integer unsigned source_width = 32'd5; //source for some reason
  //  can vary between hardware generation runs. Will leave this here for
  //  awareness, but from now on it needs to be passed on a generated accel.
  //  basis.
  parameter integer unsigned sink_width = 32'd4;

  parameter logic [2:0] GET = 3'h4;
  parameter logic [2:0] PUT_FULL = 3'h0;
  parameter logic [2:0] PUT_PART = 3'h1;
  parameter logic [1:0] ACK_DATA = 3'h1;
  parameter logic [1:0] ACC_ACK = 3'h0;
  parameter logic [2:0] ARITHMETIC = 3'h2;
  parameter logic [2:0] LOGICAL = 3'h3;
  parameter logic [2:0] INTENT = 3'h5;
  parameter logic [1:0] HINT_ACK = 3'h2;
endpackage


