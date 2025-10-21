//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_ahb_tran_item.sv                         //
//                        ahb transaction class                                //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

typedef enum { READ,
               WRITE,
               NOP
             } read_write_enum;

class ovm_ahb_tran_item extends ovm_sequence_item;

  rand logic [31:0] addr;          // transaction address
  rand logic [31:0] data;          // transaction data
  rand read_write_enum read_write; // transaction type

  //ovm stuff for factory, funct override, ovm fields etc
  `ovm_object_utils_begin(ovm_ahb_tran_item)
    `ovm_field_int  (addr                       , OVM_ALL_ON)
    `ovm_field_int  (data                       , OVM_ALL_ON)
    `ovm_field_enum (read_write_enum, read_write, OVM_ALL_ON)
  `ovm_object_utils_end

  function new (string name = "ovm_ahb_tran_item");
    super.new(name);
  endfunction : new

  function int comp (ovm_ahb_tran_item after);
    comp=1;
    if (after.data  !== this.data) begin
      comp=0;
      ovm_report_error(get_type_name(), $psprintf("ahb tran data mismatch ethalon: %0h.  after: %0h", this.data, after.data), OVM_NONE);
    end
    if (after.addr  !== this.addr) begin
      comp=0;
      ovm_report_error(get_type_name(), $psprintf("ahb tran addr mismatch ethalon: %0h.  after: %0h", this.addr, after.addr), OVM_NONE);
    end
    if (after.read_write  !== this.read_write) begin
      comp=0;
      ovm_report_error(get_type_name(), $psprintf("ahb tran rw mismatch ethalon: %0h.  after: %0h", this.read_write, after.read_write), OVM_NONE);
    end
  endfunction : comp

endclass : ovm_ahb_tran_item
