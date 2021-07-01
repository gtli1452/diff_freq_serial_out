/*
Filename    : diff_freq_serial_out_tb.v
Compiler    : ModelSim 10.2c, Debussy 5.4 v9
Description : ModelSim with debussy
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out_test (
  input  clk,          // PIN_P9
  input  rst_n,        // PIN_G13
  output o_serial_out0, // PIN_T7
  output o_serial_out1, // PIN_P8
  output o_bit_tick,   // PIN_R10
  output o_done_tick,  // PIN_T8

  // UART
  input  i_rx,
  output o_tx
);

localparam DATA_BIT = 8;
localparam PACK_NUM = 3;

wire o_rx_done_tick, o_tx_done;
wire [7:0] tb_received_data;

diff_freq_serial_out #(
  .DATA_BIT       (DATA_BIT),
  .PACK_NUM       (PACK_NUM)
) DUT (
  .clk            (clk),
  .rst_n          (rst_n),
  .i_data         (tb_received_data),
  .i_rx_done_tick (o_rx_done_tick),
  .o_serial_out0  (o_serial_out0),
  .o_serial_out1  (o_serial_out1),
  .o_bit_tick     (o_bit_tick),
  .o_done_tick    (o_done_tick)
);

localparam SYS_CLK   = 10_000_000; // 10Mhz
localparam BAUD_RATE = 19200;
localparam DATA_SIZE = 8;          // 8-bit data
localparam STOP_TICK = 16;         // 1-bit stop (16 ticks/bit)
localparam CLK_DIV   = 33;         // SYS_CLK/(16*BAUD_RATE), i.e. 10M/(16*19200)
localparam DIV_BIT   = 6;          // bits for TICK_DIVIDE, it must be >= log2(TICK_DIVIDE)

UART #(
  .SYS_CLK       (SYS_CLK),
  .BAUD_RATE     (BAUD_RATE),
  .DATA_BITS     (DATA_SIZE),
  .STOP_TICK     (STOP_TICK),
  .CLK_DIV       (CLK_DIV),
  .DIV_BIT       (DIV_BIT)
) DUT_uart (
  .clk            (clk),
  .rst_n          (rst_n),
  //rx interface
  .i_rx           (i_rx),
  .o_rx_done_tick (o_rx_done_tick),
  .o_rx_data      (tb_received_data),
  
  //tx interface
  .i_tx_start     (o_rx_done_tick),
  .i_tx_data      (tb_received_data),
  .o_tx           (o_tx),
  .o_tx_done_tick (o_tx_done)
);

endmodule
