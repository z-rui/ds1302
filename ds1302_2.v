module ds1302_2
(
	input clk, clrn, ena,
	input [7:0] addr,
	input [7:0] w,
	output [7:0] r,
	output ready,
	output done,
	output reg SCLK,
	output NRST,
	inout DATA
);

reg [4:0] state;
reg is_data_out;
wire shift_in = DATA, shift_out;

wire [7:0] parallel_q;
reg [7:0] addr_reg;
reg shift_ena;
shiftreg #(8) shiftreg0
(
	.clk(clk),
	.clrn(clrn),
	.ena(shift_ena),
	.ldn(!ready),
	.sin(shift_in),
	.sout(shift_out),
	.d(w),
	.q(r)
);

reg DATA_W;
assign DATA = is_data_out ? DATA_W : 1'bz;

always @*
case (state)
	0, 1, 2, 3, 4, 5, 6, 7:
	begin
		shift_ena = 1'b0;
		is_data_out = 1'b1;
		DATA_W = addr_reg[state];
	end
	8, 9, 10, 11, 12, 13, 14, 15:
	begin
		shift_ena = SCLK ^ addr_reg[0];
		is_data_out = !addr_reg[0];
		DATA_W = shift_out;
	end
	16:
	begin
		shift_ena = 1'b0;
		is_data_out = 1'b0;
		DATA_W = 1'bx;
	end
	17:
	begin
		shift_ena = ena;
		is_data_out = 1'b0;
		DATA_W = 1'bx;
	end
	default:
	begin
		shift_ena = 1'bx;
		is_data_out = 1'bx;
		DATA_W = 1'bx;
	end
endcase

assign ready = (state == 5'd17);
assign done = (state == 5'd16);
assign NRST = !state[4];

always @(posedge clk or negedge clrn)
begin
	if (!clrn)
	begin
		state <= 5'd17;
		addr_reg <= 0;
		SCLK <= 0;
	end
	else
	begin
		case (state)
			0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15:
			begin
				state <= state + SCLK;
				SCLK <= !SCLK;
			end
			16:
			begin
				addr_reg <= 1'bx;
				state <= 17;
				SCLK <= 0;
			end
			17:
			begin
				addr_reg <= addr;
				if (ena)
					state <= 0;
				SCLK <= 0;
			end
			default:
			begin
				addr_reg <= 1'bx;
				state <= 1'bx;
				SCLK <= 1'bx;
			end
		endcase
	end
end
	
endmodule
