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

reg[7:0] lmix;
reg[7:0] rmix;
reg[1:0] source;
always @(posedge clock)
begin
	source <= source+2'd1;
	case(source)
	0: { lmix, rmix } <= { 2{{ 1'b0, { 7{speaker} } }} };
	1: { lmix, rmix } <= { 2{specdrum} };
	2: { lmix, rmix } <= { a, b };
	3: { lmix, rmix } <= { 2{c} };
	endcase
end

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
