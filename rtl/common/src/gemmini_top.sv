module gemmini_top #(
    parameter integer IDW = 5
) (
    input              clk,
    input              rst_ni,
    input  wire [31:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [15:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [ 1:0] s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

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
    output logic m_axi_rready

);

  localparam ADDR_WIDTH = 32;

  AXI_LITE #(
      .AXI_ADDR_WIDTH(ADDR_WIDTH),
      .AXI_DATA_WIDTH(32)
  ) slv ();

  gemmini_wrapper #(
      .AXI_ADDR_WIDTH(ADDR_WIDTH),
      .AXI_SLV_DATA_WIDTH(32),
      .IDW(IDW)
  ) gemm (
      .slv,
      .clk(clk),
      .rst_ni(rst_ni),
      .irq_o(  /*EMPTY*/),
      .*
  );


  assign slv.aw_addr = {{16{1'b0}}, s_axi_awaddr[15:0]};
  assign slv.aw_prot = s_axi_awprot;
  assign slv.aw_valid = s_axi_awvalid;
  assign s_axi_awready = slv.aw_ready;

  assign slv.w_data = s_axi_wdata;
  assign slv.w_strb = s_axi_wstrb;
  assign slv.w_valid = s_axi_wvalid;
  assign s_axi_wready = slv.w_ready;

  assign s_axi_bresp = slv.b_resp;
  assign s_axi_bvalid = slv.b_valid;
  assign slv.b_ready = s_axi_bready;

  assign slv.ar_addr = {{16{1'b0}}, s_axi_araddr[15:0]};
  assign slv.ar_prot = s_axi_arprot;
  assign slv.ar_valid = s_axi_arvalid;
  assign s_axi_arready = slv.ar_ready;

  assign s_axi_rdata = slv.r_data;
  assign s_axi_rresp = slv.r_resp;
  assign s_axi_rvalid = slv.r_valid;
  assign slv.r_ready = s_axi_rready;

endmodule
