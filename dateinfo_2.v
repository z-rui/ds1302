module dateinfo_2
(
	input clk, ena,
	input [7:0] data, // BCD - date, month, year
	output reg [2:0] day, // 0 - Sunday, 1 - Monday ...
	output reg leap_year, // 0 - Non-leap, 1 - leap
	output reg [7:0] days_in_month // BCD
);

function [2:0] offset_date(input [7:0] date);
case (date)
	8'h7, 8'h14, 8'h21, 8'h28:
		offset_date = 0;
	8'h1, 8'h8, 8'h15, 8'h22, 8'h29:
		offset_date = 1;
	8'h2, 8'h9, 8'h16, 8'h23, 8'h30:
		offset_date = 2;
	8'h3, 8'h10, 8'h17, 8'h24, 8'h31:
		offset_date = 3;
	8'h4, 8'h11, 8'h18, 8'h25:
		offset_date = 4;
	8'h5, 8'h12, 8'h19, 8'h26:
		offset_date = 5;
	8'h6, 8'h13, 8'h20, 8'h27:
		offset_date = 6;
	default:
		offset_date = 1'bx;
endcase
endfunction

function [2:0] offset_month(input [7:0] month);
case (month)
	8'h1, 8'h10:
		offset_month = 0;
	8'h5:
		offset_month = 1;
	8'h8:
		offset_month = 2;
	8'h2, 8'h3, 8'h11:
		offset_month = 3;
	8'h6:
		offset_month = 4;
	8'h9:
		offset_month = 5;
	8'h4, 8'h7:
		offset_month = 6;
	default:
		offset_month = 1'bx;
endcase
endfunction

function jan_or_feb(input [7:0] month);
	jan_or_feb = (month == 8'h1 || month == 8'h2);
endfunction

function f_leap_year(input [7:0] year);
case (year[3:0])
	4'h0, 4'h4, 4'h8:
		f_leap_year = !year[4];
	4'h2, 4'h6:
		f_leap_year = year[4];
	default:
		f_leap_year = 0;
endcase
endfunction

function [7:0] f_days_in_month(input [7:0] month);
case (month)
	8'h1, 8'h3, 8'h5, 8'h7, 8'h8, 8'h10, 8'h12:
		f_days_in_month = 8'h31;
	8'h4, 8'h6, 8'h9, 8'h11:
		f_days_in_month = 8'h30;
	8'h2:
		//days_in_month = leap_year ? 8'h29 : 8'h28;
		f_days_in_month = 8'h28; // XXX please do manual fix
	default:
		f_days_in_month = 1'bx;
endcase
endfunction

function [2:0] offset_year(input [7:0] year);
case(year)
	8'h0, 8'h5, 8'h11, 8'h22, 8'h28, 8'h33, 8'h39, 8'h50, 8'h56, 8'h61, 8'h67, 8'h78, 8'h84, 8'h89, 8'h95:
		offset_year = 0;
	8'h6, 8'h12, 8'h17, 8'h23, 8'h34, 8'h40, 8'h45, 8'h51, 8'h62, 8'h68, 8'h73, 8'h79, 8'h90, 8'h96:
		offset_year = 1;
	8'h1, 8'h7, 8'h18, 8'h24, 8'h29, 8'h35, 8'h46, 8'h52, 8'h57, 8'h63, 8'h74, 8'h80, 8'h85, 8'h91:
		offset_year = 2;
	8'h2, 8'h8, 8'h13, 8'h19, 8'h30, 8'h36, 8'h41, 8'h47, 8'h58, 8'h64, 8'h69, 8'h75, 8'h86, 8'h92, 8'h97:
		offset_year = 3;
	8'h3, 8'h14, 8'h20, 8'h25, 8'h31, 8'h42, 8'h48, 8'h53, 8'h59, 8'h70, 8'h76, 8'h81, 8'h87, 8'h98:
		offset_year = 4;
	8'h4, 8'h9, 8'h15, 8'h26, 8'h32, 8'h37, 8'h43, 8'h54, 8'h60, 8'h65, 8'h71, 8'h82, 8'h88, 8'h93, 8'h99:
		offset_year = 5;
	8'h10, 8'h16, 8'h21, 8'h27, 8'h38, 8'h44, 8'h49, 8'h55, 8'h66, 8'h72, 8'h77, 8'h83, 8'h94:
		offset_year = 6;
	default:
		offset_year = 1'bx;
endcase
endfunction

function [2:0] day_of_week(input [4:0] offset_sum);
begin
	// sum = offset_y + offset_m + (leap_year && !jan_or_feb) + offset_date;
	// day_of_week = (offset_sum + 5) % 7
	case (offset_sum)
		0, 7, 14:
			day_of_week = 5;
		1, 8, 15:
			day_of_week = 6;
		2, 9, 16:
			day_of_week = 0;
		3, 10, 17:
			day_of_week = 1;
		4, 11, 18:
			day_of_week = 2;
		5, 12, 19:
			day_of_week = 3;
		6, 13:
			day_of_week = 4;
		default:
			day_of_week = 1'bx;
	endcase
end
endfunction

reg [2:0] stage1; // max 6
reg [3:0] stage2; // max 15
reg stage2_1; // max 1
reg [7:0] stage2_2; // BCD

always @(posedge clk)
begin
	if (ena)
	begin
		stage1 <= offset_date(data);
		stage2 <= stage1 + offset_month(data);
		stage2_1 <= jan_or_feb(data);
		stage2_2 <= f_days_in_month(data);
		day <= day_of_week(stage2 + offset_year(data) + (f_leap_year(data) && !stage2_1));
		days_in_month <= stage2_2 | (f_leap_year(data) && !stage2_2[4]);
		leap_year <= f_leap_year(data);
	end
end

endmodule
