/*
Filename    : diff_freq_serial_out_tb.v
Compiler    : ModelSim 10.2c, Debussy 5.4 v9
Description : ModelSim with debussy
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

module diff_freq_serial_out_tb ();

// Parameter declaration
localparam DATA_BIT      = 8;
localparam SYS_PERIOD_NS = 100;     // 1/10Mhz = 100ns
localparam IDLE_LOW      = 1'b0;
localparam IDLE_HIGH     = 1'b1;
localparam ONE_SHOT      = 1'b0;
localparam REPEAT        = 1'b1;
localparam LOW_SPEED     = 1'b0;
localparam HIGH_SPEED    = 1'b1;

// Signal declaration
reg                 clk         = 0;
reg                 rst_n       = 0;
reg                 i_sel_freq  = 0; // select low/high frequency
reg                 i_start     = 0;
reg                 i_stop      = 0;
reg                 i_mode      = 0; // one-shot, repeat
reg  [DATA_BIT-1:0] i_data      = 0;
wire                o_bit_tick;
wire                o_data;          // idle state is low
wire                o_done_tick;     // tick one clock when transmission is done

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
  .DATA_BIT    (DATA_BIT),
  .TICK_10K_HZ (),
  .TICK_20K_HZ ()
) serial_out_unit (
  .clk         (clk),
  .rst_n       (rst_n),
  .i_sel_freq  (i_sel_freq), // select high/low frequency
  .i_start     (i_start),
  .i_stop      (i_stop),
  .i_mode      (i_mode),     // one-shot, repeat
  .i_data      (i_data),
  .o_bit_tick  (o_bit_tick),
  .o_data      (o_data),     // idle state is low
  .o_done_tick (o_done_tick)
);

initial begin
  @(posedge rst_n);   // wait for finish reset
  CHANGE_CLK_PER_PACK(8'h55, HIGH_SPEED, ONE_SHOT);
  CHANGE_CLK_PER_PACK(8'hAA, LOW_SPEED, ONE_SHOT);
  CHANGE_CLK_PER_BIT(8'h55, HIGH_SPEED, ONE_SHOT);
  CHANGE_CLK_PER_BIT(8'hAA, LOW_SPEED, ONE_SHOT);

  $finish;
end

task CHANGE_CLK_PER_PACK;
  input [DATA_BIT-1:0] input_data;
  input                transmit_clk;
  input                output_mode;
  begin
    i_sel_freq = transmit_clk; // select low speed
    i_data     = input_data;
    i_start    = 1'b1;         // start transmit
    i_mode     = output_mode;  // one-shot, repeat
    @(posedge clk);
    i_start    = 1'b0;         // start signal is high in one clock
    @(posedge o_done_tick);
  end
endtask

task CHANGE_CLK_PER_BIT;
  input [DATA_BIT-1:0] input_data;
  input                transmit_clk;
  input                output_mode;
  integer i;
  begin
    i_sel_freq = transmit_clk; // select low speed
    i_data     = input_data;
    i_start    = 1'b1;         // start transmit
    i_mode     = output_mode;  // one-shot, repeat
    @(posedge clk);
    i_start    = 1'b0;         // start signal is high in one clock
    
    repeat(DATA_BIT - 1)
      begin
        @(posedge o_bit_tick);
        i_sel_freq = ~i_sel_freq;
      end

    @(posedge o_done_tick);
  end
endtask

endmodule
