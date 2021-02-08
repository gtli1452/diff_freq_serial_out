/*
Filename    : diff_freq_serial_out.v
Simulation  : ModelSim 10.2c, Debussy 5.4 v9
Description : Serially output 32-bit data by different frequency
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out #(
  parameter DATA_BIT        = 32,
  parameter PACK_NUM        = 9,
  parameter OUTPUT_NUM      = 16,
  parameter LOW_PERIOD_CLK  = 9,
  parameter HIGH_PERIOD_CLK = 3
) (
  input         clk,
  input         rst_n,
  input  [7:0]  i_data,
  input         i_rx_done_tick,
  output [15:0] o_serial_out,
  output        o_bit_tick,
  output        o_done_tick
);

// Define the states
localparam [1:0] S_IDLE   = 2'b00;
localparam [1:0] S_UPDATE = 2'b01;
localparam [1:0] S_DONE   = 2'b10;

// Signal declaration
// to load the decoder output
reg [1:0]          state_reg,   state_next;
reg [DATA_BIT-1:0] output_reg,  output_next;
reg [DATA_BIT-1:0] freq_reg,    freq_next;
reg [3:0]          sel_out_reg, sel_out_next;
reg                start_reg,   start_next;
reg                stop_reg,    stop_next;
reg                mode_reg,    mode_next;
reg                update_tick;

// Decoder signal
wire [DATA_BIT-1:0] o_decode_output;
wire [DATA_BIT-1:0] o_decode_freq;
wire [3:0]          o_decode_sel_out;
wire                o_decode_start;
wire                o_decode_stop;
wire                o_decode_mode;
wire                o_decode_done_tick;

// Signal to serial out entity
reg [DATA_BIT-1:0] channel_output      [15:0];
reg [DATA_BIT-1:0] channel_output_next [15:0];
reg [DATA_BIT-1:0] channel_freq        [15:0];
reg [DATA_BIT-1:0] channel_freq_next   [15:0];
reg [15:0]         channel_start, channel_start_next;
reg [15:0]         channel_stop,  channel_stop_next;
reg [15:0]         channel_mode,  channel_mode_next;

// Wire assignment
// Create start_tick for one-shot
wire [15:0] start_tick;
assign start_tick = channel_start & {16{update_tick}};

// for loop variable
integer i;

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
      // control bit pattern
      channel_start <= 0;
      channel_stop  <= 0;
      channel_mode  <= 0;
      // output pattern
      for (i = 0; i < OUTPUT_NUM; i = i + 1)
        channel_output[i] <= 0;
      // freq pattern
      for (i = 0; i < OUTPUT_NUM; i = i + 1)
        channel_freq[i] <= 0;
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
      // control bit pattern
      channel_start <= channel_start_next;
      channel_stop  <= channel_stop_next;
      channel_mode  <= channel_mode_next;
      // output pattern
      for (i = 0; i < OUTPUT_NUM; i = i + 1)
        channel_output[i] <= channel_output_next[i];
      // freq pattern
      for (i = 0; i < OUTPUT_NUM; i = i + 1)
        channel_freq[i] <= channel_freq_next[i];
    end
end

// FSMD next-state logic, to update the output pattern
always @(*) begin
  state_next   = state_reg;
  output_next  = output_reg;
  freq_next    = freq_reg;
  sel_out_next = sel_out_reg;
  start_next   = start_reg;
  stop_next    = stop_reg;
  mode_next    = mode_reg;
  // control bit pattern
  channel_start_next = channel_start;
  channel_stop_next  = channel_stop;
  channel_mode_next  = channel_mode;
  update_tick   = 0;
  // output pattern
  for (i = 0; i < OUTPUT_NUM; i = i + 1)
    channel_output_next[i] = channel_output[i];
  // freq pattern
  for (i = 0; i < OUTPUT_NUM; i = i + 1)
    channel_freq_next[i] = channel_freq[i];

  case (state_reg)
    S_IDLE: begin
      if (o_decode_done_tick)
        begin
          state_next   = S_UPDATE;
          output_next  = o_decode_output;
          freq_next    = o_decode_freq;
          sel_out_next = o_decode_sel_out;
          start_next   = o_decode_start;
          stop_next    = o_decode_stop;
          mode_next    = o_decode_mode;
        end
    end

    S_UPDATE: begin
      if (sel_out_reg == OUTPUT_NUM-1)
        state_next  = S_DONE;
      else
        state_next  = S_IDLE;

      channel_output_next[sel_out_reg] = output_reg;
      channel_freq_next  [sel_out_reg] = freq_reg;
      channel_start_next [sel_out_reg] = start_reg;
      channel_stop_next  [sel_out_reg] = stop_reg;
      channel_mode_next  [sel_out_reg] = mode_reg;
    end

    S_DONE: begin
      state_next  = S_IDLE;
      update_tick = 1;
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
  .o_output_pattern (o_decode_output),
  .o_freq_pattern   (o_decode_freq),
  .o_sel_out        (o_decode_sel_out),
  .o_start          (o_decode_start),
  .o_stop           (o_decode_stop),
  .o_mode           (o_decode_mode),
  .o_done_tick      (o_decode_done_tick)
);

// Use generate loop to create instances
genvar j;
generate for (j = 0; j < OUTPUT_NUM; j = j + 1)
  begin: serial_out_entity
    serial_out #(
    .DATA_BIT           (DATA_BIT),
    .LOW_FREQ           (LOW_PERIOD_CLK),
    .HIGH_FREQ          (HIGH_PERIOD_CLK)
    ) channel (
      .clk              (clk),
      .rst_n            (rst_n),
      .i_start          (start_tick    [j]),
      .i_stop           (channel_stop  [j]),
      .i_mode           (channel_mode  [j]), // one-shot, repeat
      .i_output_pattern (channel_output[j]),
      .i_freq_pattern   (channel_freq  [j]),
      .o_serial_out     (o_serial_out  [j]), // idle state is low
      .o_bit_tick       (),
      .o_done_tick      ()
    );
  end
endgenerate

endmodule
