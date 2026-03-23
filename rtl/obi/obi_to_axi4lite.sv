// Copyright 2026 Chipmind AG.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Designed by: Chipmind Agents
// Module: obi_to_axi4lite

/// OBI-to-AXI4-Lite bridge with 6-state pure-combinational FSM.
/// Translates OBI subordinate transactions to AXI4-Lite master transactions.
module obi_to_axi4lite #(
  parameter int unsigned AddrWidth = 32,
  parameter int unsigned DataWidth = 32,
  parameter int unsigned IdWidth   = 1
) (
  input  logic clk_i,
  input  logic rst_ni,

  // OBI subordinate interface
  input  logic                   obi_req_i,
  output logic                   obi_gnt_o,
  input  logic [AddrWidth-1:0]   obi_addr_i,
  input  logic                   obi_we_i,
  input  logic [DataWidth/8-1:0] obi_be_i,
  input  logic [DataWidth-1:0]   obi_wdata_i,
  input  logic [IdWidth-1:0]     obi_aid_i,
  output logic                   obi_rvalid_o,
  output logic [DataWidth-1:0]   obi_rdata_o,
  output logic                   obi_err_o,
  output logic [IdWidth-1:0]     obi_rid_o,

  // AXI4-Lite master interface
  output logic [AddrWidth-1:0]   axi_awaddr_o,
  output logic [2:0]             axi_awprot_o,
  output logic                   axi_awvalid_o,
  input  logic                   axi_awready_i,
  output logic [DataWidth-1:0]   axi_wdata_o,
  output logic [DataWidth/8-1:0] axi_wstrb_o,
  output logic                   axi_wvalid_o,
  input  logic                   axi_wready_i,
  input  logic [1:0]             axi_bresp_i,
  input  logic                   axi_bvalid_i,
  output logic                   axi_bready_o,
  output logic [AddrWidth-1:0]   axi_araddr_o,
  output logic [2:0]             axi_arprot_o,
  output logic                   axi_arvalid_o,
  input  logic                   axi_arready_i,
  input  logic [DataWidth-1:0]   axi_rdata_i,
  input  logic [1:0]             axi_rresp_i,
  input  logic                   axi_rvalid_i,
  output logic                   axi_rready_o
);

  // FSM states
  typedef enum logic [2:0] {
    IDLE        = 3'd0,
    AXI_WR_ADDR = 3'd1,
    AXI_WR_DATA = 3'd2,
    AXI_WR_RESP = 3'd3,
    AXI_RD_ADDR = 3'd4,
    AXI_RD_DATA = 3'd5
  } state_e;

  state_e state_q, state_d;

  // Latched OBI request fields
  logic [AddrWidth-1:0]   addr_q;
  logic [DataWidth-1:0]   wdata_q;
  logic [DataWidth/8-1:0] be_q;
  logic [IdWidth-1:0]     aid_q;

  // State and request register
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= IDLE;
      addr_q  <= '0;
      wdata_q <= '0;
      be_q    <= '0;
      aid_q   <= '0;
    end else begin
      state_q <= state_d;
      // Latch OBI request when granted in IDLE
      if (state_q == IDLE && obi_req_i) begin
        addr_q  <= obi_addr_i;
        wdata_q <= obi_wdata_i;
        be_q    <= obi_be_i;
        aid_q   <= obi_aid_i;
      end
    end
  end

  // Pure combinational FSM
  always_comb begin
    // Default: hold state, no outputs
    state_d = state_q;

    // OBI outputs
    obi_gnt_o    = 1'b0;
    obi_rvalid_o = 1'b0;
    obi_rdata_o  = '0;
    obi_err_o    = 1'b0;
    obi_rid_o    = aid_q;

    // AXI outputs (keep address/data from latched values)
    axi_awaddr_o  = addr_q;
    axi_awprot_o  = 3'b111; // prot=1 acts as CS for sha256_axi4
    axi_awvalid_o = 1'b0;
    axi_wdata_o   = wdata_q;
    axi_wstrb_o   = be_q;
    axi_wvalid_o  = 1'b0;
    axi_bready_o  = 1'b0;
    axi_araddr_o  = addr_q;
    axi_arprot_o  = 3'b111;
    axi_arvalid_o = 1'b0;
    axi_rready_o  = 1'b0;

    unique case (state_q)
      // -----------------------------------------------------------------------
      IDLE: begin
        if (obi_req_i) begin
          obi_gnt_o = 1'b1;
          state_d   = obi_we_i ? AXI_WR_ADDR : AXI_RD_ADDR;
        end
      end

      // -----------------------------------------------------------------------
      // Write: assert awvalid + wvalid simultaneously
      AXI_WR_ADDR: begin
        axi_awvalid_o = 1'b1;
        axi_wvalid_o  = 1'b1;
        if (axi_awready_i && axi_wready_i)
          state_d = AXI_WR_RESP;
        else if (axi_awready_i && !axi_wready_i)
          state_d = AXI_WR_DATA;
        // else stay: neither or only wready (keep both valid)
      end

      // -----------------------------------------------------------------------
      // Write: awready received, waiting for wready
      AXI_WR_DATA: begin
        axi_wvalid_o = 1'b1;
        if (axi_wready_i)
          state_d = AXI_WR_RESP;
      end

      // -----------------------------------------------------------------------
      // Write: waiting for write response
      AXI_WR_RESP: begin
        axi_bready_o = 1'b1;
        if (axi_bvalid_i) begin
          obi_rvalid_o = 1'b1;
          obi_err_o    = |axi_bresp_i;
          state_d      = IDLE;
        end
      end

      // -----------------------------------------------------------------------
      // Read: assert arvalid
      AXI_RD_ADDR: begin
        axi_arvalid_o = 1'b1;
        if (axi_arready_i)
          state_d = AXI_RD_DATA;
      end

      // -----------------------------------------------------------------------
      // Read: waiting for read data
      AXI_RD_DATA: begin
        axi_rready_o = 1'b1;
        if (axi_rvalid_i) begin
          obi_rvalid_o = 1'b1;
          obi_rdata_o  = axi_rdata_i;
          obi_err_o    = |axi_rresp_i;
          state_d      = IDLE;
        end
      end

      default: state_d = IDLE;
    endcase
  end

endmodule
