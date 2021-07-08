/* Filename  : mod_m_counter.v
 * Simulator : ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier  : Quartus Prime - Standard Edition 20.1.1
 *
 * This file use the counter to generate the baud rate of uart.
 *
 * The source code is modified from:
 * Pong P. Chu - FPGA Prototyping By Verilog Examples
 */

module mod_m_counter #(
  parameter MOD     = 65,         // mod-M
  parameter MOD_BIT = $clog2(MOD) // number of bits in counter
) (
  input  clk_i,
  input  rst_ni,
  output max_tick_o
);

  /* State declaration */
  reg  [MOD_BIT-1:0] count_reg;
  wire [MOD_BIT-1:0] count_next;

  /* Body */
  // Register
  always @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni)
      count_reg <= 0;
    else
      count_reg <= count_next;
  end

  /* Next-state logic */
  assign count_next = (count_reg == MOD - 1'b1) ? {MOD_BIT{1'b0}} : count_reg + 1'b1;
  
  /* Output */
  assign max_tick_o = (count_reg == MOD - 1'b1) ? 1'b1 : 1'b0;

endmodule