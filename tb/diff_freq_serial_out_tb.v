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
localparam PACK_NUM      = 3;

localparam SYS_PERIOD_NS = 100;     // 1/10Mhz = 100ns
localparam IDLE_LOW      = 1'b0;
localparam IDLE_HIGH     = 1'b1;
localparam ONE_SHOT      = 1'b0;
localparam REPEAT        = 1'b1;
localparam LOW_SPEED     = 1'b0;
localparam HIGH_SPEED    = 1'b1;

localparam SYS_CLK       = 10_000_000;
localparam BAUD_RATE     = 19200;
localparam CLK_PER_BIT   = 521;
localparam BIT_PERIOD    = 521_00;   // CLK_PER_BIT=1042, 1042*100ns = 104200.
localparam UART_DATA_BIT = 8;
localparam STOP_TICK     = 16;       // 1-bit stop (16 ticks/bit)
localparam CLK_DIV       = 33;       // SYS_CLK/(16*BAUD_RATE), i.e. 10M/(16*9600)
localparam DIV_BIT       = 6;        // bits for TICK_DIVIDE, it must be >= log2(TICK_DIVIDE)


// Signal declaration
reg clk   = 0;
reg rst_n = 0;

// diff_freq_serial_out signal
wire o_bit_tick;
wire o_serial_out; // idle state is low
wire o_done_tick;  // tick one clock when transmission is done

// UART signal
reg  tb_RxSerial;
wire tb_TxSerial;

// rx output port
wire       tb_rx_done;
wire       tb_tx_done;
wire [7:0] tb_received_data;


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
  .PACK_NUM    (PACK_NUM)
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

initial begin
  @(posedge rst_n);       // wait for finish reset
  UART_WRITE_BYTE(8'h55); // output pattern
  UART_WRITE_BYTE(8'h55); // frequency pattern
  UART_WRITE_BYTE(8'h01); // ch0, mode=one-shot, stop=1, start=1

  UART_WRITE_BYTE(8'hAA); // output pattern
  UART_WRITE_BYTE(8'h00); // frequency pattern
  // [7 | 6  5  4  3 |  2  |   1  |   0  ]
  // [x |   OUT_No.  | mode| STOP | START]
  UART_WRITE_BYTE(8'h01); // ch0, mode=one-shot, stop=1, start=1

  @(posedge o_done_tick);
  $finish;
end

//To check RX module
task UART_WRITE_BYTE;
  input [UART_DATA_BIT-1:0] WRITE_DATA;
  integer i;
  begin
    //Send Start Bit
    tb_RxSerial = 1'b0;
    #(BIT_PERIOD);

    //Send Data Byte
    for (i = 0; i < UART_DATA_BIT; i = i + 1)
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
