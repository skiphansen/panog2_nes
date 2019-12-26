
module tft_interface (
    TFT_Clk,                // TFT Clock
    TFT_Rst,                // TFT Reset
    HSYNC,                  // Hsync input
    VSYNC,                  // Vsync input
    DE,                     // Data Enable
    RED,                    // RED pixel data 
    GREEN,                  // Green pixel data
    BLUE,                   // Blue pixel data
    TFT_HSYNC,              // TFT Hsync
    TFT_VSYNC,              // TFT Vsync
    TFT_DE,                 // TFT data enable
    TFT_VGA_CLK,            // TFT VGA clock
    TFT_VGA_R,              // TFT VGA Red pixel data 
    TFT_VGA_G,              // TFT VGA Green pixel data
    TFT_VGA_B,              // TFT VGA Blue pixel data
    TFT_DVI_CLK_P,          // TFT DVI differential clock
    TFT_DVI_CLK_N,          // TFT DVI differential clock
    TFT_DVI_DATA,           // TFT DVI pixel data
    
    //IIC init state machine for Chrontel CH7301C
    I2C_done,               // I2C configuration done
    SCL,                    // I2C Clock input 
    SDA                     // I2C data control
);

// Inputs Ports
    input             TFT_Clk;
    input             TFT_Rst;
    input             HSYNC;                          
    input             VSYNC;                          
    input             DE;     
    input    [7:0]    RED;
    input    [7:0]    GREEN;
    input    [7:0]    BLUE;
    
// Output Ports    
    output            TFT_HSYNC;
    output            TFT_VSYNC;
    output            TFT_DE;
    output            TFT_DVI_CLK_P;
    output            TFT_DVI_CLK_N;
    output   [11:0]   TFT_DVI_DATA;

// I2C Ports
    output            I2C_done;
    output            SCL;
    output            SDA;

    // HSYNC
    FDS FDS_HSYNC (.Q(TFT_HSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(HSYNC)); 

    // VSYNC
    FDS FDS_VSYNC (.Q(TFT_VSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(VSYNC));
                     
    // DE
    FDR FDR_DE    (.Q(TFT_DE),    
                   .C(~TFT_Clk), 
                   .R(TFT_Rst), 
                   .D(DE));

    wire        tft_iic_sda_t_i;
    wire        tft_iic_scl_t_i;
    wire [11:0] dvi_data_a;
    wire [11:0] dvi_data_b;

    assign dvi_data_a[0]  = GREEN[4];
    assign dvi_data_a[1]  = GREEN[5];
    assign dvi_data_a[2]  = GREEN[6];
    assign dvi_data_a[3]  = GREEN[7];
    assign dvi_data_a[4]  = RED[0];
    assign dvi_data_a[5]  = RED[1];
    assign dvi_data_a[6]  = RED[2];
    assign dvi_data_a[7]  = RED[3];
    assign dvi_data_a[8]  = RED[4];
    assign dvi_data_a[9]  = RED[5];
    assign dvi_data_a[10] = RED[6];
    assign dvi_data_a[11] = RED[7];
    assign dvi_data_b[0]  = BLUE[0];
    assign dvi_data_b[1]  = BLUE[1];
    assign dvi_data_b[2]  = BLUE[2];
    assign dvi_data_b[3]  = BLUE[3];
    assign dvi_data_b[4]  = BLUE[4];
    assign dvi_data_b[5]  = BLUE[5];
    assign dvi_data_b[6]  = BLUE[6];
    assign dvi_data_b[7]  = BLUE[7];
    assign dvi_data_b[8]  = GREEN[0];
    assign dvi_data_b[9]  = GREEN[1];
    assign dvi_data_b[10] = GREEN[2];
    assign dvi_data_b[11] = GREEN[3];


    //// DVI Clock P
    ODDR2 TFT_CLKP_ODDR2 (.Q(TFT_DVI_CLK_P), 
                        .C0(TFT_Clk),
                        .C1(~TFT_Clk), 
                        .CE(1'b1), 
                        .R(TFT_Rst), 
                        .D0(1'b1), 
                        .D1(1'b0), 
                        .S(1'b0));
                        
    // DVI Clock N
    ODDR2 TFT_CLKN_ODDR2 (.Q(TFT_DVI_CLK_N), 
                        .C0(TFT_Clk),
                        .C1(~TFT_Clk), 
                        .CE(1'b1), 
                        .R(TFT_Rst), 
                        .D0(1'b0), 
                        .D1(1'b1), 
                        .S(1'b0));

    generate
    begin : gen_dvi_if
      genvar i;
      for (i=0;i<12;i=i+1) begin : replicate_tft_dvi_data
        ODDR2 ODDR2_TFT_DATA (.Q(TFT_DVI_DATA[i]),  
                              .C0(TFT_Clk), 
                              .C1(~TFT_Clk), 
                              .CE(1'b1), 
                              .R(~DE|TFT_Rst), 
                              .D1(dvi_data_b[i]),      
                              .D0(dvi_data_a[i]),  
                              .S(1'b0));
      end 
    endgenerate  
      
    /////////////////////////////////////////////////////////////////////
    // IIC INIT COMPONENT INSTANTIATION for Chrontel CH-7301
    /////////////////////////////////////////////////////////////////////
    iic_init  iic_init (
        .Clk              (TFT_Clk),
        .Reset            (TFT_Rst),
        .SDA              (tft_iic_sda_t_i),
        .SCL              (tft_iic_scl_t_i),
        .Done             (I2C_done)
    );

    assign SDA = tft_iic_sda_t_i ? 1'bz : 1'b0;
    assign SCL = tft_iic_scl_t_i ? 1'bz : 1'b0;

endmodule
