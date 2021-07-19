/* Filename : decoder_tb.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 *
 * Testbench of ap_decoder.
 */

`timescale 1ns / 100ps
`include "parameter.vh"
`include "../rtl/user_cmd.vh"

module decoder_tb ();

  // task parameter
  localparam ONE_SHOT_MODE = 2'b00;
  localparam CONTINUE_MODE = 2'b01;
  localparam REPEAT_MODE   = 2'b10;
  localparam DISABLE       = 1'b0;
  localparam ENABLE        = 1'b1;
  localparam IDLE_LOW      = 1'b0;
  localparam IDLE_HIGH     = 1'b1;

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
  wire [7:0]           amount_o;
  wire [`DATA_BIT-1:0] output_pattern_o;
  wire [7:0]           sel_out_o;
  wire [1:0]           mode_o;
  wire                 run_o;
  wire                 idle_o;
  wire                 enable_o;
  wire [`DATA_BIT-1:0] freq_pattern_o;
  wire [7:0]           slow_period_o;
  wire [7:0]           fast_period_o;
  wire [7:0]           repeat_o;
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
    .DATA_NUM(`DATA_NUM),
    .FREQ_NUM(`FREQ_NUM)
  ) decoder_dut (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .data_i          (tb_received_data),
    .rx_done_tick_i  (tb_rx_done),
    .amount_o        (amount_o),
    .output_pattern_o(output_pattern_o),
    .freq_pattern_o  (freq_pattern_o),
    .sel_out_o       (sel_out_o),
    .mode_o          (mode_o),
    .enable_o        (enable_o),
    .run_o           (run_o),
    .idle_o          (idle_o),
    .slow_period_o   (slow_period_o),
    .fast_period_o   (fast_period_o),
    .repeat_o        (repeat_o),
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

  reg [7:0] channel = 8'h5;
  reg [7:0] amount = 8'h4;
  reg [7:0] slow_period = 8'h14;
  reg [7:0] fast_period = 8'h5;
  reg [7:0] repeat_times = 8'h3;
  reg [31:0] freq_pattern = 32'h11223344;
  reg [31:0] data_pattern = 32'hBBCCDDEE;
  //Starting test
  initial begin
    @(posedge rst_n); // wait for finish reset
    // update frequency
    UPDATE_PERIOD(slow_period, fast_period);
    UPDATE_FREQ(amount, freq_pattern);
    UPDATE_DATA(channel, amount, data_pattern);
    UPDATE_REPEAT(channel, repeat_times);
    UPDATE_CTRL(channel, IDLE_HIGH, CONTINUE_MODE, ENABLE);
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
      for (i = 0; i < `UART_DATA_BIT; i = i + 1'b1)
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
    input [7:0] channel;
    input [7:0] amount;
    input [31:0] data;
    integer i;
    begin
      // command
      UART_WRITE_BYTE(`CMD_DATA);
      // channel index
      UART_WRITE_BYTE(channel);
      // data amount
      UART_WRITE_BYTE(amount);
      // data pattern
      for (i = 0; i < 4; i = i + 1'b1)
        begin
          UART_WRITE_BYTE(data[7:0]);
          data = data[31:8];
        end
    end
  endtask

  task UPDATE_FREQ;
    input [7:0] amount;
    input [31:0] freq;
    integer i;
    begin
      // command
      UART_WRITE_BYTE(`CMD_FREQ);
      // amount
      UART_WRITE_BYTE(amount);
      // freq pattern
      for (i = 0; i < 4; i = i + 1'b1)
        begin
          UART_WRITE_BYTE(freq[7:0]);
          freq = freq[31:8];
        end
    end
  endtask

  task UPDATE_PERIOD;
    input [7:0] slow_period;
    input [7:0] fast_period;
    begin
      // command
      UART_WRITE_BYTE(`CMD_PERIOD);
      UART_WRITE_BYTE(slow_period);
      UART_WRITE_BYTE(fast_period);
    end
  endtask

  task UPDATE_CTRL;
    input [7:0] channel;
    input idle;
    input [1:0] mode;
    input en;
    begin
      // command
      UART_WRITE_BYTE(`CMD_CTRL);
      UART_WRITE_BYTE(channel);
      UART_WRITE_BYTE({4'h0, idle, mode, en});
    end
  endtask

    task UPDATE_REPEAT;
    input [7:0] channel;
    input [7:0] repeat_times;
    begin
      // command
      UART_WRITE_BYTE(`CMD_REPEAT);
      UART_WRITE_BYTE(channel);
      UART_WRITE_BYTE(repeat_times);
    end
  endtask

endmodule
