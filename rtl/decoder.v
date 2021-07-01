/* Filename : decoder.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier : Quartus Prime - Standard Edition 20.1.1
 *
 * Decoder the uart received data
 */
 
module decoder #(
  parameter DATA_BIT = 32,
  parameter PACK_NUM = 5,
  parameter FREQ_NUM = 6
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
  output reg [7:0]          cmd_o,
  output reg                done_tick_o
);

// Define the states
localparam [1:0] S_IDLE = 2'b00;
localparam [1:0] S_FREQ = 2'b01;
localparam [1:0] S_DATA = 2'b10;
localparam [1:0] S_DONE = 2'b11;

localparam [7:0] CMD_FREQ = 8'h0A;
localparam [7:0] CMD_DATA = 8'h0B;

localparam PACK_BIT   = 8 * PACK_NUM; // 32-bit data_pattern, 8-bit control
localparam FREQ_BIT   = 8 * FREQ_NUM; // 32-bit freq_pattern, 8-bit low_period, 8-bit high_period
localparam FREQ_INDEX = 2 * DATA_BIT;

// Signal declaration
reg [1:0]          state_reg,    state_next;
reg [PACK_BIT-1:0] data_buf_reg, data_buf_next;
reg [3:0]          pack_num_reg, pack_num_next;
reg [47:0]         freq_buf_reg, freq_buf_next;
reg [3:0]          freq_num_reg, freq_num_next;
reg [7:0]          cmd_reg, cmd_next;

// Body
// FSMD state & data register
always @(posedge clk_i,  negedge rst_ni) begin
  if (~rst_ni)
    begin
      state_reg    <= S_IDLE;
      data_buf_reg <= 0;
      pack_num_reg <= 0;
      freq_buf_reg <= 0;
      freq_num_reg <= 0;
      cmd_reg      <= 0;
    end
  else
    begin
      state_reg    <= state_next;
      data_buf_reg <= data_buf_next;
      pack_num_reg <= pack_num_next;
      freq_buf_reg <= freq_buf_next;
      freq_num_reg <= freq_num_next;
      cmd_reg      <= cmd_next;
    end
end

// FSMD next-state logic
always @(*) begin
  state_next       = state_reg; // default state : the same
  data_buf_next    = data_buf_reg;
  pack_num_next    = pack_num_reg;
  freq_buf_next    = freq_buf_reg;
  freq_num_next    = freq_num_reg;
  cmd_next         = cmd_reg;
  done_tick_o      = 0;
  output_pattern_o = 0;
  freq_pattern_o   = 0;
  start_o          = 0;
  stop_o           = 0;
  mode_o           = 0;
  sel_out_o        = 0;
  slow_period_o    = 0;
  fast_period_o    = 0;
  cmd_o            = 0;

  case (state_reg)
    S_IDLE: begin
      pack_num_next = 0;
      if (rx_done_tick_i)
        begin
          cmd_next = data_i; // load rx data in MSB of data buffer
          if (cmd_next == CMD_FREQ)
            state_next = S_FREQ;
          else if (cmd_next == CMD_DATA)
            state_next = S_DATA;
        end
    end

    S_FREQ: begin
      if (rx_done_tick_i)
        begin
          freq_buf_next = {data_i, freq_buf_reg[FREQ_BIT-1:8]}; // right shift 8-bit
          freq_num_next = freq_num_reg + 1'b1;
        end
      else if (freq_num_reg == FREQ_NUM)
        begin
          state_next = S_DONE;
          freq_num_next = 0;
        end
    end

    S_DATA: begin
      if (rx_done_tick_i)
        begin
          data_buf_next = {data_i, data_buf_reg[PACK_BIT-1:8]}; // right-shift 8-bit
          pack_num_next = pack_num_reg + 1'b1;
        end
      else if (pack_num_reg == PACK_NUM)
        begin
          state_next    = S_DONE;
          pack_num_next = 0;
        end
    end

    S_DONE: begin
      done_tick_o      = 1;
      cmd_o            = cmd_reg;
      state_next       = S_IDLE;

      if (cmd_reg == CMD_FREQ)
        begin
          freq_pattern_o   = freq_buf_reg[DATA_BIT-1:0];
          slow_period_o    = freq_buf_reg[DATA_BIT+7:DATA_BIT];
          fast_period_o    = freq_buf_reg[DATA_BIT+15:DATA_BIT+8];
        end
      else if (cmd_reg == CMD_DATA)
        begin
          output_pattern_o = data_buf_reg[DATA_BIT-1:0];
          start_o          = data_buf_reg[DATA_BIT];
          stop_o           = data_buf_reg[DATA_BIT+1];
          mode_o           = data_buf_reg[DATA_BIT+2];
          sel_out_o        = data_buf_reg[DATA_BIT+7:DATA_BIT+4];
        end
    end

    default: state_next = S_IDLE;
  endcase
end

// Output

endmodule