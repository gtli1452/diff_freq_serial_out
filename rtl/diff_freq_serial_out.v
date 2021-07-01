/*
Filename    : diff_freq_serial_out.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : Serially output 32-bit data by different frequency
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out #(
  parameter DATA_BIT     = 32,
  parameter TICK_PER_BIT = 16,
  parameter TICK_10K_HZ  = 63,
  parameter TICK_20K_HZ  = 31
) (
  input                 clk,
  input                 rst_n,
  input                 i_sel_freq,  // select high/low frequency
  input                 i_start,
  input                 i_stop,
  input                 i_mode,      // one-shot, repeat
  input  [DATA_BIT-1:0] i_data,
  output                o_data,      // idle state is low
  output                o_bit_tick,
  output                o_done_tick
);

reg  tick;
wire tick_10kHz, tick_20kHz;

serial_out #(
  .DATA_BIT     (DATA_BIT),
  .TICK_PER_BIT (TICK_PER_BIT)
) serial_out1 (
  .clk          (clk),
  .rst_n        (rst_n),
  .i_tick       (tick),        // select high/low frequency
  .i_start      (i_start),
  .i_stop       (i_stop),
  .i_mode       (i_mode),      // one-shot, repeat
  .i_data       (i_data),
  .o_data       (o_data),      // idle state is low
  .o_bit_tick   (o_bit_tick),
  .o_done_tick  (o_done_tick)
);

always @(*) begin
  case (i_sel_freq)
    1'b0: begin
      tick = tick_10kHz;
    end
    1'b1: begin
      tick = tick_20kHz;
    end
    default: tick = tick_10kHz;
  endcase
end

mod_m_counter #(
  .MOD      (TICK_10K_HZ)
) tick_unit1 (
  .clk      (clk),
  .rst_n    (rst_n),
  .max_tick (tick_10kHz),
  .q        ()
);

mod_m_counter #(
  .MOD      (TICK_20K_HZ)
) tick_unit2 (
  .clk      (clk),
  .rst_n    (rst_n),
  .max_tick (tick_20kHz),
  .q        ()
);

endmodule
