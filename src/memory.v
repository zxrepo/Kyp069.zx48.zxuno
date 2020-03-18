//-------------------------------------------------------------------------------------------------
module memory
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       cpuWe,
	output wire[ 7:0] cpuDo,
	input  wire[ 7:0] cpuDi,
	input  wire[15:0] cpuA,
	output wire[ 7:0] vmmDo,
	input  wire[12:0] vmmA,
	output wire       ramWe,
	inout  wire[ 7:0] ramD,
	output wire[20:0] ramA
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] romDo;
wire[13:0] romA = cpuA[13:0];

rom #(.AW(14), .FN("48k.hex")) Rom // "48k", "brendan alford zx 036" "retroleum diagrom v24"
(
	.clock (clock),
	.do    (romDo),
	.a     (romA )
);

//-----------------------------------------------------------------------------

wire we = !(!cpuWe && cpuA[15:14] == 2'b01);
wire[12:0] a1 = cpuA[12:0];

vmm #(.AW(13)) Vmm
(
	.clock1(clock),
	.we    (we   ),
	.di    (cpuDi),
	.a1    (a1   ),
	.clock2(clock),
	.do    (vmmDo),
	.a2    (vmmA )
);

//-----------------------------------------------------------------------------

assign cpuDo = cpuA[15:14] == 2'b00 ? romDo : ramD;

assign ramWe = cpuWe;
assign ramD  = cpuWe ? 8'hZZ : cpuDi;
assign ramA  = { 5'b00000, cpuA };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
