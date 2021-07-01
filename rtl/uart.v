//////////////////////////////////////////////////////////////////////
// Filename    : uart.v
// Compiler    : ModelSim 10.2c, Debussy 5.4 v9
// Author      : Tim.Li
// Release     : 11/12/2020 v1.0 - first version
//               11/20/2020 v2.0 - add FSM
//               12/14/2020 v3.0 - modify from ref[1]
// File Ref    :
// 1. "FPGA prototyping by Verilog examples" by Pong P. Chu
//////////////////////////////////////////////////////////////////////
// Description :
// This file contains the UART Module. This UART is able to
// receive/transmit 8 bits of serial data, one start bit,
// one stop bit, and no parity bit.
//
// s_tick is 16 times the baudrate

module UART #(
  parameter SYS_CLK   = 10_000_000, // 10Mhz
  parameter BAUD_RATE = 9600,
  parameter DATA_BITS = 8,
  parameter STOP_BIT  = 1
) (
  input                  clk,
  input                  rst_n,

  //rx interface
  input                  i_rx,
  output                 o_rx_done_tick,
  output [DATA_BITS-1:0] o_rx_data,

  //tx interface
  input                  i_tx_start,
  input [DATA_BITS-1:0]  i_tx_data,
  output                 o_tx,
  output                 o_tx_done_tick
);

// Parameter
localparam STOP_TICK = STOP_BIT * 16;
localparam CLK_DIV   = SYS_CLK / (16*BAUD_RATE); // SYS_CLK/(16*BAUD_RATE)
localparam DIV_BIT   = $clog2(CLK_DIV);          // bits for TICK_DIVIDE, it must be >= log2(TICK_DIVIDE)

// Signal declaration
wire tick;

uart_rx #(
  .DATA_BITS      (DATA_BITS),
  .STOP_TICK      (STOP_TICK)
) uart_rx_unit (
  .clk            (clk),
  .rst_n          (rst_n),
  .i_sample_tick  (tick),
  .i_rx           (i_rx),
  .o_rx_done_tick (o_rx_done_tick),
  .o_rx_data      (o_rx_data)
);

uart_tx #(
  .DATA_BITS      (DATA_BITS),
  .STOP_TICK      (STOP_TICK)
) uart_tx_unit (
  .clk            (clk),
  .rst_n          (rst_n),
  .i_sample_tick  (tick),
  .i_tx_start     (i_tx_start),
  .i_tx_data      (i_tx_data),
  .o_tx           (o_tx),
  .o_tx_done_tick (o_tx_done_tick)
);

mod_m_counter #(
  .MOD      (CLK_DIV),
  .MOD_BIT  (DIV_BIT)
) baud_tick_unit (
  .clk      (clk),
  .rst_n    (rst_n),
  .max_tick (tick),
  .q        ()
);
endmodule
