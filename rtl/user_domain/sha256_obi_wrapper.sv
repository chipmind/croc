// Copyright 2026 Chipmind AG.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Designed by: Chipmind Agents
// Module: sha256_obi_wrapper

/// SHA-256 OBI wrapper: bridges OBI to AXI4-Lite and instantiates the
/// secworks sha256_axi4 IP core.
module sha256_obi_wrapper
  import croc_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,

  // OBI subordinate interface
  input  sbr_obi_req_t obi_req_i,
  output sbr_obi_rsp_t obi_rsp_o,

  // Interrupt output
  output logic hash_complete_o
);

  // AXI4-Lite signals between bridge and sha256_axi4
  logic [7:0]  axi_awaddr;
  logic [2:0]  axi_awprot;
  logic        axi_awvalid;
  logic        axi_awready;
  logic [31:0] axi_wdata;
  logic [3:0]  axi_wstrb;
  logic        axi_wvalid;
  logic        axi_wready;
  logic [1:0]  axi_bresp;
  logic        axi_bvalid;
  logic        axi_bready;
  logic [7:0]  axi_araddr;
  logic [2:0]  axi_arprot;
  logic        axi_arvalid;
  logic        axi_arready;
  logic [31:0] axi_rdata;
  logic [1:0]  axi_rresp;
  logic        axi_rvalid;
  logic        axi_rready;

  // OBI-to-AXI4-Lite bridge
  obi_to_axi4lite #(
    .AddrWidth ( 8                        ),
    .DataWidth ( SbrObiCfg.DataWidth      ),
    .IdWidth   ( SbrObiCfg.IdWidth        )
  ) i_obi_to_axi4lite (
    .clk_i,
    .rst_ni,

    .obi_req_i    ( obi_req_i.req         ),
    .obi_gnt_o    ( obi_rsp_o.gnt         ),
    .obi_addr_i   ( obi_req_i.a.addr[7:0] ),
    .obi_we_i     ( obi_req_i.a.we        ),
    .obi_be_i     ( obi_req_i.a.be        ),
    .obi_wdata_i  ( obi_req_i.a.wdata     ),
    .obi_aid_i    ( obi_req_i.a.aid       ),
    .obi_rvalid_o ( obi_rsp_o.rvalid      ),
    .obi_rdata_o  ( obi_rsp_o.r.rdata     ),
    .obi_err_o    ( obi_rsp_o.r.err       ),
    .obi_rid_o    ( obi_rsp_o.r.rid       ),

    .axi_awaddr_o  ( axi_awaddr  ),
    .axi_awprot_o  ( axi_awprot  ),
    .axi_awvalid_o ( axi_awvalid ),
    .axi_awready_i ( axi_awready ),
    .axi_wdata_o   ( axi_wdata   ),
    .axi_wstrb_o   ( axi_wstrb   ),
    .axi_wvalid_o  ( axi_wvalid  ),
    .axi_wready_i  ( axi_wready  ),
    .axi_bresp_i   ( axi_bresp   ),
    .axi_bvalid_i  ( axi_bvalid  ),
    .axi_bready_o  ( axi_bready  ),
    .axi_araddr_o  ( axi_araddr  ),
    .axi_arprot_o  ( axi_arprot  ),
    .axi_arvalid_o ( axi_arvalid ),
    .axi_arready_i ( axi_arready ),
    .axi_rdata_i   ( axi_rdata   ),
    .axi_rresp_i   ( axi_rresp   ),
    .axi_rvalid_i  ( axi_rvalid  ),
    .axi_rready_o  ( axi_rready  )
  );

  // SHA-256 AXI4-Lite IP core
  sha256_axi4 #(
    .C_S00_AXI_DATA_WIDTH ( 32 ),
    .C_S00_AXI_ADDR_WIDTH ( 8  )
  ) i_sha256_axi4 (
    .hash_complete    ( hash_complete_o ),

    .s00_axi_aclk     ( clk_i       ),
    .s00_axi_aresetn  ( rst_ni      ),
    .s00_axi_awaddr   ( axi_awaddr  ),
    .s00_axi_awprot   ( axi_awprot  ),
    .s00_axi_awvalid  ( axi_awvalid ),
    .s00_axi_awready  ( axi_awready ),
    .s00_axi_wdata    ( axi_wdata   ),
    .s00_axi_wstrb    ( axi_wstrb   ),
    .s00_axi_wvalid   ( axi_wvalid  ),
    .s00_axi_wready   ( axi_wready  ),
    .s00_axi_bresp    ( axi_bresp   ),
    .s00_axi_bvalid   ( axi_bvalid  ),
    .s00_axi_bready   ( axi_bready  ),
    .s00_axi_araddr   ( axi_araddr  ),
    .s00_axi_arprot   ( axi_arprot  ),
    .s00_axi_arvalid  ( axi_arvalid ),
    .s00_axi_arready  ( axi_arready ),
    .s00_axi_rdata    ( axi_rdata   ),
    .s00_axi_rresp    ( axi_rresp   ),
    .s00_axi_rvalid   ( axi_rvalid  ),
    .s00_axi_rready   ( axi_rready  )
  );

endmodule
