/*
Filename    : diff_freq_serial_out_tb.v
Compiler    : ModelSim 10.2c, Debussy 5.4 v9
Description : ModelSim with debussy
Author      : Tim.Li
Release     : 12/16/2020 v1.0
*/

`timescale 1ns / 100ps

module diff_freq_serial_out_tb ();

// Parameter declaration
// output & frequency pattern are all 32-bit, control_bits is 8-bit
localparam DATA_BIT      = 32;
localparam PACK_NUM      = (DATA_BIT/8)*2+3; // PACK_NUM = (out_pattern + freq_pattern + control_bits)/8 = (32+32+8)/8

localparam SYS_CLK       = 100_000_000;
localparam SYS_PERIOD_NS = 10;     // 1/100Mhz = 10ns
localparam IDLE_LOW      = 1'b0;
localparam IDLE_HIGH     = 1'b1;
localparam ONE_SHOT      = 1'b0;
localparam REPEAT        = 1'b1;
localparam [7:0] LOW_PERIOD_CLK  = 20;
localparam [7:0] HIGH_PERIOD_CLK = 5;

localparam BAUD_RATE        = 256000;
localparam CLK_PER_UART_BIT = SYS_CLK/BAUD_RATE;
localparam UART_BIT_PERIOD  = CLK_PER_UART_BIT * SYS_PERIOD_NS;
localparam UART_DATA_BIT    = 8;
localparam UART_STOP_BIT    = 1;

// Signal declaration
reg clk   = 0;
reg rst_n = 0;

// diff_freq_serial_out signal
wire o_bit_tick;
wire o_done_tick;   // tick one clock when transmission is done
wire [15:0] o_serial_out;
wire o_serial_out0  = o_serial_out[0]; // idle state is low
wire o_serial_out1  = o_serial_out[1];
wire o_serial_out2  = o_serial_out[2];
wire o_serial_out3  = o_serial_out[3];
wire o_serial_out4  = o_serial_out[4];
wire o_serial_out5  = o_serial_out[5];
wire o_serial_out6  = o_serial_out[6];
wire o_serial_out7  = o_serial_out[7];
wire o_serial_out8  = o_serial_out[8];
wire o_serial_out9  = o_serial_out[9];
wire o_serial_out10 = o_serial_out[10];
wire o_serial_out11 = o_serial_out[11];
wire o_serial_out12 = o_serial_out[12];
wire o_serial_out13 = o_serial_out[13];
wire o_serial_out14 = o_serial_out[14];
wire o_serial_out15 = o_serial_out[15];

// UART signal
reg  tb_RxSerial;
wire tb_TxSerial;

// rx output port
wire       tb_rx_done;
wire       tb_tx_done;
wire [7:0] tb_received_data;

// internal signal
wire [3:0] sel_out_reg = serial_out_unit.sel_out_reg;

// system clock generator
always #(SYS_PERIOD_NS/2) clk = ~clk;

initial begin
  #0;
  clk   = 1'b0;
  rst_n = 1'b0;

  #5;
  rst_n = 1'b1;
  #(SYS_PERIOD_NS/2);
end

diff_freq_serial_out #(
  .DATA_BIT       (DATA_BIT),
  .PACK_NUM       (PACK_NUM),
  .LOW_PERIOD_CLK (LOW_PERIOD_CLK),
  .HIGH_PERIOD_CLK(HIGH_PERIOD_CLK)
) serial_out_unit (
  .clk            (clk),
  .rst_n          (rst_n),
  .i_data         (tb_received_data),
  .i_rx_done_tick (tb_rx_done),
  .o_serial_out   (o_serial_out), // idle state is low
  .o_bit_tick     (o_bit_tick),
  .o_done_tick    (o_done_tick)
);

UART #(
  .SYS_CLK        (SYS_CLK),
  .BAUD_RATE      (BAUD_RATE),
  .DATA_BITS      (UART_DATA_BIT),
  .STOP_BIT       (UART_STOP_BIT)
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

reg [7:0] slow_period = 8'h14;
reg [7:0] fast_period = 8'h5;
initial begin
  @(posedge rst_n);       // wait for finish reset
  
  OUT_32BIT_CHANNEL(0,  ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(1,  REPEAT,   slow_period, fast_period);
  OUT_32BIT_CHANNEL(2,  ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(3,  ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(4,  ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(5,  REPEAT,   slow_period, fast_period);
  OUT_32BIT_CHANNEL(6,  ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(7,  ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(8,  ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(9,  REPEAT,   slow_period, fast_period);
  OUT_32BIT_CHANNEL(10, ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(11, ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(12, ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(13, REPEAT,   slow_period, fast_period);
  OUT_32BIT_CHANNEL(14, ONE_SHOT, slow_period, fast_period);
  OUT_32BIT_CHANNEL(15, ONE_SHOT, slow_period, fast_period);
  @(posedge o_done_tick);
  
  //$finish;
end

//To check RX module
task UART_WRITE_BYTE;
  input [UART_DATA_BIT-1:0] WRITE_DATA;
  integer i;
  begin
    //Send Start Bit
    tb_RxSerial = 1'b0;
    #(UART_BIT_PERIOD);

    //Send Data Byte
    for (i = 0; i < UART_DATA_BIT; i = i + 1)
      begin
        tb_RxSerial = WRITE_DATA[i];
        #(UART_BIT_PERIOD);
      end

    //Send Stop Bit
    tb_RxSerial = 1'b1;
    #(UART_BIT_PERIOD);
  end
endtask

task OUT_32BIT_CHANNEL;
  input [3:0] channel;
  input reg mode;
  input [7:0] slow_period;
  input [7:0] fast_period;
  begin
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);

    UART_WRITE_BYTE(8'h00);
    UART_WRITE_BYTE(8'h00);
    UART_WRITE_BYTE(8'h00);
    UART_WRITE_BYTE(8'h00);
    
    UART_WRITE_BYTE({channel, 1'b0, mode, {2'h1}});
    UART_WRITE_BYTE(slow_period);
    UART_WRITE_BYTE(fast_period);
  end
endtask

endmodule
