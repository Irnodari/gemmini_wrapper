`default_nettype wire

module gemmini_wrapper #(
    parameter integer IDW = 5,
    parameter integer AXI_ADDR_WIDTH = 32,
    parameter integer AXI_SLV_DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst_ni,

    AXI_LITE.Slave slv,

    output logic [IDW-1:0] m_axi_awid,
    output logic [31:0] m_axi_awaddr,
    output logic [7:0] m_axi_awlen,
    output logic [2:0] m_axi_awsize,
    output logic [1:0] m_axi_awburst,
    output logic [1:0] m_axi_awlock,
    output logic [3:0] m_axi_awcache,
    output logic [2:0] m_axi_awprot,
    output logic [3:0] m_axi_awregion,
    output logic [3:0] m_axi_awqos,
    output logic m_axi_awvalid,
    input logic m_axi_awready,
    output logic [IDW-1:0] m_axi_wid,
    output logic [127:0] m_axi_wdata,
    output logic [15:0] m_axi_wstrb,
    output logic m_axi_wlast,
    output logic m_axi_wvalid,
    input logic m_axi_wready,
    input logic [IDW-1:0] m_axi_bid,
    input logic [1:0] m_axi_bresp,
    input logic m_axi_bvalid,
    output logic m_axi_bready,
    output logic [IDW-1:0] m_axi_arid,
    output logic [31:0] m_axi_araddr,
    output logic [7:0] m_axi_arlen,
    output logic [2:0] m_axi_arsize,
    output logic [1:0] m_axi_arburst,
    output logic [1:0] m_axi_arlock,
    output logic [3:0] m_axi_arcache,
    output logic [2:0] m_axi_arprot,
    output logic [3:0] m_axi_arregion,
    output logic [3:0] m_axi_arqos,
    output logic m_axi_arvalid,
    input logic m_axi_arready,
    input logic [IDW-1:0] m_axi_rid,
    input logic [127:0] m_axi_rdata,
    input logic [1:0] m_axi_rresp,
    input logic m_axi_rlast,
    input logic m_axi_rvalid,
    output logic m_axi_rready,

    // Interrupts
    output logic irq_o
);
  localparam type byte_t = logic [7:0];
  localparam REG_NUM_BYTES = 32'd64;

  localparam RESET_VALS = '0;

  logic [REG_NUM_BYTES-1:0] wr_active, rd_active, reg_load;
  byte_t [REG_NUM_BYTES-1:0] reg_d, reg_q;

  axi_lite_regs_intf #(
      .REG_NUM_BYTES(REG_NUM_BYTES),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_SLV_DATA_WIDTH),
      .PRIV_PROT_ONLY('0),
      .SECU_PROT_ONLY('0),
      .AXI_READ_ONLY('0),
      .REG_RST_VAL(RESET_VALS)
  ) regs (
      .clk_i(clk),
      .rst_ni(rst_ni),
      .slv(slv),
      .wr_active_o(wr_active),
      .rd_active_o(rd_active),
      .reg_d_i(reg_d),
      .reg_load_i(reg_load),
      .reg_q_o(reg_q)
  );

  // Command interface wires and the CISC-FIFO signals
  logic cmd_valid_sig;
  logic cmd_valid_sel;
  logic cmd_valid, rocc_valid;
  logic cmd_ready, rocc_adapter_cmd_ready, rocc_ready, rocc_in_ready;
  logic [31:0] cmd_data, rocc_fifo_cmd_data;
  logic [63:0] rs1, rocc_fifo_rs1;
  logic [63:0] rs2, rocc_fifo_rs2;
  logic busy, rocc_fifo_busy;
  logic load_to_fifo, empty_fifo;

  reg [63:0] rd, rd_valid_sig;
  reg rd_ready_sig, rd_ready_sel;
  reg  rd_ready;
  wire rd_valid;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      cmd_valid_sel <= 1'b0;
      cmd_valid_sig <= 1'b0;

      rd_ready_sel  <= 1'b0;
      rd_ready_sig  <= 1'b0;

      rd_valid_sig  <= 64'h0;
    end else begin
      if (cmd_valid && !cmd_valid_sel) begin
        cmd_valid_sel <= 1'b1;
        cmd_valid_sig <= 1'b1;
      end else if (cmd_valid_sel && !cmd_valid) begin
        cmd_valid_sig <= 1'b0;
        cmd_valid_sel <= 1'b0;
      end else if (cmd_valid_sel) begin
        cmd_valid_sig <= 1'b0;
      end

      if (rd_ready && !rd_ready_sel) begin
        rd_ready_sel <= 1'b1;
        rd_ready_sig <= 1'b1;
      end else if (rd_ready_sel && !rd_ready) begin
        rd_ready_sig <= 1'b0;
        rd_ready_sel <= 1'b0;
      end else if (rd_ready_sel) begin
        rd_ready_sig <= 1'b0;
      end
      if (rd_ready_sig == 1'b1 && rd_valid == 1'b1) begin
        rd_valid_sig <= rd;
      end
    end
  end

  always_comb begin
    irq_o = '0;
    cmd_data = reg_q[3:0];
    rs1 = reg_q[11:4];
    rs2 = reg_q[19:12];
    cmd_valid = reg_q[20][0];

    //    rocc_ready = rocc_adapter_cmd_ready;  // && rocc_fifo_busy;
    cmd_ready = rocc_adapter_cmd_ready;  // && !rocc_fifo_busy;

    reg_load[23:0] = '0;
    reg_load[24] = '1;
    reg_load[25] = '1;
    reg_load[26] = '1;
    reg_load[27] = '1;
    reg_d[27:24] = {
      31'd0, cmd_ready
    };  //(cmd_ready & !load_to_fifo) | (!rocc_fifo_busy & load_to_fifo)};
    reg_load[28] = '1;
    reg_load[29] = '1;
    reg_load[30] = '1;
    reg_load[31] = '1;
    reg_d[31:28] = {31'd0, busy};  // | rocc_fifo_busy};
    reg_d[23:0] = '0;
    reg_load[43:32] = 12'hfff;
    reg_d[39:32] = rd_valid_sig;
    reg_d[43:40] = {31'd0, rd_valid};
    rd_ready = reg_q[44][0];
    reg_load[47:44] = 4'h0;
    reg_load[55:48] = 4'h0;
    reg_load[63:56] = 8'h0;
    load_to_fifo = reg_q[48][0];
    empty_fifo = reg_q[52][0];
  end

  rocc_adapter #(
      .IDW(IDW)
  ) gemm (
      .clk(clk),
      .rst_ni(rst_ni),
      .cmd_valid(cmd_valid_sig),  //((load_to_fifo | rocc_fifo_busy) ? rocc_valid : cmd_valid_sig),
      .cmd_ready(rocc_adapter_cmd_ready),
      .cmd_data(cmd_data),  //((load_to_fifo | rocc_fifo_busy) ? rocc_fifo_cmd_data : cmd_data),
      .rs1(rs1),  //((load_to_fifo | rocc_fifo_busy) ? rocc_fifo_rs1 : rs1),
      .rs2(rs2),  //((load_to_fifo | rocc_fifo_busy) ? rocc_fifo_rs2 : rs2),

      .busy(busy),

      .*
  );

  /*  rocc_fifo #(
      .DEPTH(32'd7)
  ) cisc_cmd_fifo (
      .clk(clk),
      .rst_ni(rst_ni),
      .cmd_i(cmd_data),
      .rs1_i(rs1),
      .rs2_i(rs2),

      .valid_i(cmd_valid && load_to_fifo),
      .ready_o(rocc_in_ready),

      .cmd_o  (rocc_fifo_cmd_data),
      .rs1_o  (rocc_fifo_rs1),
      .rs2_o  (rocc_fifo_rs2),
      .valid_o(rocc_valid),
      .ready_i(rocc_ready),

      .empty(empty_fifo),
      .busy (rocc_fifo_busy)
  );*/

endmodule
