//-------------------------------------------------------------------------------------------------
module div
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       ce,
	input  wire       reset,
	input  wire       mreq,
	input  wire       iorq,
	input  wire       m1,
	input  wire       wr,
	input  wire[ 7:0] d,
	input  wire[15:0] a,
	output wire       map,
	output wire       ram,
	output wire[ 3:0] page
);

reg forcemap = 1'b0;
reg automap = 1'b0;
reg mapram = 1'b0;
reg m1on = 1'b0;
reg [3:0] mappage;

always @(posedge clock) if(ce)
begin
	if(!reset)
	begin
		forcemap <= 1'b0;
		automap <= 1'b0;
		mappage <= 4'd0;
		mapram <= 1'b0;
		m1on <= 1'b0;
	end
	else
	begin
		if(!iorq && !wr && a[7:0] == 8'hE3)
		begin
			forcemap <= d[7];
			mappage <= d[3:0];
			mapram <= d[6]|mapram;
		end

		if(!mreq && !m1)
		begin
			if(a == 16'h0000 || a == 16'h0008 || a == 16'h0038 || a == 16'h0066 || a == 16'h04C6 || a == 16'h0562)
				m1on <= 1'b1; // activate automapper after this cycle

			else if(a[15:3] == 13'h3FF)
				m1on <= 1'b0; // deactivate automapper after this cycle

			else if(a[15:8] == 8'h3D)
			begin
				m1on <= 1'b1; // activate automapper immediately
				automap <= 1'b1;
			end
		end

		if(m1) automap <= m1on;
	end
end

assign map = forcemap || automap;
assign ram = mapram;
assign page = !a[13] && mapram ? 4'd3 : mappage;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
