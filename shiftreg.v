module shiftreg
#(
	parameter Nbits = 8
)
(
	input clk, clrn, ena, ldn,
	input [Nbits-1:0] d,
	input sin,
	output reg [Nbits-1:0] q,
	output sout
);

assign sout = q[0];

always @(posedge clk or negedge clrn)
begin
	if (!clrn)
		q <= 0;
	else if (ena)
	begin
		if (!ldn)
			q <= d;
		else
			q <= {sin, q[Nbits-1:1]};
	end
end

endmodule
