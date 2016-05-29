module controller
(
	input clk, clrn,
	
	output reg [3:0] ram_addr,
	output reg [7:0] ram_w,
	output reg ram_we,

	output reg [7:0] rtc_addr,
	output reg [7:0] rtc_w,
	input [7:0] rtc_r,
	output reg rtc_ena,
	input rtc_done,
	
	input [3:0] key_down,
	input [3:0] key_state,
	
	output reg [5:0] blink_mask,
	output [3:0] led_data,
	output reg [1:0] page
);

localparam
	S_INIT = 0,
	S_DISABLE_WP = 1,
	S_CHECK_CH = 2,
	S_RESET_CH = 3,
	S_CLOCK = 4,
	S_ADJUST = 5,
	S_ADJUST_INC = 6,
	S_ADJUST_DEC = 7;

localparam
	SEC = 3'd0,
	MIN = 3'd1,
	HOUR = 3'd2,
	DATE = 3'd3,
	MONTH = 3'd4,
	YEAR = 3'd5;

reg [3:0] state, next_state;
reg [2:0] cursor, next_cursor, adj_cursor, next_adj_cursor;
reg [2:0] day_of_week;
reg [7:0] days_in_month;
reg transition;

function [7:0] get_rtc_addr(input [2:0] cursor, input read);
begin
	case (cursor)
		SEC: get_rtc_addr = 8'h80;
		MIN: get_rtc_addr = 8'h82;
		HOUR: get_rtc_addr = 8'h84;
		DATE: get_rtc_addr = 8'h86;
		MONTH: get_rtc_addr = 8'h88;
		YEAR: get_rtc_addr = 8'h8c;
		default:
			get_rtc_addr = 8'hxx;
	endcase
	get_rtc_addr[0] = read;
end
endfunction

function [2:0] get_next_cursor(input [2:0] cursor);
case (cursor)
	SEC: get_next_cursor = MIN;
	MIN: get_next_cursor = HOUR;
	HOUR: get_next_cursor = DATE;
	DATE: get_next_cursor = MONTH;
	MONTH: get_next_cursor = YEAR;
	YEAR: get_next_cursor = SEC;
	default:
		get_next_cursor = 1'bx;
endcase
endfunction

