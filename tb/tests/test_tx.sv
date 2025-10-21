//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  test_tx.sv                                   //
//                        test_tx sources                                      //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class test_tx_sequence extends ovm_basic_test_sequence;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_sequence_utils(test_tx_sequence, `SYTEM_IF_SEQUENCER)

  int data;

  function new(string name="test_tx");
    super.new(name);
  endfunction

  virtual task body();
    int data;
    
    ovm_report_info(get_type_name(), "LET THE test_tx BEGIN!!!!!", OVM_LOW);

    //SPI_TX enable
    StartSPI_TX();

    //send random packet and wait
    SendRandData(10,20);
    WaitSPI_TX();

    //send random packet and wait
    SendRandData(10,20);
    WaitSPI_TX();
    //send random packet and wait
    SendRandData(10,20);
    WaitSPI_TX();

    //finish test
    global_stop_request();
  endtask

endclass : test_tx_sequence


class test_tx extends ovm_dut_basic_test;

  // ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(test_tx)

  function new (string name="test_tx", ovm_component parent=null);
    super.new (name, parent);
  endfunction : new

  virtual function void build();
     super.build();

    // test sequences configure
    set_config_string(`SYTEM_IF_SEQUENCER_PATH, "default_sequence", "test_tx_sequence");
  endfunction : build

endclass : test_tx

