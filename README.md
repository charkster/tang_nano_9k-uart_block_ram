# tang_nano_9k-uart_block_ram
UART interface to a block ram in the Tang Nano 9k FPGA. No pin connections needed, just use the USB UART.

I have updated the RTL and Python to adapt to almost any FPGA board with a USB UART. I have tested this on Tang Nano, Tang Nano 9k and CMOD A7.
Each board has a unique oscillator frequency (clock input to the FPGA), unique USB UART max baudrate, unique button name and unique LED pins.
The top-level (in this case tang_nano_9k_top.sv) will contain all the unique names and will pass parameter details to the uart_blockram_top instance.
The python code needs to be updated to have the correct number of address bits, address bytes and baudrate. Max baudrate for Tang Nano is 1Mbit/s, Tang Nano 9k is 3Mbit/s and CMOD A7 is 12Mbit/s. Max block ram available is also different for each FPGA (which is why address bits and address bytes are configurable).

Dependancies:

pip3 install pyserial

Timing Diagram:
![picture](https://github.com/charkster/tang_nano_9k-uart_block_ram/blob/main/images/uart_header1.png)
<p>Up to 127 separate memories/register-maps supported (SLAVE_ID<6:0>). Number of address bytes is configurable.</p>
  
![picture](https://github.com/charkster/tang_nano_9k-uart_block_ram/blob/main/images/tang_nano_9k_pinout.png)
