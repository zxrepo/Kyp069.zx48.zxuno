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

reg[7:0] mix;
reg[0:0] source;
always @(posedge clock)
begin
	source <= source+1'd1;
	case(source)
	0: mix <= specdrum;
	1: mix <= ula;
	endcase
end

dac Dac
(
	.clock(clock   ),
	.reset(reset   ),
	.di   (mix     ),
	.do   (audio[0])
);

assign audio[1] = audio[0];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
