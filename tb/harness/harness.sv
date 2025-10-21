//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file - harness.sv                                    //
//                        harness DUT and test env instances                   //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`define PERIOD 10
 
module harness;

  reg CLK;
  reg RST_N;
  ovm_ahb_if_wrapper ahb_wrapper;
  ovm_spi_if_wrapper spi_wrapper;

  // AHB interface instance
  AHB_if AHB_if0(.CLK(CLK), .RST_N(RST_N));

  // SPI interface instance
  SPI_if SPI_if0();

  // DUT instance
  spi_tx DUT(
     // SYSTEM
    .CLK(CLK),
    .RST_N(RST_N),
     // AHB
    .HSEL( AHB_if0.HSEL),
    .HTRANS(AHB_if0.HTRANS),
    .HADDR(AHB_if0.HADDR[3:0]),
    .HWRITE(AHB_if0.HWRITE),
    .HREADY(AHB_if0.HREADY),
    .HREADY_RESP(AHB_if0.HREADY_RESP),
    .HWDATA(AHB_if0.HWDATA),
    .HRDATA(AHB_if0.HRDATA),
     // SPI
    .SCLK(SPI_if0.SCLK),
    .SS(SPI_if0.SS),
    .MOSI(SPI_if0.MOSI)
  );

  initial begin
    ahb_wrapper=new("ahb_wrapper", AHB_if0);
    spi_wrapper=new("spi_wrapper", SPI_if0);
    set_config_object("*", "ahb_wrapper", ahb_wrapper, 0);
    set_config_object("*", "spi_wrapper", spi_wrapper, 0);
    set_config_int("*", "LEAST_BIT_FIRST", 1);

    repeat(2) @(posedge CLK);
    fork
      run_test();
    join

  end

  // GLOBAL CLOCK generation 
  always #(`PERIOD/2) CLK <= ~CLK;

  // GLOBAL RESET generation
  initial begin
    CLK = 0;
    RST_N = 1;
    #(`PERIOD/4);
    RST_N = 0;
    #(`PERIOD*4);
    RST_N = 1;
  end

endmodule



