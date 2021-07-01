/* Filename    : parameter.v
 * Simulator   : ModelSim - Intel FPGA Edition vsim 2020.1
 * Complier    : Quartus Prime - Standard Edition 20.1.1
 * Description : Parameter for testbench and top entity
 */

// system clock
`ifndef GLOBAL_PARAMETER
  // System
  `define SYS_CLK             100_000_000  // 100 MHz
  `define SYS_PERIOD_NS       10           // 1/100MHz = 10ns
  // UART
  `define BAUD_RATE           256000
  `define CLK_PER_UART_BIT    (`SYS_CLK / `BAUD_RATE)
  `define UART_BIT_PERIOD     (`CLK_PER_UART_BIT * `SYS_PERIOD_NS)
  `define UART_DATA_BIT       8
  `define UART_STOP_BIT       1
  // diff_freq_serial
  `define DATA_BIT            32
  `define PACK_NUM            ((`DATA_BIT/8)+1) // output_pattern (32-bit) + control_byte
  `define FREQ_NUM            ((`DATA_BIT/8)+2) // freq_pattern (32-bit) + hi/lo_freq_byte
  `define OUTPUT_NUM          16
  `define DEFAULT_SLOW_PERIOD 20  // 100MHz/20 = 5MHz
  `define DEFAULT_FAST_PERIOD 5   // 100MHz/5  = 20MHz
`endif