//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_dut_seq_lib.sv                           //
//                        project dpecific transaction sequences               //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

class wait_not_full extends ovm_sequence #(`SYSTEM_IF_TYPE);
// read SR register while fifo is full
  `ovm_sequence_utils(wait_not_full, `SYTEM_IF_SEQUENCER)
  load_word lw;

  function new(string name="wait_not_full");
    super.new(name);
  endfunction

  rand bit [31:0] temp;

  virtual task body();
    do begin `ovm_do_with (lw, {lw.read_adr == `SR_ADDR;}) temp = lw.read_data; end
    while (temp[1] == 1'b1);
  endtask
endclass : wait_not_full

class send_rand_data extends ovm_sequence #(`SYSTEM_IF_TYPE);
//send random number of random words
  `ovm_sequence_utils(send_rand_data, `SYTEM_IF_SEQUENCER)

  int min_word_cnt=1;
  int max_word_cnt=100;
  rand int word_cnt;

  constraint wrd_cnt {
    min_word_cnt<=word_cnt;
    max_word_cnt>=word_cnt;
  } 

  store_word sw;
  wait_not_full wnf;

  function new(string name="wait_not_full");
    super.new(name);
  endfunction

  virtual task body();
    int i;
    for (i=0; i<word_cnt; i=i+1) begin
      `ovm_do_with (sw, {sw.write_adr == `TX_ADDR;})
      `ovm_do_with (wnf, {})
    end
  endtask

endclass : send_rand_data

class ovm_basic_test_sequence extends ovm_sequence #(`SYSTEM_IF_TYPE);
// class that contains all basic operation templates for device
  
  `ovm_sequence_utils(ovm_basic_test_sequence, `SYTEM_IF_SEQUENCER)

  function new(string name="ovm_basic_test_sequence");
    super.new(name);
  endfunction

  store_word sw;
  load_word  lw;
  wait_not_full wnf;
  send_rand_data srd;

  // store data to addr
  task StoreWord(int addr, int data); 
    `ovm_do_with (sw, {sw.write_adr == addr; sw.write_data == data;})
  endtask

  // load data from addr
  task LoadWord(int addr, ref int data); 
    `ovm_do_with (lw, {lw.read_adr == addr;})
     data = lw.read_data;
  endtask

  // enable SPI_TX
  task StartSPI_TX(); 
    StoreWord(`CR_ADDR, 1);
  endtask

  // disable SPI_TX
  task StopSPI_TX();  
    StoreWord(`CR_ADDR, 0);
  endtask

  // read SR register while fifo not empty (while SPI is runing)
  task WaitSPI_TX();
    int a;
    do begin
      LoadWord(`SR_ADDR,a);
    end while (a[0]!=1);
  endtask

  // read SR register while fifo is full
  task WaitSPI_TX_NotFull(); 
    `ovm_do_with (wnf, {})
  endtask

  // send one random word
  task SendRandWord();  
    `ovm_do_with (sw, {sw.write_adr == `TX_ADDR;})
  endtask

  //send random number of random words (words number  - random from nim to max)
  task SendRandData(int min, int max); 
    `ovm_do_with (srd, {srd.word_cnt >= min; srd.word_cnt <= max;})
  endtask

  virtual task body();
  endtask

endclass : ovm_basic_test_sequence

