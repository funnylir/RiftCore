/*
* @File name: commit
* @Author: Ruige Lee
* @Email: wut.ruigeli@gmail.com
* @Date:   2020-09-11 15:41:55
* @Last Modified by:   Ruige Lee
* @Last Modified time: 2020-11-04 17:56:21
*/

module commit (

	//from phyRegister
	output [ RNBIT*32 - 1 :0 ] archi_X_dnxt,
	input  [ RNBIT*32 - 1 :0 ] archi_X_qout,

	output [32*RNDEPTH-1 : 0] wbLog_commit_rst,
	input [32*RNDEPTH-1 : 0] wbLog_qout,

	output [32*RNDEPTH-1 : 0] rnBufU_commit_rst,

	//from reOrder FIFO
	input [`REORDER_INFO_DW-1:0] commit_fifo,
	input reOrder_fifo_empty,
	output reOrder_fifo_pop,

	//from pc generate 
	//此处只需要向前握手进行pop，因为一定有数据
	input isMisPredict,


	//from Outsize
	input isAsynExcept,

	output csrILP_ready,
	output suILP_ready
);


	wire [63:0] commit_pc;
	wire [5+RNBIT-1:0] commit_rd0;
	wire isBranch;

	wire isSu;
	wire isCsr;

	assign csrILP_ready = isCsr;
	assign suILP_ready = isSu;

	assign {commit_pc, commit_rd0, isBranch, isSu, isCsr} = commit_fifo;

	wire commit_abort = (isBranch & isMisPredict) 
						| (isSynExcept)
						| (isAsynExcept);


	assign rnBufU_commit_rst = wbLog_commit_rst;

	assign reOrder_fifo_pop = ~reOrder_fifo_empty



generate
	for ( genvar regNum = 1; regNum < 32; regNum = regNum + 1 ) begin
		for ( genvar depth = 0 ; depth < RNDEPTH; depth = depth + 1 ) begin

			localparam SEL = regNum*4+depth;


			assign archi_X_dnxt[regNum] = ((wbLog_qout[SEL] == 1'b1) & (commit_rd0 == SEL) & (~commit_abort)) & (~reOrder_fifo_empty)
											?  depth
											: archi_X_qout[regNum];


			assign wbLog_commit_rst[archi_X_qout[regNum]] = (wbLog_qout[SEL] == 1'b1) & (commit_rd0 == SEL) & (~commit_abort) & (~reOrder_fifo_empty)
															? 1'b0
															: 1'b1;
		end
	end
endgenerate







endmodule


