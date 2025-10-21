//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_ahb_master_agent.sv                      //
//                        ahb agent class                                      //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class ovm_ahb_agent extends ovm_agent;
  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(ovm_ahb_agent)

  //driver, monitor, sequencer
  ovm_ahb_master_driver    mdriver;
  ovm_ahb_master_sequencer msequencer;
  ovm_ahb_monitor          monitor;

  function new(string name, ovm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build();
    super.build();
    mdriver    = ovm_ahb_master_driver::type_id::create("ovm_ahb_master_driver" ,this);
    msequencer = ovm_ahb_master_sequencer::type_id::create("ovm_ahb_master_sequencer"  ,this);
    monitor    = ovm_ahb_monitor::type_id::create("ovm_ahb_monitor",this);
  endfunction : build

  function void connect();
      mdriver.seq_item_port.connect(msequencer.seq_item_export);
  endfunction : connect

endclass : ovm_ahb_agent
