/*
Filename    : serial_out.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : Serially output 32-bit data by different frequency
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module serial_out #(
  parameter       DATA_BIT  = 32,
  parameter [7:0] LOW_FREQ  = 9,
  parameter [7:0] HIGH_FREQ = 3
) (
  input                 clk_i,
  input                 rst_ni,
  input                 start_i,
  input                 stop_i,
  input                 mode_i,        // one-shot, repeat
  input  [DATA_BIT-1:0] output_pattern_i,
  input  [DATA_BIT-1:0] freq_pattern_i,
  input  [7:0]          slow_period_i,
  input  [7:0]          fast_period_i,
  output                serial_out_o,  // idle state is low
  output                bit_tick_o,
  output                done_tick_o
);

// Define the states
localparam [1:0] S_IDLE     = 2'b00;
localparam [1:0] S_ONE_SHOT = 2'b01;
localparam [1:0] S_DONE     = 2'b10;

localparam IDLE     = 1'b0;
localparam ONE_SHOT = 1'b0;
localparam REPEAT   = 1'b1;

// Signal declaration
reg [1:0]          state_reg,     state_next;
reg                mode_reg,      mode_next;
reg                output_reg,    output_next;
reg [5:0]          data_bit_reg,  data_bit_next;
reg [DATA_BIT-1:0] data_buf_reg,  data_buf_next;
reg [DATA_BIT-1:0] freq_buf_reg,  freq_buf_next;
reg [7:0]          slow_period,   slow_period_next;
reg [7:0]          fast_period,   fast_period_next;
reg [7:0]          count_reg,     count_next;
reg                bit_tick_reg,  bit_tick_next;
reg                done_tick_reg, done_tick_next;

// Body
// FSMD state & data registers
always @(posedge clk_i, negedge rst_ni) begin
  if (~rst_ni)
    begin
      state_reg     <= S_IDLE;
      mode_reg      <= 0;
      output_reg    <= 0;
      data_bit_reg  <= 0;
      data_buf_reg  <= {(DATA_BIT){1'b0}};
      freq_buf_reg  <= {(DATA_BIT){1'b0}};
      slow_period   <= 0;
      fast_period   <= 0;
      count_reg     <= 0;
      bit_tick_reg  <= 0;
      done_tick_reg <= 0;
    end
  else
    begin
      state_reg     <= state_next;
      mode_reg      <= mode_next;
      output_reg    <= output_next;
      data_bit_reg  <= data_bit_next;
      data_buf_reg  <= data_buf_next;
      freq_buf_reg  <= freq_buf_next;
      slow_period   <= slow_period_next;
      fast_period   <= fast_period_next;
      count_reg     <= count_next;
      bit_tick_reg  <= bit_tick_next;
      done_tick_reg <= done_tick_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next       = state_reg;
  mode_next        = mode_reg;
  output_next      = output_reg;
  data_bit_next    = data_bit_reg;
  data_buf_next    = data_buf_reg;
  freq_buf_next    = freq_buf_reg;
  slow_period_next = slow_period;
  fast_period_next = fast_period;
  count_next       = count_reg;
  bit_tick_next    = 0;
  done_tick_next   = 0;

  case (state_reg)
    // S_IDLE: waiting for the start_i, output depends on mode_i
    S_IDLE: begin
      output_next = IDLE;
      // start output
      if (start_i)
        begin
          // load the input data
          state_next       = S_ONE_SHOT;
          mode_next        = mode_i;  // load the mode, 0:one-shot, 1:repeat
          data_buf_next    = output_pattern_i;
          freq_buf_next    = freq_pattern_i;
          slow_period_next = slow_period_i;
          fast_period_next = fast_period_i;
          data_bit_next    = 0;
          if (freq_buf_next[0])
            count_next = fast_period_next - 1'b1;
          else
            count_next = slow_period_next - 1'b1;
        end
    end // case: S_IDLE
    // S_ONE_SHOT: serially output 32-bit data, it can change period per bit
    S_ONE_SHOT: begin
      output_next = data_buf_reg[data_bit_reg]; // transmit lsb first
      if (stop_i)
        begin
          state_next = S_IDLE;
        end
      else if (start_i)
        begin
          // load the input data
          mode_next        = mode_i;           // load the mode, 0:one-shot, 1:repeat
          data_buf_next    = output_pattern_i;
          freq_buf_next    = freq_pattern_i;
          slow_period_next = slow_period_i;
          fast_period_next = fast_period_i;
          data_bit_next    = 0;
          if (freq_buf_next[0])
            count_next = fast_period_next - 1'b1;
          else
            count_next = slow_period_next - 1'b1;
        end
      else if (count_reg == 0)
        begin
          bit_tick_next = 1;
         
          if (data_bit_reg == (DATA_BIT - 1 ))
            state_next = S_DONE;
          else
            data_bit_next = data_bit_reg + 1'b1;

          if (freq_buf_reg[data_bit_next])    // to get the next-bit freq, use "data_bit_next"
            count_next = fast_period_next - 1'b1;
          else
            count_next = slow_period_next - 1'b1;
        end
      else
        count_next = count_reg - 1'b1;
    end // case: S_ONE_SHOT
    // S_DONE: assert done_tick_o for one clock
    S_DONE: begin
      output_next    = output_reg;
      done_tick_next = 1;
      // repeat output
      if (mode_reg == REPEAT)
        begin
          state_next    = S_ONE_SHOT;
          data_bit_next = 0;
          if (freq_buf_next[0])
            count_next = fast_period_next - 1'b1;
          else
            count_next = slow_period_next - 1'b1;
        end
      else
          state_next = S_IDLE;
    end // case: S_DONE

    default: state_next = S_IDLE;
  endcase
end

// Output
assign serial_out_o = output_reg;
assign bit_tick_o   = bit_tick_reg;
assign done_tick_o  = done_tick_reg;

endmodule
