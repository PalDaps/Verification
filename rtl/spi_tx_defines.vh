//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  spi_tx_defines.vh                            //
//                        defines for example project                          //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`ifndef SPI_TX_DEFINE
`define SPI_TX_DEFINE

`define DATA_WIDTH     32
`define AHB_ADDR_WIDTH 4

`define TX_ADDR        0
`define CR_ADDR        4
`define SR_ADDR        8

`define CR_ENABLE_POSITION 0
`define SR_EMPTY_POSITION  0
`define SR_FULL_POSITION   1

`endif