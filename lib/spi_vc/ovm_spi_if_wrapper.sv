
class ovm_spi_if_wrapper extends ovm_object;

   virtual SPI_if spi_vif;
   //`ovm_component_utils ( ovm_spi_if_wrapper )	// Register with factory

   function new (string name, virtual SPI_if _if);
     super.new(name);
     spi_vif = _if;
   endfunction : new

endclass : ovm_spi_if_wrapper