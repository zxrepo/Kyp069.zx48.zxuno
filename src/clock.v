//-------------------------------------------------------------------------------------------------
module clock
//-------------------------------------------------------------------------------------------------
(
	input  wire i,     // 50.000 MHz
	output wire o0700, //  7.000 MHz
	output wire o0350, //  3.500 MHz
	output wire o0175  //  1.750 MHz
);

IBUFG IBufg
(
	.I(i),
	.O(ci)
);
PLL_BASE #
(
	.BANDWIDTH         ("OPTIMIZED"),
	.CLK_FEEDBACK      ("CLKFBOUT" ),
	.COMPENSATION      ("SYSTEM_SYNCHRONOUS"),
	.CLKOUT0_DUTY_CYCLE( 0.500),
	.CLKFBOUT_PHASE    ( 0.000),
	.CLKOUT0_PHASE     ( 0.000),
	.CLKIN_PERIOD      (20.000),
	.REF_JITTER        ( 0.010),
	.DIVCLK_DIVIDE     ( 1    ),
	.CLKFBOUT_MULT     (14    ),
	.CLKOUT0_DIVIDE    (25    )
)
Pll
(
	.RST               (1'b0),
	.CLKFBIN           (fb),
	.CLKFBOUT          (fb),
	.CLKIN             (ci),
	.CLKOUT0           (co), // 28 MHz
	.CLKOUT1           (),
	.CLKOUT2           (),
	.CLKOUT3           (),
	.CLKOUT4           (),
	.CLKOUT5           (),
	.LOCKED            ()
);

reg[3:0] cd;
always @(posedge co) cd <= cd+4'd1;

assign o0700 = cd[1];
assign o0350 = cd[2];
assign o0175 = cd[3];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
