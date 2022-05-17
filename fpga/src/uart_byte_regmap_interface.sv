module uart_byte_regmap_interface
# ( parameter SLAVE_ID       = 7'd1,
    parameter NUM_ADDR_BYTES = 2   )
( input  logic                        clk,
  input  logic                        rst_n,
  input  logic [7:0]                  rx_data_out,
  input  logic                        rx_data_valid,
  input  logic                        rx_block_timeout,
  input  logic                        tx_bsy,
  output logic                        tx_trig,
  output logic [6:0]                  slave_id,
  output logic [NUM_ADDR_BYTES*8-1:0] address,
  output logic                        write_enable,
  output logic                        read_enable,
  output logic                        send_slave_id
);

  logic       rnw;
  logic [6:0] count;
  logic [5:0] num_read_bytes; // maximum 63
  logic       write_enable_hold; // provide 1 cycle of delay before incrementing address after write

  // count controls loading slave_id, rnw, and num_read_bytes. It also counts the read data to be transmitted 
  always@(posedge clk, negedge rst_n)
    if (~rst_n)                                                                                                 count <= 1'b0;
    else if (rx_block_timeout && (num_read_bytes == '0))                                                        count <= 1'b0;
    else if (rx_data_valid &&  (count <= (NUM_ADDR_BYTES+1)))                                                   count <= count + 1; // this applies to both reads and writes
    else if (rnw && tx_trig && (count >  (NUM_ADDR_BYTES+1)) && (count <= (NUM_ADDR_BYTES+1 + num_read_bytes))) count <= count + 1; // this applies to reads
    else if (rnw && (num_read_bytes != '0)                   && (count >  (NUM_ADDR_BYTES+1 + num_read_bytes))) count <= 1'b0;      // this applies to reads

  // slave_id allows each regmap to know when it is being accessed
  always@(posedge clk, negedge rst_n)
    if (~rst_n)                               slave_id <= 7'd0;
    else if ((count == 'd0) && rx_data_valid) slave_id <= rx_data_out[6:0];

  // rnw indicates a read or write cycle
  always@(posedge clk, negedge rst_n)
    if (~rst_n)                               rnw <= 0;
    else if ((count == 'd0) && rx_data_valid) rnw <= rx_data_out[7];

  // for simplicity the slave_id will shift thru the address
  // if the address overflows, that is on the user
  always@(posedge clk, negedge rst_n)
    if (~rst_n)                                                 address <= 'd0;
    else if ((count <= NUM_ADDR_BYTES)    && rx_data_valid)     address <= (address << 8) | rx_data_out;
    else if ((count >  NUM_ADDR_BYTES)    && write_enable_hold) address <= address + 1; // this only applies to writes
    else if ((count > (NUM_ADDR_BYTES+1)) && tx_trig)           address <= address + 1; // this only applies to reads

  always@(posedge clk, negedge rst_n)
    if (~rst_n)                                                     num_read_bytes <= 'd0;
    else if (count == '0)                                           num_read_bytes <= 'd0;
    else if (rnw && (count == (NUM_ADDR_BYTES+1)) && rx_data_valid) num_read_bytes <= rx_data_out[5:0];

  // the slave_id is sent to identify the origin of the read data
  assign send_slave_id = rnw && (count == NUM_ADDR_BYTES+1);

  always@(posedge clk, negedge rst_n)
    if (~rst_n)                                                                                              tx_trig <= 1'b0;
    else if (tx_trig)                                                                                        tx_trig <= 1'b0;
    else if (rnw && (!tx_bsy) && (count > NUM_ADDR_BYTES) && (count <= (NUM_ADDR_BYTES+1 + num_read_bytes))) tx_trig <= 1'b1;
    else                                                                                                     tx_trig <= 1'b0;

  always@(posedge clk, negedge rst_n)
    if (~rst_n)                  read_enable <= 1'b0;
    else if (rnw && (count > 0)) read_enable <= 1'b1;
    else                         read_enable <= 1'b0;

  always@(posedge clk, negedge rst_n)
    if (~rst_n)                                                 write_enable <= 1'b0;
    else if (!rnw && (count > NUM_ADDR_BYTES) && rx_data_valid) write_enable <= 1'b1;
    else                                                        write_enable <= 1'b0;

  always@(posedge clk, negedge rst_n)
    if (~rst_n) write_enable_hold <= 1'b0;
    else        write_enable_hold <= write_enable;

endmodule