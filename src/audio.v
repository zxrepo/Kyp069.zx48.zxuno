//-------------------------------------------------------------------------------------------------
module audio
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      reset,
	input  wire[7:0] specdrum,
	input  wire      speaker,
	input  wire[7:0] a1,
	input  wire[7:0] b1,
	input  wire[7:0] c1,
	input  wire[7:0] a2,
	input  wire[7:0] b2,
	input  wire[7:0] c2,
	output wire[1:0] audio
);

reg[2:0] source;
always @(posedge clock) if(source == 5) source <= 1'd0; else source <= source+1'd1;

wire[7:0] lmix;
wire[7:0] rmix;

assign { lmix, rmix }
	= source == 0 ? { 2{{ 1'b0, { 7{speaker} } }} }
	: source == 1 ? { 2{specdrum} }
	: source == 2 ? { a1, c1 }
	: source == 3 ? { 2{b1} }
	: source == 4 ? { a2, c2 }
	:               { 2{b2} };

dac LDac
(
	.clock(clock   ),
	.reset(reset   ),
	.di   (lmix    ),
	.do   (audio[0])
);

dac RDac
(
	.clock(clock   ),
	.reset(reset   ),
	.di   (rmix    ),
	.do   (audio[1])
);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
