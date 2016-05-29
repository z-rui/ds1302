module digitmap
(
	input [3:0] d,
	output reg [6:0] q
);

always @*
begin
	case (d)
		4'h0: q = 7'b0111111;
		4'h1: q = 7'b0000110;
		4'h2: q = 7'b1011011;
		4'h3: q = 7'b1001111;
		4'h4: q = 7'b1100110;
		4'h5: q = 7'b1101101;
		4'h6: q = 7'b1111101;
		4'h7: q = 7'b0100111;
		4'h8: q = 7'b1111111;
		4'h9: q = 7'b1101111;
		4'ha: q = 7'b1110111;
		4'hb: q = 7'b1111100;
		4'hc: q = 7'b1011000;
		4'hd: q = 7'b1011110;
		4'he: q = 7'b1111001;
		4'hf: q = 7'b1110001;
	endcase
end

endmodule 