//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  test_fifo.sv                                 //
//                        test fifo sources                                    //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class test_fifo_sequence extends ovm_basic_test_sequence;

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_sequence_utils(test_fifo_sequence, `SYTEM_IF_SEQUENCER)

  int data;

  function new(string name="test_fifo_sequence");
    super.new(name);
  endfunction

  virtual task body();
    int data;
    
    ovm_report_info(get_type_name(), "LET THE test_fifo BEGIN!!!!!", OVM_LOW);
    
    // put 1 word to SPI_TX FIFO
    SendRandWord();

    // check FIFO not empty
    LoadWord(`SR_ADDR,data);
    assert (data[0]===0) else begin
      ovm_report_error(get_type_name(), $psprintf("check1: SPI buffer must be not empty"), OVM_NONE); 
    end
    assert (data[1]===0) else begin
      ovm_report_error(get_type_name(), $psprintf("check2: SPI buffer must not be full"), OVM_NONE); 
    end

    //fill FIFO by random words
    SendRandWord();
    SendRandWord();
    SendRandWord();

    // check FIFO full
    LoadWord(`SR_ADDR,data);
    assert (data[0]===0) else begin
      ovm_report_error(get_type_name(), $psprintf("check1: SPI buffer must be not empty"), OVM_NONE); 
    end
    assert (data[1]===1) else begin
      ovm_report_error(get_type_name(), $psprintf("check2: SPI buffer must be full"), OVM_NONE); 
    end
    
    // transmitt all words from FIFO
    StartSPI_TX();
    WaitSPI_TX();

    // check FIFO empty
    LoadWord(`SR_ADDR,data);
    assert (data[0]===1) else begin
      ovm_report_error(get_type_name(), $psprintf("check1: SPI buffer must be empty"), OVM_NONE); 
    end
    assert (data[1]===0) else begin
      ovm_report_error(get_type_name(), $psprintf("check1: SPI buffer must not be full"), OVM_NONE); 
    end

    // transmitt another packet
    SendRandWord();
    SendRandWord();
    SendRandWord();
    WaitSPI_TX();

    // check FIFO empty
    LoadWord(`SR_ADDR,data);
    assert (data[0]===1) else begin
      ovm_report_error(get_type_name(), $psprintf("check1: SPI buffer must be empty"), OVM_NONE); 
    end
    assert (data[1]===0) else begin
      ovm_report_error(get_type_name(), $psprintf("check1: SPI buffer must not be full"), OVM_NONE); 
    end

    //finish test
    global_stop_request();

  endtask
endclass : test_fifo_sequence

class test_fifo extends ovm_dut_basic_test;

  // ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(test_fifo)

  function new (string name="test_fifo", ovm_component parent=null);
    super.new (name, parent);
  endfunction : new

  virtual function void build();
    super.build();
    // test sequences configure
    set_config_string(`SYTEM_IF_SEQUENCER_PATH, "default_sequence", "test_fifo_sequence");
  endfunction : build

endclass : test_fifo