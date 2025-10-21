//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_dut_env.sv                               //
//                        test enviroment                                      //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class ovm_dut_env extends ovm_env;
  // test enviroment: agents and scoreboard
  ovm_ahb_agent      ahb_agent;
  ovm_spi_agent      spi_agent;
  ovm_dut_scoreboard scoreboard;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(ovm_dut_env)

  function new(string name, ovm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build();
    super.build();
    ahb_agent  = ovm_ahb_agent      ::type_id::create("ovm_ahb_agent",  this);
    spi_agent  = ovm_spi_agent      ::type_id::create("ovm_spi_agent",   this);
    scoreboard = ovm_dut_scoreboard ::type_id::create("ovm_dut_scoreboard", this);
  endfunction : build

  function void connect();
    // connect monitors to scoreboard ports
    ahb_agent.monitor.ahb_item_collected_port.connect(scoreboard.system_if_analysis_port_export);
    spi_agent.monitor.spi_item_collected_port.connect(scoreboard.target_if_analysis_port_export);
  endfunction : connect

endclass : ovm_dut_env
