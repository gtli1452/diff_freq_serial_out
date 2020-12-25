/*
Filename    : diff_freq_serial_out.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : Serially output 32-bit data by different frequency
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out #(
  parameter DATA_BIT     = 32,
  parameter PACK_NUM     = 9
) (
  input        clk,
  input        rst_n,
  input  [7:0] i_data,
  input        i_rx_done_tick,
  output       o_serial_out,   // idle state is low
  output       o_bit_tick,
  output       o_done_tick
);

// Decoder signal
wire [DATA_BIT-1:0] o_output_pattern;
wire [DATA_BIT-1:0] o_freq_pattern;
wire [3:0]          o_sel_out;
wire                o_start;
wire                o_stop;
wire                o_mode;
wire                decoder_done_tick;

// Serial out signal
reg [DATA_BIT-1:0] ch0_output_pattern = 0;
reg [DATA_BIT-1:0] ch0_freq_pattern   = 0;
reg                ch0_start          = 0;
reg                ch0_stop           = 0;
reg                ch0_mode           = 0;

// Define the states
localparam [1:0] S_IDLE   = 2'b00;
localparam [1:0] S_UPDATE = 2'b01;
localparam [1:0] S_DONE   = 2'b10;


// Signal declaration
reg [1:0]          state_reg,   state_next;
reg [DATA_BIT-1:0] output_reg,  output_next;
reg [DATA_BIT-1:0] freq_reg,    freq_next;
reg [3:0]          sel_out_reg, sel_out_next;
reg                start_reg,   start_next;
reg                stop_reg,    stop_next;
reg                mode_reg,    mode_next;
reg                update_done_tick;

// Body
// FSMD state & data register
always @(posedge clk,  negedge rst_n) begin
  if (~rst_n)
    begin
      state_reg   <= S_IDLE;
      output_reg  <= 0;
      freq_reg    <= 0;
      sel_out_reg <= 0;
      start_reg   <= 0;
      stop_reg    <= 0;
      mode_reg    <= 0;
    end
  else
    begin
      state_reg   <= state_next;
      output_reg  <= output_next;
      freq_reg    <= freq_next;
      sel_out_reg <= sel_out_next;
      start_reg   <= start_next; 
      stop_reg    <= stop_next; 
      mode_reg    <= mode_next; 
    end
end

// FSMD next-state logic, to update the output pattern
always @(*) begin
  state_next       = state_reg;
  output_next      = output_reg;
  freq_next        = freq_reg;
  sel_out_next     = sel_out_reg;
  start_next       = start_reg;
  stop_next        = stop_reg;
  mode_next        = mode_reg;
  update_done_tick = 0;
  ch0_start        = 0;
  case (state_reg)
    S_IDLE: begin
      if (decoder_done_tick)
        begin
          state_reg    = S_UPDATE;
          output_next  = o_output_pattern;
          freq_next    = o_freq_pattern;
          sel_out_next = o_sel_out;
          start_next   = o_start;
          stop_next    = o_stop;
          mode_next    = o_mode;
        end
    end

    S_UPDATE: begin
      case (sel_out_reg)
        4'd0: begin
          ch0_output_pattern = output_reg;
          ch0_freq_pattern   = freq_reg;
          ch0_start          = start_reg;
          state_next         = S_DONE;
        end
      endcase
    end

    S_DONE: begin
      state_next       = S_IDLE;
      update_done_tick = 1;
    end

    default: state_next = S_IDLE;
  endcase
end

decoder #(
  .DATA_BIT (DATA_BIT),
  .PACK_NUM (PACK_NUM)
) decoder_dut (
  .clk              (clk),
  .rst_n            (rst_n),
  .i_data           (i_data),
  .i_rx_done_tick   (i_rx_done_tick),
  .o_output_pattern (o_output_pattern),
  .o_freq_pattern   (o_freq_pattern),
  .o_sel_out        (o_sel_out),
  .o_start          (o_start),
  .o_stop           (o_stop),
  .o_mode           (o_mode),
  .o_done_tick      (decoder_done_tick)
);

serial_out #(
  .DATA_BIT     (DATA_BIT)
) serial_out1 (
  .clk              (clk),
  .rst_n            (rst_n),
  .i_start          (ch0_start),
  .i_stop           (stop_reg),
  .i_mode           (mode_reg),          // one-shot, repeat
  .i_output_pattern (ch0_output_pattern),
  .i_freq_pattern   (ch0_freq_pattern),
  .o_serial_out     (o_serial_out),      // idle state is low
  .o_bit_tick       (o_bit_tick),
  .o_done_tick      (o_done_tick)
);

endmodule
