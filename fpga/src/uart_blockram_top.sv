
module uart_blockram_top (
  input  logic clk_27mhz,
  input  logic button_s1,
  input  logic uart_rx,
  output logic uart_tx,
  output logic led_1,
  output logic led_2,
  output logic led_3,
  output logic led_4,
  output logic led_5,
  output logic led_6
//  output logic rx_buffer,
//  output logic tx_buffer
);

  parameter RAM_ADDR_BITS  = 13;
  parameter RAM_WIDTH      = 8;
  parameter NUM_ADDR_BYTES = 2;

  logic       rst_n_sync;
  logic       read_enable;
  logic       write_enable;
  logic       block_ram_read_enable;
  logic       block_ram_write_enable;
  logic       rx_block_timeout;
  logic       rx_data_valid;
  logic [7:0] rx_data_out;
  logic       tx_trig;
  logic       tx_bsy;
  logic [7:0] send_data;
  logic [6:0] slave_id;
  logic       send_slave_id;
  logic [7:0] write_data;
  logic [7:0] read_data;
  logic [7:0] block_ram_read_data;

  logic        rx_bsy;
  logic [25:0] led_counter;

  logic [NUM_ADDR_BYTES*8-1:0] address;

//  assign rx_buffer  = uart_rx;
//  assign tx_buffer  = uart_tx;

  assign rst_n = button_s1;

  synchronizer u_synchronizer_rst_n_sync
    ( .clk      (clk_27mhz), // input
      .rst_n    (rst_n),     // input
      .data_in  (1'b1),      // input
      .data_out (rst_n_sync) // output
     );

  uart_tx 
  # ( .SYSCLOCK( 27.0 ), .BAUDRATE( 3.0 ) ) // MHz and Mbits
  u_uart_tx
    ( .clk       (clk_27mhz),  // input
      .rst_n     (rst_n_sync), // input
      .send_trig (tx_trig),    // input
      .send_data,              // input [7:0]
      .tx        (uart_tx),    // output
      .tx_bsy                  // output
     );

  uart_rx
  # ( .SYSCLOCK( 27.0 ), .BAUDRATE( 3.0 ) ) // MHz and Mbits
  u_uart_rx
    ( .clk           (clk_27mhz),        // input
      .rst_n         (rst_n_sync),       // input
      .rx            (uart_rx),          // input
      .rx_bsy,                           // output
      .block_timeout (rx_block_timeout), // output
      .data_valid    (rx_data_valid),    // output
      .data_out      (rx_data_out)       // output [7:0]
     );

  // this block can allow for multiple memories to be accessed,
  // but as the address width is fixed, smaller memories will need to
  // zero pad the upper address bits not used (this is done in python)
  uart_byte_regmap_interface
  # ( .NUM_ADDR_BYTES(NUM_ADDR_BYTES) )
  u_uart_byte_regmap_interface
    ( .clk          (clk_27mhz),  // input
      .rst_n        (rst_n_sync), // input
      .rx_data_out,               // input [7:0]
      .rx_data_valid,             // input
      .rx_block_timeout,          // input
      .tx_bsy,                    // input
      .tx_trig,                   // output
      .slave_id,                  // output [6:0]
      .address,                   // output [NUM_ADDR_BYTES*8-1:0]
      .write_enable,              // output
      .read_enable,               // output
      .send_slave_id              // output
     );

  // multiple memories could be used, all with different slave_ids
  assign block_ram_read_enable  = read_enable  && (slave_id == 7'd1);
  assign block_ram_write_enable = write_enable && (slave_id == 7'd1);

  block_ram
  # ( .RAM_WIDTH(8), .RAM_ADDR_BITS(RAM_ADDR_BITS) )
  u_block_ram
    ( .clk          (clk_27mhz),                  // input
      .write_enable (block_ram_write_enable),     // input 
      .address      (address[RAM_ADDR_BITS-1:0]), // input [RAM_ADDR_BITS-1:0]
      .write_data   (rx_data_out),                // input [7:0]
      .read_enable  (block_ram_read_enable),      // input
      .read_data    (block_ram_read_data)         // output [7:0]
     );

  // multiple memories could be used, all with different slave_ids
  assign read_data = block_ram_read_data & {8{(slave_id == 7'd1)}};

  // first uart byte of data to send is an read_enable and slave_id, then requested read data will be sent
  assign send_data = (send_slave_id) ? {read_enable,slave_id} : read_data;

  // led_counter will help drive the orange LEDs, which show that a USB UART access is in progress
  // 26bit counter overflows in (67,000,000)/(27,000,000) = 2.5 seconds, the 5 upper LEDs get about 0.5 seconds on-time each
  always_ff @(posedge clk_27mhz, negedge rst_n_sync)
    if (~rst_n_sync)                        led_counter <= 'd0;
    else if (rx_bsy && (led_counter == '0)) led_counter <= 'd1;
    else if (led_counter > 'd0)             led_counter <= led_counter + 1; // overflow expected

  always_comb begin
    led_1 = (led_counter == 0);
    led_2 = (led_counter < 'd10000000);
    led_3 = (led_counter < 'd20000000);
    led_4 = (led_counter < 'd30000000);
    led_5 = (led_counter < 'd40000000);
    led_6 = (led_counter < 'd50000000);
  end

endmodule
