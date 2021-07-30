/* Filename : freq_ctrl.v
 * Simulator: ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier : Quartus Prime - Standard Edition 20.1.1
 *
 * Serially output 32-bit data by different frequency
 */

module period_count #(
  parameter DATA_BIT = 32
) (
  input                 clk_i,
  input                 rst_ni,
  input  [DATA_BIT-1:0] freq_pattern_i,
  input  [7:0]          slow_period_i,
  input  [7:0]          fast_period_i,
  input  [11:0]         bit_count_0_i,
  input  [11:0]         bit_count_1_i,
  input  [11:0]         bit_count_2_i,
  input  [11:0]         bit_count_3_i,
  input  [11:0]         bit_count_4_i,
  input  [11:0]         bit_count_5_i,
  input  [11:0]         bit_count_6_i,
  input  [11:0]         bit_count_7_i,
  input  [11:0]         bit_count_8_i,
  input  [11:0]         bit_count_9_i,
  input  [11:0]         bit_count_10_i,
  input  [11:0]         bit_count_11_i,
  input  [11:0]         bit_count_12_i,
  input  [11:0]         bit_count_13_i,
  input  [11:0]         bit_count_14_i,
  input  [11:0]         bit_count_15_i,
  output [7:0]          period_0_o,
  output [7:0]          period_1_o,
  output [7:0]          period_2_o,
  output [7:0]          period_3_o,
  output [7:0]          period_4_o,
  output [7:0]          period_5_o,
  output [7:0]          period_6_o,
  output [7:0]          period_7_o,
  output [7:0]          period_8_o,
  output [7:0]          period_9_o,
  output [7:0]          period_10_o,
  output [7:0]          period_11_o,
  output [7:0]          period_12_o,
  output [7:0]          period_13_o,
  output [7:0]          period_14_o,
  output [7:0]          period_15_o
  );

  // reg [11:0] i;
  // reg [7:0] freq_buf[255:0];

  // always @(*) begin
  //   for (i = 0; i < 256; i = i + 1)
  //     freq_buf[i] = freq_pattern_i >> (i * 8);
  // end

  // wire [7:0] byte_index_0 = bit_count_0_i[10:3];
  // wire [7:0] byte_index_1 = bit_count_1_i[10:3];
  // wire [7:0] byte_index_2 = bit_count_2_i[10:3];
  // wire [7:0] byte_index_3 = bit_count_3_i[10:3];
  // wire [7:0] byte_index_4 = bit_count_4_i[10:3];
  // wire [7:0] byte_index_5 = bit_count_5_i[10:3];
  // wire [7:0] byte_index_6 = bit_count_6_i[10:3];
  // wire [7:0] byte_index_7 = bit_count_7_i[10:3];
  // wire [7:0] byte_index_8 = bit_count_8_i[10:3];
  // wire [7:0] byte_index_9 = bit_count_9_i[10:3];
  // wire [7:0] byte_index_10 = bit_count_10_i[10:3];
  // wire [7:0] byte_index_11 = bit_count_11_i[10:3];
  // wire [7:0] byte_index_12 = bit_count_12_i[10:3];
  // wire [7:0] byte_index_13 = bit_count_13_i[10:3];
  // wire [7:0] byte_index_14 = bit_count_14_i[10:3];
  // wire [7:0] byte_index_15 = bit_count_15_i[10:3];

  // wire [7:0] bit_index_0 = bit_count_0_i[2:0];
  // wire [7:0] bit_index_1 = bit_count_1_i[2:0];
  // wire [7:0] bit_index_2 = bit_count_2_i[2:0];
  // wire [7:0] bit_index_3 = bit_count_3_i[2:0];
  // wire [7:0] bit_index_4 = bit_count_4_i[2:0];
  // wire [7:0] bit_index_5 = bit_count_5_i[2:0];
  // wire [7:0] bit_index_6 = bit_count_6_i[2:0];
  // wire [7:0] bit_index_7 = bit_count_7_i[2:0];
  // wire [7:0] bit_index_8 = bit_count_8_i[2:0];
  // wire [7:0] bit_index_9 = bit_count_9_i[2:0];
  // wire [7:0] bit_index_10 = bit_count_10_i[2:0];
  // wire [7:0] bit_index_11 = bit_count_11_i[2:0];
  // wire [7:0] bit_index_12 = bit_count_12_i[2:0];
  // wire [7:0] bit_index_13 = bit_count_13_i[2:0];
  // wire [7:0] bit_index_14 = bit_count_14_i[2:0];
  // wire [7:0] bit_index_15 = bit_count_15_i[2:0];

  // wire tmp_0 = freq_buf[byte_index_0][bit_index_0];
  // wire tmp_1 = freq_buf[byte_index_1][bit_index_1];
  // wire tmp_2 = freq_buf[byte_index_2][bit_index_2];
  // wire tmp_3 = freq_buf[byte_index_3][bit_index_3];
  // wire tmp_4 = freq_buf[byte_index_4][bit_index_4];
  // wire tmp_5 = freq_buf[byte_index_5][bit_index_5];
  // wire tmp_6 = freq_buf[byte_index_6][bit_index_6];
  // wire tmp_7 = freq_buf[byte_index_7][bit_index_7];
  // wire tmp_8 = freq_buf[byte_index_8][bit_index_8];
  // wire tmp_9 = freq_buf[byte_index_9][bit_index_9];
  // wire tmp_10 =freq_buf[byte_index_10][bit_index_10];
  // wire tmp_11 =freq_buf[byte_index_11][bit_index_11];
  // wire tmp_12 =freq_buf[byte_index_12][bit_index_12];
  // wire tmp_13 =freq_buf[byte_index_13][bit_index_13];
  // wire tmp_14 =freq_buf[byte_index_14][bit_index_14];
  // wire tmp_15 =freq_buf[byte_index_15][bit_index_15];

  // assign period_0_o = tmp_0 ? fast_period_i-1 : slow_period_i-1;
  // assign period_1_o = tmp_1 ? fast_period_i-1 : slow_period_i-1;
  // assign period_2_o =  tmp_2 ? fast_period_i-1 : slow_period_i-1;
  // assign period_3_o =  tmp_3 ? fast_period_i-1 : slow_period_i-1;
  // assign period_4_o =  tmp_4 ? fast_period_i-1 : slow_period_i-1;
  // assign period_5_o =  tmp_5 ? fast_period_i-1 : slow_period_i-1;
  // assign period_6_o =  tmp_6 ? fast_period_i-1 : slow_period_i-1;
  // assign period_7_o =  tmp_7 ? fast_period_i-1 : slow_period_i-1;
  // assign period_8_o =  tmp_8 ? fast_period_i-1 : slow_period_i-1;
  // assign period_9_o =  tmp_9 ? fast_period_i-1 : slow_period_i-1;
  // assign period_10_o = tmp_10 ? fast_period_i-1 : slow_period_i-1;
  // assign period_11_o = tmp_11 ? fast_period_i-1 : slow_period_i-1;
  // assign period_12_o = tmp_12 ? fast_period_i-1 : slow_period_i-1;
  // assign period_13_o = tmp_13 ? fast_period_i-1 : slow_period_i-1;
  // assign period_14_o = tmp_14 ? fast_period_i-1 : slow_period_i-1;
  // assign period_15_o = tmp_15 ? fast_period_i-1 : slow_period_i-1;

  assign period_0_o = freq_pattern_i[bit_count_0_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_1_o = freq_pattern_i[bit_count_1_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_2_o = freq_pattern_i[bit_count_2_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_3_o = freq_pattern_i[bit_count_3_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_4_o = freq_pattern_i[bit_count_4_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_5_o = freq_pattern_i[bit_count_5_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_6_o = freq_pattern_i[bit_count_6_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_7_o = freq_pattern_i[bit_count_7_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_8_o = freq_pattern_i[bit_count_8_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_9_o = freq_pattern_i[bit_count_9_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_10_o = freq_pattern_i[bit_count_10_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_11_o = freq_pattern_i[bit_count_11_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_12_o = freq_pattern_i[bit_count_12_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_13_o = freq_pattern_i[bit_count_13_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_14_o = freq_pattern_i[bit_count_14_i] ? fast_period_i-1 : slow_period_i-1;
  assign period_15_o = freq_pattern_i[bit_count_15_i] ? fast_period_i-1 : slow_period_i-1;

endmodule
