// ***************************************************************************
// ***************************************************************************
// Copyright 2011(c) Analog Devices, Inc.
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     - Neither the name of Analog Devices, Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//     - The use of this software may or may not infringe the patent rights
//       of one or more patent holders.  This license does not release you
//       from the requirement that you obtain separate licenses from these
//       patent holders to use this software.
//     - Use of the software either in source or binary form, must be run
//       on or directly connected to an Analog Devices Inc. component.
//    
// THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
// RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module util_rfifo (

  rstn,

  m_clk,
  m_rd,
  m_en,
  m_rdata,
  m_runf,
  s_clk,
  s_rd,
  s_en,
  s_rdata,
  s_runf,

  fifo_rst,
  fifo_wr,
  fifo_wdata,
  fifo_wfull,
  fifo_rd,
  fifo_rdata,
  fifo_rempty,
  fifo_runf);

  // parameters (S) bus width must be greater than (M)

  parameter MS_CLOCK_RATIO = 4;
  parameter M_DATA_WIDTH = 32;
  parameter S_DATA_WIDTH = 64;
 
  // common clock

  input                           rstn;

  // master/slave write 

  input                           m_clk;
  input                           m_rd;
  input                           m_en;
  output  [M_DATA_WIDTH-1:0]      m_rdata;
  output                          m_runf;
  input                           s_clk;
  output                          s_rd;
  output                          s_en;
  input   [S_DATA_WIDTH-1:0]      s_rdata;
  input                           s_runf;

  // fifo interface

  output                          fifo_rst;
  output                          fifo_wr;
  output  [S_DATA_WIDTH-1:0]      fifo_wdata;
  input                           fifo_wfull;
  output                          fifo_rd;
  input   [M_DATA_WIDTH-1:0]      fifo_rdata;
  input                           fifo_rempty;
  input                           fifo_runf;

  // internal registers

  reg                             s_rd = 'd0;
  reg                             fifo_wr = 'd0;
  reg                             m_runf_m1 = 'd0;
  reg                             m_runf_m2 = 'd0;
  reg   [M_DATA_WIDTH-1:0]        m_rdata = 'd0;
  reg                             m_runf = 'd0;
  reg   [MS_CLOCK_RATIO-1:0]      m_en_m1;
  reg                             m_en_m2;
  reg                             s_en_s1;
  reg                             s_en_sync;
  reg                             s_en;

  // internal signals

  wire                            m_runf_s;

  // defaults

  assign fifo_rst = ~rstn;

  // independent clocks and buswidths- simply expect
  // user to set a reasonable threshold on the full signal

  always @(posedge s_clk) begin
    s_rd <= ~fifo_wfull & s_en_sync;
    fifo_wr <= ~fifo_wfull & s_en_sync;
    s_en <= s_en_sync;
  end

  // enable sync
  always @(posedge m_clk) begin
    if (MS_CLOCK_RATIO > 1) begin
        m_en_m1 <= {m_en_m1[MS_CLOCK_RATIO-2:0],m_en};
    end else begin
        m_en_m1 <= m_en;
    end
    m_en_m2 <= |m_en_m1;
  end
  
  always @(posedge s_clk) begin
    s_en_s1 <= m_en_m2;
    s_en_sync <= s_en_s1;
  end
  
  genvar s;
  generate
  for (s = 0; s < S_DATA_WIDTH; s = s + 1) begin: g_wdata
  assign fifo_wdata[s] = s_rdata[(S_DATA_WIDTH-1)-s];
  end
  endgenerate

  // read is non-destructive

  assign fifo_rd = m_rd;
  assign m_runf_s = s_runf | fifo_runf;

  always @(posedge m_clk) begin
    m_runf_m1 <= m_runf_s;
    m_runf_m2 <= m_runf_m1;
    m_runf <= m_runf_m2;
  end
  
  genvar m;
  generate
  for (m = 0; m < M_DATA_WIDTH; m = m + 1) begin: g_rdata
    always @(posedge m_clk) begin
        m_rdata[m] <= fifo_rdata[(M_DATA_WIDTH-1)-m];
    end
  end
  endgenerate

endmodule

// ***************************************************************************
// ***************************************************************************
