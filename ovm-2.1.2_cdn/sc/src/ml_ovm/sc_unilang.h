/*
 * Copyright (c) 2002-2008
 * Cadence, Inc.
 * 2655 Seely Avenue.
 * San Jose, CA, 95134
 * U.S.A.
 * All rights reserved worldwide.
 * This work may not be copied, modified, re-published, uploaded, 
 * executed, or distributed in any way, in any medium, whether in 
 * whole or in part, without prior written
 * permission from Cadence Design Systems, Inc.
 */

#ifndef SC_UNILANG_H
#define SC_UNILANG_H

#include "sysc/utils/sc_iostream.h"
#include "sysc/kernel/sc_object.h" 
#include "sysc/communication/sc_export.h"
#include "sysc/communication/sc_port.h"
#include "base/ovm_ids.h"
#include "sysc/cosim/ml_ovm_ids.h"
#include <typeinfo>
//#include "svdpi.h"
#include <stdio.h>

///////////

// namespace ?

// unilang_stream_type typedef copied from unilang.h
//typedef unsigned* unilang_stream_type;

struct nc_unilang_packed_obj {
  unsigned nblocks;
  unsigned *val;
  unsigned max_words;

  nc_unilang_packed_obj();
  ~nc_unilang_packed_obj(); 

  static void allocate(nc_unilang_packed_obj* obj, unsigned nwords);
};

///////////

// for internal use
// fwd declaration
struct scSessionArguments;
typedef struct scSessionArguments scSessionArgumentsT;

///////////

namespace ml_ovm {

class ml_ovm_exists {
public:
  ml_ovm_exists();
};

void ml_ovm_connect(
  std::string port_name, 
  std::string export_name
);


///////////////////

extern void sc_unilang_bootstrap(scSessionArgumentsT*);

typedef nc_unilang_packed_obj NCUPO;

// used by transmitters and receivers
class sc_unilang_utils {
public:
  static void sc_unilang_register_top(std::string name);
  static int get_max_bits();
  static int get_max_words();
  static unsigned unilangAdapterId();
  static unsigned sc_unilang_id_from_name(std::string name);
  static void fill_ncupo(NCUPO& vt, unsigned nblocks, void* stream);
  static unsigned copy_from_ncupo(const NCUPO& vt, void* stream);
  static void allocate_ncupo(NCUPO* vt);
  // for delayed ml_ovm_connect calls
  static void add_pending_ml_ovm_connect_call(
    std::string port_name,
    std::string export_name
  );
  static void do_pending_ml_ovm_connect_calls();

  static NCUPO& get_static_ncupo();
  static NCUPO* get_ncupo_from_pool();
  static void release_ncupo_to_pool(NCUPO* n);

  static bool is_old_packer();
  static int get_pack_block_size();

  static unsigned get_type_id(std::string name);
  static char* get_type_name(unsigned id);
};

///////////////////

class sc_unilang_trans {
public:
  
  // put family

  static void unilang_put_bitstream_request(
    unsigned port_connector_id, 
    NCUPO* val
  );
  static int unilang_try_put_bitstream(unsigned local_port_id, NCUPO* val);
  static int unilang_can_put(unsigned local_port_id);

  static void unilang_ok_to_put(unsigned local_port_id);

  // get family

  static void unilang_get_bitstream_request(
    unsigned port_connector_id, 
    NCUPO* val
  );
  static int unilang_try_get_bitstream(unsigned local_port_id, NCUPO* val);
  static int unilang_can_get(unsigned local_port_id);

  // peek family

  static void unilang_peek_bitstream_request(
    unsigned port_connector_id, 
    NCUPO* val
  );
  static int unilang_try_peek_bitstream(unsigned local_port_id, NCUPO* val);
  static int unilang_can_peek(unsigned local_port_id);

  static void unilang_transport_bitstream_request(
    unsigned port_connector_id, 
    NCUPO* req,
    NCUPO* rsp
  );

  static void unilang_write_bitstream(unsigned local_port_id, NCUPO* val);

