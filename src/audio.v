//-------------------------------------------------------------------------------------------------
module audio
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      reset,
	input  wire[7:0] specdrum,
	input  wire      speaker,
	input  wire[7:0] a,
	input  wire[7:0] b,
	input  wire[7:0] c,
	output wire[1:0] audio
);

reg[1:0] source;
always @(posedge clock) source <= source+2'd1;

wire[7:0] lmix;
wire[7:0] rmix;

assign { lmix, rmix }
	= source == 0 ? { 2{{ 1'b0, { 7{speaker} } }} }
	: source == 1 ? { 2{specdrum} }
	: source == 2 ? { a, b }
	:               { 2{c} };

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
