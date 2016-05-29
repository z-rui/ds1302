module counter
#(
	parameter Nbits = 4
)
(
	input clk, clrn, ena, ldn,
	input [Nbits-1:0] d,
	output reg [Nbits-1:0] q
);

always @(posedge clk, negedge clrn)
begin
	if (!clrn)
		q <= 0;
	else if (ena)
		if (!ldn)
			q <= d;
		else
		begin
			q <= q + 1'b1;
		end
end

endmodule
