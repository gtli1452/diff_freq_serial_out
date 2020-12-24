/*
Filename    : decoder_tb.v
Compiler    : ModelSim 10.2c, Debussy 5.4 v9
Description : ModelSim with debussy
Author      : Tim.Li
Release     : 12/23/2020 v1.0
*/
`timescale 1 ns / 1 ps

module decoder_tb ();

//Test bench uses a 10 MHz clock.
//UART baud is 9600 bits/s
//10_000_000/9600 = 1042 Clocks Per Bit.
localparam SYS_PERIOD_NS = 100;        // 1/10Mhz = 100ns
localparam SYS_CLK       = 10_000_000;
localparam BAUD_RATE     = 9600;
localparam CLK_PER_BIT   = 1042;
localparam BIT_PERIOD    = 1042_00;    // CLK_PER_BIT = 1042, 1042*100ns = 104200.
localparam DATA_SIZE     = 8;
localparam STOP_TICK     = 16;         // 1-bit stop (16 ticks/bit)
localparam CLK_DIV       = 65;         // SYS_CLK/(16*BAUD_RATE), i.e. 10M/(16*9600)
localparam DIV_BIT       = 7;          // bits for TICK_DIVIDE, it must be >= log2(TICK_DIVIDE)
localparam DATA_BIT      = 16;
reg clk;
reg rst_n;

reg  tb_RxSerial;
wire tb_TxSerial;

// rx output port
wire tb_rx_done;
wire [DATA_SIZE-1:0] tb_received_data;
wire tb_tx_done;

// decoder signal
  wire [DATA_BIT-1:0] o_output_pattern;
  wire [DATA_BIT-1:0] o_freq_pattern;
  wire [3:0]          o_sel_out;
  wire                o_mode;
  wire                o_stop;
  wire                o_start;
  wire                o_done_tick;

// clock, T = 20ns
always #(SYS_PERIOD_NS/2) clk = ~clk;

// reset the module
initial begin
  #0;
  clk   = 1'b0;
  rst_n = 1'b0;
  #15;
  rst_n = 1'b1;
end

initial begin
  $fsdbDumpfile("decoder.fsdb");
  $fsdbDumpvars(0, decoder_tb);
end

decoder #(
  .DATA_BIT(DATA_BIT)
) decoder_dut (
  .clk              (clk),
  .rst_n            (rst_n),
  .i_data           (tb_received_data),
  .i_rx_done_tick   (tb_rx_done),
  .o_output_pattern (o_output_pattern),
  .o_freq_pattern   (o_freq_pattern),
  .o_sel_out        (o_sel_out),
  .o_mode           (o_mode),
  .o_start          (o_start),
  .o_stop           (o_stop),
  .o_done_tick      (o_done_tick)
);

UART #(
  .SYS_CLK        (SYS_CLK),
  .BAUD_RATE      (BAUD_RATE),
  .DATA_BITS      (DATA_SIZE),
  .STOP_TICK      (STOP_TICK),
  .CLK_DIV        (CLK_DIV),
  .DIV_BIT        (DIV_BIT)
) DUT_uart (
  .clk            (clk),
  .rst_n          (rst_n),

  //rx interface
  .i_rx           (tb_RxSerial),
  .o_rx_done_tick (tb_rx_done),
  .o_rx_data      (tb_received_data),

  //tx interface
  .i_tx_start     (tb_rx_done),
  .i_tx_data      (tb_received_data),
  .o_tx           (tb_TxSerial),
  .o_tx_done_tick (tb_tx_done)
);

reg [DATA_SIZE-1:0] test_byte;

//Starting test
initial begin
  //Check RX module
  repeat(11)
    begin
      test_byte = $random;
      UART_WRITE_BYTE(test_byte);
    end
  #(4*BIT_PERIOD)
  $finish;
end

//To check RX module
task UART_WRITE_BYTE;
  input [DATA_SIZE-1:0] WRITE_DATA;
  integer i;
  begin
    //Send Start Bit
    tb_RxSerial = 1'b0;
    #(BIT_PERIOD);

    //Send Data Byte
    for (i = 0; i < DATA_SIZE; i = i + 1)
      begin
        tb_RxSerial = WRITE_DATA[i];
        #(BIT_PERIOD);
      end

    //Send Stop Bit
    tb_RxSerial = 1'b1;
    #(BIT_PERIOD);
  end
endtask


endmodule
