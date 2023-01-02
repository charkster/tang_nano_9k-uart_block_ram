module tang_nano_1k_top (
  input  logic clk_24mhz,
  input  logic button_a,
  input  logic uart_rx,
  output logic uart_tx
);

  logic rst_n;
  logic rst_n_sync;

  assign rst_n = button_a;

  synchronizer u_synchronizer_rst_n_sync
    ( .clk      (clk_24mhz), // input
      .rst_n    (rst_n),     // input
      .data_in  (1'b1),      // input
      .data_out (rst_n_sync) // output
     );

  uart_blockram_top 
  # ( .SYSCLOCK      ( 24.0 ), // MHz
      .BAUDRATE      ( 1.0  ), // Mbits
      .RAM_ADDR_BITS ( 8    ),
      .RAM_WIDTH     ( 8    ),
      .NUM_ADDR_BYTES( 1    ) )
  u_uart_blockram_top
    ( .clk        (clk_24mhz),
      .rst_n_sync,
      .uart_rx,
      .uart_tx,
      .rx_bsy     ()
     );

endmodule