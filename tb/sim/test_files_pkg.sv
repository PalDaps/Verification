//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  test_files.sv                                //
//                        harness file list                                    //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

  import ovm_pkg::*;
  `include "ovm_macros.svh"

  import ovm_ahb_vc_pkg::*;
  import ovm_spi_vc_pkg::*;
  import ovm_design_spec_pkg::*;
  `include "dut_env_defines.sv"

  `include "harness.sv"