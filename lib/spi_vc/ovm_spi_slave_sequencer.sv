//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_spi_slave_sequencer.sv                   //
//                        spi slave sequencer class                            //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//


class ovm_spi_slave_sequencer extends ovm_sequencer #(ovm_spi_tran_item);

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_sequencer_utils(ovm_spi_slave_sequencer)

  function new (string name, ovm_component parent);
    super.new(name, parent);
    `ovm_update_sequence_lib_and_item(ovm_spi_tran_item)
  endfunction : new

endclass : ovm_spi_slave_sequencer