function [7:0] bcd_inc(input [7:0] value, min, max);
begin
	if (value == max)
		bcd_inc = min;
	else if (value[3:0] == 4'h9)
		bcd_inc = {value[7:4] + 4'h1, 4'h0};
	else
		bcd_inc = {value[7:4], value[3:0] + 4'h1};
end
endfunction

function [7:0] bcd_dec(input [7:0] value, min, max);
begin
	if (value == min)
		bcd_dec = max;
	else if (value[3:0] == 4'h0)
		bcd_dec = {value[7:4] - 4'h1, 4'h9};
	else
		bcd_dec = {value[7:4], value[3:0] - 4'h1};
end
endfunction

function [7:0] f_adjust_max(input [3:0] cursor);
case (cursor)
	SEC, MIN: f_adjust_max = 8'h59;
	HOUR: f_adjust_max = 8'h23;
	DATE: f_adjust_max = days_in_month;
	MONTH: f_adjust_max = 8'h12;
	YEAR: f_adjust_max = 8'h99;
	default: f_adjust_max = 8'hxx;
endcase
endfunction

function [7:0] f_adjust_min(input [3:0] cursor);
case (cursor)
	SEC, MIN, HOUR: f_adjust_min = 8'h00;
	DATE, MONTH: f_adjust_min = 8'h01;
	YEAR: f_adjust_min = 8'h00;
	default: f_adjust_min = 8'hxx;
endcase
endfunction

wire adjust_max = f_adjust_max(adj_cursor);
wire adjust_min = f_adjust_min(adj_cursor);

always @*
case (state)
	S_CLOCK, S_ADJUST, S_ADJUST_INC, S_ADJUST_DEC:
		next_cursor = get_next_cursor(cursor);
	default:
		next_cursor = SEC;
endcase

always @*
case (state)
	S_DISABLE_WP, S_CHECK_CH, S_RESET_CH,
	S_CLOCK, S_ADJUST, S_ADJUST_INC, S_ADJUST_DEC:
		transition = rtc_done;
	default:
		transition = 1;
endcase

always @*
begin
case (state)
	S_INIT:
	begin
		rtc_addr = 8'hxx;
		rtc_w = 8'hxx;
		rtc_ena = 1'b0;
		next_state = S_DISABLE_WP;
	end
	S_DISABLE_WP:
	begin
		rtc_addr = 8'h8e;
		rtc_w = 8'h00;
		rtc_ena = 1'b1;
		next_state = S_CHECK_CH;
	end
	S_CHECK_CH:
	begin
		rtc_addr = 8'h81;
		rtc_w = 8'h00;
		rtc_ena = 1'b1;
		next_state = rtc_r[7] ? S_RESET_CH : S_CLOCK;
	end
	S_RESET_CH:
	begin
		rtc_addr = 8'h80;
		rtc_w = {1'b0, rtc_r[6:0]};
		rtc_ena = 1'b1;
		next_state = S_CLOCK;
	end
	S_CLOCK:
	begin
		rtc_addr = get_rtc_addr(cursor, 1);
		rtc_w = 8'hxx;
		rtc_ena = 1'b1;
		next_state = key_pressed[3] ? S_ADJUST : S_CLOCK;
	end
	S_ADJUST:
	begin
		rtc_ena = 1'b1;
		if (cursor == MONTH && rtc_r > days_in_month) // just read DATE
		begin // fix date
			rtc_addr = get_rtc_addr(DATE, 0);
			rtc_w = days_in_month;
		end
		else
		begin
			rtc_addr = get_rtc_addr(cursor, 1);
			rtc_w = 8'hxx;
		end
		if (key_pressed[3])
			next_state = S_CLOCK;
		else if (key_pressed[1])
			next_state = S_ADJUST_INC;
		else if (key_pressed[0])
			next_state = S_ADJUST_DEC;
		else 
			next_state = S_ADJUST;
	end
	S_ADJUST_INC:
	begin
		if (cursor == get_next_cursor(adj_cursor))
		begin
			rtc_addr = get_rtc_addr(adj_cursor, 0);
			rtc_w = bcd_inc(rtc_r, adjust_min, adjust_max);
			rtc_ena = 1'b1;
			next_state = S_ADJUST;
		end
		else
		begin
			rtc_addr = get_rtc_addr(cursor, 1);
			rtc_w = 8'hxx;
			rtc_ena = 1'b1;
			next_state = S_ADJUST_INC;
		end
	end
	S_ADJUST_DEC:
	begin
		if (cursor == get_next_cursor(adj_cursor))
		begin
			rtc_addr = get_rtc_addr(adj_cursor, 0);
			rtc_w = bcd_dec(rtc_r, adjust_min, adjust_max);
			rtc_ena = 1'b1;
			next_state = S_ADJUST;
		end
		else
		begin
			rtc_addr = get_rtc_addr(cursor, 1);
			rtc_w = 8'hxx;
			rtc_ena = 1'b1;
			next_state = S_ADJUST_DEC;
		end
	end
	default:
	begin
		rtc_addr = 8'hxx;
		rtc_w = 8'hxx;
		rtc_ena = 1'b0;
		next_state = 1'bx;
	end
endcase
end

reg [3:0] key_pressed;

always @(posedge clk, negedge clrn)
begin
	if (!clrn)
	begin
		state <= S_INIT;
		cursor <= SEC;
		adj_cursor <= SEC;
		key_pressed <= 0;
	end
	else
	begin
		if (transition)
		begin
			key_pressed <= key_down;
			cursor <= next_cursor;
			adj_cursor <= next_adj_cursor;
			state <= next_state;
		end
		else
			key_pressed <= key_pressed | key_down;
	end
end

// Adjusting time
always @*
case (state)
	S_CLOCK:
		next_adj_cursor = key_state[2] ? SEC : DATE;
	S_ADJUST, S_ADJUST_INC, S_ADJUST_DEC:
		if (key_pressed[2])
			next_adj_cursor = get_next_cursor(adj_cursor);
		else
			next_adj_cursor = adj_cursor;
	default:
		next_adj_cursor = SEC;
endcase

always @*
case (state)
	S_ADJUST, S_ADJUST_INC, S_ADJUST_DEC:
		case (adj_cursor)
			SEC, DATE: blink_mask = 6'b000011;
			MIN, MONTH: blink_mask = 6'b001100;
			HOUR, YEAR:	blink_mask = 6'b110000;
			default: blink_mask = 1'bx;
		endcase
	default:
		blink_mask = 6'b000000;
endcase

// Display page
always @*
case (state)
	S_CLOCK:
		page = !key_state[2];
	S_ADJUST, S_ADJUST_INC, S_ADJUST_DEC:
		case (adj_cursor)
			SEC, MIN, HOUR: page = 0;
			DATE, MONTH, YEAR: page = 1;
			default: page = 1'bx;
		endcase
	default:
		page = 0;
endcase
		
// Writing to RAM
always @*
begin
	if (rtc_addr[0] && rtc_done)
	begin
		ram_we = 1'b1;
		ram_w = rtc_r;
		case (cursor)
			SEC: ram_addr = 4'h0;
			MIN: ram_addr = 4'h1;
			HOUR: ram_addr = 4'h2;
			DATE: ram_addr = 4'h4;
			MONTH: ram_addr = 4'h5;
			YEAR: ram_addr = 4'h6;
			default:
				ram_addr = 4'hx;
		endcase
	end
	else
	begin
		ram_we = 1'b0;
		ram_w = 8'hxx;
		ram_addr = 4'hx;
	end
end

// Date information

wire [2:0] dateinfo_day;
//wire dateinfo_leap_year;
wire [7:0] dateinfo_days_in_month;
dateinfo_2 dateinfo0
(
	.clk(clk),
	.ena(rtc_done),
	.data(rtc_r),
	.day(dateinfo_day),
//	.leap_year(dateinfo_leap_year),
	.days_in_month(dateinfo_days_in_month)
);

always @(posedge clk)
	if (cursor == SEC)
	begin
		day_of_week <= dateinfo_day;
//		leap_year <= dateinfo_leap_year;
		days_in_month <= dateinfo_days_in_month;
	end
assign led_data[2:0] = day_of_week;


endmodule
