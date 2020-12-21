/*
Filename    : diff_freq_serial_out_tb.v
Compiler    : ModelSim 10.2c, Debussy 5.4 v9
Description : ModelSim with debussy
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out_tb ();

// Parameter declaration
localparam       DATA_BIT      = 8;
localparam       SYS_PERIOD_NS = 100; // 1/10Mhz = 100ns

localparam [7:0] LOW_FREQ      = 20;  // 10MHz/20 = 0.5MHz
localparam [7:0] HIGH_FREQ     = 10;  // 10MHz/10 = 1MHz

localparam [1:0] IDLE_LOW      = 2'b00;
localparam [1:0] IDLE_HIGH     = 2'b01;
localparam [1:0] IDLE_KEEP     = 2'b10;
localparam [1:0] IDLE_REPEAT   = 2'b11;

localparam       LOW_SPEED     = 1'b0;
localparam       HIGH_SPEED    = 1'b1;

// Signal declaration
reg                 clk         = 1'b0;
reg                 rst_n       = 1'b0;
reg                 i_sel_freq  = 1'b0; // select high/low frequency
reg                 i_start     = 1'b0;
reg                 i_stop      = 1'b0;
reg  [1:0]          i_idle_mode = 0;    // high, low, keep, repeat
reg  [DATA_BIT-1:0] i_data      = 0;
wire                o_data;             // idle state is low
wire                o_done_tick;        // tick one clock when transmission is done

always #(SYS_PERIOD_NS/2) clk = ~clk;

initial begin
  #0;
  clk   = 1'b0;
  rst_n = 1'b0;

  #5;
  rst_n = 1'b1;
  #(SYS_PERIOD_NS/2);
end

initial begin
  $fsdbDumpfile("diff_freq_serial_out.fsdb");
  $fsdbDumpvars(0, diff_freq_serial_out_tb);
end

diff_freq_serial_out #(
  .DATA_BIT  (DATA_BIT),
  .LOW_FREQ  (LOW_FREQ),
  .HIGH_FREQ (HIGH_FREQ)
) serial_out_unit (
  .clk         (clk),
  .rst_n       (rst_n),
  .i_sel_freq  (i_sel_freq),  // select high/low frequency
  .i_start     (i_start),
  .i_stop      (i_stop),
  .i_idle_mode (i_idle_mode), // high, low, keep, repeat
  .i_data      (i_data),
  .o_data      (o_data),      // idle state is low
  .o_done_tick (o_done_tick)
);

initial begin
  @(posedge rst_n);   // wait for finish reset
  CHANGE_CLK_PER_PACKAGE(8'h55, HIGH_SPEED, IDLE_LOW);
  CHANGE_CLK_PER_PACKAGE(8'h55, LOW_SPEED, IDLE_LOW);
  CHANGE_CLK_PER_PACKAGE(8'h55, LOW_SPEED, IDLE_LOW);
  
  $finish;
end

task CHANGE_CLK_PER_PACKAGE;
  input [DATA_BIT-1:0] input_data;
  input                transmit_clk;
  input                idle_output;
  begin
    i_sel_freq  = transmit_clk; // select low speed
    i_data      = input_data;
    i_start     = 1'b1;         // start transmit
    i_idle_mode = idle_output;  // idle output is low
    @(posedge clk);
    i_start     = 1'b0;         // start signal is high in one clock  
    @(negedge o_done_tick);
  end
endtask


endmodule
