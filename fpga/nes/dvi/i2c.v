module i2c (
  clk,     // internal FPGA clock
  reset,   // internal FPGA reset
  scl,
  sda,
  init_done
);

  input clk;
  input reset;
  inout scl;
  inout sda;
  output init_done;
  
  parameter CHR_ADDR = 7'h76;
  parameter WRITE = 1'b0;
  parameter READ = 1'b1;
  
  parameter 
  INIT      = 27'b000000000000000000000000001,
  START_1   = 27'b000000000000000000000000010,
  START_2   = 27'b000000000000000000000000100,
  START_3   = 27'b000000000000000000000001000,
  ADDR_1    = 27'b000000000000000000000010000,
  ADDR_2    = 27'b000000000000000000000100000,
  ADDR_3    = 27'b000000000000000000001000000,
  ADDR_4    = 27'b000000000000000000010000000,
  REG_1     = 27'b000000000000000000100000000,
  REG_2     = 27'b000000000000000001000000000,
  REG_3     = 27'b000000000000000010000000000,
  REG_4     = 27'b000000000000000100000000000,
  DATA_1    = 27'b000000000000001000000000000,
  DATA_2    = 27'b000000000000010000000000000,
  DATA_3    = 27'b000000000000100000000000000,
  DATA_4    = 27'b000000000001000000000000000,
  STOP_1    = 27'b000000000010000000000000000,
  STOP_2    = 27'b000000000100000000000000000,
  STOP_3    = 27'b000000001000000000000000000,
  STOP_4    = 27'b000000010000000000000000000,
  DONE      = 27'b000000100000000000000000000;
  
  reg [4:0] i2c_cdiv;
  reg [7:0] i2c_address;
  reg [7:0] i2c_register;
  reg [7:0] i2c_data;
  reg [26:0] state, next_state;
  reg [11:0] dly_counter;
  reg [3:0] index, next_index;
  reg [7:0] data, next_data;
  reg sda_oe, next_sda_oe;
  reg sda_out, next_sda_out;
  reg scl_oe, next_scl_oe;
  reg scl_out, next_scl_out;
  reg ack, next_ack;
  reg [2:0] bitcnt, next_bitcnt;
  reg [2:0] bytecnt, next_bytecnt;
  reg read, next_read;
  reg init_done, next_init_done;
  reg clear_dly_counter;
  reg i2c_cen;

  IOBUF buf_scl (.IO(scl), .O(scl_in), .I(scl_out), .T(scl_oe));
  IOBUF buf_sda (.IO(sda), .O(sda_in), .I(sda_out), .T(sda_oe));
  
  always @ (posedge clk) begin
    if (reset) begin
      i2c_cdiv <= 5'd0;
      i2c_cen <= 1'b0;
    end else if (i2c_cdiv == 5'd24) begin
      // 25 MHz/25 = 1000 kHz clock enable => i2c clock = 100 kHz
      i2c_cdiv <= 5'd0;
      i2c_cen <= 1'b1;
    end else begin
      i2c_cdiv <= i2c_cdiv + 1'b1;
      i2c_cen <= 1'b0;
    end
  end

  always @ * begin
    case (index)
      4'd0: i2c_address = {CHR_ADDR, WRITE};
      4'd1: i2c_address = {CHR_ADDR, WRITE};
      4'd2: i2c_address = {CHR_ADDR, WRITE};
      4'd3: i2c_address = {CHR_ADDR, WRITE};
      4'd4: i2c_address = {CHR_ADDR, WRITE};
      default: i2c_address = 8'hff;
    endcase
  end
  
  always @ * begin
    case (index)
      4'd0: i2c_register = 8'h49;
      4'd1: i2c_register = 8'h21;
      4'd2: i2c_register = 8'h33;
      4'd3: i2c_register = 8'h34;
      4'd4: i2c_register = 8'h36;
      default: i2c_register = 8'hff;
    endcase
  end

  always @ * begin
    case (index)
      4'd0: i2c_data = 8'hc0;
      4'd1: i2c_data = 8'h09;
      4'd2: i2c_data = 8'h08;
      4'd3: i2c_data = 8'h16;
      4'd4: i2c_data = 8'h60;
      default: i2c_data = 8'hff;
    endcase
  end

  always @ (posedge clk) begin
    if (reset) begin
      state <= INIT;
      dly_counter <= 12'd0;
      index <= 4'd0;
      sda_oe <= 1'b1;
      sda_out <= 1'b1;
      scl_oe <= 1'b1;
      scl_out <= 1'b1;
      ack <= 1'b1;
      bitcnt <= 3'd0;
      data <= 8'hff;
      read <= 1'b0;
      bytecnt <= 3'd0;
      init_done <= 1'b0;
    end else if (i2c_cen) begin
      state <= next_state;
      dly_counter <= clear_dly_counter ? 12'd0 : dly_counter + 1'b1;
      index <= next_index;
      sda_oe <= next_sda_oe;
      sda_out <= next_sda_out;
      scl_oe <= next_scl_oe;
      scl_out <= next_scl_out;
      ack <= next_ack;
      bitcnt <= next_bitcnt;
      data <= next_data;
      read <= next_read;
      bytecnt <= next_bytecnt;
      init_done <= next_init_done;
    end
  end
  
  always @ * begin
    next_state = state;
    clear_dly_counter = 1'b0;
    next_index = index;
    next_data = data;
    next_sda_oe = sda_oe;
    next_sda_out = sda_out;
    next_scl_oe = scl_oe;
    next_scl_out = scl_out;
    next_ack = 1'b1;
    next_bitcnt = bitcnt;
    next_read = read;
    next_bytecnt = bytecnt;
    next_init_done = init_done;
    case(state)
      INIT: begin
        next_init_done = 1'b0;
        next_sda_oe = 1'b1;
        next_sda_out = 1'b1;
        next_scl_oe = 1'b1;
        next_scl_out = 1'b1;
        next_index = 4'd0;
        // wait 4 ms befor start programming
        if (dly_counter == 12'd4000) begin
          clear_dly_counter = 1'b1;
          next_state = START_1;
        end
      end
      START_1: begin
        next_sda_oe = 1'b0;
        next_sda_out = 1'b1;
        next_scl_oe = 1'b0;
        next_scl_out = 1'b1;
        if (dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = START_2;
        end
      end
      START_2: begin
        next_sda_out = 1'b0;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = START_3;
        end
      end
      START_3: begin
        next_scl_out = 1'b0;
        next_data = i2c_address;
        next_read = i2c_address[0];
        next_bitcnt = 3'd0;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = ADDR_1;
        end
      end
      ADDR_1: begin
        next_scl_oe = 1'b0;
        next_sda_oe = data[7];
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = ADDR_2;
        end
      end
      ADDR_2: begin
        next_scl_oe = 1'b1;
        clear_dly_counter = ((scl_oe == 1'b1) && (scl_in == 1'b0)); // clock stretching
        if(dly_counter == 12'd4) begin
          next_bitcnt = bitcnt + 1'b1;
          next_data = data << 1;
          clear_dly_counter = 1'b1;
          if (bitcnt == 3'd7)
            next_state = ADDR_3;
          else
            next_state = ADDR_1;
        end
      end
      ADDR_3: begin
        next_scl_oe = 1'b0;
        next_sda_oe = 1'b1;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = ADDR_4;
        end
      end
      ADDR_4: begin
        next_scl_oe = 1'b1;
        clear_dly_counter = ((scl_oe == 1'b1) && (scl_in == 1'b0)); // clock stretching
        next_data = i2c_register;
        next_ack = sda_in;
        next_bitcnt = 3'd0;
        next_bytecnt = 3'd0;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          if (ack == 1'b1)
            next_state = STOP_1; // NACK
          else
            next_state = REG_1;  // register write
        end
      end
      REG_1: begin
        next_scl_oe = 1'b0;
        next_sda_oe = data[7];
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = REG_2;
        end
      end
      REG_2: begin
        next_scl_oe = 1'b1;
        clear_dly_counter = ((scl_oe == 1'b1) && (scl_in == 1'b0)); // clock stretching
        if(dly_counter == 12'd4) begin
          next_bitcnt = bitcnt + 1'b1;
          next_data = data << 1;
          clear_dly_counter = 1'b1;
          if (bitcnt == 3'd7)
            next_state = REG_3;
          else
            next_state = REG_1;
        end
      end
      REG_3: begin
        next_scl_oe = 1'b0;
        next_sda_oe = 1'b1;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = REG_4;
        end
      end
      REG_4: begin
        next_scl_oe = 1'b1;
        clear_dly_counter = ((scl_oe == 1'b1) && (scl_in == 1'b0)); // clock stretching
        next_data = i2c_data;
        next_ack = sda_in;
        next_bitcnt = 3'd0;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          if (ack == 1'b1)
            next_state = STOP_1; // NACK
          else
            next_state = DATA_1;
        end
      end
      DATA_1: begin
        next_scl_oe = 1'b0;
        next_sda_oe = data[7];
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = DATA_2;
        end
      end
      DATA_2: begin
        next_scl_oe = 1'b1;
        clear_dly_counter = ((scl_oe == 1'b1) && (scl_in == 1'b0)); // clock stretching
        if(dly_counter == 12'd4) begin
          next_bitcnt = bitcnt + 1'b1;
          next_data = data << 1;
          clear_dly_counter = 1'b1;
          if (bitcnt == 3'd7)
            next_state = DATA_3;
          else
            next_state = DATA_1;
        end
      end
      DATA_3: begin
        next_scl_oe = 1'b0;
        next_sda_oe = 1'b1;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = DATA_4;
        end
      end
      DATA_4: begin
        next_scl_oe = 1'b1;
        clear_dly_counter = ((scl_oe == 1'b1) && (scl_in == 1'b0)); // clock stretching
        next_ack = sda_in;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          if (ack == 1'b0)
            next_index = index + 1'b1;
          next_state = STOP_1;
        end
      end
      STOP_1: begin
        next_scl_oe = 1'b0;
        next_sda_oe = 1'b0;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = STOP_2;
        end
      end
      STOP_2: begin
        next_scl_oe = 1'b1;
        clear_dly_counter = ((scl_oe == 1'b1) && (scl_in == 1'b0)); // clock stretching
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = STOP_3;
        end
      end
      STOP_3: begin
        next_sda_oe = 1'b1;
        if(dly_counter == 12'd4) begin
          clear_dly_counter = 1'b1;
          next_state = STOP_4;
        end
      end
      STOP_4: begin
        if(dly_counter == 12'd100) begin
          clear_dly_counter = 1'b1;
          next_state = (index > 4'd4) ? DONE : START_1;
        end
      end
      DONE: begin
        next_init_done = 1'b1;
      end
      default: begin
        next_state = INIT;
      end
    endcase
  end

endmodule
