/*
Filename    : diff_freq_serial_out.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : Serially output 32-bit data by different frequency
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out #(
  parameter       DATA_BIT     = 16,
  parameter       TICK_PER_BIT = 16,
  parameter [7:0] LOW_FREQ     = 20,
  parameter [7:0] HIGH_FREQ    = 10
) (
  input                 clk,
  input                 rst_n,
  input                 i_sel_freq,  // select high/low frequency
  input                 i_start,
  input                 i_stop,
  input  [1:0]          i_idle_mode, // high, low, keep, repeat
  input  [DATA_BIT-1:0] i_data,
  output                o_data,      // idle state is low
  output                o_done_tick
);

wire tick;

serial_out #(
  .DATA_BIT     (DATA_BIT), 
  .TICK_PER_BIT (TICK_PER_BIT)
) serial_out1 (
  .clk          (clk),
  .rst_n        (rst_n),
  .i_tick       (tick),  // select high/low frequency
  .i_start      (i_start),
  .i_stop       (i_stop),
  .i_idle_mode  (i_idle_mode), // high, low, keep, repeat
  .i_data       (i_data),
  .o_data       (o_data),      // idle state is low
  .o_done_tick  (o_done_tick)
);

mod_m_counter #(
  .MOD      (2)
) tick_10us (
  .clk      (clk),
  .rst_n    (rst_n),
  .max_tick (tick),
  .q        ()
);

endmodule
