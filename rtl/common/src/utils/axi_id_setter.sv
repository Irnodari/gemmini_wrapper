module axi_id_setter #(
    parameter AXI_ID_WIDTH = 16,
    parameter ID = 0
) (
    // AXI Interface for remapping ID
    AXI_BUS.Slave slv,

    // ID remapped interface
    AXI_BUS.Master mst
);
  // miso
  assign slv.aw_ready = mst.aw_ready;
  assign slv.w_ready = mst.w_ready;
  assign slv.b_id = mst.b_id;  // Pass through
  assign slv.b_resp = mst.b_resp;
  assign slv.b_user = mst.b_user;
  assign slv.b_valid = mst.b_valid;
  assign slv.ar_ready = mst.ar_ready;
  assign slv.r_id = mst.r_id;  // Pass through
  assign slv.r_data = mst.r_data;
  assign slv.r_resp = mst.r_resp;
  assign slv.r_last = mst.r_last;
  assign slv.r_user = mst.r_user;
  assign slv.r_valid = mst.r_valid;

  // mosi
  // assign mst.aw_id = slv.aw_id;
  assign mst.aw_id = ID;  // Remap ID
  assign mst.aw_addr = slv.aw_addr;
  assign mst.aw_len = slv.aw_len;
  assign mst.aw_size = slv.aw_size;
  assign mst.aw_burst = slv.aw_burst;
  assign mst.aw_lock = slv.aw_lock;
  assign mst.aw_cache = slv.aw_cache;
  assign mst.aw_prot = slv.aw_prot;
  assign mst.aw_qos = slv.aw_qos;
  assign mst.aw_region = slv.aw_region;
  assign mst.aw_user = slv.aw_user;
  assign mst.aw_valid = slv.aw_valid;
  assign mst.w_data = slv.w_data;
  assign mst.w_strb = slv.w_strb;
  assign mst.w_last = slv.w_last;
  assign mst.w_user = slv.w_user;
  assign mst.w_valid = slv.w_valid;
  assign mst.b_ready = slv.b_ready;
  // assign mst.ar_id = slv.ar_id;
  assign mst.ar_id = ID;  // Remap ID
  assign mst.ar_addr = slv.ar_addr;
  assign mst.ar_len = slv.ar_len;
  assign mst.ar_size = slv.ar_size;
  assign mst.ar_burst = slv.ar_burst;
  assign mst.ar_lock = slv.ar_lock;
  assign mst.ar_cache = slv.ar_cache;
  assign mst.ar_prot = slv.ar_prot;
  assign mst.ar_qos = slv.ar_qos;
  assign mst.ar_region = slv.ar_region;
  assign mst.ar_user = slv.ar_user;
  assign mst.ar_valid = slv.ar_valid;
  assign mst.r_ready = slv.r_ready;
  assign mst.aw_atop = slv.aw_atop;

  // pragma translate_off
`ifndef VERILATOR
  initial begin
    assert (ID < (2 ** AXI_ID_WIDTH))
    else $fatal(1, "ID must fit in AXI_ID_WIDTH!");
    assert (slv.AXI_ADDR_WIDTH == mst.AXI_ADDR_WIDTH)
    else $fatal(1, "Interface definition mismatch");
    assert (slv.AXI_DATA_WIDTH == mst.AXI_DATA_WIDTH)
    else $fatal(1, "Interface definition mismatch");
    assert (slv.AXI_ID_WIDTH == mst.AXI_ID_WIDTH)
    else $fatal(1, "Interface definition mismatch");
    assert (slv.AXI_USER_WIDTH == mst.AXI_USER_WIDTH)
    else $fatal(1, "Interface definition mismatch");
  end
`endif
  // pragma translate_on
endmodule
