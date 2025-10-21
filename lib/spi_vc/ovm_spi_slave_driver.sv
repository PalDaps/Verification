//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_spi_slave_driver.sv                      //
//                        spi slave driver class                               //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`ifndef SPI_IF_WRAPPER
`define SPI_IF_WRAPPER spi_wrapper.spi_vif 
`endif

class ovm_spi_slave_driver extends ovm_driver #(ovm_spi_tran_item);

  // interface wrapper (configured with ovm_configure_object..) 
  ovm_spi_if_wrapper spi_wrapper;


  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils_begin ( ovm_spi_slave_driver )	// Register with factory
    `ovm_field_object( spi_wrapper, OVM_ALL_ON )
  `ovm_component_utils_end

  ovm_spi_tran_item req;

  // new - constructor
  function new (string name, ovm_component parent);
    super.new(name, parent);
  endfunction : new

  // run phase
  virtual task run();
    fork
      drive_transactions();
    join
  endtask : run

  extern task drive_transactions();

endclass : ovm_spi_slave_driver

task ovm_spi_slave_driver::drive_transactions();
  forever begin
    @(posedge `SPI_IF_WRAPPER.SCLK);
    seq_item_port.get_next_item(req);
    req.data = `SPI_IF_WRAPPER.MOSI;
    seq_item_port.item_done();
    //ovm_report_info("SPI_Driver", "Printing req item :", OVM_LOW);
    //req.print();
  end
endtask