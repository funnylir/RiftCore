/*
* @File name: csr
* @Author: Ruige Lee
* @Email: wut.ruigeli@gmail.com
* @Date:   2020-10-30 14:30:32
* @Last Modified by:   Ruige Lee
* @Last Modified time: 2020-11-04 15:32:44
*/



module csr (

	input csr_exeparam_vaild,
	input [`CSR_EXEPARAM_DW-1 :0] csr_exeparam,

	output csr_writeback_vaild,
	output [63:0] csr_res_qout,
	output [(5+RNBIT-1):0] csr_rd0_qout,

	input CLK,
	input RSTn
	
);


	wire rv64csr_rw;
	wire rv64csr_rs;
	wire rv64csr_rc;

	wire [(5+RNBIT)-1:0] csr_rd0_dnxt;
	wire [63:0] op;
	wire [11:0] addr;

	assign { 
			rv64csr_rw,
			rv64csr_rs,
			rv64csr_rc,

			csr_rd0_dnxt,
			op,
			addr

			} = csr_exeparam;


wire dontRead = (csr_rd0_dnxt == 'd0) & rv64csr_rw;
wire dontWrite = (op == 'd0) & ( rv64csr_rs | rv64csr_rc );



initial $warning("暂时不产生异常");

wire illagle_op = 1'b0;

wire [63:0] csr_res_dnxt = (~dontRead) &
						(
							({64{addr == 12'hF11}} & {32'b0,mvendorid})
							|
							({64{addr == 12'hF12}} & marchid)
							|
							({64{addr == 12'hF13}} & mimpid)
							|
							({64{addr == 12'hF14}} & mhartid)
							|
							({64{addr == 12'h300}} & mstatus_qout)
							|
							({64{addr == 12'h301}} & misa)
							|
							({64{addr == 12'h304}} & mie_qout)
							|
							({64{addr == 12'h305}} & mtvec_qout)
							|
							({64{addr == 12'h341}} & mepc_qout)
							|
							({64{addr == 12'h342}} & mcause_qout)
							|
							({64{addr == 12'h343}} & mtval_qout)
							|
							({64{addr == 12'h344}} & mip_qout)
						);



assign mstatus_dnxt = {64{~dontWrite}} & {64{addr == 12'h300}} &
						(
							({64{rv64csr_rw}} & op)
							|
							({64{rv64csr_rs}} | op)
							|
							({64{rv64csr_rc}} & (~op))
						);

assign mie_dnxt = {64{~dontWrite}} & {64{addr == 12'h304}} &
						(
							({64{rv64csr_rw}} & op)
							|
							({64{rv64csr_rs}} | op)
							|
							({64{rv64csr_rc}} & (~op))
						);

assign mtvec_dnxt = {64{~dontWrite}} & {64{addr == 12'h305}} &
						(
							({64{rv64csr_rw}} & op)
							|
							({64{rv64csr_rs}} | op)
							|
							({64{rv64csr_rc}} & (~op))
						);

assign mepc_dnxt = {64{~dontWrite}} & {64{addr == 12'h341}} &
						(
							({64{rv64csr_rw}} & op)
							|
							({64{rv64csr_rs}} | op)
							|
							({64{rv64csr_rc}} & (~op))
						);

assign mcause_dnxt = {64{~dontWrite}} & {64{addr == 12'h342}} &
						(
							({64{rv64csr_rw}} & op)
							|
							({64{rv64csr_rs}} | op)
							|
							({64{rv64csr_rc}} & (~op))
						);

assign mtval_dnxt = {64{~dontWrite}} & {64{addr == 12'h343}} &
						(
							({64{rv64csr_rw}} & op)
							|
							({64{rv64csr_rs}} | op)
							|
							({64{rv64csr_rc}} & (~op))
						);

assign mip_dnxt = {64{~dontWrite}} & {64{addr == 12'h344}} &
						(
							({64{rv64csr_rw}} & op)
							|
							({64{rv64csr_rs}} | op)
							|
							({64{rv64csr_rc}} & (~op))
						);






wire [63:0] mstatus_dnxt,mstatus_qout;
wire [63:0] mie_dnxt, mie_qout;
wire [63:0] mtvec_dnxt,mtvec_qout; 
wire [63:0] mepc_dnxt,mepc_qout;
wire [63:0] mcause_dnxt,mcause_qout;
wire [63:0] mtval_dnxt,mtval_qout;
wire [63:0] mip_dnxt,mip_qout;


// Machine Information Registers
wire [31:0] mvendorid = 'd0;
wire [63:0] marchid = 'd0;
wire [63:0] mimpid = 'd0;
wire [63:0] mhartid = 'd0;







//Machine Trap Setup
gen_dffr # (.DW(64)) mstatus ( .dnxt(mstatus_dnxt), .qout(mstatus_qout), .CLK(CLK), .RSTn(RSTn) );
wire [63:0] misa = {2'b10,36'b0,26'b00000000000000000100000000};
// gen_dffr # (.DW()) medeleg ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) mideleg ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
gen_dffr # (.DW(64)) mie ( .dnxt(mie_dnxt), .qout(mie_qout), .CLK(CLK), .RSTn(RSTn) );
gen_dffr # (.DW(64)) mtvec ( .dnxt(mtvec_dnxt), .qout(mtvec_qout), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) mcounteren ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) mstatush ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) ); //RV32 only

//Machine Trap Handling
// gen_dffr # (.DW()) mscratch ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
gen_dffr # (.DW(64)) mepc ( .dnxt(mepc_dnxt), .qout(mepc_qout), .CLK(CLK), .RSTn(RSTn) );
gen_dffr # (.DW(64)) mcause ( .dnxt(mcause_dnxt), .qout(mcause_qout), .CLK(CLK), .RSTn(RSTn) );
gen_dffr # (.DW(64)) mtval ( .dnxt(mtval_dnxt), .qout(mtval_qout), .CLK(CLK), .RSTn(RSTn) );
gen_dffr # (.DW(64)) mip ( .dnxt(mip_dnxt), .qout(mip_qout), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) mtinst ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) mtval2 ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );

//Machine Memory Protection

//Machine Counter/Timer
// gen_dffr # (.DW()) mcycle ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) minstret ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );


//Machine Counter Setup



//Debug/Trace Register
// gen_dffr # (.DW()) tselect ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) tdata1 ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) tdata2 ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) tdata3 ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );

//Debug Mode Register
// gen_dffr # (.DW()) dcsr ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) dpc ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) dscratch0 ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );
// gen_dffr # (.DW()) dscratch1 ( .dnxt(), .qout(), .CLK(CLK), .RSTn(RSTn) );








	gen_dffr #(.DW(1)) csr_vaild ( .dnxt(csr_execute_vaild), .qout(csr_writeback_vaild), .CLK(CLK), .RSTn(RSTn) );
	gen_dffr #(.DW((5+RNBIT)) wb_rd0 ( .dnxt(rd0), .qout(csr_rd0), .CLK(CLK), .RSTn(RSTn) );



gen_dffr # (.DW((5+RNBIT))) csr_rd0 ( .dnxt(csr_rd0_dnxt), .qout(csr_rd0_qout), .CLK(CLK), .RSTn(RSTn));
gen_dffr # (.DW(64)) csr_res ( .dnxt(csr_res_dnxt), .qout(csr_res_qout), .CLK(CLK), .RSTn(RSTn));
gen_dffr # (.DW(1)) vaild ( .dnxt(csr_exeparam_vaild), .qout(csr_writeback_vaild), .CLK(CLK), .RSTn(RSTn));



endmodule














