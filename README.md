# tang_nano_9k-uart_block_ram
UART interface to a block ram in the Tang Nano 9k FPGA. No pin connections needed, just use the USB UART.

Dependancies:

pip3 install pyftdi

pip3 install pyserial==3.4

Timing Diagram:
![picture](https://github.com/charkster/tang_nano_9k-uart_block_ram/blob/main/images/uart_header1.png)
<p>Up to 127 separate memories/register-maps supported (SLAVE_ID<6:0>). Number of address bytes is configurable.</p>
  
![picture](https://github.com/charkster/usb_pd_monitor/blob/main/images/tang_nano_9k_pinout.gif)
