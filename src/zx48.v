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

	output wire       spiCs,
	output wire       spiCk,
	output wire       spiDi,
	input  wire       spiDo,

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
	.m1      (m1      ),
	.rd      (rd      ),
	.wr      (wr      ),
	.di      (di      ),
	.do      (do      ),
	.a       (a       )
);

//-----------------------------------------------------------------------------

wire ioFE = !iorq && !a[0];

reg speaker;
reg[2:0] border;

always @(posedge cpuClock) if(ioFE && !wr) { speaker, border } <= { do[4], do[2:0] };

//-----------------------------------------------------------------------------

wire ioDF = !iorq && a[7:4] == 4'b1101;

reg[7:0] specdrum;
always @(posedge cpuClock) if(ioDF && !wr) specdrum <= do;

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
	.specdrum(specdrum),
	.speaker (speaker ),
	.mic     (mic     ),
	.ear     (ear     ),
	.audio   (audio   )
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

wire[3:0] divPage;

div Div
(
	.clock   (cpuClock),
	.reset   (reset   ),
	.mreq    (mreq    ),
	.iorq    (iorq    ),
	.m1      (m1      ),
	.wr      (wr      ),
	.d       (do      ),
	.a       (a       ),
	.map     (divMap  ),
	.ram     (divRam  ),
	.page    (divPage )
);

//-----------------------------------------------------------------------------

wire ioEB = !iorq && a[7:0] == 8'hEB;

wire[7:0] mmcDo;
wire[7:0] mmcA = a[7:0];

mmc Mmc
(
	.clock   (vmmClock),
	.iorq    (iorq    ),
	.wr      (wr      ),
	.rd      (rd      ),
	.di      (do      ),
	.do      (mmcDo   ),
	.a       (mmcA    ),
	.spiCs   (spiCs   ),
	.spiCk   (spiCk   ),
	.spiDo   (spiDo   ),
	.spiDi   (spiDi   )
);

//-----------------------------------------------------------------------------

wire memWe = !(!mreq && !wr);
wire[7:0] memDo;

memory Memory
(
	.cpuClock(cpuClock),
	.cpuWe   (memWe   ),
	.cpuDo   (memDo   ),
	.cpuDi   (do      ),
	.cpuA    (a       ),
	.vmmClock(vmmClock),
	.vmmDo   (vmmDo   ),
	.vmmA    (vmmA    ),
	.divMap  (divMap  ),
	.divRam  (divRam  ),
	.divPage (divPage ),
	.ramWe   (ramWe   ),
	.ramD    (ramD    ),
	.ramA    (ramA    )
);

//-----------------------------------------------------------------------------

assign di
	= ioFE  && !rd ? { 1'b1, !ear, 1'b1, keyDo }
	: ioEB  && !rd ? mmcDo
	: !mreq && !rd ? memDo
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
