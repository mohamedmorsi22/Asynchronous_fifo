`timescale 1ns / 1ps



module asyn_fifo
	#(
		parameter DATA_WIDTH = 8,
				  DEPTH = 11  
	)
	(
	input  rst_n,
	input  clk_wr,clk_rd, //two clock domains
	input  wr,rd, 
	input  [DATA_WIDTH-1:0] in_data,        //input from clk_wr domain
	output [DATA_WIDTH-1:0] out_data,     //output to clk_rd domain
	output reg full,empty, 
	output reg [DEPTH-1:0] data_count_w,data_count_r //counts number of data left in fifo memory
    );
	 

	 initial begin
		full=0;
		empty=1;
	 end
	 
	
	// fifo 
	localparam fifo_DEPTH=2**DEPTH;

	//WRITE CLOCK DOMAIN
	 reg[DEPTH:0] wr_ptr = 0; //write pointer counter
	 reg[DEPTH:0] rd_ptr; //read pointer counter
	 reg[DEPTH:0] rd_grey; //grey counter for the read pointer synchronized to write clock
	 reg[3:0] i; //log_2(FIFO_DEPTH_WIDTH)
	 wire[DEPTH:0] wr_grey,wr_grey_next; //grey counter for write pointer
	 wire we;
	 	 
	 assign wr_grey = wr_ptr ^ (wr_ptr>>1); //binary to grey code conversion for current write pointer
	 assign wr_grey_next = (wr_ptr+1'b1)^((wr_ptr+1'b1)>>1);
	 assign we= wr && !full; 
	 
	 
	   //instantiation of dual port block ram
 BRAM #(.ADDR_WIDTH(DEPTH) , .DATA_WIDTH(DATA_WIDTH)) instance1
 (
     .clk_r(clk_rd),
     .clk_w(clk_wr),
     .wr_en(we),
     .in_data(in_data),
     .wr_addr(wr_ptr[DEPTH-1:0]), //write address
     .rd_addr(rd_ptr[DEPTH-1:0]), //read address ,addr_b is already buffered inside this module so we will use the "_d" ptr to advance the data(not "_q")
     .out_data(out_data)
 );

	 //register operation
	 always @(posedge clk_wr,negedge rst_n) begin
		if(!rst_n) begin
			wr_ptr <= 0;
			full <= 0;
		end
		else begin
			if(wr && !full) begin 
				wr_ptr <= wr_ptr +1'b1; 
				full <= wr_grey_next == {~rd_grey[DEPTH :DEPTH-1], rd_grey[DEPTH-2:0]}; //algorithm for full logic
			end
			else full <= wr_grey == {~rd_grey[DEPTH : DEPTH-1],rd_grey[DEPTH-2:0]}; 
			
			//grey code to binary converter
			for(i=0;i<=DEPTH;i=i+1) rd_ptr[i]=^(rd_grey>>i);  
			data_count_w <= (wr_ptr>=rd_ptr)? (wr_ptr-rd_ptr):(fifo_DEPTH-rd_ptr+wr_ptr);
		end							
	 end

	 
	  //READ CLOCK DOMAIN
	 reg[DEPTH:0] r_ptr_q=0; //read binary counter
	 reg[DEPTH:0] w_ptr_sync; //write pointer counter
	 reg[DEPTH:0] w_grey_sync; //grey counter for the write pointer
	 
	 wire[DEPTH:0] r_grey,r_grey_nxt; //grey counter for read pointer 
	 wire[DEPTH:0] r_ptr_d;
	 
	 
	 //binary to grey code conversion
	 assign r_grey= r_ptr_q^(r_ptr_q>>1);  
	 assign r_grey_nxt= (r_ptr_q+1'b1)^((r_ptr_q+1'b1)>>1); //next grey code
	 assign r_ptr_d= (rd && !empty)? r_ptr_q+1'b1:r_ptr_q;
	 
	 //register operation
	 always @(posedge clk_rd,negedge rst_n) begin
		if(!rst_n) begin
			r_ptr_q<=0;
			empty<=1;
		end
		else begin
			r_ptr_q<=r_ptr_d;
			if(rd && !empty) empty <= r_grey_nxt==w_grey_sync;//empty condition
			else empty <= r_grey==w_grey_sync; 
			
			for(i=0;i<=DEPTH;i=i+1) w_ptr_sync[i]=^(w_grey_sync>>i); //grey code to binary converter
			data_count_r = (wr_ptr>=rd_ptr)? (wr_ptr-rd_ptr):(fifo_DEPTH-rd_ptr+wr_ptr); 
		end
	 end
	 ////////////////////////////////////////////////////////////////////////
	 
	 
	 //CLOCK DOMAIN CROSSING
     reg[DEPTH:0] r_grey_sync_temp;
	 reg[DEPTH:0] w_grey_sync_temp;
	 
	 //2 flops synchronizer to reduced metastability in clock domain crossing from READ DOMAIN to WRITE DOMAIN
	 always @(posedge clk_wr) begin 
		r_grey_sync_temp<=r_grey; 
		rd_grey<=r_grey_sync_temp;
	 end
	 //2 flops synchronizer for reduced metastability in clock domain crossing from WRITE DOMAIN to READ DOMAIN
	 always @(posedge clk_rd) begin 
		w_grey_sync_temp<=wr_grey;
		w_grey_sync<=w_grey_sync_temp;
	 end
	 	 
	 

endmodule
