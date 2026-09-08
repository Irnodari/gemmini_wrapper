`include "tl2axi.svh"
module rocc_adapter
  import tl2axi_pkg::*;
#(
    parameter integer IDW = 5
) (
    input clk,
    rst_ni,

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

    input logic cmd_valid,
    output logic cmd_ready,
    input logic [31:0] cmd_data,
    input logic [63:0] rs1,
    rs2,
    output logic [63:0] rd,
    input logic rd_ready,
    output logic rd_valid,
    output logic busy
);


  typedef `TL_MOSI_SIGNALS(128, 32, IDW) tl_mosi_signals_t;
  typedef `TL_MISO_SIGNALS(128, 32, IDW) tl_miso_signals_t;
  typedef `AXI_MOSI_SIGNALS(128, 32, IDW) axi_mosi_signals_t;
  typedef `AXI_MISO_SIGNALS(128, 32, IDW) axi_miso_signals_t;

  tl_mosi_signals_t tl_mosi;
  tl_miso_signals_t tl_miso;
  axi_mosi_signals_t axi_mosi;
  axi_miso_signals_t axi_miso;
  logic busy_gemm;

  wire gemm_rst;
  assign gemm_rst = !rst_ni;
  assign busy = busy_gemm;


  Gemmini gemm (
      .clock(clk),
      .reset(~rst_ni),
      .auto_spad_id_out_a_ready(tl_miso.a_ready),
      .auto_spad_id_out_a_valid(tl_mosi.a_valid),
      .auto_spad_id_out_a_bits_opcode(tl_mosi.opcode),
      .auto_spad_id_out_a_bits_param(tl_mosi.param),
      .auto_spad_id_out_a_bits_size(tl_mosi.size),
      .auto_spad_id_out_a_bits_source(tl_mosi.source),
      .auto_spad_id_out_a_bits_address(tl_mosi.addr),
      .auto_spad_id_out_a_bits_mask(tl_mosi.mask),
      .auto_spad_id_out_a_bits_data(tl_mosi.data),
      .auto_spad_id_out_a_bits_corrupt(tl_mosi.corrupt),
      .auto_spad_id_out_d_ready(tl_mosi.d_ready),
      .auto_spad_id_out_d_valid(tl_miso.d_valid),
      .auto_spad_id_out_d_bits_opcode(tl_miso.opcode),
      .auto_spad_id_out_d_bits_param(tl_miso.param),
      .auto_spad_id_out_d_bits_size(tl_miso.size),
      .auto_spad_id_out_d_bits_source(tl_miso.source),
      .auto_spad_id_out_d_bits_sink(tl_miso.sink),
      .auto_spad_id_out_d_bits_denied(tl_miso.denied),
      .auto_spad_id_out_d_bits_data(tl_miso.data),
      .auto_spad_id_out_d_bits_corrupt(tl_miso.corrupt),
      .io_cmd_ready(cmd_ready),
      .io_cmd_valid(cmd_valid),
      .io_cmd_bits_inst_funct(cmd_data[31:25]),
      .io_cmd_bits_inst_rs2(cmd_data[24:20]),
      .io_cmd_bits_inst_rs1(cmd_data[19:15]),
      .io_cmd_bits_inst_xd(cmd_data[14]),
      .io_cmd_bits_inst_xs1(cmd_data[13]),
      .io_cmd_bits_inst_xs2(cmd_data[12]),
      .io_cmd_bits_inst_rd(cmd_data[11:7]),
      .io_cmd_bits_inst_opcode(cmd_data[6:0]),
      .io_cmd_bits_rs1(rs1),
      .io_cmd_bits_rs2(rs2),
      .io_cmd_bits_status_debug(1'b0),
      .io_cmd_bits_status_cease(1'b0),
      .io_cmd_bits_status_wfi(1'b0),
      .io_cmd_bits_status_isa(32'b0),
      .io_cmd_bits_status_dprv(2'b0),
      .io_cmd_bits_status_dv(1'b0),
      .io_cmd_bits_status_prv(2'b0),
      .io_cmd_bits_status_v(1'b0),
      .io_cmd_bits_status_sd(1'b0),
      .io_cmd_bits_status_zero2(23'b0),
      .io_cmd_bits_status_mpv(1'b0),
      .io_cmd_bits_status_gva(1'b0),
      .io_cmd_bits_status_mbe(1'b0),
      .io_cmd_bits_status_sbe(1'b0),
      .io_cmd_bits_status_sxl(2'b0),
      .io_cmd_bits_status_uxl(2'b0),
      .io_cmd_bits_status_sd_rv32(1'b0),
      .io_cmd_bits_status_zero1(8'b0),
      .io_cmd_bits_status_tsr(1'b0),
      .io_cmd_bits_status_tw(1'b0),
      .io_cmd_bits_status_tvm(1'b0),
      .io_cmd_bits_status_mxr(1'b0),
      .io_cmd_bits_status_sum(1'b0),
      .io_cmd_bits_status_mprv(1'b0),
      .io_cmd_bits_status_xs(2'b0),
      .io_cmd_bits_status_fs(2'b0),
      .io_cmd_bits_status_mpp(2'b0),
      .io_cmd_bits_status_vs(2'b0),
      .io_cmd_bits_status_spp(1'b0),
      .io_cmd_bits_status_mpie(1'b0),
      .io_cmd_bits_status_ube(1'b0),
      .io_cmd_bits_status_spie(1'b0),
      .io_cmd_bits_status_upie(1'b0),
      .io_cmd_bits_status_mie(1'b0),
      .io_cmd_bits_status_hie(1'b0),
      .io_cmd_bits_status_sie(1'b0),
      .io_cmd_bits_status_uie(1'b0),
      .io_resp_ready(rd_ready),
      .io_resp_valid(rd_valid),
      .io_resp_bits_rd(  /*Empty*/),
      .io_resp_bits_data(rd),
      .io_busy(busy_gemm)
  );


  tl2axi #(
      .DATAW(128),
      .ADDRW(32),
      .IDW(IDW),
      .axi_miso_t(axi_miso_signals_t),
      .axi_mosi_t(axi_mosi_signals_t),
      .tl_miso_t(tl_miso_signals_t),
      .tl_mosi_t(tl_mosi_signals_t)
  ) tl2axi (
      .clk,
      .nrst(rst_ni),
      .axi_miso,
      .axi_mosi,
      .tl_miso,
      .tl_mosi
  );

  assign m_axi_awid = axi_mosi.awid;
  assign m_axi_awaddr = axi_mosi.awaddr;
  assign m_axi_awlen = axi_mosi.awlen;
  assign m_axi_awsize = axi_mosi.awsize;
  assign m_axi_awburst = axi_mosi.awburst;
  assign m_axi_awlock = axi_mosi.awlock;
  assign m_axi_awcache = axi_mosi.awcache;
  assign m_axi_awprot = axi_mosi.awprot;
  assign m_axi_awregion = axi_mosi.awregion;
  assign m_axi_awqos = axi_mosi.awqos;
  assign m_axi_awvalid = axi_mosi.awvalid;
  assign axi_miso.awready = m_axi_awready;
  assign m_axi_wid = axi_mosi.wid;
  assign m_axi_wdata = axi_mosi.wdata;
  assign m_axi_wstrb = axi_mosi.wstrb;
  assign m_axi_wlast = axi_mosi.wlast;
  assign m_axi_wvalid = axi_mosi.wvalid;
  assign axi_miso.wready = m_axi_wready;
  assign axi_miso.bid = m_axi_bid;
  assign axi_miso.bresp = m_axi_bresp;
  assign axi_miso.bvalid = m_axi_bvalid;
  assign m_axi_bready = axi_mosi.bready;
  assign m_axi_arid = axi_mosi.arid;
  assign m_axi_araddr = axi_mosi.araddr;
  assign m_axi_arlen = axi_mosi.arlen;
  assign m_axi_arsize = axi_mosi.arsize;
  assign m_axi_arburst = axi_mosi.arburst;
  assign m_axi_arlock = axi_mosi.arlock;
  assign m_axi_arcache = axi_mosi.arcache;
  assign m_axi_arprot = axi_mosi.arprot;
  assign m_axi_arregion = axi_mosi.arregion;
  assign m_axi_arqos = axi_mosi.arqos;
  assign m_axi_arvalid = axi_mosi.arvalid;
  assign axi_miso.arready = m_axi_arready;
  assign axi_miso.rid = m_axi_rid;
  assign axi_miso.rdata = m_axi_rdata;
  assign axi_miso.rresp = m_axi_rresp;
  assign axi_miso.rlast = m_axi_rlast;
  assign axi_miso.rvalid = m_axi_rvalid;
  assign m_axi_rready = axi_mosi.rready;

endmodule
