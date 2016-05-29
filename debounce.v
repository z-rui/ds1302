module debounce
#(
	parameter FDIV_N = 10
)
(
	input clk, clrn,
	input in_state,
	output reg out_state, out_edge
);

wire [FDIV_N-1:0] fdiv_q;
wire equal;
assign equal = (out_state == in_state);

counter #(FDIV_N) fdiv
(
	.clk(clk),
	.clrn(clrn),
	.ena(1),
	.ldn(!equal),
	.d(0),
	.q(fdiv_q)
);

always @(posedge clk, negedge clrn)
begin
	if (!clrn)
	begin
		out_state <= 0;
		out_edge <= 0;
	end
	else
	begin
		if (&fdiv_q)
		begin
			out_state <= in_state;
			out_edge <= !equal;
		end
		else
			out_edge <= 0;
	end
end

endmodule
