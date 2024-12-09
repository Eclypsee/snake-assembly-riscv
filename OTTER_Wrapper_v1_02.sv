`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: J. Calllenes
//           P. Hummel: 36 times
//
// Create Date: 01/20/2019 10:36:50 AM
// Module Name: OTTER_Wrapper
// Target Devices: OTTER MCU on Basys3
// Description: OTTER_WRAPPER with Switches, LEDs, and 7-segment display
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Updated MMIO Addresses, signal names
/////////////////////////////////////////////////////////////////////////////

module OTTER_Wrapper(
   input CLK,
   input [3:0] BTNS, //0 is up, 1 is right, 2 is down, 3 is left
   input BTNC,
   input [15:0] SWITCHES,
   output logic [15:0] LEDS,
   output [7:0] CATHODES,
   output [3:0] ANODES,
   output [11:0] VGA_RGB,
   output VGA_HS,
   output VGA_VS
   );
       
    // INPUT PORT IDS ///////////////////////////////////////////////////////
    // Right now, the only possible inputs are the switches
    // In future labs you can add more MMIO, and you'll have
    // to add constants here for the mux below
    localparam SWITCHES_AD = 32'h11000000;
    localparam BTNS_AD    = 32'h11000060; 
    localparam VGA_READ_AD = 32'h11000160;
           
    // OUTPUT PORT IDS //////////////////////////////////////////////////////
    // In future labs you can add more MMIO
    localparam LEDS_AD    = 32'h11000020; //32'h11000020
    localparam SSEG_AD    = 32'h11000040; //32'h11000040
    localparam VGA_ADDR_AD  = 32'h11000120;
    localparam VGA_COLOR_AD = 32'h11000140; 
   // Signals for connecting OTTER_MCU to OTTER_wrapper /////////////////////

   logic clk_50 = 0;
   logic [3:0] INTERNALS_BTNS;
   logic [31:0] IOBUS_out, IOBUS_in, IOBUS_addr;
   logic s_reset, IOBUS_wr;
   
   // Registers for buffering outputs  /////////////////////////////////////
   logic [15:0] r_SSEG;
   // Signals for connecting VGA Framebuffer Driver
   logic r_vga_we;             // write enable
   logic [14:0] r_vga_wa;      // address of framebuffer to read and write
   logic [11:0] r_vga_wd;      // pixel color data to write to framebuffer
   logic [11:0] r_vga_rd;      // pixel color data read from framebuffer
    
   // Declare OTTER_CPU ////////////////////////////////////////////////////
   OTTER_PROCESSOR OTTER_PROCESSOR (.RST(s_reset), .INTR(SHOULD_INTR), .clk(clk_50),
                  .IOBUS_OUT(IOBUS_out), .IOBUS_IN(IOBUS_in),
                  .IOBUS_ADDR(IOBUS_addr), .IOBUS_WR(IOBUS_wr));

   // Declare Seven Segment Display /////////////////////////////////////////
   SevSegDisp SSG_DISP (.DATA_IN(r_SSEG), .CLK(CLK), .MODE(1'b0),
                       .CATHODES(CATHODES), .ANODES(ANODES));
   
                           
   // Clock Divider to create 50 MHz Clock //////////////////////////////////
   always_ff @(posedge CLK) begin
       clk_50 <= ~clk_50;
   end
   
   // Connect Signals ///////////////////////////////////////////////////////
   assign s_reset = BTNC;
   //connect debouncer to interrupt
  Debouncer Debouncer0(.CLK_50(clk_50), .RST(s_reset), .BTN(BTNS[0]), .OneShot(INTERNALS_BTNS[0]));
  Debouncer Debouncer1(.CLK_50(clk_50), .RST(s_reset), .BTN(BTNS[1]), .OneShot(INTERNALS_BTNS[1]));
  Debouncer Debouncer2(.CLK_50(clk_50), .RST(s_reset), .BTN(BTNS[2]), .OneShot(INTERNALS_BTNS[2]));
  Debouncer Debouncer3(.CLK_50(clk_50), .RST(s_reset), .BTN(BTNS[3]), .OneShot(INTERNALS_BTNS[3]));
  logic SHOULD_INTR;
  assign SHOULD_INTR = INTERNALS_BTNS[0]|INTERNALS_BTNS[1]|INTERNALS_BTNS[2]|INTERNALS_BTNS[3];
   // Declare VGA Frame Buffer //////////////////////////////////////////////
   VGA_FB_Driver VGA(.CLK_50MHz(clk_50), .WA(r_vga_wa), .WD(r_vga_wd),
                               .WE(r_vga_we), .RD(r_vga_rd), .ROUT(VGA_RGB[11:8]),
                               .GOUT(VGA_RGB[7:4]), .BOUT(VGA_RGB[3:0]),
                               .HS(VGA_HS), .VS(VGA_VS));   
   // Connect Board input peripherals (Memory Mapped IO devices) to IOBUS
   always_comb begin
        case(IOBUS_addr)
            SWITCHES_AD: IOBUS_in = {16'b0,SWITCHES};
            BTNS_AD:     IOBUS_in = {28'b0,BTNS};
            default:     IOBUS_in = 32'b0;    // default bus input to 0
        endcase
    end
   
   
   // Connect Board output peripherals (Memory Mapped IO devices) to IOBUS
    always_ff @ (posedge clk_50) begin
        if(IOBUS_wr)
            case(IOBUS_addr)
                LEDS_AD: LEDS   <= IOBUS_out[15:0];
                SSEG_AD: r_SSEG <= IOBUS_out[15:0];
                VGA_ADDR_AD: r_vga_wa <= IOBUS_out[14:0];
                VGA_COLOR_AD: begin  
                        r_vga_wd <= IOBUS_out[11:0];
                        r_vga_we <= 1;  
                end   
            endcase
    end
   
   endmodule
