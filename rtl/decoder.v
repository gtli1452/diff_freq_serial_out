/*
Filename    : unpack.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : decoder the uart received data
Author      : Tim.Li
Release     : 12/23/2020 v1.0
*/

module decoder #(
  parameter DATA_BIT = 16,
  parameter PACK_NUM = 5
) (
  input                     clk,
  input                     rst_n,
  input      [7:0]          i_data,
  input                     i_rx_done_tick,
  output reg [DATA_BIT-1:0] o_output_pattern,
  output reg [DATA_BIT-1:0] o_freq_pattern,
  output reg                o_mode,
  output                    o_start,
  output reg                o_stop,
  output reg                o_done_tick
);

// Define the states
localparam [1:0] S_IDLE = 2'b00;
localparam [1:0] S_DATA = 2'b01;
localparam [1:0] S_DONE = 2'b10;

localparam PACK_BIT = 8 * PACK_NUM;

// Signal declaration
reg [1:0]          state_reg,    state_next;
reg [7:0]          data_reg,     data_next;
reg [PACK_BIT-1:0] out_reg,      out_next;
reg [2:0]          pack_num_reg, pack_num_next;
reg                start_reg,    start_next;

// Body
// FSMD state & data register
always @(posedge clk,  negedge rst_n) begin
  if (~rst_n)
    begin
      state_reg    <= S_IDLE;
      data_reg     <= 0;
      out_reg      <= 0;
      pack_num_reg <= 0;
      start_reg    <= 0;
    end
  else
    begin
      state_reg    <= state_next;
      data_reg     <= data_next;
      out_reg      <= out_next;
      pack_num_reg <= pack_num_next;
      start_reg    <= start_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next    = state_reg; // default state : the same
  data_next     = data_reg;
  out_next      = out_reg;
  pack_num_next = pack_num_reg;
  start_next    = start_reg;
  o_done_tick   = 0;

  case (state_reg)
    S_IDLE: begin
      pack_num_next = 0;
      if (i_rx_done_tick)
        begin
          state_next = S_DATA;
          data_next  = i_data; // load rx data
        end
    end

    S_DATA: begin
      // out_next[31:24] = data_reg;
      out_next[PACK_BIT-1:PACK_BIT-8] = data_reg;
      if (i_rx_done_tick)
        begin
          out_next      = {i_data, out_reg[PACK_BIT-1:8]}; // right-shift 8-bit
          data_next     = i_data;
          pack_num_next = pack_num_reg + 1'b1;
        end
      else if (pack_num_reg == 4)
        begin
          state_next    = S_DONE;
          data_next     = i_data;
          pack_num_next = 0;
        end
    end

    S_DONE: begin
      o_done_tick      = 1;
      state_next       = S_IDLE;
      o_output_pattern = out_reg[15:0];
      o_freq_pattern   = out_reg[31:16];
      o_mode           = out_reg[34];
      o_stop           = out_reg[33];
      start_next       = out_reg[32];
    end

    default: state_next = S_IDLE;
  endcase
end

// Output
assign o_start = start_next & (~start_reg);

endmodule