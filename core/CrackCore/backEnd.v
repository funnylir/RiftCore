/*
* @File name: backEnd
* @Author: Ruige Lee
* @Email: wut.ruigeli@gmail.com
* @Date:   2020-11-02 17:24:26
* @Last Modified by:   Ruige Lee
* @Last Modified time: 2020-11-04 19:43:38
*/



module backEnd (



	input [DECODE_INFO_DW-1:0] decode_microInstr_pop,
	output instrFifo_pop,
	input instrFifo_empty,

	// to pcGen
	output jalr_vaild_qout,
	output [63:0] jalr_pc_qout,
	input isMisPredict,

	input pcGen_ready,
	output takenBranch_qout,
	output takenBranch_vaild_qout,


	input CLK,
	input RSTn

);

	wire backend_Flush;




	wire  [(64*RNDEPTH*32)-1:0] regFileX_dnxt;
	wire [(64*RNDEPTH*32)-1:0] regFileX_qout;
	wire [ RNBIT*32 - 1 :0 ] rnAct_X_dnxt;
	wire [ RNBIT*32 - 1 :0 ] rnAct_X_qout;
	wire [32*RNDEPTH-1 : 0] rnBufU_rename_set;
	wire [32*RNDEPTH-1 : 0] rnBufU_commit_rst;
	wire [32*RNDEPTH-1 : 0] rnBufU_qout;
	wire [32*RNDEPTH-1 : 0] wbLog_writeb_set;
	wire [32*RNDEPTH-1 : 0] wbLog_commit_rst;
	wire [32*RNDEPTH-1 : 0] wbLog_qout;
	wire [ RNBIT*32 - 1 :0 ] archi_X_dnxt;
	wire [ RNBIT*32 - 1 :0 ] archi_X_qout;



	//dispat to issue
	wire adder_buffer_pop;
	wire [$clog2(`ADDER_ISSUE_DEPTH)-1:0] adder_buffer_pop_index;
	wire [`ADDER_ISSUE_DEPTH-1:0] adder_buffer_malloc;
	wire [`ADDER_ISSUE_INFO_DW*`ADDER_ISSUE_DEPTH-1 : 0] adder_issue_info
	wire logCmp_buffer_pop;
	wire [$clog2(`LOGCMP_ISSUE_DEPTH)-1:0] logCmp_buffer_pop_index;
	wire [`LOGCMP_ISSUE_DEPTH-1:0] logCmp_buffer_malloc;
	wire [`LOGCMP_ISSUE_INFO_DW*`LOGCMP_ISSUE_DEPTH-1 : 0] logCmp_issue_info;
	wire shift_buffer_pop;
	wire [$clog2(`SHIFT_ISSUE_DEPTH)-1:0] shift_buffer_pop_index;
	wire [`SHIFT_ISSUE_DEPTH-1:0] shift_buffer_malloc;
	wire [`SHIFT_ISSUE_INFO_DW*`SHIFT_ISSUE_DEPTH-1 : 0] shift_issue_info;
	wire jal_buffer_pop;
	wire [$clog2(`JAL_ISSUE_DEPTH)-1:0] jal_buffer_pop_index;
	wire [`JAL_ISSUE_DEPTH-1:0] jal_buffer_malloc;
	wire [`JAL_ISSUE_INFO_DW*`JAL_ISSUE_DEPTH-1 : 0] jal_issue_info;
	wire bru_fifo_pop;
	wire bru_fifo_empty;
	wire [`BRU_ISSUE_INFO_DW-1:0] bru_issue_info;
	wire csr_fifo_pop;
	wire csr_fifo_empty;
	wire [`CSR_ISSUE_INFO_DW-1:0] csr_issue_info;
	wire lu_buffer_pop;
	wire [$clog2(`ADDER_ISSUE_DEPTH)-1:0] lu_buffer_pop_index;
	wire [`LU_ISSUE_DEPTH-1:0] lu_buffer_malloc;
	wire [`LU_ISSUE_INFO_DW*`LU_ISSUE_DEPTH-1 : 0] lu_issue_info;
	wire su_fifo_pop;
	wire su_fifo_empty;
	wire [`SU_ISSUE_INFO_DW-1:0] su_issue_info;

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
	wire lu_exeparam_ready;
	wire lu_exeparam_vaild;
	wire [`LU_EXEPARAM_DW-1:0] lu_exeparam;
	wire su_exeparam_ready;
	wire su_exeparam_vaild;
	wire [`SU_EXEPARAM_DW-1:0] su_exeparam;



	//execute to writeback
	wire adder_writeback_vaild;
	wire [63:0] adder_res;
	wire [(5+RNBIT-1):0] adder_rd0;
	wire logCmp_writeback_vaild;
	wire [63:0] logCmp_res;
	wire [(5+RNBIT-1):0] logCmp_rd0;
	wire shift_writeback_vaild;
	wire [63:0] shift_res;
	wire [(5+RNBIT-1):0] shift_rd0;
	wire jal_writeback_vaild;
	wire [63:0] jal_res;
	wire [(5+RNBIT-1):0] jal_rd0;
	wire lsu_writeback_vaild;
	wire [(5+RNBIT-1):0] lsu_rd0;
	wire [63:0] lsu_res;
	wire csr_writeback_vaild;
	wire [(5+RNBIT-1):0] csr_rd0;
	wire [63:0] csr_res;

	wire csrILP_ready;
	wire suILP_ready;
//C3


	wire [`REORDER_INFO_DW-1:0] dispat_info;
	wire reOrder_fifo_push;
	wire reOrder_fifo_ful;
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
	wire su_fifo_push;
	wire su_fifo_full;
	wire [`SU_ISSUE_INFO_DW-1:0] su_dispat_info;
	wire lu_buffer_push;
	wire lu_buffer_full;
	wire [`LU_ISSUE_INFO_DW-1:0] lu_dispat_info;
	wire fence_fifo_push;
	wire fence_fifo_full;
	wire [`FENCE_ISSUE_INFO_DW-1:0] fence_dispat_info;
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
	.reOrder_fifo_full(reOrder_fifo_full)



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

	.su_fifo_push(su_fifo_push),
	.su_fifo_full(su_fifo_full),
	.su_dispat_info(su_dispat_info),
	.su_fifo_empty(su_fifo_empty),

	.lu_buffer_push(lu_buffer_push),
	.lu_buffer_full(lu_buffer_full),
	.lu_dispat_info(lu_dispat_info),
	.lu_buffer_malloc(lu_buffer_malloc),

	.csr_fifo_push(csr_fifo_push),
	.csr_fifo_full(csr_fifo_full),
	.csr_dispat_info(csr_dispat_info),
);



//T3
issue_buffer #( .DW(`ADDER_ISSUE_INFO_DW), .DP(ADDER_ISSUE_DEPTH))
adder_issue_buffer
(
	.dispat_info(adder_dispat_info),
	.issue_info_qout(adder_issue_info),

	.buffer_push(adder_buffer_push),
	.buffer_pop(adder_buffer_pop),	

	.buffer_full(adder_buffer_full),
	.buffer_malloc_qout(adder_buffer_malloc),
	.issue_pop_index(adder_buffer_pop_index),
	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
);

issue_buffer #(.DW(`LOGCMP_ISSUE_INFO_DW), .DP(LOGCMP_ISSUE_DEPTH))
logCmp_issue_buffer
(
	.dispat_info(logCmp_dispat_info),
	.issue_info_qout(logCmp_issue_info),

	.buffer_push(logCmp_buffer_push),
	.buffer_pop(logCmp_buffer_pop),	
	
	.buffer_full(logCmp_buffer_full),
	.buffer_malloc_qout(logCmp_buffer_malloc),
	.issue_pop_index(logCmp_buffer_pop_index),
	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
	
);



issue_buffer #(	.DW(`SHIFT_ISSUE_INFO_DW), .DP(SHIFT_ISSUE_DEPTH))
shift_issue_buffer
(
	.dispat_info(shift_dispat_info),
	.issue_info_qout(shift_issue_info),

	.buffer_push(shift_buffer_push),
	.buffer_pop(shift_buffer_pop),	
	
	.buffer_full(shift_buffer_full),
	.buffer_malloc_qout(shift_buffer_malloc),
	.issue_pop_index(shift_buffer_pop_index),
	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
);

issue_buffer #(.DW(`JAL_ISSUE_INFO_DW),.DP(JAL_ISSUE_DEPTH))
jal_issue_buffer
(
	.dispat_info(jal_dispat_info),
	.issue_info_qout(jal_issue_info),

	.buffer_push(jal_buffer_push),
	.buffer_pop(jal_buffer_pop),	
	
	.buffer_full(jal_buffer_full),
	.buffer_malloc_qout(jal_buffer_malloc),
	.issue_pop_index(jal_buffer_pop_index),
	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
	
);

issue_fifo #( .DW(`BRU_ISSUE_INFO_DW), .DP(BRU_ISSUE_DEPTH))
bru_issue_fifo (
	.issue_info_push(bru_dispat_info),
	.issue_info_pop(bru_issue_info),

	.issue_push(bru_fifo_push),
	.issue_pop(bru_fifo_pop),
	.fifo_full(bru_fifo_full),
	.fifo_empty(bru_fifo_empty),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);

issue_fifo #(.DW(`SU_ISSUE_INFO_DW), .DP(SU_ISSUE_DEPTH))
su_issue_fifo
(
	.issue_info_push(su_dispat_info),
	.issue_info_pop(su_issue_info),

	.issue_push(su_fifo_push),
	.issue_pop(su_fifo_pop),
	.fifo_full(su_fifo_full),
	.fifo_empty(su_fifo_empty),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
	
);

issue_buffer #(.DW(`LU_ISSUE_INFO_DW),.DP(LU_ISSUE_DEPTH))
lu_issue_buffer
(
	.dispat_info(lu_dispat_info),
	.issue_info_qout(lu_issue_info),

	.buffer_push(lu_buffer_push),
	.buffer_pop(lu_buffer_pop),	
	
	.buffer_full(lu_buffer_full),
	.buffer_malloc_qout(lu_buffer_malloc),
	.issue_pop_index(lu_buffer_pop_index),
	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
	
);

issue_fifo #(.DW(`CSR_ISSUE_INFO_DW),.DP(1))
csr_issue_fifo
(
	.issue_info_push(csr_dispat_info),
	.issue_info_pop(csr_issue_info),

	.issue_push(csr_buffer_push),
	.issue_pop(csr_fifo_pop),	
	
	.fifo_full(csr_buffer_full),
	.fifo_empty(csr_fifo_empty),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
	
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

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
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

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);

shift_issue i_shiftIssue(
	
	.shift_buffer_pop(shift_buffer_pop),
	.shift_buffer_pop_index(shift_buffer_pop_index),
	.shift_buffer_malloc(shift_buffer_malloc),
	.shift_issue_info(shift_issue_info),

	.shift_exeparam_vaild_qout(shift_exeparam_vaild),
	.shift_exeparam_qout(shift_exeparam),

	.regFileX_read(regFileX_read),
	.wbLog_qout(wbLog_qout),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);

jal_issue i_jalIssue(

	.jal_buffer_pop(jal_buffer_pop),
	.jal_buffer_pop_index(jal_buffer_pop_index),
	.jal_buffer_malloc(jal_buffer_malloc),
	.jal_issue_info(jal_issue_info),

	.jal_exeparam_vaild_qout(jal_exeparam_vaild),
	.jal_exeparam_qout(jal_exeparam),

	.regFileX_read(regFileX_read),
	.wbLog_qout(wbLog_qout),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);


bru_issue i_bruIssue(
	.bru_fifo_pop(bru_fifo_pop),
	.bru_fifo_empty(bru_fifo_empty),
	.bru_issue_info(bru_issue_info),

	.bru_exeparam_ready(bru_exeparam_ready),
	.bru_exeparam_vaild_qout(bru_exeparam_vaild),
	.bru_exeparam_qout(bru_exeparam),

	.regFileX_read(regFileX_read),
	.wbLog_qout(wbLog_qout),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);



csr_issue i_csrIssue(
	.csr_fifo_pop(csr_fifo_pop),
	.csr_fifo_empty(csr_fifo_empty),
	.csr_issue_info(csr_issue_info),

	.csr_exeparam_vaild_qout(csr_exeparam_vaild),
	.csr_exeparam_qout(csr_exeparam),

	.regFileX_read(regFileX_read),
	.wbLog_qout(wbLog_qout),

	//from commit
	.csrILP_ready(csrILP_ready),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);



lsu_issue i_lsuIssue(

	.lu_buffer_pop(lu_buffer_pop),
	.lu_buffer_pop_index(lu_buffer_pop_index),
	.lu_buffer_malloc(lu_buffer_malloc),
	.lu_issue_info(lu_issue_info),

	.lu_exeparam_ready(lu_exeparam_ready),
	.lu_exeparam_vaild_qout(lu_exeparam_vaild),
	.lu_exeparam_info(lu_exeparam),

	.su_fifo_pop(su_fifo_pop),
	.su_fifo_empty(su_fifo_empty),
	.su_issue_info(su_issue_info),
	
	.su_exeparam_ready(su_exeparam_ready),
	.su_exeparam_vaild_qout(su_exeparam_vaild),
	.su_exeparam(su_exeparam),

	.regFileX_read(regFileX_read),
	.wbLog_qout(wbLog_qout),

	.suILP_ready(suILP_ready),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);










//C5 and T5
adder i_adder(
	.adder_exeparam_vaild(adder_exeparam_vaild),
	.adder_exeparam(adder_exeparam),

	.adder_writeback_vaild(adder_writeback_vaild),
	.adder_res_qout(adder_res),
	.adder_rd0_qout(adder_rd0),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
);



logCmp i_logCmp(
	.logCmp_exeparam_vaild(logCmp_exeparam_vaild),
	.logCmp_exeparam(logCmp_exeparam),

	.logCmp_writeback_vaild(logCmp_writeback_vaild),
	.logCmp_res_qout(logCmp_res),
	.logCmp_rd0_qout(logCmp_rd0),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	

);



shift i_shift(
	.shift_exeparam_vaild(shift_exeparam_vaild),
	.shift_exeparam(shift_exeparam),

	.shift_writeback_vaild(shift_writeback_vaild),
	.shift_res_qout(shift_res),
	.shift_rd0_qout(shift_rd0),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))	
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

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);



bru i_bru(

	.bru_exeparam_ready(bru_exeparam_ready),
	.bru_exeparam_vaild(bru_exeparam_vaild),
	.bru_exeparam(bru_exeparam), 

	.pcGen_ready(pcGen_ready),
	.takenBranch_qout(takenBranch_qout),
	.takenBranch_vaild_qout(takenBranch_vaild_qout),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);



csr i_csr(
	.csr_exeparam_vaild(csr_exeparam_vaild),
	.csr_exeparam(csr_exeparam),

	.csr_writeback_vaild(csr_writeback_vaild),
	.csr_res_qout(csr_res),
	.csr_rd0_qout(csr_rd0),

	.CLK(CLK),
	.RSTn(RSTn),
	.beFlush(beFlush)
);

lsu i_lsu(
	.lu_exeparam_ready(lu_exeparam_ready),
	.lu_exeparam_vaild(lu_exeparam_vaild),
	.lu_exeparam(lu_exeparam),

	.su_exeparam_ready(su_exeparam_ready),
	.su_exeparam_vaild(su_exeparam_vaild),
	.su_exeparam(su_exeparam),
	
	.lsu_writeback_vaild(lsu_writeback_vaild),
	.lsu_res_qout(lsu_res),
	.lsu_rd0_qout(lsu_rd0),

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
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
	
	.lsu_writeback_vaild(lsu_writeback_vaild),
	.lsu_rd0(lsu_rd0),
	.lsu_res(lsu_res),

	.csr_writeback_vaild(csr_writeback_vaild),
	.csr_rd0(csr_rd0),
	.csr_res(csr_res)

);


wire csrILP_ready;
wire suILP_ready;

//C7 and T7
commit i_commit(
	.archi_X_dnxt(archi_X_dnxt),
	.archi_X_qout(archi_X_qout),

	.wbLog_commit_rst(wbLog_commit_rst),
	.wbLog_qout(wbLog_qout),

	.rnBufU_commit_rst(rnBufU_commit_rst),

	.reOrder_fifo_pop(reOrder_fifo_pop),
	.reOrder_fifo_empty(reOrder_fifo_empty),
	.commit_fifo(commit_fifo)

	.isMisPredict(isMisPredict),

	.isAsynExcept(1'b0),

	.csrILP_ready(csrILP_ready),
	.suILP_ready(suILP_ready)
);


















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

	.CLK(CLK),
	.RSTn(RSTn&(~beFlush))
);









phyRegister (

	.beFlush(beFlush)

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









