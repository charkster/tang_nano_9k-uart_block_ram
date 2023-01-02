import serial
import time

class scarf_uart_slave:
	
	# Constructor
	def __init__(self, slave_id=0x00, num_addr_bytes=1, port='/dev/ttyUSB1', baudrate=1000000, debug=False):
		self.slave_id         = slave_id
		self.num_addr_bytes   = num_addr_bytes
		self.serial           = serial.Serial(port=port, baudrate=baudrate, bytesize=8, parity='N', stopbits=1, timeout=0.01)
		self.read_buffer_max  = 60 - self.num_addr_bytes
		self.write_buffer_max = 60 - self.num_addr_bytes # cmod_a7 can be increased to 255
		self.debug            = debug
		
	def read_list(self, addr=0x00, num_bytes=1):
		if (self.debug == True):
			print("Called read_list")
		if (num_bytes == 0):
			print("Error: num_bytes must be larger than zero")
			return []
		else:
			byte0 = (self.slave_id + 0x80) & 0xFF # most significant bit is RNW
			remaining_bytes = num_bytes
			read_list = []
			address = addr - self.read_buffer_max # expecting to add self.read_buffer_max
			while (remaining_bytes > 0):
				if (remaining_bytes >= self.read_buffer_max):
					step_size = self.read_buffer_max
					remaining_bytes = remaining_bytes - self.read_buffer_max
				else:
					step_size = remaining_bytes
					remaining_bytes = 0
				address = address + self.read_buffer_max
				addr_byte_list = []
				for addr_byte_num in range(self.num_addr_bytes):
					addr_byte_list.insert(0, address >> (8*addr_byte_num) & 0xFF )
				self.serial.write(bytearray([byte0] + addr_byte_list + [step_size]))
				time.sleep(0.006)
				tmp_read_list = list(self.serial.read(step_size + self.num_addr_bytes + 1))
				read_list.extend(tmp_read_list[-step_size:])
			if (self.debug == True):
				address = addr
				for read_byte in read_list:
#					print("Address 0x{:02x} Read data 0x{:02x}".format(address,read_byte))
					print("Address {:d} Read data {:d}".format(address,read_byte))
					address += 1
			return read_list
	
	def write_list(self, addr=0x00, write_byte_list=[]):
		byte0 = self.slave_id & 0xFF
		remaining_bytes = len(write_byte_list)
		address = addr - self.write_buffer_max # expecting to add self.write_buffer_max
		while (remaining_bytes > 0):
			if (remaining_bytes >= self.write_buffer_max):
				step_size = self.write_buffer_max
				remaining_bytes = remaining_bytes - self.write_buffer_max
			else:
				step_size = remaining_bytes
				remaining_bytes = 0
			address = address + self.write_buffer_max
			addr_byte_list = []
			for addr_byte_num in range(self.num_addr_bytes):
				addr_byte_list.insert(0, address >> (8*addr_byte_num) & 0xFF )
			self.serial.write(bytearray([byte0] + addr_byte_list + write_byte_list[address-addr:address+step_size]))
			time.sleep(0.01)
		if (self.debug == True):
			print("Called write_bytes")
			address = addr
			for write_byte in write_byte_list:
#				print("Wrote address 0x{:02x} data 0x{:02x}".format(address,write_byte))
				print("Wrote address {:d} data {:d}".format(address,write_byte))
				address += 1
		return 1
		
	def read_id(self):
		byte0 = (self.slave_id + 0x80)
		self.serial.write(bytearray([byte0] + [0x00, 0x01]))
		time.sleep(0.01)
		slave_id_list = list(self.serial.read(2))
		slave_id = slave_id_list[0] - 0x80
		if (self.debug == True):
			print("Slave ID is 0x{:02x}".format(slave_id))
		return slave_id
