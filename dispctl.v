module dispctl
(
	input clk, clrn,
	input [1:0] page,
	input [5:0] blink_mask,
	input [3:0] led_data,

	output [3:0] ram_addr,
	input [7:0] ram_r,

	output [7:0] DIG,
	output [5:0] SEL,
	output [3:0] LED
);

wire [2:0] scan_q;
wire [5:0] scan_sel;

counter #(3) scanner
(
	.clk(clk),
	.clrn(clrn),
	.ena(1'b1),
	.ldn(scan_q != 3'd5),
	.d(3'd0),
	.q(scan_q)
);

assign scan_sel = 6'b1 << scan_q;

localparam FDIV_N = 11;

wire [FDIV_N-1:0] fdiv_q;
wire blink_clk;
assign blink_clk = fdiv_q[FDIV_N-1];

counter #(FDIV_N) fdiv
(
	.clk(clk),
	.clrn(clrn),
	.ena(1'b1),
	.ldn(1'b1),
	.d(),
	.q(fdiv_q)
);

wire [3:0] digit;
wire [6:0] glyph;
assign ram_addr = {page, scan_q[2:1]};
assign digit = scan_q[0] ? ram_r[7:4] : ram_r[3:0];

digitmap dmap
(
	.d(digit),
	.q(glyph)
);

assign SEL = clrn ? (~scan_sel) | (blink_clk ? blink_mask : 6'b0) : 6'b111111;
assign DIG[6:0] = ~glyph;
assign DIG[7] = !(scan_sel & 6'b010100);

assign LED = clrn ? led_data : 4'b0;

endmodule
