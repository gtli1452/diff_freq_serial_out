/* Filename : ram_tb.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 *
 * Testbench of diff_freq_serial_out.
 */

`timescale 1ns / 100ps
`include "parameter.vh"
`include "../rtl/user_cmd.vh"

module ram_tb ();

  // Signal declaration
  reg clk   = 0;
  reg rst_n = 0;

  // system clock generator
  always #(`SYS_PERIOD_NS/2) clk = ~clk;

  initial begin
    #0;
    clk   = 1'b0;
    rst_n = 1'b0;

    #5;
    rst_n = 1'b1;
    #(`SYS_PERIOD_NS/2);
  end

  /* RAM */
  reg        wr_a;
  reg  [7:0] addr_a;
  reg  [7:0] data_a_i;
  wire [7:0] data_a_o;
  reg        wr_b;
  reg  [7:0] addr_b;
  reg  [7:0] data_b_i;
  wire [7:0] data_b_o;

  /*
   * Delay N clock cycles
   */
  `define N 3
  reg [`N-1:0] r;
  reg d;
  wire q = r[`N-1];

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n)
      begin
        addr_a   <= 0;
        data_a_i <= 0;
        wr_a     <= 0;
        addr_b   <= 0;
        data_b_i <= 0;
        wr_b     <= 0;
      end
    else
      begin
      end
  end

  pattern_ram ram_a (
    .address(addr_a),
    .clock  (clk),
    .data   (data_a_i),
    .wren   (wr_a),
    .q      (data_a_o)
  );

  pattern_ram ram_b (
    .address(addr_b),
    .clock  (clk),
    .data   (data_b_i),
    .wren   (wr_b),
    .q      (data_b_o)
  );

  integer i;
  initial begin
    @(posedge rst_n); // wait for finish reset

    for (i = 0; i < 5; i = i + 1) begin
      @(posedge clk) begin
        wr_a = 1'b1;
        addr_a = i;
        data_a_i = i;

        wr_b = 1'b1;
        addr_b = i;
        data_b_i = i;
      end

      @(negedge clk)
        wr_a = 1'b0;
    end

    wr_a = 1'b0;
    addr_a = 0;
    data_a_i = 0;

    wr_b = 1'b0;
    addr_b = 0;
    data_b_i = 0;

    for (i = 0; i < 5; i = i + 1) begin
      @(posedge clk) begin
        addr_a = i;
        addr_b = i;
      end
    end

    @(posedge clk)
      d = 1'b1;

  end

endmodule
