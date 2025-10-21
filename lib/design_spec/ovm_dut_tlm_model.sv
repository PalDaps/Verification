//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_dut_tlm_model.sv                         //
//                        TLM model of SPI_TX                                  //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

//adj. class CR register function model
class cr_register;
  bit enable;

  function new();
    enable=0;
  endfunction

  // read register
  function int get_value();
    get_value=0;
    get_value[0]=enable;
  endfunction

  // write register
  function void set_value(int data);
    enable=data[0];
  endfunction

endclass:cr_register

//adj. class SR register function model, FIFO states included to SR class
class sr_register;
  bit full;
  bit empty;
  int fifo_level;

  covergroup fifo_sates @fifo_level;
    coverpoint empty;
    coverpoint full;
  endgroup

  function new();
    fifo_level=0;
    full=0;
    empty=1;
    fifo_sates = new(); 
  endfunction

  protected function void analize_fifo_state();
  // calculate FIFO state according to FIFO_DEPTH and pointers state 
    if (fifo_level>`FIFO_DEPTH)  fifo_level=`FIFO_DEPTH;
    if (fifo_level<0)            fifo_level=0;
    if (fifo_level==0)           empty=1;
    else                         empty=0;
    if (fifo_level==`FIFO_DEPTH) full=1;
    else                         full=0;
  endfunction

  // read register
  function int get_value();
    get_value=0;
    get_value[0]=empty;
    get_value[1]=full;
  endfunction

  //update status register state on write to fifo event
  function void write_to_fifo_callback();
    fifo_level+=1;
    analize_fifo_state();
  endfunction

  //update status register state on read from fifo event
  function void read_from_fifo_callback();
    fifo_level-=1;
    analize_fifo_state();
  endfunction

endclass:sr_register

class ovm_dut_tlm_model extends ovm_component;
  // SYSTEM interface ports  (put and get ports whith FIFO)
  //ports 
  ovm_get_port #(`SYSTEM_IF_TYPE) system_if_get_port;
  ovm_put_port #(`SYSTEM_IF_TYPE) system_if_put_port;
  //FIFO for ports
  tlm_fifo #(`SYSTEM_IF_TYPE) system_if_get_port_fifo;
  tlm_fifo #(`SYSTEM_IF_TYPE) system_if_put_port_fifo;

  // TARGET interface port (all ovm_dut_tlm_model is realized as get port to realize Get operation as function and process get call_backs in SPI model)
  ovm_get_peek_imp #(`TARGET_IF_TYPE, ovm_dut_tlm_model) target_if_get_export;

  // device registers (CR, SR)
  cr_register cr;
  sr_register sr;

    // transmit FIFO
  mailbox #(`TARGET_IF_TYPE) target_if_tx_fifo;
  
  //ovm stuff for factory, funct override, ovm fields etc
  //`ovm_component_utils(ovm_dut_tlm_model)

  function new(string name="ovm_dut_tlm_model", ovm_component p = null);
    super.new(name,p);
  endfunction

  function void build;
    cr = new();
    sr = new();
    target_if_tx_fifo = new(`FIFO_DEPTH);
    system_if_get_port=new("system_if_get_port", this);
    system_if_put_port=new("system_if_put_port", this);
    system_if_get_port_fifo=new("system_if_get_port_fifo", this);
    system_if_put_port_fifo=new("system_if_put_port_fifo", this);
    target_if_get_export=new("target_if_get_export", this);
  endfunction

  function void connect();
    system_if_get_port.connect(system_if_get_port_fifo.get_export);
    system_if_put_port.connect(system_if_put_port_fifo.put_export);
  endfunction

  //process write to TX register operation (write to FIFO and send)
  protected task send_data(int data);
    `TARGET_IF_TYPE send_tran;
    if (!sr.full) begin
      // if FIFO not FULL - process send operation
      send_tran = new; // create target interface transaction
      send_tran.data=data; // write data to transaction 
      target_if_tx_fifo.put(send_tran); // write transaction to output FIFO
      sr.write_to_fifo_callback(); // update status register state
    end
    else begin
      ovm_report_warning(get_type_name(), $psprintf("Trying to write to full SPI FIFO!"), OVM_NONE);
    end
  endtask:send_data

  // process system interface operation (write to or read from device registers)
  // executes appropriate functions in case of access to varios device registers 
  protected task process_system_tran(ref `SYSTEM_IF_TYPE system_trans);
    if (system_trans.read_write == WRITE) begin
      case (system_trans.addr) 
        `TX_ADDR: begin send_data(system_trans.data); end
        `CR_ADDR: begin cr.set_value(system_trans.data); end
        `SR_ADDR: begin ovm_report_warning(get_type_name(), $psprintf("Trying to write data (%h) to SR register!", system_trans.data), OVM_NONE); end
        default:  begin ovm_report_warning(get_type_name(), $psprintf("Write to nonexist address (%h)", system_trans.addr), OVM_NONE); end
      endcase
    end
    if (system_trans.read_write == READ) begin
      case (system_trans.addr) 
        `TX_ADDR: begin ovm_report_warning(get_type_name(), $psprintf("Trying to read from TX register!"), OVM_NONE); end
        `CR_ADDR: begin system_trans.data=cr.get_value(); end
        `SR_ADDR: begin system_trans.data=sr.get_value();  end
        default:  begin ovm_report_warning(get_type_name(), $psprintf("Read from nonexist address (%h)", system_trans.addr), OVM_NONE); end
      endcase
    end

    //tracer
    if (system_trans.read_write == WRITE) begin
      case (system_trans.addr) 
        `TX_ADDR: begin ovm_report_info(get_type_name(), $psprintf("Write to TX = %h", system_trans.data), OVM_HIGH); end
        `CR_ADDR: begin ovm_report_info(get_type_name(), $psprintf("Write to CR = %h", system_trans.data), OVM_HIGH); end
        `SR_ADDR: begin ovm_report_info(get_type_name(), $psprintf("Write to SR = %h", system_trans.data), OVM_HIGH); end
      endcase
    end
    if (system_trans.read_write == READ) begin
      case (system_trans.addr) 
        `TX_ADDR: begin ovm_report_info(get_type_name(), $psprintf("Read from TX = %h", system_trans.data), OVM_HIGH); end
        `CR_ADDR: begin ovm_report_info(get_type_name(), $psprintf("Read from CR = %h", system_trans.data), OVM_HIGH); end
        `SR_ADDR: begin ovm_report_info(get_type_name(), $psprintf("Read from SR = %h", system_trans.data), OVM_HIGH); end
      endcase
    end
  endtask:process_system_tran

  //  process read from target interface operation (final stage of sending data)
  //  realized on try_get operation of TLM model, that work as get port
  function bit try_get(output `TARGET_IF_TYPE target_tran);
    bit success;
    target_tran = new;
    if (!sr.empty) begin
      // if FIFO is not empty send data to scoreboard
      success=target_if_tx_fifo.try_get(target_tran);
      sr.read_from_fifo_callback();
      //tracer
      ovm_report_info(get_type_name(), $psprintf("Transmit SPI DATA = %h", target_tran.data), OVM_HIGH);
      try_get=1;
    end
    else 
      ovm_report_warning(get_type_name(), $psprintf("Trying to read from empty SPI FIFO!"), OVM_NONE);
  endfunction
  

  // RUN: forever get control transactions from system_if_port, process it and return response.
  task run();
    `SYSTEM_IF_TYPE system_trans;
    int a;
    forever begin
      system_if_get_port.get(system_trans);
      process_system_tran(system_trans);
      system_if_put_port.put(system_trans);
    end
  endtask

// for compatability whith get interface begin
  task get( output `TARGET_IF_TYPE t );
    $display("get not realized");
  endtask

  task peek( output `TARGET_IF_TYPE t );
    $display("peek not realized");
  endtask

  function bit try_peek( output `TARGET_IF_TYPE t );
    begin
      $display("try peek not realized");
      return 0;
    end
  endfunction

  function bit can_peek();
    begin
      $display("can peek not realized");
      return 0;
    end
  endfunction

  function bit can_get();
    begin
      $display("can get not realized");
      return 0;
    end
  endfunction
// for compatability whith get interface end

endclass: ovm_dut_tlm_model