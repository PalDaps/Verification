//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_ahb_if_wrapper.sv                        //
//                        library of basic AHB transactions                    //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class ovm_ahb_if_wrapper extends ovm_object;

    // Register with factory
   //`ovm_component_utils(ovm_ahb_if_wrapper)

    virtual AHB_if ahb_vif;

   function new (string name, virtual AHB_if _if);
     super.new(name);
     ahb_vif = _if;
   endfunction : new

endclass : ovm_ahb_if_wrapper