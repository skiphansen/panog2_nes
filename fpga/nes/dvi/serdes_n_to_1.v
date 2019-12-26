`timescale 1ps/1ps

module serdes_n_to_1 (ioclk, serdesstrobe, reset, gclk, datain, iob_data_out);

parameter integer SF = 8;

input ioclk;
input serdesstrobe;
input reset;
input gclk;
input [SF-1:0] datain;
output iob_data_out;

wire cascade_di;
wire cascade_do;
wire cascade_ti;
wire cascade_to;
wire [8:0] mdatain;

genvar i ;
generate
  for (i = 0; i <= (SF - 1); i = i + 1)
    begin : loop0
      assign mdatain[i] = datain[i] ;
    end
endgenerate

generate
  for (i = (SF); i <= 8; i = i + 1)
    begin : loop1
      assign mdatain[i] = 1'b0 ;
    end
endgenerate

OSERDES2 #(
  .DATA_WIDTH   (SF),
  .DATA_RATE_OQ ("SDR"),
  .DATA_RATE_OT ("SDR"),
  .SERDES_MODE  ("MASTER"),
  .OUTPUT_MODE  ("DIFFERENTIAL")
) oserdes_m (
  .OQ        (iob_data_out),
  .OCE       (1'b1),
  .CLK0      (ioclk),
  .CLK1      (1'b0),
  .IOCE      (serdesstrobe),
  .RST       (reset),
  .CLKDIV    (gclk),
  .D4        (mdatain[7]),
  .D3        (mdatain[6]),
  .D2        (mdatain[5]),
  .D1        (mdatain[4]),
  .TQ        (),
  .T1        (1'b0),
  .T2        (1'b0),
  .T3        (1'b0),
  .T4        (1'b0),
  .TRAIN     (1'b0),
  .TCE       (1'b1),
  .SHIFTIN1  (1'b1),
  .SHIFTIN2  (1'b1),
  .SHIFTIN3  (cascade_do),
  .SHIFTIN4  (cascade_to),
  .SHIFTOUT1 (cascade_di),
  .SHIFTOUT2 (cascade_ti),
  .SHIFTOUT3 (),
  .SHIFTOUT4 ()
);

OSERDES2 #(
  .DATA_WIDTH   (SF),
  .DATA_RATE_OQ ("SDR"),
  .DATA_RATE_OT ("SDR"),
  .SERDES_MODE  ("SLAVE"),
  .OUTPUT_MODE  ("DIFFERENTIAL")
) oserdes_s (
  .OQ        (),
  .OCE       (1'b1),
  .CLK0      (ioclk),
  .CLK1      (1'b0),
  .IOCE      (serdesstrobe),
  .RST       (reset),
  .CLKDIV    (gclk),
  .D4        (mdatain[3]),
  .D3        (mdatain[2]),
  .D2        (mdatain[1]),
  .D1        (mdatain[0]),
  .TQ        (),
  .T1        (1'b0),
  .T2        (1'b0),
  .T3        (1'b0),
  .T4        (1'b0),
  .TRAIN     (1'b0),
  .TCE       (1'b1),
  .SHIFTIN1  (cascade_di),
  .SHIFTIN2  (cascade_ti),
  .SHIFTIN3  (1'b1),
  .SHIFTIN4  (1'b1),
  .SHIFTOUT1 (),
  .SHIFTOUT2 (),
  .SHIFTOUT3 (cascade_do),
  .SHIFTOUT4 (cascade_to)
);

endmodule
