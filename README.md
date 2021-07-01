# Different Frequency Serial Output

## Features

* interface: UART 256000bps
* 16 x output channels
* output the LSB first.
* idle low or idle high
* a data pattern whose bit amount can be set from 1 to 256 bits.
* a 32-bit frequency pattern to determine the corresponding data bit rate.
* an 8-bit parameter to set the bit amount of data pattern.
* an 8-bit parameter to set the slow bit rate.
* an 8-bit parameter to set the fast bit rate.
* Control byte
  1. Enable: to enable the channel.
  2. Mode: 0 is one-shot mode; 1 is repeat mode.
* an 8-bit parameter to set the repeat times in repeat mode.

## TODO

1. Modify the decoder
   * bit amount
   * repeat times
   * idle state
   * global enable signal
   * update slow period
   * update fast period
2. Modify control byte
   * rename start bit to enable bit
   * delete stop bit
   * change the position of mode bit
3. Add repeat times parameter
4. Modify data pattern depends on the bit-amount parameter
5. Global control
   * enable
   * idle state
6. serial_out module
   * add idle_state_i
   * add bit_amount_i
   * add repeat_time_i
7. UART timeout function

## Bug List

1. Error occurs when the frequency parameter is 0.
