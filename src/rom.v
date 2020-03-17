//-------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------------------------------------

module rom #
(
	parameter DW = 8,
	parameter AW = 14,
	parameter FN = "rom8x16K.hex"
)
(
	input  wire         clock,
	output reg [DW-1:0] do,
	input  wire[AW-1:0] a
);

reg[DW-1:0] d[(2**AW)-1:0];
initial $readmemh(FN, d, 0);

always @(posedge clock) do <= d[a];

endmodule
