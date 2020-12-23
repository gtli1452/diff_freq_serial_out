//////////////////////////////////////////////////////////////////////
// Filename    : uart_rx.v
// Compiler    : ModelSim 10.2c, Debussy 5.4 v9
// Author      : Tim.Li
// Release     : 11/12/2020 v1.0 - first version
//               11/20/2020 v2.0 - add FSM
//               12/14/2020 v3.0 - modify from ref[1]
// File Ref    :
// 1. "FPGA prototyping by Verilog examples" by Pong P. Chu
//////////////////////////////////////////////////////////////////////
// Description :
// This file contains the UART Receiver. This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit. When receive is completed o_rx_done_tick will be
// driven high for one clock cycle.
//
// i_sample_tick is 16 times the baud rate

module uart_rx #(
  parameter DATA_BITS = 8,
  parameter STOP_TICK = 16
) (
  input                  clk,
  input                  rst_n,
  input                  i_sample_tick,
  input                  i_rx,
  output reg             o_rx_done_tick,
  output [DATA_BITS-1:0] o_rx_data
);

// Define the states
localparam [1:0]    S_IDLE  = 2'b00;
localparam [1:0]    S_START = 2'b01;
localparam [1:0]    S_DATA  = 2'b10;
localparam [1:0]    S_STOP  = 2'b11;

// Signal declaration
reg [1:0]           state_reg, state_next;
reg [3:0]           tick_count_reg, tick_count_next; // i_sample_tick counter
reg [2:0]           data_count_reg, data_count_next; // data bit counter
reg [DATA_BITS-1:0] data_buf_reg, data_buf_next;     // data buf

// Body
// FSMD state & data registers
always @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    begin
      state_reg      <= S_IDLE;
      tick_count_reg <= 0;
      data_count_reg <= 0;
      data_buf_reg   <= 0;
    end
  else
    begin
      state_reg      <= state_next;
      tick_count_reg <= tick_count_next;
      data_count_reg <= data_count_next;
      data_buf_reg   <= data_buf_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next      = state_reg;
  tick_count_next = tick_count_reg;
  data_count_next = data_count_reg;
  data_buf_next   = data_buf_reg;
  o_rx_done_tick  = 1'b0;

  case (state_reg)
    // S_Idle: waiting for the start bit
    S_IDLE: begin
      if (~i_rx)
        begin
          state_next      = S_START;
          tick_count_next = 0;
        end
    end // case: S_IDLE

    // S_START: sample the middle of the start bit
    S_START: begin
      if (i_sample_tick)
        begin
          if (tick_count_reg == 7)
            begin // sample the middle of start bit (16 ticks per bit)
              state_next      = S_DATA;
              tick_count_next = 0;
              data_count_next = 0;
            end
          else
            tick_count_next = tick_count_reg + 1'b1;
        end
    end // case: S_START

    // S_DATA: sample the middle of each data bit
    S_DATA: begin
      if (i_sample_tick)
        begin
          if (tick_count_reg == 15)
            begin
              tick_count_next = 0;
              data_buf_next   = {i_rx, data_buf_reg[7:1]}; // right-shit 1-bit
              if (data_count_reg == (DATA_BITS - 1))
                state_next = S_STOP;
              else
                data_count_next = data_count_reg + 1'b1;
            end
          else
            tick_count_next = tick_count_reg + 1'b1;
        end
    end // case: S_DATA

    // S_STOP: sample the stop bit, and assert o_rx_done_tick
    S_STOP: begin
      if (i_sample_tick)
        begin
          if (tick_count_reg == (STOP_TICK - 1))
            begin
              state_next     = S_IDLE;
              o_rx_done_tick = 1'b1;
            end
          else
            tick_count_next = tick_count_reg + 1'b1;
        end
    end // case: S_STOP

    default: state_next = S_IDLE;
  endcase
end

// Output
assign o_rx_data = data_buf_reg;

endmodule