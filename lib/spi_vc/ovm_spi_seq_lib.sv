//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_spi_slave_sequence_lib.sv                //
//                        spi standart transaction library                     //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//


class ovm_spi_slave_sequence extends ovm_sequence #(ovm_spi_tran_item);

  function new(string name="ovm_spi_slave_sequence");
    super.new(name);
  endfunction

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_sequence_utils(ovm_spi_slave_sequence, ovm_spi_slave_sequencer)

  virtual task body();
    $cast(req, create_item(ovm_spi_tran_item::get_type(), p_sequencer, "req"));
    forever begin
      wait_for_grant();
      send_request(req);
      wait_for_item_done();
    end
  endtask : body

endclass : ovm_spi_slave_sequence
