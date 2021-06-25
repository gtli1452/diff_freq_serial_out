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
localparam DATA_BIT      = 32;
localparam PACK_NUM      = 9;          // PACK_NUM = 2*(DATA_BIT/8) + 1

reg clk;
reg rst_n;

reg  tb_RxSerial;
wire tb_TxSerial;

// rx output port
wire tb_rx_done;
wire [DATA_SIZE-1:0] tb_received_data;
wire tb_tx_done;

// decoder signal
  wire [DATA_BIT-1:0] output_pattern_o;
  wire [DATA_BIT-1:0] freq_pattern_o;
  wire [3:0]          sel_out_o;
  wire                mode_o;
  wire                stop_o;
  wire                start_o;
  wire                done_tick_o;

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
  .DATA_BIT(DATA_BIT),
  .PACK_NUM(PACK_NUM)
) decoder_dut (
  .clk_i            (clk),
  .rst_ni           (rst_n),
  .data_i           (tb_received_data),
  .rx_done_tick_i   (tb_rx_done),
  .output_pattern_o (output_pattern_o),
  .freq_pattern_o   (freq_pattern_o),
  .sel_out_o        (sel_out_o),
  .mode_o           (mode_o),
  .start_o          (start_o),
  .stop_o           (stop_o),
  .done_tick_o      (done_tick_o)
);

UART #(
  .SYS_CLK       (SYS_CLK),
  .BAUD_RATE     (BAUD_RATE),
  .DATA_BITS     (DATA_SIZE),
  .STOP_TICK     (STOP_TICK),
  .CLK_DIV       (CLK_DIV),
  .DIV_BIT       (DIV_BIT)
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

reg [DATA_SIZE-1:0] test_byte = 0;

//Starting test
initial begin
  //Check RX module
  repeat(19)
    begin
      test_byte = test_byte + 1;//$random;
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
