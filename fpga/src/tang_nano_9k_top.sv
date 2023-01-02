module tang_nano_9k_top (
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
);

  logic        rst_n_sync;
  logic        rx_bsy;
  logic [25:0] led_counter;

  assign rst_n = button_s1;

  synchronizer u_synchronizer_rst_n_sync
    ( .clk      (clk_27mhz), // input
      .rst_n    (rst_n),     // input
      .data_in  (1'b1),      // input
      .data_out (rst_n_sync) // output
     );

  uart_blockram_top 
  # ( .SYSCLOCK      ( 27.0 ), // MHz
      .BAUDRATE      ( 3.0  ), // Mbits
      .RAM_ADDR_BITS ( 13   ),
      .RAM_WIDTH     ( 8    ),
      .NUM_ADDR_BYTES( 2    ) )
  u_uart_blockram_top
    ( .clk (clk_27mhz),
      .rst_n_sync,
      .uart_rx,
      .uart_tx,
      .rx_bsy
     );

  // led_counter will help drive the orange LEDs, which show that a USB UART access is in progress
  // 26bit counter overflows in (67,000,000)/(27,000,000) = 2.5 seconds
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