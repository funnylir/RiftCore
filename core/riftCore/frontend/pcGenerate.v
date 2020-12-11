/*
* @File name: pcGenerate
* @Author: Ruige Lee
* @Email: wut.ruigeli@gmail.com
* @Date:   2020-10-13 16:56:39
* @Last Modified by:   Ruige Lee
* @Last Modified time: 2020-12-10 17:57:02
*/

/*
  Copyright (c) 2020 - 2020 Ruige Lee <wut.ruigeli@gmail.com>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/



`timescale 1 ns / 1 ps

`include "define.vh"

module pcGenerate (

	output [63:0] fetch_pc_qout,

	input isReset,

	//from jalr exe
	input jalr_vaild,
	input [63:0] jalr_pc,
	
	//from bru
	input bru_res_vaild,
	input bru_takenBranch,

	// from expection 	
	input [63:0] privileged_pc,
	input privileged_vaild,

	//to commit to flush
	output isMisPredict,

	//to fetch
	output [31:0] instr_readout,
	output is_rvc_instr,

	//hadnshake

	output isInstrReadOut,
	input instrFifo_full,




	//IFU inner_bus


	output [63:0] M_IFU_ARADDR,
	output M_IFU_ARVALID,

	output M_IFU_RREADY,
	input M_IFU_RVALID,
	input [63: 0] M_IFU_RDATA,





	input CLK,
	input RSTn

);

	wire [63:0] fetch_pc_dnxt;
	wire [63:0] fetch_pc_qout;


	// from branch predict
	wire isTakenBranch;
	wire isPredit;


	wire pcGen_fetch_vaild;


	wire isExpection = privileged_vaild;
	wire [63:0] expection_pc = privileged_pc;


	wire isJal;
	wire isJalr;
	wire isBranch;

	wire isCall;
	wire isReturn;
	wire [63:0] load_instr;
	wire [63:0] next_pc;
	wire [63:0] take_pc;
	wire ras_empty;

	// wire itcm_ready;


	wire [63+1:0] bht_data_pop;
	wire [63+1:0] bht_data_push = {
									isTakenBranch, 
									(({64{~isTakenBranch}} & take_pc) | ({64{isTakenBranch}} & next_pc))
									};

	wire bht_full;
	wire bht_pop = bru_res_vaild;
	wire bht_push = isPredit & ~bht_full & pcGen_fetch_vaild;

	assign isMisPredict = bru_res_vaild & ( bru_takenBranch ^ bht_data_pop[64]);
	wire [63:0] resolve_pc = bht_data_pop[63:0];


	// wire instrFifo_stall = instrFifo_full;
	wire jalr_stall = isJalr & ~jalr_vaild & ( ras_empty | ~isReturn );
	wire bht_stall = (bht_full & isPredit);

	assign pcGen_fetch_vaild = (~bht_stall & ~jalr_stall & ~instrFifo_full) | isMisPredict | isExpection;


	assign fetch_pc_dnxt = 	( {64{isReset}} & 64'h8000_0000)
							|
							({64{~isReset}} & (( {64{isExpection}} & expection_pc )
															| 
															( ( {64{~isExpection}} ) & 
																(	
																	( {64{isMisPredict}} & resolve_pc)
																	|
																	(
																		{64{~isMisPredict}} &
																		(
																			{64{~bht_stall}} &
																			(
																				{64{isTakenBranch}} & take_pc 
																				|
																				{64{~isTakenBranch}} & next_pc
																			)
																			| 
																			{64{bht_stall | jalr_stall}} &
																			(
																				fetch_pc_qout
																			)
																		)
																	)
																)
															)));






























	//branch predict
	wire isIJal = ~is_rvc_instr & (instr_readout[6:0] == 7'b1101111);			
	wire isCJal =	 instr_readout[1:0] == 2'b01 & instr_readout[15:13] == 3'b101;

	wire isIJalr = ~is_rvc_instr & (instr_readout[6:0] == 7'b1100111);
	wire isCJalr = (instr_readout[1:0] == 2'b10 & instr_readout[15:13] == 3'b100)
					&
					(
						(~instr_readout[12] & (instr_readout[6:2] == 0)) 
						| 
						( instr_readout[12] & (|instr_readout[11:7]) & (&(~instr_readout[6:2])))
					);

	wire isIBranch = ~is_rvc_instr & (instr_readout[6:0] == 7'b1100011);
	wire isCBranch =  instr_readout[1:0] == 2'b01 & instr_readout[15:14] == 2'b11;

	wire isICall = (isIJalr | isIJal) & ((instr_readout[11:7] == 5'd1) | instr_readout[11:7] == 5'd5);
	wire isCCall = isCJalr & instr_readout[12];

	wire isIReturn =  isIJalr & ((instr_readout[19:15] == 5'd1) | instr_readout[19:15] == 5'd5)
									& (instr_readout[19:15] != instr_readout[11:7]);

	wire isCReturn =  isCJalr & ~instr_readout[12]
							& ((instr_readout[11:7] == 5'd1) | (instr_readout[11:7] == 5'd5));




	wire [63:0] Iimm = 
		({64{isIJal}} & {{44{instr_readout[31]}},instr_readout[19:12],instr_readout[20],instr_readout[30:21],1'b0})
		|
		({64{isIJalr}} & {{52{instr_readout[31]}},instr_readout[31:20]})
		|
		({64{isIBranch}} & {{52{instr_readout[31]}},instr_readout[7],instr_readout[30:25],instr_readout[11:8],1'b0});

	wire [63:0] Cimm = 
		({64{isCJal}} & {{52{instr_readout[12]}}, instr_readout[12], instr_readout[8], instr_readout[10:9], instr_readout[6], instr_readout[7], instr_readout[2], instr_readout[11], instr_readout[5:3], 1'b0})
		|
		({64{isCJalr}} & 64'b0)
		|
		({64{isCBranch}} & {{55{instr_readout[12]}}, instr_readout[12], instr_readout[6:5], instr_readout[2], instr_readout[11:10], instr_readout[4:3], 1'b0});

	assign isJal = isIJal | isCJal; 
	assign isJalr = isIJalr | isCJalr;
	assign isBranch = isIBranch | isCBranch;
	assign isCall = isICall | isCCall;
	assign isReturn = isIReturn | isCReturn;

	wire [63:0] imm = is_rvc_instr ? Cimm : Iimm;




	assign isPredit = isBranch;

	//static predict
	assign isTakenBranch = ( (isBranch) & ( imm[63] == 1'b0) )
							| (isJal | isJalr); 


	wire [63:0] ras_addr_pop;
	wire [63:0] ras_addr_push;

	wire ras_push = isCall & ( isJal | isJalr ) & pcGen_fetch_vaild;
	wire ras_pop = isReturn & ( isJalr ) & ( !ras_empty ) & pcGen_fetch_vaild;

	assign next_pc = fetch_pc_qout + ( is_rvc_instr ? 64'd2 : 64'd4 );
	assign take_pc = ( {64{isJal | isBranch}} & (fetch_pc_qout + imm) )
						| ( {64{isJalr &  ras_pop}} & ras_addr_pop ) 
						| ( {64{isJalr & !ras_pop & jalr_vaild}} & jalr_pc  );
	assign ras_addr_push = next_pc;





ifu # ( .DW(64) ) i_ifu(

	.M_IFU_ARADDR(M_IFU_ARADDR),
	.M_IFU_ARVALID(M_IFU_ARVALID),

	.M_IFU_RREADY(M_IFU_RREADY),
	.M_IFU_RVALID(M_IFU_RVALID),
	.M_IFU_RDATA(M_IFU_RDATA),

	.fetch_pc_dnxt(fetch_pc_dnxt),
	// .itcm_ready(itcm_ready),
	.pcGen_fetch_vaild(pcGen_fetch_vaild),
	.instrFifo_full(instrFifo_full),
	.instr(load_instr),
	.isInstrReadOut(isInstrReadOut),
	.fetch_pc_qout(fetch_pc_qout),

	.CLK(CLK),
	.RSTn(RSTn)

);

wire [31:0] addr_align = fetch_pc_qout[1] ? load_instr[47:16] : load_instr[31:0];
assign is_rvc_instr = (addr_align[1:0] != 2'b11);
assign instr_readout = addr_align;






gen_fifo # (
	.DW(64+1),
	.AW(4)
) bht(

	.fifo_pop(bht_pop), 
	.fifo_push(bht_push),
	.data_push(bht_data_push),

	.fifo_empty(), 
	.fifo_full(bht_full), 
	.data_pop(bht_data_pop),

	.flush(isMisPredict|isExpection),
	.CLK(CLK),
	.RSTn(RSTn)
);



initial $warning("no feedback from commit, if flush, all flush");
gen_ringStack # (.DW(64), .AW(4)) ras(
	.stack_pop(ras_pop), .stack_push(ras_push),
	.stack_empty(ras_empty),
	.data_pop(ras_addr_pop), .data_push(ras_addr_push),

	.flush(isMisPredict|isExpection),
	.CLK(CLK),
	.RSTn(RSTn)
);




endmodule









