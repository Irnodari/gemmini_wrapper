`timescale 1ns / 1ps

`include "tl2axi.svh"

module tl2axi
  import tl2axi_pkg::*;
#(
    parameter integer DATAW = 128,
    parameter integer ADDRW = 32,
    parameter integer IDW = 5,
    parameter type tl_mosi_t = logic,
    parameter type tl_miso_t = logic,
    parameter type axi_mosi_t = logic,
    parameter type axi_miso_t = logic
) (

    input clk,
    input nrst,

    input  tl_mosi_t  tl_mosi,
    output tl_miso_t  tl_miso,
    output axi_mosi_t axi_mosi,
    input  axi_miso_t axi_miso
);

  typedef enum {
    s_rq_wait,
    s_rq_get,
    s_rq_put,
    s_rq_wburst_1,
    s_rq_wburst_2
  } tl2axi_req_state_t;

  typedef enum {
    s_rs_wait,
    s_rs_bresp,
    s_rs_rresp_1,
    s_rs_rresp_2
  } tl2axi_rsp_state_t;

  tl2axi_req_state_t req_state;

  tl2axi_rsp_state_t rsp_state;

  typedef struct {
    logic [tl2axi_pkg::size_width-1:0]   size;
    logic [tl2axi_pkg::opcode_width-1:0] opcode;
  } tl_req_metadata_t;

  tl_req_metadata_t req_metadata[1<<IDW];
  logic [DATAW-1:0] data;
  logic [(DATAW>>3)-1:0] strb;
  logic [ADDRW-1:0] addr;
  logic [IDW-1:0] id;
  logic [7:0] burst_op;  //AXI awlen width

  logic [1:0] rsp_resp;
  logic [DATAW-1:0] rsp_data;
  logic [IDW-1:0] rsp_id;
  logic rsp_last;

  always_ff @(posedge clk or negedge nrst) begin  //States and clocked signals for mosi
    if (!nrst) begin
      req_state <= s_rq_wait;
    end else begin
      unique case (req_state)
        s_rq_wait: begin
          if (tl_mosi.a_valid && tl_miso.a_ready) begin
            req_metadata[tl_mosi.source].opcode <= tl_mosi.opcode;
            req_metadata[tl_mosi.source].size <= tl_mosi.size;
            id <= tl_mosi.source;
            if (tl_mosi.size > $clog2(DATAW >> 3)) begin
              burst_op <= (1 << (tl_mosi.size - $clog2(DATAW >> 3))) - 1;
            end else begin
              burst_op <= 0;
            end

            unique case (tl_mosi.opcode)
              GET: begin
                req_state <= s_rq_get;
                addr <= tl_mosi.addr;
              end
              PUT_FULL, PUT_PART: begin
                req_state <= s_rq_put;
                data <= tl_mosi.data;
                strb <= tl_mosi.mask;
                addr <= tl_mosi.addr;
              end
            endcase
          end
        end
        s_rq_get: begin
          if (axi_mosi.arvalid && axi_miso.arready) begin
            req_state <= s_rq_wait;
          end
        end
        s_rq_put: begin
          if (axi_mosi.awvalid && axi_miso.awready) begin
            req_state <= s_rq_wburst_1;
            if (axi_mosi.awlen) req_state <= s_rq_wburst_1;
          end
        end
        s_rq_wburst_1: begin
          if (axi_mosi.wvalid && axi_miso.wready) begin
            if (burst_op == 0) req_state <= s_rq_wait;
            else begin
              req_state <= s_rq_wburst_2;
              burst_op  <= burst_op - 1;
            end
          end
        end
        s_rq_wburst_2: begin
          if (axi_mosi.wvalid && axi_miso.wready) begin
            if (burst_op == 0) req_state <= s_rq_wait;
            else burst_op <= burst_op - 1;
          end
        end
      endcase
    end
  end

  always_comb begin  //Comb logic for mosi
    axi_mosi.wdata = 'x;
    axi_mosi.wstrb = 'x;
    unique case (req_state)
      s_rq_wait: begin
        tl_miso.a_ready  = 1;
        axi_mosi.awvalid = 0;
        axi_mosi.wvalid  = 0;
        axi_mosi.arvalid = 0;
      end
      s_rq_get: begin
        tl_miso.a_ready  = 0;
        axi_mosi.arvalid = 1;
        axi_mosi.awvalid = 0;
        axi_mosi.wvalid  = 0;
      end
      s_rq_put: begin
        tl_miso.a_ready  = 0;
        axi_mosi.arvalid = 0;
        axi_mosi.awvalid = 1;
        axi_mosi.wvalid  = 0;
      end
      s_rq_wburst_1: begin
        tl_miso.a_ready  = 0;
        axi_mosi.arvalid = 0;
        axi_mosi.awvalid = 0;
        axi_mosi.wvalid  = 1;
        axi_mosi.wdata   = data;
        axi_mosi.wstrb   = strb;
      end
      s_rq_wburst_2: begin
        tl_miso.a_ready  = axi_miso.wready;
        axi_mosi.wvalid  = tl_mosi.a_valid;
        axi_mosi.awvalid = 0;
        axi_mosi.arvalid = 0;
        axi_mosi.wstrb   = tl_mosi.mask;
        axi_mosi.wdata   = tl_mosi.data;
      end
    endcase

    //Things that can be generically connected
    axi_mosi.wlast = (burst_op == 0);
    axi_mosi.awid = id;
    axi_mosi.wid = id;
    axi_mosi.arid = id;
    axi_mosi.awlen = burst_op;
    axi_mosi.awsize = $clog2(DATAW >> 3);
    axi_mosi.awburst = 2'h1;
    axi_mosi.awlock = 2'h0;
    axi_mosi.awcache = 4'b0000;
    axi_mosi.awprot = 3'h1;
    axi_mosi.awregion = 4'h0;
    axi_mosi.awaddr = addr;
    axi_mosi.awqos = 4'h0;

    axi_mosi.wid = id;

    axi_mosi.arid = id;
    axi_mosi.araddr = addr;
    axi_mosi.arlen = burst_op;
    axi_mosi.arsize = $clog2(DATAW >> 3);
    axi_mosi.arburst = 2'h1;
    axi_mosi.arlock = 2'h0;
    axi_mosi.arcache = 4'b0000;
    axi_mosi.arprot = 3'h1;
    axi_mosi.arqos = 4'h0;
    axi_mosi.arregion = 4'h0;
  end

  always_ff @(posedge clk or negedge nrst) begin  //States and clocked signals for miso
    if (!nrst) begin
      rsp_state <= s_rs_wait;
    end else begin
      unique case (rsp_state)
        s_rs_wait: begin
          if (axi_miso.bvalid && axi_mosi.bready) begin
            rsp_state <= s_rs_bresp;
            rsp_resp <= axi_miso.bresp;
            rsp_id <= axi_miso.bid;
          end else if (axi_miso.rvalid && axi_mosi.rready) begin
            rsp_state <= s_rs_rresp_1;
            rsp_resp <= axi_miso.rresp;
            rsp_data <= axi_miso.rdata;
            rsp_id <= axi_miso.rid;
            rsp_last <= axi_miso.rlast;
          end
        end
        s_rs_bresp: begin
          if (tl_miso.d_valid && tl_mosi.d_ready) begin
            rsp_state <= s_rs_wait;
          end
        end
        s_rs_rresp_1: begin
          if (tl_miso.d_valid && tl_mosi.d_ready) begin
            if (rsp_last) rsp_state <= s_rs_wait;
            else rsp_state <= s_rs_rresp_2;
          end
        end
        s_rs_rresp_2: begin
          if (tl_miso.d_valid && tl_mosi.d_ready) begin
            if (axi_miso.rlast) rsp_state <= s_rs_wait;
          end
        end
      endcase
    end
  end

  always_comb begin
    tl_miso.denied = 'x;
    tl_miso.opcode = 'x;
    tl_miso.size   = 'x;
    tl_miso.source = 'x;
    tl_miso.data   = 'x;
    unique case (rsp_state)
      s_rs_wait: begin
        tl_miso.d_valid = 0;
        axi_mosi.rready = 1;
        axi_mosi.bready = !(axi_mosi.rready && axi_miso.rvalid);
      end
      s_rs_bresp: begin
        axi_mosi.rready = 0;
        axi_mosi.bready = 0;
        tl_miso.d_valid = 1;
        tl_miso.opcode = ACC_ACK;
        tl_miso.param = 2'h0;
        tl_miso.size = req_metadata[rsp_id].size;
        tl_miso.source = rsp_id;
        tl_miso.denied = rsp_resp[1];
        tl_miso.sink = 4'h0;
        tl_miso.corrupt = 0;
        tl_miso.d_valid = 1;
      end
      s_rs_rresp_1: begin
        axi_mosi.rready = 0;
        axi_mosi.bready = 0;
        tl_miso.d_valid = 1;
        tl_miso.opcode = ACK_DATA;
        tl_miso.param = 2'h0;
        tl_miso.size = req_metadata[rsp_id].size;
        tl_miso.source = rsp_id;
        tl_miso.denied = rsp_resp[1];
        tl_miso.sink = 4'h0;
        tl_miso.corrupt = 0;
        tl_miso.d_valid = 1;
        tl_miso.data = rsp_data;
      end
      s_rs_rresp_2: begin
        axi_mosi.bready = 0;
        axi_mosi.rready = tl_mosi.d_ready;
        tl_miso.d_valid = axi_miso.rvalid;
        tl_miso.opcode = ACK_DATA;
        tl_miso.param = 2'h0;
        tl_miso.size = req_metadata[rsp_id].size;
        tl_miso.source = rsp_id;
        tl_miso.denied = rsp_resp[1];
        tl_miso.sink = 4'h0;
        tl_miso.corrupt = 0;
        tl_miso.data = axi_miso.rdata;
      end
    endcase
  end

endmodule
