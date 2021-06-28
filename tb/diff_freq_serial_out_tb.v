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
/*
 * PACK_DATA = out_pattern + freq_pattern + control_byte + lo_freq_byte + hi_freq_freq
 * pack_num = (32+32+8+8+8)/8 = 11
 */
localparam PACK_NUM      = (DATA_BIT/8)+1;
localparam FREQ_NUM      = (DATA_BIT/8)+2;
localparam OUTPUT_NUM    = 3;

localparam SYS_CLK       = 100_000_000;
localparam SYS_PERIOD_NS = 10;     // 1/100Mhz = 10ns
localparam IDLE_LOW      = 1'b0;
localparam IDLE_HIGH     = 1'b1;
localparam ONE_SHOT_MODE      = 1'b0;
localparam REPEAT_MODE        = 1'b1;
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
wire bit_tick_o;
wire done_tick_o;   // tick one clock when transmission is done
wire [OUTPUT_NUM-1:0] serial_out_o;
wire serial_out0_o  = serial_out_o[0]; // idle state is low
wire serial_out1_o  = serial_out_o[1];
wire serial_out2_o  = serial_out_o[2];
// wire serial_out3_o  = serial_out_o[3];
// wire serial_out4_o  = serial_out_o[4];
// wire serial_out5_o  = serial_out_o[5];
// wire serial_out6_o  = serial_out_o[6];
// wire serial_out7_o  = serial_out_o[7];
// wire serial_out8_o  = serial_out_o[8];
// wire serial_out9_o  = serial_out_o[9];
// wire serial_out10_o = serial_out_o[10];
// wire serial_out11_o = serial_out_o[11];
// wire serial_out12_o = serial_out_o[12];
// wire serial_out13_o = serial_out_o[13];
// wire serial_out14_o = serial_out_o[14];
// wire serial_out15_o = serial_out_o[15];

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
  .OUTPUT_NUM     (OUTPUT_NUM),
  .LOW_PERIOD_CLK (LOW_PERIOD_CLK),
  .HIGH_PERIOD_CLK(HIGH_PERIOD_CLK)
) serial_out_unit (
  .clk_i          (clk),
  .rst_ni         (rst_n),
  .data_i         (tb_received_data),
  .rx_done_tick_i (tb_rx_done),
  .serial_out_o   (serial_out_o), // idle state is low
  .bit_tick_o     (bit_tick_o),
  .done_tick_o    (done_tick_o)
);

UART #(
  .SYS_CLK       (SYS_CLK),
  .BAUD_RATE     (BAUD_RATE),
  .DATA_BITS     (UART_DATA_BIT),
  .STOP_BIT      (UART_STOP_BIT)
) DUT_uart (
  .clk_i         (clk),
  .rst_ni        (rst_n),
  //rx interface
  .rx_i          (tb_RxSerial),
  .rx_done_tick_o(tb_rx_done),
  .rx_data_o     (tb_received_data),
  //tx interface
  .tx_start_i    (tb_rx_done),
  .tx_data_i     (tb_received_data),
  .tx_o          (tb_TxSerial),
  .tx_done_tick_o(tb_tx_done)
);

reg [7:0] slow_period = 8'h14;
reg [7:0] fast_period = 8'h5;
initial begin
  @(posedge rst_n);       // wait for finish reset
  // update frequency
  UPDATE_FREQ(slow_period, fast_period);
  UPDATE_DATA(0,  ONE_SHOT_MODE);
  UPDATE_DATA(1,  ONE_SHOT_MODE);
  UPDATE_DATA(2,  ONE_SHOT_MODE);
  // OUT_32BIT_CHANNEL(0,  ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(1,  REPEAT,   slow_period, fast_period);
  // OUT_32BIT_CHANNEL(2,  ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(3,  ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(4,  ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(5,  REPEAT,   slow_period, fast_period);
  // OUT_32BIT_CHANNEL(6,  ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(7,  ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(8,  ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(9,  REPEAT,   slow_period, fast_period);
  // OUT_32BIT_CHANNEL(10, ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(11, ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(12, ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(13, REPEAT,   slow_period, fast_period);
  // OUT_32BIT_CHANNEL(14, ONE_SHOT, slow_period, fast_period);
  // OUT_32BIT_CHANNEL(15, ONE_SHOT, slow_period, fast_period);
  @(posedge done_tick_o);
  
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
    // data pattern
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    // freq pattern
    UART_WRITE_BYTE(8'h00);
    UART_WRITE_BYTE(8'h00);
    UART_WRITE_BYTE(8'h00);
    UART_WRITE_BYTE(8'h00);
    
    UART_WRITE_BYTE({channel, 1'b0, mode, {2'h1}});
    UART_WRITE_BYTE(slow_period);
    UART_WRITE_BYTE(fast_period);
  end
endtask

task UPDATE_DATA;
  input [3:0] channel;
  input reg mode;
  begin
    // comand
    UART_WRITE_BYTE(8'h0B);
    // data pattern
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    UART_WRITE_BYTE(8'h55);
    // control byte
    UART_WRITE_BYTE({channel, 1'b0, mode, {2'h1}});
  end
endtask

task UPDATE_FREQ;
  input [7:0] slow_period;
  input [7:0] fast_period;
  begin
    // command
    UART_WRITE_BYTE(8'h0A);
    // freq pattern
    UART_WRITE_BYTE(8'h11);
    UART_WRITE_BYTE(8'h22);
    UART_WRITE_BYTE(8'h33);
    UART_WRITE_BYTE(8'h44);

    UART_WRITE_BYTE(slow_period);
    UART_WRITE_BYTE(fast_period);
  end
endtask

endmodule
