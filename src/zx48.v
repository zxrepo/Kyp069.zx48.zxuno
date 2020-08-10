//-------------------------------------------------------------------------------------------------
// ZX48: ZX Spectrum 48K implementation for ZX-Uno board by Kyp
// https://github.com/Kyp069/zx48
//-------------------------------------------------------------------------------------------------
// Z80 chip module implementation by Sorgelig
// https://github.com/sorgelig/ZX_Spectrum-128K_MIST
//-------------------------------------------------------------------------------------------------
// AY chip module implementation by Miguel Angel Rodriguez Jodar
// https://github.com/mcleod-ideafix/zxuno_spectrum_core
// Unused io ports removed and audio ports renamed.
//-------------------------------------------------------------------------------------------------
module zx48
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,
	output wire       led,

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
	.i      (clock50),
	.o      (clock  )
);


reg[3:0] ce;
always @(negedge clock) ce <= ce+1'd1;

wire ce14n = ~ce[0];
wire ce14p =  ce[0];

wire ce70n = ~ce[0] & ~ce[1];
wire ce70p = ~ce[0] &  ce[1];

wire ce35n = ~ce[0] & ~ce[1] & ~ce[2];
wire ce35p = ~ce[0] & ~ce[1] &  ce[2];

wire ce17n = ~ce[0] & ~ce[1] & ~ce[2] & ~ce[3];
wire ce17p = ~ce[0] & ~ce[1] & ~ce[2] &  ce[3];


wire cc = ~contend;

reg ccd;
always @(posedge clock) if(ce14p) ccd <= cc;

wire cc35p = ce35n & cc;
wire cc35n = ce35p & (cc|ccd);

//-----------------------------------------------------------------------------

wire[ 7:0] di;
wire[ 7:0] do;
wire[15:0] a;

cpu Cpu
(
	.clock  (clock  ),
	.cep    (cc35p  ),
	.cen    (cc35n  ),
	.reset  (reset  ),
	.mreq   (mreq   ),
	.iorq   (iorq   ),
	.nmi    (nmi    ),
	.int    (int    ),
	.m1     (m1     ),
	.rd     (rd     ),
	.wr     (wr     ),
	.di     (di     ),
	.do     (do     ),
	.a      (a      )
);

//-----------------------------------------------------------------------------

wire ioUla = !(!iorq && !a[0]);

reg speaker;
reg[2:0] border;

always @(posedge clock) if(ce70n) if(!ioUla && !wr) { speaker, border } <= { do[4], do[2:0]};

//-----------------------------------------------------------------------------

