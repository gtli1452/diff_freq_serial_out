/*
Filename    : diff_freq_serial_out.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : Serially output 32-bit data by different frequency
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out #(
  parameter       DATA_BIT  = 16,
  parameter [7:0] LOW_FREQ  = 20,
  parameter [7:0] HIGH_FREQ = 10
) (
  input                 clk,
  input                 rst_n,
  input                 i_sel_freq,  // select high/low frequency
  input                 i_start,
  input                 i_stop,
  input  [1:0]          i_idle_mode, // high, low, keep, repeat
  input  [DATA_BIT-1:0] i_data,
  output                o_data,      // idle state is low
  output reg            o_done_tick
);

// Define the states
localparam [1:0] S_IDLE    = 2'b00;
localparam [1:0] S_ENABLE  = 2'b01;
localparam [1:0] S_DONE    = 2'b10;

localparam [1:0] LOW       = 2'b00;
localparam [1:0] HIGH      = 2'b01;
localparam [1:0] KEEP      = 2'b10;
localparam [1:0] REPEAT    = 2'b11;

// Signal declaration
reg [1:0]          state_reg,     state_next;
reg                output_reg,    output_next;
reg [5:0]          data_bit_reg,  data_bit_next;
reg [DATA_BIT-1:0] data_buf_reg,  data_buf_next;
reg [7:0]          count_reg,     count_next;
reg [7:0]          count_max_reg, count_max_next;

// Body
// FSMD state & data registers
always @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    begin
      state_reg     <= S_IDLE;
      output_reg    <= 1'b0;
      data_bit_reg  <= 5'b0;
      data_buf_reg  <= {(DATA_BIT){1'b0}};
      count_reg     <= 7'b0;
      count_max_reg <= LOW_FREQ - 1'b1;
    end
  else
    begin
      state_reg     <= state_next;
      output_reg    <= output_next;
      data_bit_reg  <= data_bit_next;
      data_buf_reg  <= data_buf_next;
      count_reg     <= count_next;
      count_max_reg <= count_max_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next     = state_reg;
  output_next    = output_reg;
  data_bit_next  = data_bit_reg;
  data_buf_next  = data_buf_reg;
  count_next     = count_reg;
  count_max_next = count_max_reg;
  o_done_tick    = 1'b0;

  case (state_reg)
    // S_IDLE: waiting for the i_start, output depends on i_idle_mode
    S_IDLE: begin
      // determine the idle output, default is low.
      case (i_idle_mode)
        HIGH:    output_next = 1'b1;
        LOW:     output_next = 1'b0;
        KEEP:    output_next = output_reg;
        default: output_next = 1'b0;
      endcase
      // start output
      if (i_start)
        begin
          state_next    = S_ENABLE;
          data_buf_next = i_data; // load the input data
          data_bit_next = 0;
          count_next    = 7'b0;   // reset the counter
          if (i_sel_freq) // get the frequency for next bit
            count_max_next = HIGH_FREQ - 1'b1;
          else
            count_max_next = LOW_FREQ - 1'b1;
        end
    end // case: S_IDLE
    // S_ENABLE: serially output 32-bit data, it can change period per bit
    S_ENABLE: begin
      output_next = data_buf_next[0]; // transmit lsb first
      if (i_stop)
        begin
          state_next = S_IDLE;
        end
      else if (count_reg == count_max_reg)
        begin
          count_next = 7'b0;
          data_buf_next = data_buf_reg >> 1;

          if (i_sel_freq) // get the frequency for next bit
            count_max_next = HIGH_FREQ - 1'b1;
          else
            count_max_next = LOW_FREQ - 1'b1;

          if (data_bit_reg == (DATA_BIT - 1 ))
            state_next = S_DONE;
          else
            data_bit_next = data_bit_reg + 1'b1;
        end
      else
        count_next = count_reg + 1'b1;
    end // case: S_ENABLE
    // S_DONE: assert o_done_tick for one clock
    S_DONE: begin
      o_done_tick = 1'b1;
      state_next  = S_IDLE;

      case (i_idle_mode)
        HIGH:    output_next = 1'b1;
        LOW:     output_next = 1'b0;
        KEEP: begin
          output_next = output_reg;
          state_next    = S_ENABLE;
          data_buf_next = i_data; // load the input data
          data_bit_next = 0;
          count_next    = 7'b0;   // reset the counter
        end
        default: output_next = 1'b0;
      endcase

    end // case: S_DONE

    default: state_reg = S_IDLE;
  endcase
end

// Output
assign o_data = output_reg;

endmodule
