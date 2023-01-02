
module uart_blockram_top (
  input  logic clk_100mhz, // MY CMOD A7 board has a custom 100MHz crystal
  input  logic button_0,
  input  logic uart_rx, // fpga rx
  output logic uart_tx  // fpga tx
);

  logic rst_n;
  logic rst_n_sync;

  assign rst_n = ~button_0;

  synchronizer u_synchronizer_rst_n_sync
    ( .clk      (clk_100mhz), // input
      .rst_n    (rst_n),      // input
      .data_in  (1'b1),       // input
      .data_out (rst_n_sync)  // output
     );

  uart_blockram_top 
  # ( .SYSCLOCK      ( 100.0 ), // MHz
      .BAUDRATE      ( 12.0  ), // Mbits
      .RAM_ADDR_BITS ( 8     ),
      .RAM_WIDTH     ( 8     ),
      .NUM_ADDR_BYTES( 1     ) )
  u_uart_blockram_top
    ( .clk        (clk_100mhz),
      .rst_n_sync,
      .uart_rx,
      .uart_tx,
      .rx_bsy     ()
     );

endmodule