wire ioSpd = !(!iorq && a[7:4] == 4'b1101);

reg[7:0] specdrum;
always @(posedge clock) if(cc35p) if(!ioSpd && !wr) specdrum <= do;

//-----------------------------------------------------------------------------

// IN  (0xfffd) - !bdir  -  bc1 - Read the value of the selected register
// OUT (0xbffd) -  bdir  - !bc1 - Write to the selected register
// OUT (0xfffd) -  bdir  -  bc1 - Select a register 0-15

wire ioPsg = !(!iorq && a[15] && !a[1]);

wire psgOe;
wire bdir = !ioPsg && !wr;
wire bc1  = !ioPsg && a[14] && (!rd || !wr);

reg psgSel;
always @(posedge clock) if(!reset) psgSel <= 1'b0; else if(bdir && bc1 && do[4]) psgSel <= ~do[0];

wire bdir1 = !psgSel ? bdir : 1'b0;
wire bdir2 =  psgSel ? bdir : 1'b0;

wire bc11 = !psgSel ? bc1 : 1'b0;
wire bc12 =  psgSel ? bc1 : 1'b0;

wire[7:0] psgA1;
wire[7:0] psgB1;
wire[7:0] psgC1;
wire[7:0] psgDo1;

ay_3_8192 Psg1
(
	.clock  (clock  ),
	.clken  (ce17p  ),
	.reset  (reset  ),
	.bdir   (bdir1  ),
	.bc1    (bc11   ),
	.di     (do     ),
	.do     (psgDo1 ),
	.a      (psgA1  ),
	.b      (psgB1  ),
	.c      (psgC1  )
);

wire[7:0] psgA2;
wire[7:0] psgB2;
wire[7:0] psgC2;
wire[7:0] psgDo2;

ay_3_8192 Psg2
(
	.clock  (clock  ),
	.clken  (ce17p  ),
	.reset  (reset  ),
	.bdir   (bdir2  ),
	.bc1    (bc12   ),
	.di     (do     ),
	.do     (psgDo2 ),
	.a      (psgA2  ),
	.b      (psgB2  ),
	.c      (psgC2  )
);

wire[7:0] psgDo = !psgSel ? psgDo1 : psgDo2;

//-----------------------------------------------------------------------------

wire[ 7:0] vmmDo;
wire[12:0] vmmA;

video Video
(
	.clock  (clock  ),
	.ce     (ce70n  ),
	.border (border ),
	.stdn   (stdn   ),
	.sync   (sync   ),
	.rgb    (rgb    ),
	.int    (int    ),
	.rd     (vmmRd  ),
	.cn     (vmmCn  ),
	.d      (vmmDo  ),
	.a      (vmmA   )
);

//-----------------------------------------------------------------------------

audio Audio
(
	.clock   (clock   ),
	.reset   (reset   ),
	.specdrum(specdrum),
	.speaker (speaker ),
	.a1      (psgA1   ),
	.b1      (psgB1   ),
	.c1      (psgC1   ),
	.a2      (psgA2   ),
	.b2      (psgB2   ),
	.c2      (psgC2   ),
	.audio   (audio   )
);

//-----------------------------------------------------------------------------

wire[4:0] keyDo;
wire[7:0] keyA = a[15:8];

keyboard Keyboard
(
	.clock  (clock  ),
	.ce     (ce70n  ),
	.ps2    (ps2    ),
	.reset  (reset  ),
	.nmi    (nmi    ),
	.do     (keyDo  ),
	.a      (keyA   )
);

//-----------------------------------------------------------------------------

wire[3:0] divPage;

div Div
(
	.clock  (clock  ),
	.ce     (cc35p  ),
	.reset  (reset  ),
	.mreq   (mreq   ),
	.iorq   (iorq   ),
	.m1     (m1     ),
	.wr     (wr     ),
	.d      (do     ),
	.a      (a      ),
	.map    (divMap ),
	.ram    (divRam ),
	.page   (divPage)
);

//-----------------------------------------------------------------------------

wire ioMmc = !(!iorq && a[7:0] == 8'hEB);

wire[7:0] mmcDo;
wire[7:0] mmcA = a[7:0];

mmc Mmc
(
	.clock  (clock  ),
	.cep    (ce70p  ),
	.cen    (ce70n  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.di     (do     ),
	.do     (mmcDo  ),
	.a      (mmcA   ),
	.spiCs  (spiCs  ),
	.spiCk  (spiCk  ),
	.spiDo  (spiDo  ),
	.spiDi  (spiDi  )
);

assign led = ~spiCs;

//-----------------------------------------------------------------------------

wire memWe = !(!mreq && !wr);
wire[7:0] memDo;

memory Memory
(
	.clock  (clock  ),
	.cpuCe  (cc35p  ),
	.cpuWe  (memWe  ),
	.cpuDo  (memDo  ),
	.cpuDi  (do     ),
	.cpuA   (a      ),
	.vmmCe  (ce70n  ),
	.vmmDo  (vmmDo  ),
	.vmmA   (vmmA   ),
	.divMap (divMap ),
	.divRam (divRam ),
	.divPage(divPage),
	.ramWe  (ramWe  ),
	.ramD   (ramD   ),
	.ramA   (ramA   )
);

//-----------------------------------------------------------------------------

reg iorqtw3;
reg mreqt23;
reg cpuck;

wire iorqula = !(!iorq && !a[0]);

wire nor1 = ~vmmCn | ~cpuck | ~(a[14] | ~iorqula) | ~(~a[15] | ~iorqula) | ~iorqtw3 | ~mreqt23;
//wire nor2 = ~vmmCn | ~cpuck | iorqula | ~iorqtw3;

assign contend = ~nor1; // | ~nor2;

always @(posedge clock) if(ce70n) if(cpuck && !contend) cpuck <= 0; else cpuck <= 1;

always @(posedge clock) if(cc35p)
begin
	iorqtw3 <= iorqula;
	mreqt23 <= mreq;
end

//-----------------------------------------------------------------------------

assign di
	= !mreq  && !rd ? memDo
	: !ioUla && !rd ? { 1'b1, !ear, 1'b1, keyDo }
	: !ioPsg && !rd && a[14] ? psgDo
	: !ioMmc && !rd ? mmcDo
	: !iorq  && !rd && vmmRd ? vmmDo
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
