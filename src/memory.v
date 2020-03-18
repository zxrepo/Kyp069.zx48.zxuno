//-------------------------------------------------------------------------------------------------
module memory
//-------------------------------------------------------------------------------------------------
(
	input  wire       cpuClock,
	input  wire       cpuWe,
	output wire[ 7:0] cpuDo,
	input  wire[ 7:0] cpuDi,
	input  wire[15:0] cpuA,
	input  wire       vmmClock,
	output wire[ 7:0] vmmDo,
	input  wire[12:0] vmmA,
	input  wire       divMap,
	input  wire       divRam,
	input  wire[ 3:0] divPage,
	output wire       ramWe,
	inout  wire[ 7:0] ramD,
	output wire[20:0] ramA
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] romDo;
wire[13:0] romA = cpuA[13:0];

rom #(.AW(14), .FN("48k.hex")) Rom // "48k", "brendan alford zx 036" "retroleum diagrom v24"
(
	.clock (cpuClock),
	.do    (romDo),
	.a     (romA )
);

//-----------------------------------------------------------------------------

wire[ 7:0] divDo;
wire[12:0] divA = cpuA[12:0];

rom #(.AW(13), .FN("esxdos mmc 086.hex")) DivRom
(
	.clock   (cpuClock),
	.do      (divDo),
	.a       (divA )
);

//-----------------------------------------------------------------------------

wire we = !(!cpuWe && cpuA[15:13] == 2'b010);
wire[12:0] a1 = cpuA[12:0];

vmm #(.AW(13)) Vmm
(
	.clock1(cpuClock),
	.we    (we      ),
	.di    (cpuDi   ),
	.a1    (a1      ),
	.clock2(vmmClock),
	.do    (vmmDo   ),
	.a2    (vmmA    )
);

//-----------------------------------------------------------------------------

assign cpuDo
	= cpuA[15:13] == 3'b000 && divMap && !divRam ? divDo
	: cpuA[15:14] == 2'b00 && !divMap ? romDo
	: ramD;

//-----------------------------------------------------------------------------

assign ramWe = cpuWe;
assign ramD  = cpuWe ? 8'hZZ : cpuDi;
assign ramA
	= cpuA[15:13] == 3'b000 && divMap && divRam ? { 2'b10, 4'd3, cpuA[12:0] }
	: cpuA[15:13] == 3'b001 && divMap ? { 2'b10, divPage, cpuA[12:0] }
	: { 2'b00, 1'b0, cpuA };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
