module toplevel
(
	input CLOCK, IO3,
	input KEY4, KEY3, KEY2, KEY1,
	output [7:0] DIG,
	output [5:0] SEL,
	output [3:0] LED,
	output RTC_SCLK, RTC_NRST,
	inout RTC_DATA
);

wire RESET = IO3;

wire clk, clk_scan;

pll pll0
(
	.inclk0(CLOCK),
	.c0(clk),
	.c1(clk_scan)
);
/*
wire clk_1;
wire [10:0] fdiv_q;
counter #(11) fdiv(clk_scan, 1, 1, 1, , fdiv_q);
assign clk_1 = fdiv_q[9];
*/

wire [3:0] disp_addr, ctl_addr;
wire [7:0] disp_data, ctl_data;
wire ctl_we;

wire [7:0] rtc_addr, rtc_w, rtc_r;
wire rtc_ena;
wire 	rtc_ready, rtc_done;

wire [3:0] key_state, key_down;

wire [5:0] blink_mask;
wire [3:0] led_data;
wire [1:0] page;

memory #(.AddrWidth(4), .DataWidth(8)) ram0
(
	.clk(clk),
	.addr_w(ctl_addr),
	.addr_r(disp_addr),
	.we(ctl_we),
	.d(ctl_data),
	.q(disp_data)
);

controller ctl0
(
	.clk(clk),
	.clrn(RESET),
	.ram_addr(ctl_addr),
	.ram_w(ctl_data),
	.ram_we(ctl_we),
	.rtc_addr(rtc_addr),
	.rtc_w(rtc_w),
	.rtc_r(rtc_r),
	.rtc_ena(rtc_ena),
	.rtc_done(rtc_done),
	.key_down(key_down),
	.key_state(key_state),
	.blink_mask(blink_mask),
	.led_data(led_data),
	.page(page)
);

ds1302_2 rtc0
(
	.clk(clk),
	.clrn(RESET),
	.addr(rtc_addr),
	.w(rtc_w),
	.r(rtc_r),
	.ena(rtc_ena),
	.ready(),
	.done(rtc_done),
	.SCLK(RTC_SCLK),
	.NRST(RTC_NRST),
	.DATA(RTC_DATA)
);

dispctl dispctl0
(
	.clk(clk_scan),
	.clrn(RESET),
	.page(page),
	.ram_addr(disp_addr),
	.ram_r(disp_data),
	.led_data(led_data),
	.blink_mask(blink_mask),
	.DIG(DIG),
	.SEL(SEL),
	.LED(LED)
);

keysctl keysctl0
(
	.clk(clk),
	.clrn(RESET),
	.pins({KEY4, KEY3, KEY2, KEY1}),
	.state(key_state),
	.edge_p(),
	.edge_n(key_down)
);
endmodule
