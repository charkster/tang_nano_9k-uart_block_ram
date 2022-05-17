module block_ram
#( parameter RAM_WIDTH     = 8,
   parameter RAM_ADDR_BITS = 13 )
 ( input  logic                     clk,
   input  logic                     write_enable, 
   input  logic [RAM_ADDR_BITS-1:0] address,
   input  logic [RAM_WIDTH-1:0]     write_data,
   input  logic                     read_enable,
   output logic [RAM_WIDTH-1:0]     read_data
  );

   (* RAM_STYLE="BLOCK" *)
   logic [RAM_WIDTH-1:0] bram [(2**RAM_ADDR_BITS)-1:0];
   
//   initial
//     $readmemh("bram_initial_hex_values.data", bram, 0, (2**RAM_ADDR_BITS)-1);
   
   always@(posedge clk) begin
     if (write_enable) bram[address] <= write_data;
     if (read_enable)      read_data <= bram[address];
   end

endmodule