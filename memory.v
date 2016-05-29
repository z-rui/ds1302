module memory
#(
	parameter AddrWidth = 8,
	parameter DataWidth = 8
)
(
	input clk,
	input [AddrWidth-1:0] addr_r, addr_w,
	input we,
	input [DataWidth-1:0] d,
	output reg [DataWidth-1:0] q
);

reg [DataWidth-1:0] mem[(1<<AddrWidth)-1:0];

always @(posedge clk)
begin
	q <= mem[addr_r];
	if (we)
		mem[addr_w] <= d;
end

endmodule
