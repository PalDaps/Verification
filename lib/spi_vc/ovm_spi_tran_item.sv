//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_spi_tran_item.sv                         //
//                        spi basic transaction                                //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class ovm_spi_tran_item extends ovm_sequence_item;

  rand logic [31:0] data;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_object_utils_begin(ovm_spi_tran_item)
    `ovm_field_int  (data, OVM_ALL_ON)
  `ovm_object_utils_end

  function new (string name = "ovm_spi_tran_item");
    super.new(name);
  endfunction : new

  function int comp (ovm_spi_tran_item after);
    comp=1;
    if (after.data   !== this.data)    begin
      comp=0;
      ovm_report_error(get_type_name(), $psprintf("spi tran data mismatch ethalon: %0h.  after: %0h", this.data, after.data), OVM_NONE);
    end
  endfunction : comp

endclass : ovm_spi_tran_item
