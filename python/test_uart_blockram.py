from pyftdi.ftdi import Ftdi
import pyftdi.serialext
import time,random

port = pyftdi.serialext.serial_for_url('ftdi://ftdi:2232:1/2', baudrate=3000000, bytesize=8, parity='N', stopbits=1, timeout=0.001)
port.flush()
time.sleep(0.0005)

# fpga design has a byte wide block ram with 13bit address
list_w_rand = [random.randint(0,255) for _ in range(0,2 ** 13)]
wrong_list  = [random.randint(0,255) for _ in range(0,2 ** 13)]

# load the block ram with random data 32 bytes in a single bus cycle
for block in range(0,256):
	write_list = [1, (block*32)>>8, (block*32) & 0xFF]    # first byte is write command and slave_id, next 2 bytes are address
	write_list.extend(list_w_rand[block*32:(block+1)*32]) # extend array with 32 bytes of write data
	port.write(bytearray(write_list))
	time.sleep(0.0005) # this delay is needed to ensure separation between the block writes

# read all values in the block ram using read requests of 32 bytes
for block in range(0,256):
	port.write(bytearray([129, (block*32)>>8, (block*32) & 0xFF, 32])) # request 32 bytes of read data
	time.sleep(0.0005) # this delay is needed to ensure that all data is received by the USB-UART before we read the USB-UART
	response = port.read(33)
	response_list = list(response)
	read_list = response_list[1:] # ignore first data which is read command and slave_id
	for index in range(0,32):
		if (read_list[index] != list_w_rand[block*32+index]):
#		if (read_list[index] != wrong_list[block*32+index]):
			print("miscompare at block {:d} and index {:d}".format(block,index))
	
