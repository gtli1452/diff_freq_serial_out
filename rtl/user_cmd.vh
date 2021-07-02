/* Filename   : user_cmd.v
 * Simulator  : ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier   : Quartus Prime - Standard Edition 20.1.1
 * Description: User command definition
 */

// system clock
`ifndef UART_COMMAND
`define UART_COMMAND
  // UART command
  `define CMD_FREQ        8'h0A
  `define CMD_PERIOD      8'h0B
  `define CMD_GLOBAL_CTRL 8'h0C
  `define CMD_CTRL        8'h0D
  `define CMD_REPEAT      8'h0E
  `define CMD_DATA        8'h0F
`endif