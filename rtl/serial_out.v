/*
Filename    : serial_out.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : Serially output 32-bit data by different frequency
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module serial_out #(
  parameter DATA_BIT     = 32,
  parameter TICK_PER_BIT = 16
) (
  input                 clk,
  input                 rst_n,
  input                 i_start,
  input                 i_stop,
  input                 i_mode,        // one-shot, repeat
  input  [DATA_BIT-1:0] i_output_pattern,
  input  [DATA_BIT-1:0] i_freq_pattern,
  output                o_serial_out,  // idle state is low
  output                o_done_tick,
  output                o_bit_tick
);

// Define the states
localparam [1:0] S_IDLE   = 2'b00;
localparam [1:0] S_ENABLE = 2'b01;
localparam [1:0] S_DONE   = 2'b10;

localparam       IDLE     = 1'b0;
localparam       ONE_SHOT = 1'b0;
localparam       REPEAT   = 1'b1;

localparam       LOW_FREQ  = 9;
localparam       HIGH_FREQ = 3;

// Signal declaration
reg [1:0]          state_reg,     state_next;
reg                output_reg,    output_next;
reg [5:0]          data_bit_reg,  data_bit_next;
reg [DATA_BIT-1:0] data_buf_reg,  data_buf_next;
reg [DATA_BIT-1:0] freq_buf_reg,  freq_buf_next;
reg [7:0]          count_reg,     count_next;
reg                bit_tick_reg,  bit_tick_next;
reg                done_tick_reg, done_tick_next;

// Body
// FSMD state & data registers
always @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    begin
      state_reg     <= S_IDLE;
      output_reg    <= 0;
      data_bit_reg  <= 0;
      data_buf_reg  <= {(DATA_BIT){1'b0}};
      freq_buf_reg  <= {(DATA_BIT){1'b0}};
      count_reg     <= 0;
      bit_tick_reg  <= 0;
      done_tick_reg <= 0;
    end
  else
    begin
      state_reg     <= state_next;
      output_reg    <= output_next;
      data_bit_reg  <= data_bit_next;
      data_buf_reg  <= data_buf_next;
      freq_buf_reg  <= freq_buf_next;
      count_reg     <= count_next;
      bit_tick_reg  <= bit_tick_next;
      done_tick_reg <= done_tick_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next     = state_reg;
  output_next    = output_reg;
  data_bit_next  = data_bit_reg;
  data_buf_next  = data_buf_reg;
  freq_buf_next  = freq_buf_reg;
  count_next     = count_reg;
  bit_tick_next  = 0;
  done_tick_next = 0;

  case (state_reg)
    // S_IDLE: waiting for the i_start, output depends on i_mode
    S_IDLE: begin
      output_next = IDLE;
      // start output
      if (i_start)
        begin
          state_next    = S_ENABLE;
          data_buf_next = i_output_pattern; // load the input data
          freq_buf_next = i_freq_pattern;   // load the input data
          data_bit_next = 0;
          if (freq_buf_next[0])
            count_next = HIGH_FREQ - 1'b1;
          else
            count_next = LOW_FREQ - 1'b1;
        end
    end // case: S_IDLE
    // S_ENABLE: serially output 32-bit data, it can change period per bit
    S_ENABLE: begin
      output_next = data_buf_reg[data_bit_reg]; // transmit lsb first
      if (i_stop)
        begin
          state_next = S_IDLE;
        end
      else if (count_reg == 0)
        begin
          bit_tick_next = 1;
         
          if (data_bit_reg == (DATA_BIT - 1 ))
            state_next = S_DONE;
          else
            data_bit_next = data_bit_reg + 1'b1;

          if (freq_buf_reg[data_bit_next])    // to get the next-bit freq, use "data_bit_next"
            count_next = HIGH_FREQ - 1'b1;
          else
            count_next = LOW_FREQ - 1'b1;
        end
      else
        count_next = count_reg - 1'b1;
    end // case: S_ENABLE
    // S_DONE: assert o_done_tick for one clock
    S_DONE: begin
      output_next    = output_reg;
      done_tick_next = 1;
      // repeat output
      if (i_mode == REPEAT)
        begin
          state_next    = S_ENABLE;
          data_buf_next = i_output_pattern; // load the input data
          freq_buf_next = i_freq_pattern;   // load the input data
          data_bit_next = 0;
          if (freq_buf_next[0])
            count_next = HIGH_FREQ - 1'b1;
          else
            count_next = LOW_FREQ - 1'b1;
        end
      else
          state_next = S_IDLE;
    end // case: S_DONE

    default: state_reg = S_IDLE;
  endcase
end

// Output
assign o_serial_out = output_reg;
assign o_bit_tick   = bit_tick_reg;
assign o_done_tick  = done_tick_reg;

endmodule
