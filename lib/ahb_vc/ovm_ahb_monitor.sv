//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_ahb_monitorr.sv                          //
//                        ahb monitor class                                    //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//


`ifndef AHB_IF_WRAPPER
`define AHB_IF_WRAPPER ahb_wrapper.ahb_vif 
`endif

class ovm_ahb_monitor extends ovm_monitor;

  // interface wrapper (configured with ovm_configure_object..) 
  ovm_ahb_if_wrapper ahb_wrapper;

  // output port to scoreboard
  ovm_analysis_port #(ovm_ahb_tran_item) ahb_item_collected_port;

  protected ovm_ahb_tran_item trans_collected;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils_begin ( ovm_ahb_monitor )	// Register with factory
    `ovm_field_object( ahb_wrapper, OVM_ALL_ON )
  `ovm_component_utils_end

  // new - constructor
  function new (string name, ovm_component parent);
    super.new(name, parent);
    ahb_item_collected_port = new("ahb_item_collected_port", this);
    trans_collected = new();
  endfunction : new

  // run phase (forever monitor interface and collect transactions)
  virtual task run();
    fork
      collect_transactions();
    join
  endtask : run

  // collect_transactions
  virtual protected task collect_transactions();
    forever begin
      collect_address_phase(); // put address information to transaction
      collect_data_phase();    // put data to transaction
      if (trans_collected.read_write != NOP)
        // send transaction to scoreboard analysis port through ahb_item_collected_port
        ahb_item_collected_port.write(trans_collected);
    end
  endtask : collect_transactions

  // collect_address_phase (put address information to transaction)
  virtual protected task collect_address_phase();
    do begin 
      @(`AHB_IF_WRAPPER.MON_CB);
    end while ((`AHB_IF_WRAPPER.MON_CB.HREADY && `AHB_IF_WRAPPER.MON_CB.HSEL)!==1'b1);
    // AHB specififc signal read in ADDRESS CYCLE
    trans_collected.addr = `AHB_IF_WRAPPER.MON_CB.HADDR;
    if(`AHB_IF_WRAPPER.MON_CB.HREADY && `AHB_IF_WRAPPER.MON_CB.HSEL && `AHB_IF_WRAPPER.MON_CB.HTRANS && `AHB_IF_WRAPPER.MON_CB.HWRITE===1'b1) trans_collected.read_write = WRITE;
    else if(`AHB_IF_WRAPPER.MON_CB.HREADY && `AHB_IF_WRAPPER.MON_CB.HSEL && `AHB_IF_WRAPPER.MON_CB.HTRANS && !`AHB_IF_WRAPPER.MON_CB.HWRITE===1'b1) trans_collected.read_write = READ;
    else trans_collected.read_write = NOP;
    void'(this.begin_tr(trans_collected));
  endtask : collect_address_phase

  // collect_data_phase (put data to transaction)
  virtual protected task collect_data_phase();
    if (trans_collected.read_write != NOP) begin
      @(`AHB_IF_WRAPPER.MON_CB);
      // AHB specififc signal read in DATA CYCLE
      if (trans_collected.read_write == WRITE) trans_collected.data = `AHB_IF_WRAPPER.MON_CB.HWDATA;
      if (trans_collected.read_write == READ)  trans_collected.data = `AHB_IF_WRAPPER.MON_CB.HRDATA;
    end
    this.end_tr(trans_collected);
  endtask : collect_data_phase

endclass : ovm_ahb_monitor
