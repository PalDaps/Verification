//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  spi_tx_tracer.v                              //
//                        spi activity tracer                                  //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

module spi_tx_tracer ();

  // pragma coverage off
  // synopsys translate_off

  // --- read write to registers trace ---
  always @(posedge ahb_cntrl.CLK) begin
    if (ahb_cntrl.wr && ahb_cntrl.cs_tx) $display("%t::%m::write to TX = %h",$time, ahb_cntrl.HWDATA);
    if (ahb_cntrl.wr && ahb_cntrl.cs_cr) $display("%t::%m::write to CR = %h",$time, ahb_cntrl.HWDATA);
    if (ahb_cntrl.wr && ahb_cntrl.cs_sr) $display("%t::%m::write to SR = %h",$time, ahb_cntrl.HWDATA);
    if (ahb_cntrl.rd && ahb_cntrl.cs_tx) $display("%t::%m::read from TX = %h",$time, ahb_cntrl.HRDATA);
    if (ahb_cntrl.rd && ahb_cntrl.cs_cr) $display("%t::%m::read from CR = %h",$time, ahb_cntrl.HRDATA);
    if (ahb_cntrl.rd && ahb_cntrl.cs_sr) $display("%t::%m::read from SR = %h",$time, ahb_cntrl.HRDATA);
  end


  // --- spi transmitt trace ---
  //reg fifo_tx_readR;  for delayed output from fifo case
  always @(posedge spi_cntrl.CLK) begin
    //fifo_tx_readR <= spi_cntrl.fifo_tx_read;
    if (spi_cntrl.fifo_tx_read) $display("%t::%m::finish SPI trinsmit = %h",$time, spi_cntrl.fifo_tx_data_out);
  end

  // synopsys translate_on
  // pragma coverage on

endmodule

