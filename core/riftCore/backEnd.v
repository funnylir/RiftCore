/*
* @File name: backEnd
* @Author: Ruige Lee
* @Email: wut.ruigeli@gmail.com
* @Date:   2020-11-02 17:24:26
* @Last Modified by:   Ruige Lee
* @Last Modified time: 2020-11-12 10:42:03
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

module backEnd (



	input [`DECODE_INFO_DW-1:0] decode_microInstr_pop,
	output instrFifo_pop,
	input instrFifo_empty,

	// to pcGen
	output jalr_vaild_qout,
	output [63:0] jalr_pc_qout,
	input isMisPredict,

	output takenBranch_qout,
	output takenBranch_vaild_qout,

	output isFlush,

	input CLK,
	input RSTn

);

	wire flush;
	assign isFlush = flush;


	wire [63:0] commit_pc;

	wire  [(64*`RP*32)-1:0] regFileX_dnxt;
	wire [(64*`RP*32)-1:0] regFileX_qout;
	wire [ `RB*32 - 1 :0 ] rnAct_X_dnxt;
	wire [ `RB*32 - 1 :0 ] rnAct_X_qout;
	wire [32*`RP-1 : 0] rnBufU_rename_set;
	wire [32*`RP-1 : 0] rnBufU_commit_rst;
	wire [32*`RP-1 : 0] rnBufU_qout;
	wire [32*`RP-1 : 0] wbLog_writeb_set;
	wire [32*`RP-1 : 0] wbLog_commit_rst;
	wire [32*`RP-1 : 0] wbLog_qout;
	wire [ `RB*32 - 1 :0 ] archi_X_dnxt;
	wire [ `RB*32 - 1 :0 ] archi_X_qout;



	//dispat to issue
	wire adder_buffer_pop;
	wire [$clog2(`ADDER_ISSUE_INFO_DP)-1:0] adder_buffer_pop_index;
	wire [`ADDER_ISSUE_INFO_DP-1:0] adder_buffer_malloc;
	wire [`ADDER_ISSUE_INFO_DW*`ADDER_ISSUE_INFO_DP-1 : 0] adder_issue_info;

	wire logCmp_buffer_pop;
	wire [$clog2(`LOGCMP_ISSUE_INFO_DP)-1:0] logCmp_buffer_pop_index;
	wire [`LOGCMP_ISSUE_INFO_DP-1:0] logCmp_buffer_malloc;
	wire [`LOGCMP_ISSUE_INFO_DW*`LOGCMP_ISSUE_INFO_DP-1 : 0] logCmp_issue_info;

	wire shift_buffer_pop;
	wire [$clog2(`SHIFT_ISSUE_INFO_DP)-1:0] shift_buffer_pop_index;
	wire [`SHIFT_ISSUE_INFO_DP-1:0] shift_buffer_malloc;
	wire [`SHIFT_ISSUE_INFO_DW*`SHIFT_ISSUE_INFO_DP-1 : 0] shift_issue_info;

	wire jal_buffer_pop;
	wire [$clog2(`JAL_ISSUE_INFO_DP)-1:0] jal_buffer_pop_index;
	wire [`JAL_ISSUE_INFO_DP-1:0] jal_buffer_malloc;
	wire [`JAL_ISSUE_INFO_DW*`JAL_ISSUE_INFO_DP-1 : 0] jal_issue_info;

	wire bru_fifo_pop;
	wire bru_fifo_push;
	wire bru_fifo_empty;
	wire [`BRU_ISSUE_INFO_DW-1:0] bru_issue_info;

	wire csr_fifo_pop;
	wire csr_fifo_empty;
	wire [`CSR_ISSUE_INFO_DW-1:0] csr_issue_info;

	wire lsu_fifo_pop;
	wire lsu_fifo_empty;
	wire [`LSU_ISSUE_INFO_DW-1:0] lsu_issue_info;

	//issue to execute
	wire adder_exeparam_vaild;
	wire [`ADDER_EXEPARAM_DW-1:0] adder_exeparam;
	wire logCmp_exeparam_vaild;
	wire [`LOGCMP_EXEPARAM_DW-1:0] logCmp_exeparam;
	wire shift_exeparam_vaild;
	wire [`SHIFT_EXEPARAM_DW-1:0] shift_exeparam;
	wire jal_exeparam_vaild;
	wire [`JAL_EXEPARAM_DW-1:0] jal_exeparam;
	wire bru_exeparam_ready;
	wire bru_exeparam_vaild;
	wire [`BRU_EXEPARAM_DW-1:0] bru_exeparam;
	wire csr_exeparam_vaild;
	wire [`CSR_EXEPARAM_DW-1 :0] csr_exeparam;
	wire lsu_exeparam_ready;
	wire lsu_exeparam_vaild;
	wire [`LSU_EXEPARAM_DW-1:0] lsu_exeparam;



	//execute to writeback
	wire adder_writeback_vaild;
	wire [63:0] adder_res;
	wire [(5+`RB-1):0] adder_rd0;
	wire logCmp_writeback_vaild;
	wire [63:0] logCmp_res;
	wire [(5+`RB-1):0] logCmp_rd0;
	wire shift_writeback_vaild;
	wire [63:0] shift_res;
	wire [(5+`RB-1):0] shift_rd0;
	wire jal_writeback_vaild;
	wire [63:0] jal_res;
	wire [(5+`RB-1):0] jal_rd0;
	wire bru_writeback_vaild;
	wire [(5+`RB-1):0] bru_rd0;
	wire [63:0] bru_res;
	wire lsu_writeback_vaild;
	wire [(5+`RB-1):0] lsu_rd0;
	wire [63:0] lsu_res;
	wire csr_writeback_vaild;
	wire [(5+`RB-1):0] csr_rd0;
	wire [63:0] csr_res;

	wire suILP_ready;
//C3


	wire [`REORDER_INFO_DW-1:0] dispat_info;
	wire reOrder_fifo_push;
	wire reOrder_fifo_full;
	wire reOrder_fifo_empty;
	wire reOrder_fifo_pop;
	wire [`REORDER_INFO_DW-1:0] commit_info;


	wire adder_buffer_push;
	wire adder_buffer_full;
	wire [`ADDER_ISSUE_INFO_DW-1:0] adder_dispat_info;
	wire logCmp_buffer_push;
	wire logCmp_buffer_full;
	wire [`LOGCMP_ISSUE_INFO_DW-1:0] logCmp_dispat_info;
	wire shift_buffer_push;
	wire shift_buffer_full;
	wire [`SHIFT_ISSUE_INFO_DW-1:0] shift_dispat_info;
	wire jal_buffer_push;
	wire jal_buffer_full;
	wire [`JAL_ISSUE_INFO_DW-1:0] jal_dispat_info;
	wire bru_dispat_push;
	wire bru_fifo_full;
	wire [`BRU_ISSUE_INFO_DW-1:0] bru_dispat_info;
	wire lsu_fifo_push;
	wire lsu_fifo_full;
	wire [`LSU_ISSUE_INFO_DW-1:0] lsu_dispat_info;
	wire csr_fifo_push;
	wire csr_fifo_full;
	wire [`CSR_ISSUE_INFO_DW-1:0] csr_dispat_info;



dispatch i_dispatch(
	.rnAct_X_dnxt(rnAct_X_dnxt),
	.rnAct_X_qout(rnAct_X_qout),

	.rnBufU_rename_set(rnBufU_rename_set),
	.rnBufU_qout(rnBufU_qout),

	//from instr fifo
	.decode_microInstr_pop(decode_microInstr_pop),
	.instrFifo_pop(instrFifo_pop),
	.instrFifo_empty(instrFifo_empty),

	.dispat_info(dispat_info),
	.reOrder_fifo_push(reOrder_fifo_push),
	.reOrder_fifo_full(reOrder_fifo_full),



	//to issue
	.adder_buffer_push(adder_buffer_push),
	.adder_buffer_full(adder_buffer_full),
	.adder_dispat_info(adder_dispat_info),

	.logCmp_buffer_push(logCmp_buffer_push),
	.logCmp_buffer_full(logCmp_buffer_full),
	.logCmp_dispat_info(logCmp_dispat_info),

	.shift_buffer_push(shift_buffer_push),
	.shift_buffer_full(shift_buffer_full),
	.shift_dispat_info(shift_dispat_info),

	.jal_buffer_push(jal_buffer_push),
	.jal_buffer_full(jal_buffer_full),
	.jal_dispat_info(jal_dispat_info),

	.bru_fifo_push(bru_fifo_push),
	.bru_fifo_full(bru_fifo_full),
	.bru_dispat_info(bru_dispat_info),

	.lsu_fifo_push(lsu_fifo_push),
	.lsu_fifo_full(lsu_fifo_full),
	.lsu_dispat_info(lsu_dispat_info),
	.lsu_fifo_empty(lsu_fifo_empty),

	.csr_fifo_push(csr_fifo_push),
	.csr_fifo_full(csr_fifo_full),
	.csr_dispat_info(csr_dispat_info)
);



//T3
issue_buffer #( .DW(`ADDER_ISSUE_INFO_DW), .DP(`ADDER_ISSUE_INFO_DP))
adder_issue_buffer
(
	.dispat_info(adder_dispat_info),
	.issue_info_qout(adder_issue_info),

	.buffer_push(adder_buffer_push),
	.buffer_pop(adder_buffer_pop),	

	.buffer_full(adder_buffer_full),
	.buffer_malloc_qout(adder_buffer_malloc),
	.pop_index(adder_buffer_pop_index),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	
);

issue_buffer #(.DW(`LOGCMP_ISSUE_INFO_DW), .DP(`LOGCMP_ISSUE_INFO_DP))
logCmp_issue_buffer
(
	.dispat_info(logCmp_dispat_info),
	.issue_info_qout(logCmp_issue_info),

	.buffer_push(logCmp_buffer_push),
	.buffer_pop(logCmp_buffer_pop),	
	
	.buffer_full(logCmp_buffer_full),
	.buffer_malloc_qout(logCmp_buffer_malloc),
	.pop_index(logCmp_buffer_pop_index),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	
	
);



issue_buffer #(	.DW(`SHIFT_ISSUE_INFO_DW), .DP(`SHIFT_ISSUE_INFO_DP))
shift_issue_buffer
(
	.dispat_info(shift_dispat_info),
	.issue_info_qout(shift_issue_info),

	.buffer_push(shift_buffer_push),
	.buffer_pop(shift_buffer_pop),	
	
	.buffer_full(shift_buffer_full),
	.buffer_malloc_qout(shift_buffer_malloc),
	.pop_index(shift_buffer_pop_index),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	
);

issue_buffer #(.DW(`JAL_ISSUE_INFO_DW),.DP(`JAL_ISSUE_INFO_DP))
jal_issue_buffer
(
	.dispat_info(jal_dispat_info),
	.issue_info_qout(jal_issue_info),

	.buffer_push(jal_buffer_push),
	.buffer_pop(jal_buffer_pop),	
	
	.buffer_full(jal_buffer_full),
	.buffer_malloc_qout(jal_buffer_malloc),
	.pop_index(jal_buffer_pop_index),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	
	
);

issue_fifo #( .DW(`BRU_ISSUE_INFO_DW), .DP(`BRU_ISSUE_INFO_DP))
bru_issue_fifo (
	.issue_info_push(bru_dispat_info),
	.issue_info_pop(bru_issue_info),

	.issue_push(bru_fifo_push),
	.issue_pop(bru_fifo_pop),
	.fifo_full(bru_fifo_full),
	.fifo_empty(bru_fifo_empty),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);

issue_fifo #(.DW(`LSU_ISSUE_INFO_DW), .DP(`LSU_ISSUE_INFO_DP))
lsu_issue_fifo
(
	.issue_info_push(lsu_dispat_info),
	.issue_info_pop(lsu_issue_info),

	.issue_push(lsu_fifo_push),
	.issue_pop(lsu_fifo_pop),
	.fifo_full(lsu_fifo_full),
	.fifo_empty(lsu_fifo_empty),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
	
);

issue_fifo #(.DW(`CSR_ISSUE_INFO_DW),.DP(`CSR_ISSUE_INFO_DP))
csr_issue_fifo
(
	.issue_info_push(csr_dispat_info),
	.issue_info_pop(csr_issue_info),

	.issue_push(csr_fifo_push),
	.issue_pop(csr_fifo_pop),	
	
	.fifo_full(csr_fifo_full),
	.fifo_empty(csr_fifo_empty),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	
	
);



//C4 and T4

adder_issue i_adderIssue(
	.adder_buffer_pop(adder_buffer_pop),
	.adder_buffer_pop_index(adder_buffer_pop_index),
	.adder_buffer_malloc(adder_buffer_malloc),
	.adder_issue_info(adder_issue_info),

	.adder_exeparam_vaild_qout(adder_exeparam_vaild),
	.adder_exeparam_qout(adder_exeparam),

	.regFileX_read(regFileX_qout),
	.wbLog_qout(wbLog_qout),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);

logCmp_issue i_logCmpIssue(
	.logCmp_buffer_pop(logCmp_buffer_pop),
	.logCmp_buffer_pop_index(logCmp_buffer_pop_index),
	.logCmp_buffer_malloc(logCmp_buffer_malloc),
	.logCmp_issue_info(logCmp_issue_info),

	.logCmp_exeparam_vaild_qout(logCmp_exeparam_vaild),
	.logCmp_exeparam_qout(logCmp_exeparam),

	.regFileX_read(regFileX_qout),
	.wbLog_qout(wbLog_qout),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);

shift_issue i_shiftIssue(
	
	.shift_buffer_pop(shift_buffer_pop),
	.shift_buffer_pop_index(shift_buffer_pop_index),
	.shift_buffer_malloc(shift_buffer_malloc),
	.shift_issue_info(shift_issue_info),

	.shift_exeparam_vaild_qout(shift_exeparam_vaild),
	.shift_exeparam_qout(shift_exeparam),

	.regFileX_read(regFileX_qout),
	.wbLog_qout(wbLog_qout),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);

jal_issue i_jalIssue(

	.jal_buffer_pop(jal_buffer_pop),
	.jal_buffer_pop_index(jal_buffer_pop_index),
	.jal_buffer_malloc(jal_buffer_malloc),
	.jal_issue_info(jal_issue_info),

	.jal_exeparam_vaild_qout(jal_exeparam_vaild),
	.jal_exeparam_qout(jal_exeparam),

	.regFileX_read(regFileX_qout),
	.wbLog_qout(wbLog_qout),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);


bru_issue i_bruIssue(
	.bru_fifo_pop(bru_fifo_pop),
	.bru_fifo_empty(bru_fifo_empty),
	.bru_issue_info(bru_issue_info),

	.bru_exeparam_ready(bru_exeparam_ready),
	.bru_exeparam_vaild_qout(bru_exeparam_vaild),
	.bru_exeparam_qout(bru_exeparam),

	.regFileX_read(regFileX_qout),
	.wbLog_qout(wbLog_qout),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);



csr_issue i_csrIssue(
	.csr_fifo_pop(csr_fifo_pop),
	.csr_fifo_empty(csr_fifo_empty),
	.csr_issue_info(csr_issue_info),

	.csr_exeparam_vaild_qout(csr_exeparam_vaild),
	.csr_exeparam_qout(csr_exeparam),

	.regFileX_read(regFileX_qout),
	.wbLog_qout(wbLog_qout),

	//from commit
	.commit_pc(commit_pc),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);



lsu_issue i_lsuIssue(
	.lsu_fifo_pop(lsu_fifo_pop),
	.lsu_fifo_empty(lsu_fifo_empty),
	.lsu_issue_info(lsu_issue_info),

	.lsu_exeparam_ready(lsu_exeparam_ready),
	.lsu_exeparam_vaild_qout(lsu_exeparam_vaild),
	.lsu_exeparam_qout(lsu_exeparam),

	.regFileX_read(regFileX_qout),
	.wbLog_qout(wbLog_qout),

	.suILP_ready(suILP_ready),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);




//C5 and T5
adder i_adder(
	.adder_exeparam_vaild(adder_exeparam_vaild),
	.adder_exeparam(adder_exeparam),

	.adder_writeback_vaild(adder_writeback_vaild),
	.adder_res_qout(adder_res),
	.adder_rd0_qout(adder_rd0),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	
);



logCmp i_logCmp(
	.logCmp_exeparam_vaild(logCmp_exeparam_vaild),
	.logCmp_exeparam(logCmp_exeparam),

	.logCmp_writeback_vaild(logCmp_writeback_vaild),
	.logCmp_res_qout(logCmp_res),
	.logCmp_rd0_qout(logCmp_rd0),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	

);



shift i_shift(
	.shift_exeparam_vaild(shift_exeparam_vaild),
	.shift_exeparam(shift_exeparam),

	.shift_writeback_vaild(shift_writeback_vaild),
	.shift_res_qout(shift_res),
	.shift_rd0_qout(shift_rd0),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)	
);


jal i_jal(
	.jal_exeparam_vaild(jal_exeparam_vaild),
	.jal_exeparam(jal_exeparam), 

	// to branch predict
	.jalr_vaild_qout(jalr_vaild_qout),
	.jalr_pc_qout(jalr_pc_qout),

	// to writeback
	.jal_writeback_vaild(jal_writeback_vaild),
	.jal_res_qout(jal_res),
	.jal_rd0_qout(jal_rd0),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);



bru i_bru(

	.bru_exeparam_ready(bru_exeparam_ready),
	.bru_exeparam_vaild(bru_exeparam_vaild),
	.bru_exeparam(bru_exeparam), 

	.takenBranch_qout(takenBranch_qout),
	.takenBranch_vaild_qout(takenBranch_vaild_qout),

	.bru_writeback_vaild(bru_writeback_vaild),
	.bru_res_qout(bru_res),
	.bru_rd0_qout(bru_rd0),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);



csr i_csr(
	.csr_exeparam_vaild(csr_exeparam_vaild),
	.csr_exeparam(csr_exeparam),

	.csr_writeback_vaild(csr_writeback_vaild),
	.csr_res_qout(csr_res),
	.csr_rd0_qout(csr_rd0),

	.CLK(CLK),
	.RSTn(RSTn),
	.flush(flush)
);

lsu i_lsu(

	.lsu_exeparam_ready(lsu_exeparam_ready),
	.lsu_exeparam_vaild(lsu_exeparam_vaild),
	.lsu_exeparam(lsu_exeparam),
	
	.lsu_writeback_vaild(lsu_writeback_vaild),
	.lsu_res_qout(lsu_res),
	.lsu_rd0_qout(lsu_rd0),

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);







//C6
writeBack i_writeBack(
	.regFileX_qout(regFileX_qout),
	.regFileX_dnxt(regFileX_dnxt),

	.wbLog_writeb_set(wbLog_writeb_set),

	.adder_writeback_vaild(adder_writeback_vaild),
	.adder_res(adder_res),
	.adder_rd0(adder_rd0),

	.logCmp_writeback_vaild(logCmp_writeback_vaild),
	.logCmp_res(logCmp_res),
	.logCmp_rd0(logCmp_rd0),

	.shift_writeback_vaild(shift_writeback_vaild),
	.shift_res(shift_res),
	.shift_rd0(shift_rd0),

	.jal_writeback_vaild(jal_writeback_vaild),
	.jal_res(jal_res),
	.jal_rd0(jal_rd0),
	
	.bru_writeback_vaild(bru_writeback_vaild),
	.bru_res(bru_res),
	.bru_rd0(bru_rd0),

	.lsu_writeback_vaild(lsu_writeback_vaild),
	.lsu_rd0(lsu_rd0),
	.lsu_res(lsu_res),

	.csr_writeback_vaild(csr_writeback_vaild),
	.csr_rd0(csr_rd0),
	.csr_res(csr_res)

);

wire commit_abort;
//C7 and T7
commit i_commit(
	.archi_X_dnxt(archi_X_dnxt),
	.archi_X_qout(archi_X_qout),

	.wbLog_commit_rst(wbLog_commit_rst),
	.wbLog_qout(wbLog_qout),

	.rnBufU_commit_rst(rnBufU_commit_rst),

	.reOrder_fifo_pop(reOrder_fifo_pop),
	.reOrder_fifo_empty(reOrder_fifo_empty),
	.commit_fifo(commit_info),

	.isMisPredict(isMisPredict),
	.commit_abort(commit_abort),

	.isAsynExcept(1'b0),

	.commit_pc(commit_pc),
	.suILP_ready(suILP_ready)
);

assign flush = commit_abort;
// gen_dffr # (.DW(1)) beflush ( .dnxt(commit_abort), .qout(flush), .CLK(CLK), .RSTn(RSTn));















gen_fifo #(
	.DW(`REORDER_INFO_DW),
	.AW(4)
)
reOrder_fifo(

	.fifo_push(reOrder_fifo_push),
	.data_push(dispat_info),

	.fifo_empty(reOrder_fifo_empty), 
	.fifo_full(reOrder_fifo_full), 

	.data_pop(commit_info),
	.fifo_pop(reOrder_fifo_pop), 

	.flush(flush),
	.CLK(CLK),
	.RSTn(RSTn)
);









phyRegister i_phyRegister(

	.flush(flush),

	.regFileX_dnxt(regFileX_dnxt),
	.regFileX_qout(regFileX_qout), 

	.rnAct_X_dnxt(rnAct_X_dnxt),
	.rnAct_X_qout(rnAct_X_qout),

	.rnBufU_rename_set(rnBufU_rename_set),
	.rnBufU_commit_rst(rnBufU_commit_rst),
	.rnBufU_qout(rnBufU_qout),

	.wbLog_writeb_set(wbLog_writeb_set),
	.wbLog_commit_rst(wbLog_commit_rst),
	.wbLog_qout(wbLog_qout),

	.archi_X_dnxt(archi_X_dnxt),
	.archi_X_qout(archi_X_qout),

	.CLK(CLK),
	.RSTn(RSTn)
	
);




endmodule









