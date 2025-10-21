//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_dut_scoreboard.sv                        //
//                        scoreboard (coverage and analysis)                   //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

// port class for scoreboard
// on write event executes write_system_tran function in scoreboard
class ovm_analysis_system #(type T=int, type IMP=int)
  extends ovm_port_base #(tlm_if_base #(T,T));
  `OVM_IMP_COMMON(`TLM_ANALYSIS_MASK,"ovm_analysis_system",IMP)
  function void write (input T t);
    m_imp.write_system_tran(t);
  endfunction
endclass

// port class for scoreboard
// on write event executes write_target_tran function in scoreboard
class ovm_analysis_target #(type T=int, type IMP=int)
  extends ovm_port_base #(tlm_if_base #(T,T));
  `OVM_IMP_COMMON(`TLM_ANALYSIS_MASK,"ovm_analysis_target",IMP)
  function void write (input T t);
    m_imp.write_target_tran(t);
  endfunction
endclass

class ovm_dut_scoreboard extends ovm_scoreboard;
  // scoreboard ports
  ovm_analysis_system #(`SYSTEM_IF_TYPE, ovm_dut_scoreboard) system_if_analysis_port_export;
  ovm_analysis_target #(`TARGET_IF_TYPE, ovm_dut_scoreboard) target_if_analysis_port_export;
  
  // device TLM model 
  ovm_dut_tlm_model dut_tlm_model;

  // comporators
  ovm_in_order_class_comparator #(`TARGET_IF_TYPE) target_if_comparator;
  ovm_analysis_port #(`TARGET_IF_TYPE) target_if_before_port;
  ovm_analysis_port #(`TARGET_IF_TYPE) target_if_after_port;
  ovm_in_order_class_comparator #(`SYSTEM_IF_TYPE) system_if_comparator;
  ovm_analysis_port #(`SYSTEM_IF_TYPE) system_if_before_port;
  ovm_analysis_port #(`SYSTEM_IF_TYPE) system_if_after_port;

  // ports for TLM connection to scoreboard
  ovm_put_port #(`SYSTEM_IF_TYPE) system_if_put_port; // system transaction if
  ovm_get_port #(`SYSTEM_IF_TYPE) system_if_get_port; // system transaction if responses
  ovm_get_port #(`TARGET_IF_TYPE) target_if_get_port; // target if

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(ovm_dut_scoreboard)

  // new - constructor
  function new (string name, ovm_component parent);
    super.new(name, parent);
  endfunction : new

  //build
  function void build();
    system_if_analysis_port_export = new("system_if_analysis_port_export", this);
    target_if_analysis_port_export = new("target_if_analysis_port_export", this);
    dut_tlm_model=new();
    system_if_comparator = new("system_if_comparator",this);
    system_if_before_port= new("system_if_before_port",this);
    system_if_after_port = new("system_if_after_port",this);
    target_if_comparator = new("target_if_comparator",this);
    target_if_before_port= new("target_if_before_port",this);
    target_if_after_port = new("target_if_after_port",this);
    system_if_get_port = new("system_if_get_port",this);
    system_if_put_port = new("system_if_put_port",this);
    target_if_get_port = new("target_if_get_port",this);
  endfunction : build

  function void connect();
    //connect TLM model
    system_if_put_port.connect(dut_tlm_model.system_if_get_port_fifo.put_export);
    system_if_get_port.connect(dut_tlm_model.system_if_put_port_fifo.get_export);
    target_if_get_port.connect(dut_tlm_model.target_if_get_export);
    system_if_after_port.connect(system_if_comparator.after_export);
    system_if_before_port.connect(system_if_comparator.before_export);
    target_if_after_port.connect(target_if_comparator.after_export);
    target_if_before_port.connect(target_if_comparator.before_export);
  endfunction

  // process system transaction 
  virtual function void write_system_tran(`SYSTEM_IF_TYPE system_tran);
    bit success_write;
    `SYSTEM_IF_TYPE resp_system_tran;
    $cast(resp_system_tran, system_tran.clone());
    system_if_after_port.write(system_tran); // dublicate system transaction for further comporation
    success_write = system_if_put_port.try_put(resp_system_tran);   // send system transaction to TLM 
    assert(success_write==1) else ovm_report_error(get_type_name(), "write system_if_put_port buffer error", OVM_NONE);
  endfunction : write_system_tran

  // process target transaction 
  virtual function void write_target_tran(`TARGET_IF_TYPE target_tran);
    int success_read;
    `TARGET_IF_TYPE resp_target_tran;
    success_read=target_if_get_port.try_get(resp_target_tran); // get target transaction from TLM
    assert(success_read==1) else ovm_report_error(get_type_name(), "read from target_if_get_port buffer error", OVM_NONE);
    target_if_after_port.write(target_tran); // dublicate system transaction for further comporation
    target_if_before_port.write(resp_target_tran);
  endfunction : write_target_tran

  // compare system transactions from DUT and TLM 
  task check_system_trans();
    `SYSTEM_IF_TYPE resp_system_tran;
    system_if_get_port.get(resp_system_tran);       // get responce from TLM 
    system_if_before_port.write(resp_system_tran);  // send responce from TLM to comparator
  endtask : check_system_trans

  // RUN: forever check transactions
  task run;
    forever begin
      check_system_trans();
    end
  endtask : run

  // report
  virtual function void report();
      
  endfunction : report

endclass : ovm_dut_scoreboard
