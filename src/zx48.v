//-------------------------------------------------------------------------------------------------
module zx48
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] stdn,
	output wire[ 1:0] sync,
	output wire[ 8:0] rgb,

	output wire       ramWe,
	inout  wire[ 7:0] ramD,
	output wire[20:0] ramA
);

//-----------------------------------------------------------------------------

clock Clock
(
	.i       (clock50 ),
	.o1400   (co1400  ),
	.o0700   (co0700  ),
	.o0350   (co0350  )
);

BUFG bufg1400(.I(co1400), .O(memClock));
BUFG bufg0700(.I(co0700), .O(vmmClock));
BUFG bufg0350(.I(co0350), .O(cpuClock));

//-----------------------------------------------------------------------------

reg[5:0] rc;
always @(posedge cpuClock) if(!rc[5]) rc <= rc+6'd1;

wire reset = rc[5];

//-----------------------------------------------------------------------------

wire[ 7:0] di;
wire[ 7:0] do;
wire[15:0] a;

cpu Cpu
(
	.clock   (vmmClock), // 2x
	.reset   (reset   ),
	.mreq    (mreq    ),
	.iorq    (iorq    ),
	.nmi     (1'b1    ),
	.int     (int     ),
	.m1      (        ),
	.rd      (rd      ),
	.wr      (wr      ),
	.di      (di      ),
	.do      (do      ),
	.a       (a       )
);

//-----------------------------------------------------------------------------

wire ioFE = !iorq && !a[0];

reg[2:0] border;

always @(posedge cpuClock) if(ioFE && !wr) border <= do[2:0];

//-----------------------------------------------------------------------------

wire[ 7:0] vmmDo;
wire[12:0] vmmA;

video Video
(
	.clock   (vmmClock),
	.border  (border  ),
	.stdn    (stdn    ),
	.sync    (sync    ),
	.rgb     (rgb     ),
	.int     (int     ),
	.d       (vmmDo   ),
	.a       (vmmA    )
);

//-----------------------------------------------------------------------------

wire memWe = !(!mreq && !wr);
wire[7:0] memDo;

memory Memory
(
	.clock   (memClock),
	.cpuWe   (memWe   ),
	.cpuDo   (memDo   ),
	.cpuDi   (do      ),
	.cpuA    (a       ),
	.vmmDo   (vmmDo   ),
	.vmmA    (vmmA    ),
	.ramWe   (ramWe   ),
	.ramD    (ramD    ),
	.ramA    (ramA    )
);

//-----------------------------------------------------------------------------

assign di
	= !mreq && !rd ? memDo
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
