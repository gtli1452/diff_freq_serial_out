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
  input                     clk_i,
  input                     rst_ni,
  input      [7:0]          data_i,
  input                     rx_done_tick_i,
  output reg [DATA_BIT-1:0] output_pattern_o,
  output reg [DATA_BIT-1:0] freq_pattern_o,
  output reg [3:0]          sel_out_o,
  output reg                start_o,
  output reg                stop_o,
  output reg                mode_o,
  output reg [7:0]          slow_period_o,
  output reg [7:0]          fast_period_o,
  output reg                done_tick_o
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
always @(posedge clk_i,  negedge rst_ni) begin
  if (~rst_ni)
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
  done_tick_o      = 0;
  output_pattern_o = 0;
  freq_pattern_o   = 0;
  start_o          = 0;
  stop_o           = 0;
  mode_o           = 0;
  sel_out_o        = 0;
  slow_period_o    = 0;
  fast_period_o    = 0;

  case (state_reg)
    S_IDLE: begin
      pack_num_next = 0;
      if (rx_done_tick_i)
        begin
          state_next = S_DATA;
          data_buf_next[PACK_BIT-1:PACK_BIT-8] = data_i; // load rx data in MSB of data buffer
        end
    end

    S_DATA: begin
      if (rx_done_tick_i)
        begin
          data_buf_next = {data_i, data_buf_reg[PACK_BIT-1:8]}; // right-shift 8-bit
          pack_num_next = pack_num_reg + 1'b1;
        end
      else if (pack_num_reg == PACK_NUM-1)
        begin
          state_next    = S_DONE;
          pack_num_next = 0;
        end
    end

    S_DONE: begin
      done_tick_o      = 1;
      state_next       = S_IDLE;
      
      output_pattern_o = data_buf_reg[DATA_BIT-1:0];
      freq_pattern_o   = data_buf_reg[FREQ_INDEX-1:DATA_BIT];
      start_o          = data_buf_reg[FREQ_INDEX];
      stop_o           = data_buf_reg[FREQ_INDEX+1];
      mode_o           = data_buf_reg[FREQ_INDEX+2];
      sel_out_o        = data_buf_reg[FREQ_INDEX+7:FREQ_INDEX+4];
      slow_period_o    = data_buf_reg[FREQ_INDEX+15:FREQ_INDEX+8];
      fast_period_o    = data_buf_reg[FREQ_INDEX+23:FREQ_INDEX+16];
    end

    default: state_next = S_IDLE;
  endcase
end

// Output

endmodule