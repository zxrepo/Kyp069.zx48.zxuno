//-------------------------------------------------------------------------------------------------
// ZX48: ZX Spectrum 48K implementation by Kyp
// https://github.com/Kyp069/zx48
//-------------------------------------------------------------------------------------------------
// Z80 chip module implementation by Sorgelig for Mist.
// https://github.com/sorgelig/ZX_Spectrum-128K_MIST
//-------------------------------------------------------------------------------------------------
// AY chip module implementation by Miguel Angel Rodriguez Jodar's for ZX-Uno.
// Unused ports removed and audio ports renamed.
// https://github.com/mcleod-ideafix/zxuno_spectrum_core
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
	.o0350   (co0350  ),
	.o0175   (co0175  )
);

//-----------------------------------------------------------------------------

wire[ 7:0] di;
wire[ 7:0] do;
wire[15:0] a;

cpu Cpu
(
	.clock   (cpuClock),
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

wire ioUla = !(!iorq && !a[0]);

reg speaker;
reg[2:0] border;

always @(posedge cpuClock) if(!ioUla && !wr) { speaker, border } <= { do[4], do[2:0]};

//-----------------------------------------------------------------------------

wire ioSpd = !(!iorq && a[7:4] == 4'b1101);

reg[7:0] specdrum;
always @(posedge cpuClock) if(!ioSpd && !wr) specdrum <= do;

//-----------------------------------------------------------------------------

wire ioPsg = !(!iorq && a[15:14] == 2'b11 && !a[1]);

wire[7:0] psgA;
wire[7:0] psgB;
wire[7:0] psgC;
wire[7:0] psgDo;

wire psgOe;
wire bdir = !iorq && a[15] && a[1:0] == 2'b01 && !wr;
wire bc1  = !iorq && a[15] && a[1:0] == 2'b01 && a[14];

ay_3_8192 Psg
(
	.clock   (psgClock),
	.clken   (1'b1    ),
	.reset   (reset   ),
	.bdir    (bdir    ),
	.bc1     (bc1     ),
	.di      (do      ),
	.do      (psgDo   ),
	.a       (psgA    ),
	.b       (psgB    ),
	.c       (psgC    )
);

//-----------------------------------------------------------------------------

wire[ 7:0] vmmDo;
wire[12:0] vmmA;

video Video
(
	.clock   (vmmClock),
	.border  (border  ),
	.busy    (busy    ),
	.read    (read    ),
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
	.a       (psgA    ),
	.b       (psgB    ),
	.c       (psgC    ),
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

wire ioMmc = !(!iorq && a[7:0] == 8'hEB);

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

wire causeContention = !(a[15:14] == 2'b01 || !ioUla);

reg cancelContention = 1'b1;
always @(negedge cpuClock) cancelContention = !mreq || !ioUla;

BUFG bufg0700(.I(co0700), .O(vmmClock));
BUFG bufg0175(.I(co0175), .O(psgClock));
BUFGCE_1 bufgce(.I(co0700), .O(cpuClock), .CE(busy|causeContention|cancelContention));

//-----------------------------------------------------------------------------

assign di
	= !mreq  && !rd ? memDo
	: !ioUla && !rd ? { 1'b1, !ear, 1'b1, keyDo }
	: !ioPsg && !rd ? psgDo
	: !ioMmc && !rd ? mmcDo
	: !iorq  && !rd && read ? vmmDo
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
