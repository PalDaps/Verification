//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_spi_agent.sv                       //
//                        spi slave verification component (agent)             //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//


class ovm_spi_agent extends ovm_agent;

  // driver, monitor and sequencer
  ovm_spi_slave_driver    sdriver;
  ovm_spi_slave_sequencer ssequencer;
  ovm_spi_monitor         monitor;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(ovm_spi_agent)

  // new - constructor
  function new (string name, ovm_component parent);
    super.new(name, parent);
  endfunction : new

  // build
  virtual function void build();
    super.build();
    sdriver    = ovm_spi_slave_driver::type_id::create("ovm_spi_slave_driver", this);
    ssequencer = ovm_spi_slave_sequencer::type_id::create("ovm_spi_slave_sequencer", this);
    monitor    = ovm_spi_monitor::type_id::create("ovm_spi_monitor",this);
  endfunction : build

  // connect
  function void connect();
    sdriver.seq_item_port.connect(ssequencer.seq_item_export);
  endfunction : connect

endclass : ovm_spi_agent
