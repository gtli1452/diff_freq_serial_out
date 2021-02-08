/*
Filename    : unpack.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : decoder the uart received data
Author      : Tim.Li
Release     : 12/23/2020 v1.0
*/

module decoder #(
  parameter DATA_BIT = 32,
  parameter PACK_NUM = 11
) (
  input                     clk,
  input                     rst_n,
  input      [7:0]          i_data,
  input                     i_rx_done_tick,
  output reg [DATA_BIT-1:0] o_output_pattern,
  output reg [DATA_BIT-1:0] o_freq_pattern,
  output reg [3:0]          o_sel_out,
  output reg                o_start,
  output reg                o_stop,
  output reg                o_mode,
  output reg [7:0]          o_slow_period,
  output reg [7:0]          o_fast_period,
  output reg                o_done_tick
);

// Define the states
localparam [1:0] S_IDLE = 2'b00;
localparam [1:0] S_DATA = 2'b01;
localparam [1:0] S_DONE = 2'b10;

localparam PACK_BIT   = 8 * PACK_NUM;
localparam FREQ_INDEX = 2 * DATA_BIT;

// Signal declaration
reg [1:0]          state_reg,    state_next;
reg [PACK_BIT-1:0] data_buf_reg, data_buf_next;
reg [3:0]          pack_num_reg, pack_num_next;

// Body
// FSMD state & data register
always @(posedge clk,  negedge rst_n) begin
  if (~rst_n)
    begin
      state_reg    <= S_IDLE;
      data_buf_reg <= 0;
      pack_num_reg <= 0;
    end
  else
    begin
      state_reg    <= state_next;
      data_buf_reg <= data_buf_next;
      pack_num_reg <= pack_num_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next       = state_reg; // default state : the same
  data_buf_next    = data_buf_reg;
  pack_num_next    = pack_num_reg;
  o_done_tick      = 0;
  o_output_pattern = 0;
  o_freq_pattern   = 0;
  o_start          = 0;
  o_stop           = 0;
  o_mode           = 0;
  o_sel_out        = 0;
  o_slow_period    = 0;
  o_fast_period    = 0;

  case (state_reg)
    S_IDLE: begin
      pack_num_next = 0;
      if (i_rx_done_tick)
        begin
          state_next = S_DATA;
          data_buf_next[PACK_BIT-1:PACK_BIT-8] = i_data; // load rx data in MSB of data buffer
        end
    end

    S_DATA: begin
      if (i_rx_done_tick)
        begin
          data_buf_next = {i_data, data_buf_reg[PACK_BIT-1:8]}; // right-shift 8-bit
          pack_num_next = pack_num_reg + 1'b1;
        end
      else if (pack_num_reg == PACK_NUM-1)
        begin
          state_next    = S_DONE;
          pack_num_next = 0;
        end
    end

    S_DONE: begin
      o_done_tick      = 1;
      state_next       = S_IDLE;
      
      o_output_pattern = data_buf_reg[DATA_BIT-1:0];
      o_freq_pattern   = data_buf_reg[FREQ_INDEX-1:DATA_BIT];
      o_start          = data_buf_reg[FREQ_INDEX];
      o_stop           = data_buf_reg[FREQ_INDEX+1];
      o_mode           = data_buf_reg[FREQ_INDEX+2];
      o_sel_out        = data_buf_reg[FREQ_INDEX+7:FREQ_INDEX+4];
      o_slow_period    = data_buf_reg[FREQ_INDEX+15:FREQ_INDEX+8];
      o_fast_period    = data_buf_reg[FREQ_INDEX+23:FREQ_INDEX+16];
    end

    default: state_next = S_IDLE;
  endcase
end

// Output

endmodule