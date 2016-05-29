module keysctl
(
	input clk, clrn,
	input [3:0] pins,
	output [3:0] state,
	output [3:0] edge_p, edge_n
);

localparam FDIV_N = 13;

wire [3:0] trig;

debounce #(FDIV_N) inst[3:0] (
	.clk(clk),
	.clrn(clrn),
	.in_state(pins),
	.out_state(state),
	.out_edge(trig)
);

assign edge_p = trig & state;
assign edge_n = trig & ~state;

endmodule
