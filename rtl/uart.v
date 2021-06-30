/* Filename : uart.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier : Quartus Prime - Standard Edition 20.1.1
 *
 * This file contains the UART Module. It is able to receive/transmit
 * 8 bits of serial data, one start bit, one stop bit, and no parity bit.
 *
 * The source code is modified from:
 * Pong P. Chu - FPGA Prototyping By Verilog Examples
 */

module UART #(
  parameter SYS_CLK   = 10_000_000, // 10Mhz
  parameter BAUD_RATE = 9600,
  parameter DATA_BITS = 8,
  parameter STOP_BIT  = 1
) (
  input                  clk_i,
  input                  rst_ni,
  //rx interface
  input                  rx_i,
  output                 rx_done_tick_o,
  output [DATA_BITS-1:0] rx_data_o,
  //tx interface
  input                  tx_start_i,
  input [DATA_BITS-1:0]  tx_data_i,
  output                 tx_o,
  output                 tx_done_tick_o
);

// Parameter
localparam STOP_TICK = STOP_BIT * 16;
localparam CLK_DIV   = SYS_CLK / (16*BAUD_RATE); // SYS_CLK/(16*BAUD_RATE)
localparam DIV_BIT   = $clog2(CLK_DIV);          // bits for TICK_DIVIDE, it must be >= log2(TICK_DIVIDE)

// Signal declaration
wire tick;

uart_rx #(
  .DATA_BITS     (DATA_BITS),
  .STOP_TICK     (STOP_TICK)
) uart_rx_unit (
  .clk_i         (clk_i),
  .rst_ni        (rst_ni),
  .sample_tick_i (tick),
  .rx_i          (rx_i),
  .rx_done_tick_o(rx_done_tick_o),
  .rx_data_o     (rx_data_o)
);

uart_tx #(
  .DATA_BITS     (DATA_BITS),
  .STOP_TICK     (STOP_TICK)
) uart_tx_unit (
  .clk_i         (clk_i),
  .rst_ni        (rst_ni),
  .sample_tick_i (tick),
  .tx_start_i    (tx_start_i),
  .tx_data_i     (tx_data_i),
  .tx_o          (tx_o),
  .tx_done_tick_o(tx_done_tick_o)
);

mod_m_counter #(
  .MOD       (CLK_DIV),
  .MOD_BIT   (DIV_BIT)
) baud_tick_unit (
  .clk_i     (clk_i),
  .rst_ni    (rst_ni),
  .max_tick_o(tick)
);
endmodule
