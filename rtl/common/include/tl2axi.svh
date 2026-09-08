`define TL_MOSI_SIGNALS(DWIDTH, ADDRWIDTH, IDWIDTH) struct packed{ \
    logic [(DWIDTH)-1:0] data; \
    logic [tl2axi_pkg::opcode_width-1:0] opcode; \
    logic [tl2axi_pkg::a_param_width-1:0] param; \
    logic [tl2axi_pkg::size_width-1:0] size; \
    logic [IDWIDTH-1:0] source; \
    logic [(ADDRWIDTH)-1:0] addr; \
    logic [((DWIDTH)>>3)-1:0] mask; \
    logic corrupt; \
    logic a_valid; \
    logic d_ready; \
  }

`define TL_MISO_SIGNALS(DWIDTH, ADDRWIDTH, IDWIDTH) struct packed{ \
    logic [(DWIDTH)-1:0] data; \
    logic [tl2axi_pkg::opcode_width-1:0] opcode; \
    logic [tl2axi_pkg::d_param_width-1:0] param; \
    logic [tl2axi_pkg::size_width-1:0] size; \
    logic [IDWIDTH-1:0] source; \
    logic denied; \
    logic [tl2axi_pkg::sink_width-1:0] sink; \
    logic corrupt; \
    logic a_ready; \
    logic d_valid; \
  }

`define AXI_MOSI_SIGNALS(DWIDTH, ADDRWIDTH, IDWIDTH) struct packed { \
    logic [(IDWIDTH)-1:0] awid; \
    logic [(ADDRWIDTH)-1:0] awaddr; \
    logic [7:0] awlen; \
    logic [3:0] awsize; \
    logic [1:0] awburst; \
    logic [1:0] awlock; \
    logic [3:0] awcache; \
    logic [2:0] awprot; \
    logic [3:0] awqos; \
    logic [3:0] awregion; \
    logic awvalid; \
    logic [(IDWIDTH)-1:0] wid; \
    logic [(DWIDTH)-1:0] wdata; \
    logic [((DWIDTH)>>3)-1:0] wstrb; \
    logic wlast; \
    logic wvalid; \
    logic bready; \
    logic [(IDWIDTH)-1:0] arid; \
    logic [(ADDRWIDTH)-1:0] araddr; \
    logic [7:0] arlen; \
    logic [((DWIDTH)>>3)-1:0] arsize; \
    logic [1:0] arburst; \
    logic [1:0] arlock; \
    logic [3:0] arcache; \
    logic [2:0] arprot; \
    logic [3:0] arqos; \
    logic [3:0] arregion; \
    logic arvalid; \
    logic rready; \
  }

`define AXI_MISO_SIGNALS(DWIDTH, ADDRWIDTH, IDWIDTH) struct packed { \
    logic awready; \
    logic wready; \
    logic [(IDWIDTH)-1:0] bid; \
    logic [1:0] bresp; \
    logic bvalid; \
    logic [(IDWIDTH)-1:0] rid; \
    logic [(DWIDTH)-1:0] rdata; \
    logic [1:0] rresp; \
    logic arready; \
    logic rlast; \
    logic rvalid; \
  }


