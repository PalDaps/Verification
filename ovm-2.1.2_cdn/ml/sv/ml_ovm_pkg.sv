`define UNILANG_OVM             1
`define uvm_ovm_(body)          ovm_``body
`define UVM_OVM_(body)          OVM_``body
`define UVM_OVM_MACRO_(body)   `OVM_``body
`define uvm_ovm_literal_(body) `"ovm_``body`"
`define uvm_ovm_TLM_(body)     `TLM_``body     

`include "unilang_pkg.sv"

package ml_ovm;
  import unilang::*;

  export "DPI" function force_elaboration;
  function void force_elaboration(); endfunction
  
  function void connect_names(string path1, string path2);

    unilang::connect_names(path1, path2);
  endfunction

  function void connect(ovm_if_base_abstract port, /* port or export or imp */
                        string external_path, 
                        string T1_name, 
                        string T2_name = "");
    unilang::connect(port,external_path, T1_name, T2_name);
  endfunction

  function void external_if (ovm_if_base_abstract port_or_export,
                             string T1_name, 
                             string T2_name = "");
    unilang::external_if(port_or_export,T1_name,T2_name);
  endfunction

  function bit in_ml_ovm_mode();
    in_ml_ovm_mode = unilang::in_ml_ovm_mode();
  endfunction

  typedef `STREAM_T      ml_ovm_bitstream_t;

  class ml_ovm_class_serializer extends unilang_class_serializer;
    virtual function void serialize(ovm_object obj);
    endfunction

    virtual function void deserialize(inout ovm_object obj);
    endfunction  

    function void pack_field_int (logic[63:0] value, int size);
      super.pack_field_int(value, size);
    endfunction  
    function void pack_field     (ovm_bitstream_t value, int size);
      super.pack_field(value, size);
    endfunction
    function void pack_string    (string value);
      super.pack_string(value);
    endfunction
    function void pack_time      (time value);
      super.pack_time(value);
    endfunction
    function void pack_real      (real value);
      super.pack_real(value);
    endfunction

    function bit         is_null          ();
      return super.is_null();
    endfunction
    function logic[63:0] unpack_field_int (int size);
      return super.unpack_field_int(size);
    endfunction
    function ovm_bitstream_t unpack_field     (int size);
      return super.unpack_field(size);
    endfunction
    function string      unpack_string    (int num_chars=-1);
      return super.unpack_string(num_chars);
    endfunction
    function time        unpack_time      ();
      return super.unpack_time();
    endfunction
    function real        unpack_real      ();
      return super.unpack_real();
    endfunction
    function ovm_object  unpack_field_object();
      return super.unpack_field_object();
    endfunction
  endclass

  function bit register_class_serializer (ml_ovm_class_serializer serializer, ovm_object_wrapper  sv_type);
    return unilang::register_class_serializer (serializer, sv_type);
  endfunction

  function automatic int unsigned serialize_object(ovm_object obj, ref ml_ovm_bitstream_t out_stream);
    return unilang::serialize_object(obj, out_stream);
  endfunction

  function automatic ovm_object deserialize_object(int unsigned           stream_size,
                                                   ref ml_ovm_bitstream_t stream);
    return unilang::deserialize_object(stream_size, stream);
  endfunction

  function void set_type_match(string type_name1, string type_name2);
    unilang::set_type_match(type_name1, type_name2);
  endfunction

endpackage
