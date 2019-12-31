// `define NES_OWNS_PORT

//-----------------------------------------------------------------
// TOP
//-----------------------------------------------------------------
module top
(
     input           SYSCLK
    ,inout           pano_button
    ,output          GMII_RST_N
    ,output          led_red
    ,inout           led_green
    ,inout           led_blue

    // UART
    ,input           uart_txd_i
    ,output          uart_rxd_o

    // SPI-Flash
    ,output          flash_sck_o
    ,output          flash_cs_o
    ,output          flash_si_o
    ,input           flash_so_i

     // WM8750 Codec
     ,output codec_mclk
     ,output codec_bclk
     ,output codec_dacdata
     ,output codec_daclrck
     ,input  codec_adcdata
     ,output codec_adclrck
     ,inout  codec_scl
     ,inout  codec_sda

     ,output wire        HSYNC
     ,output wire        VSYNC
     ,output wire        DE
     ,output wire        DVI_CLK_P
     ,output wire        DVI_CLK_N
     ,output wire [11:0] DVI_DATA
     ,output wire        SCL
     ,output wire        SDA
     ,output wire        V1_RESET_N

);

// Generate 100 Mhz and 25 Mhz clocks from 125 Mhz input clock
wire        pll_locked;

IBUFG clkin1_buf
(   .O (clkin1),
    .I (SYSCLK)
);

PLL_BASE
    #(.BANDWIDTH              ("OPTIMIZED"),
      .CLKFBOUT_MULT          (24),
      .CLKFBOUT_PHASE         (0.000),
      .CLK_FEEDBACK           ("CLKFBOUT"),
      .CLKIN_PERIOD           (8.000),
      .COMPENSATION           ("SYSTEM_SYNCHRONOUS"),
      .DIVCLK_DIVIDE          (5),
      .REF_JITTER             (0.010),
      .CLKOUT0_DIVIDE         (6),
      .CLKOUT0_DUTY_CYCLE     (0.500),
      .CLKOUT0_PHASE          (0.000),
      .CLKOUT1_DIVIDE         (24),
      .CLKOUT1_DUTY_CYCLE     (0.500),
      .CLKOUT1_PHASE          (0.000),
      .CLKOUT2_DIVIDE         (50),
      .CLKOUT2_DUTY_CYCLE     (0.500),
      .CLKOUT2_PHASE          (0.000)
    )
    pll_base_inst
      // Output clocks
     (.CLKFBOUT              (clkfbout),
      .CLKOUT0               (clkout100),
      .CLKOUT1               (clkout25),
      .CLKOUT2               (clkout12),
      .CLKOUT3               (),
      .CLKOUT4               (),
      .CLKOUT5               (),
      // Status and control signals
      .LOCKED                (pll_locked),
      .RST                   (RESET),
       // Input clock control
      .CLKFBIN               (clkfbout_buf),
      .CLKIN                 (clkin1)
);

// Output buffering
//-----------------------------------
BUFG clkf_buf
 (.O (clkfbout_buf),
  .I (clkfbout));

BUFG clk100_buf
  (.O (clk100),
   .I (clkout100));

BUFG clk25_buf
(.O (clk25),
 .I (clkout25));

BUFG clk12_buf
(.O (clk12),
 .I (clkout12));


//-----------------------------------------------------------------
// Reset
//-----------------------------------------------------------------
wire rst;

reset_gen
u_rst
(
    .clk_i(clk100),
    .rst_o(rst)
);

//-----------------------------------------------------------------
// Core
//-----------------------------------------------------------------
wire        dbg_txd_w;
wire        uart_txd_w;

wire        spi_clk_w;
wire        spi_so_w;
wire        spi_si_w;
wire [7:0]  spi_cs_w;

wire [31:0] gpio_in_w;
wire [31:0] gpio_out_w;
wire [31:0] gpio_out_en_w;

wire nes_tx_o;
wire nes_txd_i;

fpga_top
#(
    .CLK_FREQ(25000000)
   ,.BAUDRATE(1000000)   // SoC UART baud rate
   ,.UART_SPEED(1000000) // Debug bridge UART baud (should match BAUDRATE)
   ,.C_SCK_RATIO(1)      // SPI clock divider (M25P128 maxclock = 54 Mhz)
   ,.CPU("riscv")        // riscv or armv6m
)
u_top
(
     .clk_i(clk25)
    ,.rst_i(rst)

    ,.dbg_rxd_o(dbg_txd_w)
    ,.dbg_txd_i(uart_txd_i)

    ,.uart_tx_o(uart_txd_w)
    ,.uart_rx_i(uart_txd_i)
    ,.nes_uart_rx_i(nes_txd_i)

    ,.spi_clk_o(spi_clk_w)
    ,.spi_mosi_o(spi_si_w)
    ,.spi_miso_i(spi_so_w)
    ,.spi_cs_o(spi_cs_w)

    ,.gpio_input_i(gpio_in_w)
    ,.gpio_output_o(gpio_out_w)
    ,.gpio_output_enable_o(gpio_out_en_w)

    ,.nes_tx_o(nes_tx_o)
);

