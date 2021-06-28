
# Different Frequency Serial Output

## Features

* 16 x output channels.
* A channel serially outputs the data pattern and transmits the LSB of data first.
* Each data bit is set to high/low-frequency within the frequency pattern.
* User can adjust the high/low frequency by parameters.
* Each channel has 2 control bit.
  
  1. Enable bit: to enable the channel
  2. Mode bit: 0 is one-shot mode; 1 is repeat mode.
  3. Stop bit: to stop the output

## Keyword

* Output the LSB first.
* User can set the high/low frequency.
* 32-bit data pattern
* 32-bit frequency pattern
* 8-bit low frequency parameter
* 8-bit high frequency parameter
* Mode: Start, One-shot, Repeat
* Interface: UART 256000bps

# Bug List

1. Error occurs when frequency parameter is 0.

# TODO

1. Delete the respective freq_pattern and slow/fast period of each channel, and use the public freq_pattern and slow/fast period for all channels.