  static void unilang_notify_end_task(
    unsigned callback_adapter_id, 
  unsigned call_id
  );
};

///////////////////

class sc_unilang_transrec_base {
public:
  sc_unilang_transrec_base(const char* name_);
  virtual ~sc_unilang_transrec_base();
  sc_core::sc_object* object() const;
  void object(sc_core::sc_object* b);
  unsigned unilang_id() const;
  virtual bool is_transmitter() const = 0;
  virtual std::string get_intf_name() const;
  virtual std::string get_REQ_name() const;
  virtual std::string get_RSP_name() const;
  virtual void set_intf_name(std::string s); 
  virtual void set_REQ_name(std::string s); 
  virtual void set_RSP_name(std::string s); 
  bool id_is_valid() const;
  void id_is_valid(bool b);
  void unconnected_error() const;
protected:
  sc_core::sc_object* m_obj;
  std::string m_intf_name;
  std::string m_REQ_name;
  std::string m_RSP_name;
  bool m_id_is_valid;
};

///////////////////

class sc_unilang_transmitter_base : public sc_unilang_transrec_base {
public:
  sc_unilang_transmitter_base(const char* name_);
  virtual ~sc_unilang_transmitter_base();
  virtual bool is_transmitter() const;
  virtual void register_port( sc_core::sc_port_base& port_, const char*) {
    this->object(&port_);
  }
};

class sc_unilang_receiver_base : public sc_unilang_transrec_base {
public:
  sc_unilang_receiver_base(const char* name_);
  virtual ~sc_unilang_receiver_base();
  virtual bool is_transmitter() const;
  virtual void bind_export(sc_core::sc_export_base* b);
  virtual sc_core::sc_interface* get_interface() const;
  //
protected:
  sc_core::sc_interface* m_iface;
public:
  void umsg(std::string f) {
    char msg[1024];
    sprintf(msg,"ovm function not implemented by receiver: %s",f.c_str());
    SC_REPORT_ERROR(sc_core::OVM_RECEIVER_FUNC_NOT_IMPL_,msg);
  }
  //virtual void tlm_blocking_put_if_put(NCUPO* arg) { 
  //  umsg("tlm_blocking_put_if_put");
 // }
  //virtual unsigned tlm_blocking_get_if_get(NCUPO* arg) { 
  //  umsg("tlm_blocking_get_if_get");
   // return 0;
  //}
  //
  virtual unsigned put_bitstream(
    unsigned stream_size, 
    void * stream
  ) { umsg("put_bitstream"); return 0; }
  virtual void put_bitstream_request(
    unsigned call_id, 
    unsigned stream_size, 
    void * stream
  ) { umsg("put_bitstream_request"); }
  virtual int try_put_bitstream(
    unsigned stream_size , 
    void * stream
  ) { umsg("try_put_bitstream"); return 0; } 
  virtual int can_put() { umsg("can_put"); return 0; } 
  //
  virtual void ok_to_put() { umsg("ok_to_put"); } 
  virtual void notify_ok_to_put() { umsg("notify_ok_to_put"); } 
  //
  virtual unsigned get_bitstream(
    unsigned* stream_size , 
    void * stream
  ) { umsg("get_bitstream"); return 0; } 
  virtual void get_bitstream_request(
    unsigned call_id
  ) { umsg("get_bitstream_request"); } 
  virtual int try_get_bitstream(
    unsigned * stream_size_ptr,
    void * stream
  ) { umsg("try_get_bitstream"); return 0; } 
  virtual int can_get() { umsg("can_get"); return 0; } 
  //
  virtual unsigned peek_bitstream(
    unsigned * stream_size_ptr,
    void * stream
  ) { umsg("peek_bitstream"); return 0; } 
  virtual void peek_bitstream_request(
    unsigned call_id
  ) { umsg("peek_bitstream_request"); } 
  virtual int try_peek_bitstream(
    unsigned * stream_size_ptr,
    void * stream
  ) { umsg("try_peek_bitstream"); return 0; } 
  virtual int can_peek() { umsg("can_peek"); return 0; } 
  //
  virtual unsigned transport_bitstream(
    unsigned req_stream_size, 
    void * req_stream,
    unsigned* rsp_stream_size,
    void* rsp_stream
  ) { umsg("transport_bitstream"); return 0; }
  virtual void transport_bitstream_request(
    unsigned call_id, 
    unsigned req_stream_size, 
    void * req_stream,
    unsigned* rsp_stream_size,
    void* rsp_stream
  ) { umsg("transport_bitstream_request"); }
  virtual void write_bitstream(
    unsigned stream_size , 
    void * stream
  ) { umsg("write_bitstream"); return; } 
};

/////////////////

template <class IF> class sc_unilang_transmitter :
  public sc_unilang_transmitter_base, virtual public IF {
public:
  // If you get here it won't compile
};

template <class IF> class sc_unilang_receiver :
  public sc_unilang_receiver_base, virtual public IF {
public:
  // If you get here it won't compile
};

/////////////////

/////////////////

} // namespace ml_ovm

#endif
