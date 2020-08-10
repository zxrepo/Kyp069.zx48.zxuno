//-------------------------------------------------------------------------------------------------
module mmc
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      cep,
	input  wire      cen,
	input  wire      iorq,
	input  wire      wr,
	input  wire      rd,
	input  wire[7:0] di,
	output wire[7:0] do,
	input  wire[7:0] a,
	output wire      spiCs,
	output wire      spiCk,
	output wire      spiDi,
	input  wire      spiDo
);
//-------------------------------------------------------------------------------------------------

reg cs;
always @(posedge clock) if(cep) if(!iorq && !wr && a == 8'hE7) cs <= di[0];

//-------------------------------------------------------------------------------------------------

wire iotx = !iorq && !wr && a == 8'hEB;
wire iorx = !iorq && !rd && a == 8'hEB;

reg tx, dtx;
reg rx, drx;

always @(posedge clock) if(cep)
begin
	tx <= 1'b0;
	dtx <= iotx;
	if(iotx && !dtx && a == 8'hEB) tx <= 1'b1;

	rx <= 1'b0;
	drx <= iorx;
	if(iorx && !drx && a == 8'hEB) rx <= 1'b1;
end

//-------------------------------------------------------------------------------------------------

reg[7:0] cpud;
reg[7:0] spid;
reg[4:0] count = 5'b10000;

always @(posedge clock) if(cen)
	if(count[4])
	begin
		if(tx || rx)
		begin
			cpud <= spid;
			spid <= tx ? di : 8'hFF;
			count <= 5'd0;
		end
	end
	else
	begin
		if(count[0]) spid <= { spid[6:0], spiDo };
		count <= count+5'd1;
	end

//-------------------------------------------------------------------------------------------------

assign do = cpud;
assign spiCs = cs;
assign spiCk = count[0];
assign spiDi = spid[7];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
