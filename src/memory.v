//-------------------------------------------------------------------------------------------------
module memory
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       rfsh,
	input  wire       cpuCe,
	input  wire       cpuWe,
	output wire[ 7:0] cpuDo,
	input  wire[ 7:0] cpuDi,
	input  wire[15:0] cpuA,
	input  wire       vmmCe,
	input  wire       vmmRd,
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
	.clock(clock),
	.ce   (cpuCe),
	.do   (romDo),
	.a    (romA )
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] divDo;
wire[12:0] divA = cpuA[12:0];

rom #(.AW(13), .FN("esxdos mmc 087.hex")) DivRom
(
	.clock(clock),
	.ce   (cpuCe),
	.do   (divDo),
	.a    (divA )
);

//-------------------------------------------------------------------------------------------------

//wire we = !(!cpuWe && cpuA[15:13] == 2'b010);
//wire[12:0] a1 = cpuA[12:0];
//
//vmm #(.AW(13)) Vmm
//(
//	.clock(clock),
//	.ce1  (cpuCe),
//	.we   (we   ),
//	.di   (cpuDi),
//	.a1   (a1   ),
//	.ce2  (vmmCe),
//	.do   (vmmDo),
//	.a2   (vmmA )
//);

wire sprWe = !(!cpuWe && cpuA[15:14] == 2'b01);
wire[ 7:0] sprDo;
wire[13:0] sprA = !rfsh && cpuA[15:14] == 2'b01 ? { 1'b0, vmmA[12:7], cpuA[6:0] } : !vmmRd ? cpuA[13:0] : { 1'b0, vmmA };

spr #(.AW(14)) Vmm
(
	.clock(clock),
	.ce   (vmmCe),
	.we   (sprWe),
	.di   (cpuDi),
	.do   (sprDo),
	.a    (sprA )
);

//-------------------------------------------------------------------------------------------------

assign vmmDo = sprDo;
assign cpuDo
	= cpuA[15:13] == 3'b000 && divMap && !divRam ? divDo
	: cpuA[15:14] == 2'b00 && !divMap ? romDo
	: cpuA[15:14] == 2'b01 ? sprDo
	: ramD;

//-------------------------------------------------------------------------------------------------

assign ramWe = !(!cpuWe && (cpuA[15] || (cpuA[15:13] == 3'b001 && divMap)));
assign ramD  = ramWe ? 8'hZZ : cpuDi;
assign ramA =
{
	2'b00
	, cpuA[15:13] == 3'b000 && divMap && divRam ? { 2'b10, 4'd3, cpuA[12:0] }
	: cpuA[15:13] == 3'b001 && divMap ? { 2'b10, divPage, cpuA[12:0] }
	: { 2'b00, 1'b0, cpuA }
};

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
