//-------------------------------------------------------------------------------------------------
module zx48
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] stdn,
	output wire[ 1:0] sync,
	output wire[ 8:0] rgb,

	output wire[ 1:0] audio,
	input  wire       ear,

	input  wire[1:0]  ps2,

	output wire       ramWe,
	inout  wire[ 7:0] ramD,
	output wire[20:0] ramA
);

//-----------------------------------------------------------------------------

clock Clock
(
	.i       (clock50 ),
	.o0700   (co0700  ),
	.o0350   (co0350  )
);

BUFG bufg0700(.I(co0700), .O(vmmClock));
BUFG bufg0350(.I(co0350), .O(cpuClock));

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
	.nmi     (nmi     ),
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

reg mic;
reg speaker;
reg[2:0] border;

always @(posedge cpuClock) if(ioFE && !wr) { speaker, mic, border } <= do[4:0];

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

audio Audio
(
	.clock   (vmmClock),
	.reset   (reset   ),
	.speaker (speaker ),
	.mic     (mic     ),
	.ear     (ear     ),
	.audio   (audio   )
);

//-----------------------------------------------------------------------------

wire memWe = !(!mreq && !wr);
wire[7:0] memDo;

memory Memory
(
	.clock   (vmmClock),
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

wire[4:0] keyDo;
wire[7:0] keyA = a[15:8];

keyboard Keyboard
(
	.clock  (vmmClock),
	.ps2    (ps2     ),
	.reset  (reset   ),
	.nmi    (nmi     ),
	.do     (keyDo   ),
	.a      (keyA    )
);

//-----------------------------------------------------------------------------

assign di
	= ioFE  && !rd ? { 1'b1, !ear, 1'b1, keyDo }
	: !mreq && !rd ? memDo
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
