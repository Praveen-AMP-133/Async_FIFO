module async_fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 8
)(
  //--------------------input signals--------------------
  input                     clk_a,     //Write clock
  input                     rst_a,     //Read reset
  input [$clog2(DEPTH)-1:0] addr_a,    //Write address
  input [WIDTH-1:0]         data_in,   //Write data(Input data)
  input                     wr_en,     //Write enable

  input                     clk_b,     //Read clock
  input                     rst_b,     //Read reset
  input [$clog2(DEPTH)-1:0] addr_b,    //Read address
  input                     rd_en,     //Read enable
  //------------------ output signals------------------------
  output                    full,      //Full signal
  output                    empty,     //Empty signal
  output reg [WIDTH-1:0]    data_out   //Read data(output data)
);
  //--------------Local memory and registers-----------------
  reg [WIDTH-1:0] memory [0:DEPTH-1];  //Memory of the async fifo
  reg [$clog2(DEPTH):0]  wr_ptr;     //Write pointer 
  reg [$clog2(DEPTH):0]  rd_ptr;     //Read pointer
  
  wire [$clog2(DEPTH):0] gray_wr_ptr; //Gray write pointer
  wire [$clog2(DEPTH):0] gray_rd_ptr; //Gray read pointer
  
  reg [$clog2(DEPTH):0]  wr_sync1;    //Write synchronizer1
  reg [$clog2(DEPTH):0]  wr_sync2;    //Write synchronizer2
  reg [$clog2(DEPTH):0]  rd_sync1;    //Read synchronizer1
  reg [$clog2(DEPTH):0]  rd_sync2;    //read synchronizer2
  
  //write logic code
  always@(posedge clk_a or negedge rst_a) begin
    if(!rst_a) begin
      wr_ptr   <= 0;
      rd_sync1 <= 0;
      rd_sync2 <= 0;  
    end
    else begin
      rd_sync1 <= gray_rd_ptr;
      rd_sync2 <= rd_sync1 ;
      if(wr_en && !full) begin
        memory[addr_a] <= data_in;
        //memory[wr_ptr[$clog2(DEPTH)-1:0]] <= data_in;
        wr_ptr <= wr_ptr + 1;
      end
    end
   end
  
  //Read logic code 
  always@(posedge clk_b or negedge rst_b) begin
    if(!rst_b) begin
      rd_ptr   <= 0;
      wr_sync1 <= 0;
      wr_sync2 <= 0;
    end
    else begin
      wr_sync1 <= gray_wr_ptr;
      wr_sync2 <= wr_sync1;
      if (rd_en && !empty) begin
        data_out <= memory[addr_b];
        //data_out <= memory[rd_ptr[$clog2(DEPTH)-1:0]];
        rd_ptr <= rd_ptr + 1;
      end
    end
  end
  
  assign gray_wr_ptr = (wr_ptr >> 1) ^ wr_ptr ; //Gray write pointer logic
  assign gray_rd_ptr = (rd_ptr >> 1) ^ rd_ptr ; //Gray read pointer logic
  
  //assign full = (wr_ptr + 1 == rd_ptr);
  //assign empty = (wr_ptr == rd_ptr);
  assign full = (gray_wr_ptr == {~rd_sync2[$clog2(DEPTH)-1:$clog2(DEPTH)-2], rd_sync2[$clog2(DEPTH)-3:0]});                   //FIFO Full  logic
  assign empty = (gray_rd_ptr == wr_sync2);      //FIFO Empty logic
  
endmodule
