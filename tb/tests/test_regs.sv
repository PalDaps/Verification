//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  test_regs.sv                                 //
//                        test_regs sources                                    //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class test_regs_sequence extends ovm_basic_test_sequence;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_sequence_utils(test_regs_sequence, `SYTEM_IF_SEQUENCER)

  int data;

  function new(string name="test_regs_sequence");
    super.new(name);
  endfunction

  virtual task body();
    int data;
    
    ovm_report_info(get_type_name(), "LET THE test_regs BEGIN!!!!!", OVM_LOW);
    
    //check state of SR after reset
    LoadWord(`SR_ADDR,data);
    assert (data===1) else begin
      ovm_report_error(get_type_name(), $psprintf("SR value mismatch Expected (%h) Actual(%h)", 1, data), OVM_NONE); 
    end
    //check state of CR after reset
    LoadWord(`CR_ADDR,data);
    assert (data===0) else begin
      ovm_report_error(get_type_name(), $psprintf("CR value mismatch Expected (%h) Actual(%h)", 0, data), OVM_NONE); 
    end

    //finish test
    global_stop_request();

  endtask
endclass : test_regs_sequence


class test_regs extends ovm_dut_basic_test;

  // ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(test_regs)

  function new (string name="test_shuf", ovm_component parent=null);
    super.new (name, parent);
  endfunction : new

  virtual function void build();
    super.build();
    // test sequences configure
    set_config_string(`SYTEM_IF_SEQUENCER_PATH, "default_sequence", "test_regs_sequence");
  endfunction : build

endclass : test_regs