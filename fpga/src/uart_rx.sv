module uart_rx
# ( parameter SYSCLOCK = 27.0, // MHz
    parameter BAUDRATE = 1.0 ) // Mbits
( input  logic       clk,
  input  logic       rst_n,
  input  logic       rx,
  output logic       rx_bsy,        // high when rx is receiving data
  output logic       block_timeout, // pulses high when timeout is reached
  output logic       data_valid,    // pulses high when data_out is valid
  output logic [7:0] data_out       // byte frame data
);
    localparam SYNC_DELAY = 2;
    localparam CLKPERFRM = int'(SYSCLOCK/BAUDRATE*9.8)-SYNC_DELAY;
    // bit order is lsb-msb
    localparam TBITAT    = int'(SYSCLOCK/BAUDRATE*0.8)-SYNC_DELAY; // START BIT
    localparam BIT0AT    = int'(SYSCLOCK/BAUDRATE*1.5)-SYNC_DELAY;
    localparam BIT1AT    = int'(SYSCLOCK/BAUDRATE*2.5)-SYNC_DELAY;
    localparam BIT2AT    = int'(SYSCLOCK/BAUDRATE*3.5)-SYNC_DELAY;
    localparam BIT3AT    = int'(SYSCLOCK/BAUDRATE*4.5)-SYNC_DELAY;
    localparam BIT4AT    = int'(SYSCLOCK/BAUDRATE*5.5)-SYNC_DELAY;
    localparam BIT5AT    = int'(SYSCLOCK/BAUDRATE*6.5)-SYNC_DELAY;
    localparam BIT6AT    = int'(SYSCLOCK/BAUDRATE*7.5)-SYNC_DELAY;
    localparam BIT7AT    = int'(SYSCLOCK/BAUDRATE*8.5)-SYNC_DELAY;
    localparam PBITAT    = int'(SYSCLOCK/BAUDRATE*9.2)-SYNC_DELAY; // STOP bit
    localparam BLK_TIMEOUT = BIT1AT; // this depends on your USB UART chip 

    logic [$clog2(CLKPERFRM):0] rx_cnt;      // rx flow control

    logic rx_sync;
    logic rx_sync_hold;
    logic frame_begin;
    logic frame_end;
    logic start_valid;
    logic stop_valid;
    logic timeout;
    
    synchronizer u_synchronizer
    ( .clk      (clk),    // input
      .rst_n    (rst_n),  // input
      .data_in  (rx),     // input
      .data_out (rx_sync) // output
     );

    always@(posedge clk, negedge rst_n)
      if (~rst_n) rx_sync_hold <= 1'b0; // this needs to match synchronizer reset val
      else        rx_sync_hold <= rx_sync;
        
    assign frame_begin = (!rx_bsy) && (!rx_sync) && rx_sync_hold; // negative edge detect
    assign frame_end   =   rx_bsy  && (rx_cnt == CLKPERFRM);      // final count

    // START bit must be low  for 80% of the bit duration
    assign start_invalid = rx_bsy && (rx_cnt < TBITAT) &&   rx_sync;

    // STOP  bit must be high for 80% of the bit duration
    assign stop_invalid  = rx_bsy && (rx_cnt > PBITAT) && (!rx_sync);

    always@(posedge clk, negedge rst_n)
      if (~rst_n)                             rx_bsy <= 1'b0;
      else if (frame_begin)                   rx_bsy <= 1'b1;
      else if (start_invalid || stop_invalid) rx_bsy <= 1'b0;
      else if (frame_end)                     rx_bsy <= 1'b0;
    
    // count if frame is valid or until the timeout
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                                          rx_cnt <= 'd0;
      else if (frame_begin)                                rx_cnt <= 'd0;
      else if (start_invalid || stop_invalid || frame_end) rx_cnt <= 'd0;
      else if (!timeout)                                   rx_cnt <= rx_cnt + 1'b1; 
      else                                                 rx_cnt <= 'd0;

    // this just stops the rx_cnt, remains high until new data received
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                                    timeout <= 1'b0;
      else if (frame_begin)                          timeout <= 1'b0;
      else if ((!rx_bsy) && (rx_cnt == BLK_TIMEOUT)) timeout <= 1'b1;

    // this signals the end of block uart transfer, stays low after it pulses
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                                    block_timeout <= 1'b0;
      else if ((!rx_bsy) && (rx_cnt == BLK_TIMEOUT)) block_timeout <= 1'b1;
      else                                           block_timeout <= 1'b0;

    // this pulses upon completion of a clean frame
    always@(posedge clk, negedge rst_n)
      if (~rst_n)         data_valid <= 1'b0;
      else if (frame_end) data_valid <= 1'b1;
      else                data_valid <= 1'b0;

    // rx data control
    always@(posedge clk, negedge rst_n)
      if (~rst_n)                   data_out[7:0] <= 8'd0;
      else if (rx_bsy) case(rx_cnt)
                            BIT0AT: data_out[0] <= rx;
                            BIT1AT: data_out[1] <= rx;
                            BIT2AT: data_out[2] <= rx;
                            BIT3AT: data_out[3] <= rx;
                            BIT4AT: data_out[4] <= rx;
                            BIT5AT: data_out[5] <= rx;
                            BIT6AT: data_out[6] <= rx;
                            BIT7AT: data_out[7] <= rx;
                       endcase

endmodule
