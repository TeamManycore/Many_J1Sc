//
// Author: <AUTHORNAME> (<AUTHOREMAIL>)
// Committer: <COMMITTERNAME>
//
// Creation Date:  Sat Apr 8 21:13:17 GMT+2 2017
// Module Name:    Board_Nexys4DDR - Behavioral
// Project Name:   J1Sc - A simple J1 implementation in Scala using Spinal HDL
//
//

module Board_Nexys4DDR (reset,
		                clk100Mhz, 
 		                extInt,
		                leds,   
           		        pmodA,
		                rx,    
		                tx);
		                
 // Input ports
 input reset;
 input clk100Mhz;
 input [0:0] extInt;
 input rx;

 // Output ports
 output [15:0] leds;
 output tx;

 // Bidirectional port
 inout [7:0] pmodA;

 // Clock generation
 wire boardClk;
 wire boardClkLocked;

 // Internal wiring 
 wire [7:0] pmodA_read;
 wire [7:0] pmodA_write;
 wire [7:0] pmodA_writeEnable;

 // Instantiate a PLL/MMCM (makes a 80Mhz clock)
 PLL makeClk (.clkIn    (clk100Mhz),
              .clkOut   (boardClk),
              .isLocked (boardClkLocked));

 // Instantiate the J1SoC core generated by Spinal
 J1SoC core (.reset              (reset),
             .boardClk           (boardClk),
             .boardClkLocked     (boardClkLocked),
             .extInt             (extInt),
             .leds               (leds),
             .pmodA_read         (pmodA_read),
             .pmodA_write        (pmodA_write),
             .pmodA_writeEnable  (pmodA_writeEnable),
             .rx                 (rx),
             .tx                 (tx));

  // Connect the pmodA read port
  assign pmodA_read = pmodA;

  // Generate the write port and equip it with tristate functionality
  genvar i;
  generate
     for (i = 0; i < 8; i = i + 1) begin
	   assign pmodA[i] = pmodA_writeEnable[i] ? pmodA_write[i] : 1'bZ;
     end
  endgenerate
  
endmodule