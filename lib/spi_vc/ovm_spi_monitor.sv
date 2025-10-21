//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_spi_monitor.sv                           //
//                        spi slave monitor class                              //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`ifndef SPI_IF_WRAPPER
`define SPI_IF_WRAPPER spi_wrapper.spi_vif 
`endif

class ovm_spi_monitor extends ovm_monitor;

  // interface wrapper (configured with ovm_configure_object..) 
  ovm_spi_if_wrapper spi_wrapper;

  // LEAST_BIT_FIRST=1 => least bit first mode
  // LEAST_BIT_FIRST=0 => master bit first mode
  int LEAST_BIT_FIRST;

  // output port to scoreboard
  ovm_analysis_port #(ovm_spi_tran_item) spi_item_collected_port;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils_begin ( ovm_spi_monitor )	// Register with factory
    `ovm_field_object( spi_wrapper, OVM_ALL_ON )
    `ovm_field_int( LEAST_BIT_FIRST, OVM_ALL_ON )
  `ovm_component_utils_end

  // new - constructor
  function new (string name, ovm_component parent);
    super.new(name, parent);
    spi_item_collected_port = new("spi_item_collected_port", this);
  endfunction : new

  // run phase
  virtual task run();
    fork
      collect_transactions();
    join
  endtask : run


  // collect_data
  virtual protected task collect_transactions();
    int spi_cntr;
    ovm_spi_tran_item trans_collected;
    @(`SPI_IF_WRAPPER.MON_CB);
    
    forever begin
      // wait ss
      while (`SPI_IF_WRAPPER.MON_CB.SS!==0) @(`SPI_IF_WRAPPER.MON_CB);
      //$display("%t, SS captured", $time);
      // collect full 32 bit word from serial interface
      spi_cntr = 0;
      trans_collected = new();
      do begin
        if (spi_cntr==0) void'(this.begin_tr(trans_collected));
        if (!LEAST_BIT_FIRST) trans_collected.data[31-spi_cntr]=`SPI_IF_WRAPPER.MON_CB.MOSI;
        else                  trans_collected.data[spi_cntr]   =`SPI_IF_WRAPPER.MON_CB.MOSI;
        spi_cntr+=1; // next bit
        //$display("%t, bit [%d] captured %b", $time, spi_cntr, `SPI_IF_WRAPPER.MON_CB.MOSI);
        if (`SPI_IF_WRAPPER.MON_CB.SS!==0) ovm_report_error(get_full_name(),"SS must be 0 during active transfer!");
        @(`SPI_IF_WRAPPER.MON_CB);
      end while (spi_cntr<32);
      
      this.end_tr(trans_collected); // end transaction stuff
      //send transaction to scoreboard analysis port through spi_item_collected_port
      spi_item_collected_port.write(trans_collected);

    end
  endtask : collect_data

endclass : ovm_spi_monitor
