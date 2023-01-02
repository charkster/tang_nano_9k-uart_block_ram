#!/usr/bin/python

import time, random
from scarf_uart_slave import scarf_uart_slave

bram = scarf_uart_slave(slave_id=0x01, num_addr_bytes=2, baudrate=3000000, debug=False)
num_address_bits = 13

# fpga design has a byte wide block ram with 8bit address
list_w_rand = [random.randint(0,255) for _ in range(0,2**num_address_bits)]

bram.write_list(addr=0x00,write_byte_list=list_w_rand)
time.sleep(0.1)
read_list = bram.read_list(addr=0x00, num_bytes=2**num_address_bits)
print(list_w_rand)
print(read_list)
for index in range(0,2**num_address_bits):
	if (list_w_rand[index] != read_list[index]):
		print("At index {:d} write value {:d} != read value {:d}".format(index,list_w_rand[index],read_list[index]))
