//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_ahb_seq_lib.sv                           //
//                        library of basic AHB transactions                    //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class store_word extends ovm_sequence #(ovm_ahb_tran_item);

   //ovm stuff for factory, funct override, ovm fields etc
  `ovm_sequence_utils(store_word, ovm_ahb_master_sequencer)

  function new(string name="store_word");
    super.new(name);
  endfunction

  rand bit [31:0] write_adr;
  rand bit [31:0] write_data;

  // send data to address
  virtual task body();
    `ovm_do_with(req,{req.addr == write_adr; req.data == write_data; req.read_write == WRITE;})
  endtask

endclass : store_word

class load_word extends ovm_sequence #(ovm_ahb_tran_item);
  `ovm_sequence_utils(load_word, ovm_ahb_master_sequencer)

  function new(string name="load_word");
    super.new(name);
  endfunction

  rand bit [31:0] read_adr;
  rand bit [31:0] read_data;
  
  // get data from address
  virtual task body();
    `ovm_do_with(req,{req.addr == read_adr; req.read_write == READ;})
    get_response(rsp);
    read_data = rsp.data;
  endtask

endclass : load_word
