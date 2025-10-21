class ovm_dut_basic_test extends ovm_test;

  // ovm stuff for factory, funct override, ovm fields etc
  `ovm_component_utils(ovm_dut_basic_test)

  // test env instance
  ovm_dut_env dut_env;

  function new (string name="test_shuf", ovm_component parent=null);
    super.new (name, parent);
  endfunction : new

  virtual function void build();
    super.build();
    // test sequences configure
    // Enable transaction recording for everything
    set_config_int("*", "recording_detail", OVM_FULL);
    dut_env = ovm_dut_env::type_id::create("dut_env",this);
  endfunction : build

  function void end_of_elaboration();
    ovm_report_info(get_full_name(),"End_of_elaboration", OVM_LOG);
    ovm_report_info(get_type_name(), $psprintf("TB structure...\n%s", this.sprint()), OVM_DEBUG);
  endfunction

endclass : ovm_dut_basic_test