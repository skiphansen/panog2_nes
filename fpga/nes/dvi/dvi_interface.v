
module dvi_interface (
  Clk,                // TFT Clock
  Rst,                // TFT Reset
  hsync_in,           // Hsync input
  vsync_in,           // Vsync input
  de_in,              // Data Enable
  red_in,             // RED pixel data 
  green_in,           // Green pixel data
  blue_in,            // Blue pixel data
  HSYNC,              // TFT Hsync
  VSYNC,              // TFT Vsync
  DE,                 // TFT data enable
  DVI_CLK_P,          // TFT DVI differential clock
  DVI_CLK_N,          // TFT DVI differential clock
  DVI_DATA,           // TFT DVI pixel data
  
  //IIC init state machine for Chrontel CH7301C
  I2C_done,           // I2C configuration done
  SCL,                // I2C Clock
  SDA                 // I2C Data
);

// Inputs Ports
  input             Clk;
  input             Rst;
  input             hsync_in;                          
  input             vsync_in;                          
  input             de_in;     
  input    [7:0]    red_in;
  input    [7:0]    green_in;
  input    [7:0]    blue_in;
  
// Output Ports    
  output            HSYNC;
  output            VSYNC;
  output            DE;
  output            DVI_CLK_P;
  output            DVI_CLK_N;
  output   [11:0]   DVI_DATA;

// I2C Ports
  output            I2C_done;
  output            SCL;
  output            SDA;

  // HSYNC
  FDS FDS_HSYNC (.Q(HSYNC), 
                 .C(~Clk), 
                 .S(Rst), 
                 .D(hsync_in)); 

  // VSYNC
  FDS FDS_VSYNC (.Q(VSYNC), 
                 .C(~Clk), 
                 .S(Rst), 
                 .D(vsync_in));
                   
  // DE
  FDR FDR_DE    (.Q(DE),    
                 .C(~Clk), 
                 .R(Rst), 
                 .D(de_in));

  wire        iic_sda;
  wire        iic_scl;
  wire [11:0] dvi_data_a;
  wire [11:0] dvi_data_b;

  assign dvi_data_a[0]  = green_in[4];
  assign dvi_data_a[1]  = green_in[5];
  assign dvi_data_a[2]  = green_in[6];
  assign dvi_data_a[3]  = green_in[7];
  assign dvi_data_a[4]  = red_in[0];
  assign dvi_data_a[5]  = red_in[1];
  assign dvi_data_a[6]  = red_in[2];
  assign dvi_data_a[7]  = red_in[3];
  assign dvi_data_a[8]  = red_in[4];
  assign dvi_data_a[9]  = red_in[5];
  assign dvi_data_a[10] = red_in[6];
  assign dvi_data_a[11] = red_in[7];
  assign dvi_data_b[0]  = blue_in[0];
  assign dvi_data_b[1]  = blue_in[1];
  assign dvi_data_b[2]  = blue_in[2];
  assign dvi_data_b[3]  = blue_in[3];
  assign dvi_data_b[4]  = blue_in[4];
  assign dvi_data_b[5]  = blue_in[5];
  assign dvi_data_b[6]  = blue_in[6];
  assign dvi_data_b[7]  = blue_in[7];
  assign dvi_data_b[8]  = green_in[0];
  assign dvi_data_b[9]  = green_in[1];
  assign dvi_data_b[10] = green_in[2];
  assign dvi_data_b[11] = green_in[3];


  //// DVI Clock P
  ODDR2 CLKP_ODDR2 (.Q(DVI_CLK_P), 
                    .C0(Clk),
                    .C1(~Clk), 
                    .CE(1'b1), 
                    .R(Rst), 
                    .D0(1'b1), 
                    .D1(1'b0), 
                    .S(1'b0));
                      
  // DVI Clock N
  ODDR2 CLKN_ODDR2 (.Q(DVI_CLK_N), 
                    .C0(Clk),
                    .C1(~Clk), 
                    .CE(1'b1), 
                    .R(Rst), 
                    .D0(1'b0), 
                    .D1(1'b1), 
                    .S(1'b0));

  generate
    begin : gen_dvi_if
      genvar i;
      for (i=0;i<12;i=i+1) begin : replicate_tft_dvi_data
        ODDR2 ODDR2_DATA (.Q(DVI_DATA[i]),  
                          .C0(Clk), 
                          .C1(~Clk), 
                          .CE(1'b1), 
                          .R(~de_in|Rst), 
                          .D1(dvi_data_b[i]),      
                          .D0(dvi_data_a[i]),  
                          .S(1'b0));
      end 
    end 
  endgenerate  

  
  /////////////////////////////////////////////////////////////////////
  // IIC INIT COMPONENT INSTANTIATION for Chrontel CH-7301
  /////////////////////////////////////////////////////////////////////
  iic_init  iic_init (
    .Clk              (Clk),
    .Reset            (Rst),
    .SDA              (iic_sda),
    .SCL              (iic_scl),
    .Done             (I2C_done)
  );

  assign SDA = iic_sda ? 1'bz : 1'b0;
  assign SCL = iic_scl ? 1'bz : 1'b0;
/*
  i2c i2c_i (
    .clk        (Clk),
    .reset      (Rst),
    .scl        (SCL),
    .sda        (SDA),
    .init_done  (I2C_done)
  );
*/
endmodule
