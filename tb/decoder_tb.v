/* Filename : decoder_tb.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 *
 * Testbench of ap_decoder.
 */

`timescale 1ns / 100ps
`include "parameter.v"

module decoder_tb ();

// task parameter
localparam ONE_SHOT_MODE = 1'b0;
localparam REPEAT_MODE   = 1'b1;

// Signal declaration
reg clk;
reg rst_n;

// UART signal
reg  tb_RxSerial;
wire tb_TxSerial;

// rx output port
wire tb_rx_done;
wire tb_tx_done;
wire [`UART_DATA_BIT-1:0] tb_received_data;

// decoder signal
  wire [`DATA_BIT-1:0] output_pattern_o;
  wire [3:0]           sel_out_o;
  wire                 mode_o;
  wire                 stop_o;
  wire                 start_o;
  wire [`DATA_BIT-1:0] freq_pattern_o;
  wire [7:0]           slow_period_o;
  wire [7:0]           fast_period_o;
  wire [7:0]           cmd_o;
  wire                 done_tick_o;

// clock, T = 20ns
always #(`SYS_PERIOD_NS/2) clk = ~clk;

// reset the module
initial begin
  #0;
  clk   = 1'b0;
  rst_n = 1'b0;

  #5;
  rst_n = 1'b1;
  #(`SYS_PERIOD_NS/2);
end

decoder #(
  .DATA_BIT(`DATA_BIT),
  .PACK_NUM(`PACK_NUM),
  .FREQ_NUM(`FREQ_NUM)
) decoder_dut (
  .clk_i           (clk),
  .rst_ni          (rst_n),
  .data_i          (tb_received_data),
  .rx_done_tick_i  (tb_rx_done),
  .output_pattern_o(output_pattern_o),
  .freq_pattern_o  (freq_pattern_o),
  .sel_out_o       (sel_out_o),
  .mode_o          (mode_o),
  .start_o         (start_o),
  .stop_o          (stop_o),
  .slow_period_o   (slow_period_o),
  .fast_period_o   (fast_period_o),
  .cmd_o           (cmd_o),
  .done_tick_o     (done_tick_o)
);

UART #(
  .SYS_CLK  (`SYS_CLK),
  .BAUD_RATE(`BAUD_RATE),
  .DATA_BITS(`UART_DATA_BIT),
  .STOP_BIT (`UART_STOP_BIT)
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
//Starting test
initial begin
  @(posedge rst_n); // wait for finish reset
  // update frequency
  UPDATE_FREQ(slow_period, fast_period);
  UPDATE_DATA(0,  ONE_SHOT_MODE);

end

//To check RX module
task UART_WRITE_BYTE;
  input [`UART_DATA_BIT-1:0] WRITE_DATA;
  integer i;
  begin
    //Send Start Bit
    tb_RxSerial = 1'b0;
    #(`UART_BIT_PERIOD);

    //Send Data Byte
    for (i = 0; i < `UART_DATA_BIT; i = i + 1)
      begin
        tb_RxSerial = WRITE_DATA[i];
        #(`UART_BIT_PERIOD);
      end

    //Send Stop Bit
    tb_RxSerial = 1'b1;
    #(`UART_BIT_PERIOD);
  end
endtask

task UPDATE_DATA;
  input [3:0] channel;
  input reg mode;
  begin
    // command
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
