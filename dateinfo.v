module dateinfo
(
	input [7:0] year, month, date, // BCD
	output reg [2:0] day, // 0 - Sunday, 1 - Monday ...
	output reg leap_year, // 0 - Non-leap, 1 - leap
	output reg [7:0] days_in_month // BCD
);

reg [2:0] offset_y, offset_m, offset_d;
reg jan_or_feb;

always @*
case (date)
	8'h7, 8'h14, 8'h21, 8'h28:
		offset_d = 0;
	8'h1, 8'h8, 8'h15, 8'h22, 8'h29:
		offset_d = 1;
	8'h2, 8'h9, 8'h16, 8'h23, 8'h30:
		offset_d = 2;
	8'h3, 8'h10, 8'h17, 8'h24, 8'h31:
		offset_d = 3;
	8'h4, 8'h11, 8'h18, 8'h25:
		offset_d = 4;
	8'h5, 8'h12, 8'h19, 8'h26:
		offset_d = 5;
	8'h6, 8'h13, 8'h20, 8'h27:
		offset_d = 6;
	default:
		offset_d = 1'bx;
endcase

always @*
case (month)
	8'h1, 8'h10:
		offset_m = 0;
	8'h5:
		offset_m = 1;
	8'h8:
		offset_m = 2;
	8'h2, 8'h3, 8'h11:
		offset_m = 3;
	8'h6:
		offset_m = 4;
	8'h9:
		offset_m = 5;
	8'h4, 8'h7:
		offset_m = 6;
	default:
		offset_m = 1'bx;
endcase

always @*
begin
	case (month)
		8'h1, 8'h2:
			jan_or_feb = 1;
		default:
			jan_or_feb = 0;
	endcase
	case (year[3:0])
		4'h0, 4'h4, 4'h8:
			leap_year = !year[4];
		4'h2, 4'h6:
			leap_year = year[4];
		default:
			leap_year = 0;
	endcase
	case (month)
		8'h1, 8'h3, 8'h5, 8'h7, 8'h8, 8'h10, 8'h12:
			days_in_month = 8'h31;
		8'h4, 8'h6, 8'h9, 8'h11:
			days_in_month = 8'h30;
		8'h2:
			days_in_month = leap_year ? 8'h29 : 8'h28;
		default:
			days_in_month = 1'bx;
	endcase
end

always @*
case(year)
	8'h0, 8'h5, 8'h11, 8'h22, 8'h28, 8'h33, 8'h39, 8'h50, 8'h56, 8'h61, 8'h67, 8'h78, 8'h84, 8'h89, 8'h95:
		offset_y = 0;
	8'h6, 8'h12, 8'h17, 8'h23, 8'h34, 8'h40, 8'h45, 8'h51, 8'h62, 8'h68, 8'h73, 8'h79, 8'h90, 8'h96:
		offset_y = 1;
	8'h1, 8'h7, 8'h18, 8'h24, 8'h29, 8'h35, 8'h46, 8'h52, 8'h57, 8'h63, 8'h74, 8'h80, 8'h85, 8'h91:
		offset_y = 2;
	8'h2, 8'h8, 8'h13, 8'h19, 8'h30, 8'h36, 8'h41, 8'h47, 8'h58, 8'h64, 8'h69, 8'h75, 8'h86, 8'h92, 8'h97:
		offset_y = 3;
	8'h3, 8'h14, 8'h20, 8'h25, 8'h31, 8'h42, 8'h48, 8'h53, 8'h59, 8'h70, 8'h76, 8'h81, 8'h87, 8'h98:
		offset_y = 4;
	8'h4, 8'h9, 8'h15, 8'h26, 8'h32, 8'h37, 8'h43, 8'h54, 8'h60, 8'h65, 8'h71, 8'h82, 8'h88, 8'h93, 8'h99:
		offset_y = 5;
	8'h10, 8'h16, 8'h21, 8'h27, 8'h38, 8'h44, 8'h49, 8'h55, 8'h66, 8'h72, 8'h77, 8'h83, 8'h94:
		offset_y = 6;
	default:
		offset_y = 1'bx;
endcase

reg [4:0] day_tmp;

always @*
begin
	day_tmp = offset_y + offset_m + (leap_year && !jan_or_feb) + offset_d;
	// day = (day_tmp + 5) % 7
	case (day_tmp)
		0, 7, 14:
			day = 5;
		1, 8, 15:
			day = 6;
		2, 9, 16:
			day = 0;
		3, 10, 17:
			day = 1;
		4, 11, 18:
			day = 2;
		5, 12, 19:
			day = 3;
		6, 13:
			day = 4;
		default:
			day = 1'bx;
	endcase
end

endmodule
