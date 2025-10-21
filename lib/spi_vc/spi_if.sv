//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  spi_if.sv                                    //
//                        spi interface                                        //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

parameter spi_input_del  = 1;

interface SPI_if ();
  logic SCLK;
  logic MOSI;
  logic SS;
  
  clocking MON_CB @(negedge SCLK);
    default input #spi_input_del;
    input   MOSI, SS;
  endclocking
  
endinterface