//-----------------------------------------------------------------
// SPI Flash
//-----------------------------------------------------------------
assign flash_sck_o = spi_clk_w;
assign flash_si_o  = spi_si_w;
assign flash_cs_o  = spi_cs_w[0];
assign spi_so_w    = flash_so_i;

//-----------------------------------------------------------------
// GPIO bits
// 0: Not implmented
// 1: Pano button
// 2: Output only - red LED
// 3: In/out - green LED
// 4: In/out - blue LED
// 5: Wolfson codec SDA
// 6: Wolfson codec SCL
// 9...31: Not implmented
//-----------------------------------------------------------------

assign gpio_in_w[0]  = gpio_out_w[0];

assign pano_button = gpio_out_en_w[1]  ? gpio_out_w[1]  : 1'bz;
assign gpio_in_w[1]  = pano_button;

assign led_red = gpio_out_w[2];
assign gpio_in_w[2]  = led_red;

assign led_green = gpio_out_en_w[3]  ? gpio_out_w[3]  : 1'bz;
assign gpio_in_w[3]  = led_green;

assign led_blue = gpio_out_en_w[4]  ? gpio_out_w[4]  : 1'bz;
assign gpio_in_w[4]  = led_blue;

assign codec_sda = gpio_out_en_w[5]  ? gpio_out_w[5]  : 1'bz;
assign gpio_in_w[5]  = codec_sda;


assign codec_scl = gpio_out_en_w[6]  ? gpio_out_w[6]  : 1'bz;
assign gpio_in_w[6]  = codec_scl;


genvar i;
generate
for (i=7; i < 32; i=i+1)
begin
    assign gpio_in_w[i]  = 1'b0;
end
endgenerate

`ifndef NES_OWNS_PORT
//-----------------------------------------------------------------
// UART Tx combine
//-----------------------------------------------------------------
// Xilinx placement pragmas:
//synthesis attribute IOB of uart_rxd_o is "TRUE"
reg txd_q;

always @ (posedge clk100 or posedge rst)
if (rst)
    txd_q <= 1'b1;
else
    txd_q <= dbg_txd_w & uart_txd_w;

// 'OR' two UARTs together
assign uart_rxd_o  = txd_q;
`endif

// Audio
reset_gen reset_gen_12 (
    .clk_i(clk12)
    ,.rst_o(reset12)
);

wire [15:0] audio_o;

audio audio_out (
    .clk12(clk12)
    ,.reset12(reset12)
    ,.codec_dacdat(codec_dacdata)
    ,.codec_daclrc(codec_daclrck)
    ,.codec_adcdat(codec_adcdata)
    ,.codec_adclrc(codec_adclrck)
    ,.audio_right_sample(audio_o)
    ,.audio_left_sample(audio_o)
);

ODDR2 mclk_buf (
    .S(1'b0),
    .R(1'b0),
    .D0(1'b1),
    .D1(1'b0),
    .C0(clk25),
    .C1(!clk25),
    .CE(1'b1),
    .Q(codec_mclk)
);

ODDR2 bclk_buf (
    .S(1'b0),
    .R(1'b0),
    .D0(1'b1),
    .D1(1'b0),
    .C0(clk12),
    .C1(!clk12),
    .CE(1'b1),
    .Q(codec_bclk)
);

// NES

nes_top nes_top_u (
    .CLK_25MHZ(clk25)         // 25MHz system clock signal
    ,.CLK_100MHZ(clk100)
    ,.pll_locked(pll_locked)
    ,.CONSOLE_RESET_N(1'b1)   // console reset
`ifdef NES_OWNS_PORT
    ,.RXD(uart_txd_i)           // rs-232 rx signal
    ,.TXD(uart_rxd_o)          // rs-232 tx signal
`else
    ,.RXD(nes_tx_o)           // rs-232 rx signal
    ,.TXD(nes_txd_i)          // rs-232 tx signal
`endif
    ,.HSYNC(HSYNC)
    ,.VSYNC(VSYNC)
    ,.DE(DE)
    ,.DVI_CLK_P(DVI_CLK_P)
    ,.DVI_CLK_N(DVI_CLK_N)
    ,.DVI_DATA(DVI_DATA)
    ,.SCL(SCL)
    ,.SDA(SDA)
    ,.V1_RESET_N(V1_RESET_N)
    ,.audio_out(audio_o)
);

//-----------------------------------------------------------------
// Tie-offs
//-----------------------------------------------------------------

// Must remove reset from the Ethernet Phy for 125 Mhz input clock.
// See https://github.com/tomverbeure/panologic-g2
assign GMII_RST_N = 1'b1;

endmodule
