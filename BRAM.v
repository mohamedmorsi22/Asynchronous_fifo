`timescale 1ns / 1ps



module BRAM
	#(
		parameter ADDR_WIDTH = 11, 
				  DATA_WIDTH = 8
	)
	(
		input  clk_r, clk_w,
		input  wr_en, 
		input [DATA_WIDTH-1:0] in_data,
		input [ADDR_WIDTH-1:0] wr_addr ,rd_addr, 
		output [DATA_WIDTH-1:0] out_data
	);
	
	reg[DATA_WIDTH-1:0] bram [2**ADDR_WIDTH-1:0];
	reg[ADDR_WIDTH-1:0] addr_b;
	
	always @(posedge clk_w) begin
		if(wr_en) 
		bram[wr_addr] <= in_data;
	end
	always @(posedge clk_r) begin
		addr_b <= rd_addr;	
	end
	assign out_data = bram[addr_b];
	
endmodule
