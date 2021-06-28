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
  input                   clk_i,
  input                   rst_ni,
  input  [7:0]            data_i,
  input                   rx_done_tick_i,
  output [OUTPUT_NUM-1:0] serial_out_o,
  output                  bit_tick_o,
  output                  done_tick_o
);

// Define the states
localparam [1:0] S_IDLE   = 2'b00;
localparam [1:0] S_UPDATE = 2'b01;
localparam [1:0] S_DONE   = 2'b10;

localparam [7:0] CMD_FREQ = 8'h0A;
localparam [7:0] CMD_DATA = 8'h0B;

// Signal declaration
// to load the decoder output
reg [1:0]          state_reg,   state_next;
reg [DATA_BIT-1:0] output_reg,  output_next;
reg [DATA_BIT-1:0] freq_reg,    freq_next;
reg [3:0]          sel_out_reg, sel_out_next;
reg                start_reg,   start_next;
reg                stop_reg,    stop_next;
reg                mode_reg,    mode_next;
reg [7:0]          low_period_reg,  low_period_next;
reg [7:0]          high_period_reg, high_period_next;
reg                update_tick;

// Decoder signal
wire [DATA_BIT-1:0] decode_output;
wire [DATA_BIT-1:0] decode_freq;
wire [3:0]          decode_sel_out;
wire                decode_start;
wire                decode_stop;
wire                decode_mode;
wire [7:0]          decode_low_period;
wire [7:0]          decode_high_period;
wire [7:0]          decode_cmd;
wire                decode_done_tick;

// Signal to serial out entity
reg [DATA_BIT-1:0]   channel_output[OUTPUT_NUM-1:0];
reg [DATA_BIT-1:0]   channel_output_next[OUTPUT_NUM-1:0];
reg [DATA_BIT-1:0]   channel_freq;
reg [DATA_BIT-1:0]   channel_freq_next;
reg [7:0]            channel_low_period;
reg [7:0]            channel_low_period_next;
reg [7:0]            channel_high_period;
reg [7:0]            channel_high_period_next;
reg [OUTPUT_NUM-1:0] channel_start, channel_start_next;
reg [OUTPUT_NUM-1:0] channel_stop,  channel_stop_next;
reg [OUTPUT_NUM-1:0] channel_mode,  channel_mode_next;

// Wire assignment
// Create start_tick for one-shot
wire [OUTPUT_NUM-1:0] start_tick;
assign start_tick = channel_start & {OUTPUT_NUM{update_tick}};

// for loop variable
integer i;

// Body
// FSMD state & data register
always @(posedge clk_i,  negedge rst_ni) begin
  if (~rst_ni)
    begin
      state_reg       <= S_IDLE;
      output_reg      <= 0;
      freq_reg        <= 0;
      sel_out_reg     <= 0;
      start_reg       <= 0;
      stop_reg        <= 0;
      mode_reg        <= 0;
      low_period_reg  <= 0;
      high_period_reg <= 0;
      // control bit pattern
      channel_start   <= 0;
      channel_stop    <= 0;
      channel_mode    <= 0;
      // freq pattern
      channel_freq        <= 0;
      channel_low_period  <= 0;
      channel_high_period <= 0;

      for (i = 0; i < OUTPUT_NUM; i = i + 1)
        begin
          channel_output[i]      <= 0;
        end
    end
  else
    begin
      state_reg       <= state_next;
      output_reg      <= output_next;
      freq_reg        <= freq_next;
      sel_out_reg     <= sel_out_next;
      start_reg       <= start_next;
      stop_reg        <= stop_next;
      mode_reg        <= mode_next;
      low_period_reg  <= low_period_next;
      high_period_reg <= high_period_next;
      // control bit pattern
      channel_start   <= channel_start_next;
      channel_stop    <= channel_stop_next;
      channel_mode    <= channel_mode_next;
      // freq pattern
      channel_freq        <= channel_freq_next;
      channel_low_period  <= channel_low_period_next;
      channel_high_period <= channel_high_period_next;
      
      for (i = 0; i < OUTPUT_NUM; i = i + 1)
        begin
          channel_output[i] <= channel_output_next[i];
        end
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
  low_period_next  = low_period_reg;
  high_period_next = high_period_reg;
  // control bit pattern
  channel_start_next = channel_start;
  channel_stop_next  = channel_stop;
  channel_mode_next  = channel_mode;
  update_tick   = 0;
  // freq pattern
  channel_freq_next        = channel_freq;
  channel_low_period_next  = channel_low_period;
  channel_high_period_next = channel_high_period;
  
  for (i = 0; i < OUTPUT_NUM; i = i + 1)
    begin
      channel_output_next[i]      = channel_output[i];
    end

  case (state_reg)
    S_IDLE: begin
      if (decode_done_tick)
        begin
          state_next = S_UPDATE;
          if (decode_cmd == CMD_FREQ)
            begin
              freq_next        = decode_freq;
              low_period_next  = decode_low_period;
              high_period_next = decode_high_period;
            end
          else if (decode_cmd == CMD_DATA)
            begin
              output_next      = decode_output;
              sel_out_next     = decode_sel_out;
              start_next       = decode_start;
              stop_next        = decode_stop;
              mode_next        = decode_mode;
            end
        end
    end

    S_UPDATE: begin
      if (sel_out_reg == OUTPUT_NUM-1)
        state_next  = S_DONE;
      else
        state_next  = S_IDLE;

      channel_output_next[sel_out_reg]      = output_reg;
      channel_start_next[sel_out_reg]       = start_reg;
      channel_stop_next[sel_out_reg]        = stop_reg;
      channel_mode_next[sel_out_reg]        = mode_reg;
      channel_freq_next        = freq_reg;
      channel_low_period_next  = low_period_reg;
      channel_high_period_next = high_period_reg;
    end

    S_DONE: begin
      state_next  = S_IDLE;
      update_tick = 1;
    end

    default: state_next = S_IDLE;
  endcase
end

decoder #(
  .DATA_BIT        (DATA_BIT),
  .PACK_NUM        (PACK_NUM)
) decoder_dut (
  .clk_i           (clk_i),
  .rst_ni          (rst_ni),
  .data_i          (data_i),
  .rx_done_tick_i  (rx_done_tick_i),
  .output_pattern_o(decode_output),
  .freq_pattern_o  (decode_freq),
  .sel_out_o       (decode_sel_out),
  .start_o         (decode_start),
  .stop_o          (decode_stop),
  .mode_o          (decode_mode),
  .slow_period_o   (decode_low_period),
  .fast_period_o   (decode_high_period),
  .cmd_o           (decode_cmd),
  .done_tick_o     (decode_done_tick)
);

// Use generate loop to create instances
genvar j;
generate for (j = 0; j < OUTPUT_NUM; j = j + 1)
  begin: serial_out_entity
    serial_out #(
    .DATA_BIT          (DATA_BIT),
    .LOW_FREQ          (LOW_PERIOD_CLK),
    .HIGH_FREQ         (HIGH_PERIOD_CLK)
    ) channel (
      .clk_i           (clk_i),
      .rst_ni          (rst_ni),
      .start_i         (start_tick[j]),
      .stop_i          (channel_stop[j]),
      .mode_i          (channel_mode[j]), // one-shot, repeat
      .output_pattern_i(channel_output[j]),
      .freq_pattern_i  (channel_freq),
      .slow_period_i   (channel_low_period),
      .fast_period_i   (channel_high_period),
      .serial_out_o    (serial_out_o[j]), // idle state is low
      .bit_tick_o      (),
      .done_tick_o     ()
    );
  end
endgenerate

endmodule
