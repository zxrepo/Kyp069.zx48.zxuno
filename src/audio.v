//-------------------------------------------------------------------------------------------------
module audio
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      reset,
	input  wire[7:0] specdrum,
	input  wire      speaker,
	input  wire      mic,
	input  wire      ear,
	input  wire[7:0] a,
	input  wire[7:0] b,
	input  wire[7:0] c,
	output wire[1:0] audio
);

wire[2:0] inp = { ear, speaker, mic };
wire[7:0] ula
	= inp == 3'b000 ? 8'h11
	: inp == 3'b001 ? 8'h24
	: inp == 3'b010 ? 8'hB8
	: inp == 3'b011 ? 8'hC0
	: inp == 3'b100 ? 8'h16
	: inp == 3'b101 ? 8'h30
	: inp == 3'b110 ? 8'hF4
	: 8'hFF;

reg[7:0] lmix;
reg[7:0] rmix;
reg[1:0] source;
always @(posedge clock)
begin
	source <= source+2'd1;
	case(source)
	0: { lmix, rmix } <= { 2{specdrum} };
	1: { lmix, rmix } <= { 2{ula} };
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
