//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ahb_control.v                                //
//                        AHB bus control block                                //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`include "spi_tx_defines.vh"

module ahb_control (
  // SYSTEM
  input                        CLK,          // Clock
  input                        RST_N,        // Reset

  //AHB
  input                        HSEL,         // AHB INTERFACE SELECT DEVICE
  input                        HTRANS,       // AHB INTERFACE TRANSACTION ENABLE
  input  [`AHB_ADDR_WIDTH-1:0] HADDR,        // AHB INTERFACE ADDRESS
  input                        HWRITE,       // AHB INTERFACE WRITE/READ TRANSACTION SELECT
  input                        HREADY,       // AHB INTERFACE MASTER HANDSHAKE
  output                       HREADY_RESP,  // AHB INTERFACE SLAVE HANDSHAKE
  input      [`DATA_WIDTH-1:0] HWDATA,       // AHB INTERFACE WRITE DATA
  output     [`DATA_WIDTH-1:0] HRDATA,       // AHB INTERFACE READ DATA
  
  //control
  output reg                   enable,        // enable transmitter control signal
  input                        fifo_tx_empty, // fifo_tx empty state indicator
  input                        fifo_tx_full,  // fifo_tx full state indicator
  output                       fifo_tx_write  // write to FIFO control signal

);

  // AHB INTERFACE Control
  reg                        hrdy;            // ready signal for AHB interface
  reg                        wr;              // captured AHB write transaction
  reg                        rd;              // captured AHB read transaction 
  reg  [`AHB_ADDR_WIDTH-1:0] haddr;           // captured AHB transaction address

  // CR - Control register and fields
  wire     [`DATA_WIDTH-1:0] CR;

  // SR - status register and fields
  wire     [`DATA_WIDTH-1:0] SR;

  wire cs_sr;                                 // SR register data transfer is active
  wire cs_cr;                                 // CR register data transfer is active
  wire cs_tx;                                 // TX register data transfer is active

  //-------------------------- AHB interface CONTROL---------------------------------------//
  //extract control signals from AHB interface
  always @ (negedge RST_N or posedge CLK) if (!RST_N) hrdy <= 0 ; else
      hrdy <= HREADY & HSEL ;
  assign HREADY_RESP = hrdy;

  always @ (negedge RST_N or posedge CLK) if (!RST_N) wr <= 0 ; else
      wr <= HREADY & HSEL & HTRANS & HWRITE ;
  always @ (negedge RST_N or posedge CLK) if (!RST_N) rd <= 0 ; else
      rd <= HREADY & HSEL & HTRANS & ~HWRITE ;
  always @ (negedge RST_N or posedge CLK) if (!RST_N) haddr <= 0 ; else
      if (HREADY && HSEL) haddr <= HADDR ;

  // Register select  (decode address)
  /*
  Mistake 2
  The size for the variables should be adjusted automatically.  It was like this:
  assign cs_tx = (haddr == 2'h`TX_ADDR);
  assign cs_cr = (haddr == 2'h`CR_ADDR);
  assign cs_sr = (haddr == 2'h`SR_ADDR);
  */
  assign cs_tx = (haddr == `TX_ADDR);
  assign cs_cr = (haddr == `CR_ADDR);
  assign cs_sr = (haddr == `SR_ADDR);

  // AHB data read from registers
  assign HRDATA =
    (rd && cs_cr)  ? CR:
    (rd && cs_sr)  ? SR: 0;

  //---------------------------------- CR register----------------------------------------//
  always @ (negedge RST_N or posedge CLK) begin
    if (!RST_N)          enable <= 0;
    else if(wr && cs_cr) enable <= HWDATA[0];
  end
  assign CR[0]               = enable;
  /* 
  Mistake 4
  Let's just say that CR takes 0. It was like this:
  assign CR[1]               = 1'b1; // stupid error 
  */
  assign CR[1]               = 1'b0; // stupid error
  assign CR[`DATA_WIDTH-1:2] = 0;
  
  //---------------------------------- SR register ---------------------------------------//
  assign SR[0]               = fifo_tx_empty;
  assign SR[1]               = fifo_tx_full;
  assign SR[`DATA_WIDTH-1:2] = 0;
 
  //---------------------------------- TX register---------------------------------------//
  //fifo control
  // process write to fifo operation when write to TX register address
  assign fifo_tx_write =  wr && cs_tx;

endmodule

