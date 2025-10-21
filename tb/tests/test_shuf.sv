//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  test_regs.sv                                 //
//                        test_regs sources                                    //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class test_shuf_sequence extends ovm_basic_test_sequence;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_sequence_utils(test_shuf_sequence, `SYTEM_IF_SEQUENCER)

  int data;

  function new(string name="test_shuf_sequence");
    super.new(name);
  endfunction

  virtual task body();
    int data;

    ovm_report_info(get_type_name(), "LET THE test_shuf BEGIN!!!!!", OVM_LOW);
    
    StoreWord(`CR_ADDR,32'hFFFFFFFE);
    StoreWord(`CR_ADDR,32'h00000000);

    //finish test
    global_stop_request();

  endtask
endclass : test_shuf_sequence

class test_shuf extends ovm_dut_basic_test;

  // ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(test_shuf)

  function new (string name="test_shuf", ovm_component parent=null);
    super.new (name, parent);
  endfunction : new

  virtual function void build();
    super.build();
    // test sequences configure
    // Enable transaction recording for everything
    set_config_string(`SYTEM_IF_SEQUENCER_PATH, "default_sequence", "test_shuf_sequence");
  endfunction : build

endclass : test_shuf