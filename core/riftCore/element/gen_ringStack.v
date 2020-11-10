/*
* @File name: gen_ringStack
* @Author: Ruige Lee
* @Email: wut.ruigeli@gmail.com
* @Date:   2020-10-30 17:55:22
* @Last Modified by:   Ruige Lee
* @Last Modified time: 2020-11-10 10:52:51
*/


`timescale 1 ns / 1 ps

module gen_ringStack # (
	parameter DW = 64,
	parameter AW = 3
) (

	input stack_pop, 
	input stack_push,

	output stack_empty,

	output [DW-1:0] data_pop,
	input [DW-1:0] data_push,

	input flush,
	input CLK,
	input RSTn
);

	localparam DP = 2**AW;

	wire stack_full;
	wire [AW+1-1:0] btm_addr_dnxt, btm_addr_qout;
	wire [AW+1-1:0] top_addr_dnxt, top_addr_qout;
	wire [DP*DW-1:0] stack_data_dnxt, stack_data_qout;

	gen_dffr #(.DW(AW+1)) btm_addr   (.dnxt(btm_addr_dnxt), .qout(btm_addr_qout), .CLK(CLK), .RSTn(RSTn));
	gen_dffr #(.DW(AW+1)) top_addr  (.dnxt(top_addr_dnxt), .qout(top_addr_qout), .CLK(CLK), .RSTn(RSTn));

	assign stack_empty = (btm_addr_qout == top_addr_qout);
	assign stack_full = (btm_addr_qout[AW-1:0] == top_addr_qout[AW-1:0]) & (btm_addr_qout[AW] != top_addr_qout[AW]);

	wire [AW-1:0] read_addr = top_addr_qout[AW-1:0] - 'd1;
	wire [AW-1:0] write_addr = top_addr_qout[AW-1:0];


generate
	for ( genvar i = 0; i < DP; i = i + 1 ) begin
		assign stack_data_dnxt[DW*i+:DW] = (stack_push & (write_addr == i) ) ? data_push : stack_data_qout[DW*i+:DW];

		gen_dffr #(.DW(DW)) stack_data  (.dnxt(stack_data_dnxt[DW*i+:DW]), .qout(stack_data_qout[DW*i+:DW]), .CLK(CLK), .RSTn(RSTn));

	end
endgenerate




	assign data_pop = stack_data_qout[DW*read_addr+:DW];

	assign btm_addr_dnxt = flush ? {(AW+1){1'b0}} : ( (stack_push & stack_full) ? btm_addr_qout + 'd1 : btm_addr_qout );
	assign top_addr_dnxt = flush ? {(AW+1){1'b0}} : (({64{stack_push}} & (top_addr_qout + 'd1 ))
										|
										({64{stack_pop & ~stack_empty}} & (top_addr_qout - 'd1)) 
										|
										({64{~stack_push | ~(stack_pop & ~stack_empty)}} & top_addr_qout));

endmodule 



