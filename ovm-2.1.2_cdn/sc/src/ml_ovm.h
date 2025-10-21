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

#ifndef ML_OVM_H
#define ML_OVM_H

#include "ovm.h"
#include "tlm.h"
#include "ml_ovm/ml_ovm_packer.h"
#include "ml_ovm/sc_unilang.h"
#include "sysc/cosim/sc_cosim_ids.h"
#include "sysc/cosim/ml_ovm_ids.h"

namespace ml_ovm {

static ml_ovm_exists m;

template <typename T1, typename T2>
class sc_unilang_transmitter_tlm :
  virtual public sc_unilang_transmitter_base,
  virtual public tlm::tlm_master_if<T1,T2>,
  virtual public tlm::tlm_slave_if<T2,T1>
#ifdef __TLM_ANALYSIS_H__
  ,virtual public tlm::tlm_analysis_if<T1>
#endif
{
public:
  sc_unilang_transmitter_tlm(const char* name_) 
    : sc_unilang_transmitter_base(name_), dummy_event(0, "sync") { 
  }
  ~sc_unilang_transmitter_tlm() { }
  virtual std::string interface_name() { return "tlm"; } // object->if_name()???
  unsigned connId;
  unsigned adapterId;

  // the put family

  virtual void put( const T1 &t ) {
    if (!this->id_is_valid()) { this->unconnected_error(); return; }
    //nc_unilang_packed_obj v;
    // blocking call, need to use ncupo from pool
    nc_unilang_packed_obj* v = sc_unilang_utils::get_ncupo_from_pool();
    ml_ovm_packer_pack(t,v);
    unsigned connId = this->unilang_id();
    sc_unilang_trans::unilang_put_bitstream_request(
      connId, v
    );
    sc_unilang_utils::release_ncupo_to_pool(v);
  }

  virtual bool nb_put( const T1 &t ) { 
    if (!this->id_is_valid()) { this->unconnected_error(); return false; }
    //nc_unilang_packed_obj v;
    nc_unilang_packed_obj& v = sc_unilang_utils::get_static_ncupo();
    ml_ovm_packer_pack(t,&v);
    unsigned connId = this->unilang_id();
    int ret = sc_unilang_trans::unilang_try_put_bitstream(
      connId, &v
    );
    return (ret == 0) ? false : true;
  }

  virtual bool nb_can_put( tlm::tlm_tag<T1> *t = 0 ) const { 
    if (!this->id_is_valid()) { this->unconnected_error(); return false; }
    unsigned connId = this->unilang_id();
    int ret = sc_unilang_trans::unilang_can_put(connId);
    return (ret == 0) ? false : true;
  }

  virtual const sc_event &ok_to_put( tlm::tlm_tag<T1> *t = 0 ) const {
    char msg[1024];
    sprintf(msg, "\nTLM interface is 'ok_to_put' \n");
    SC_REPORT_ERROR(sc_core::ML_OVM_UNIMPLEMENTED_INTERFACE_, msg); 
    return dummy_event;
  }

  // the get family

  virtual T2 get( tlm::tlm_tag<T2> *tag = 0 ) {
    if (!this->id_is_valid()) { this->unconnected_error(); return T2(); }
    //nc_unilang_packed_obj v;
    // blocking call, need to use ncupo from pool
    nc_unilang_packed_obj* v = sc_unilang_utils::get_ncupo_from_pool();
    sc_unilang_utils::allocate_ncupo(v);
    unsigned connId = this->unilang_id();
    sc_unilang_trans::unilang_get_bitstream_request(
      connId, v
    );
    T2* t;
    ml_ovm_packer_unpack_create(v, t, t);
    T2 tt = *t;
    delete t;
    sc_unilang_utils::release_ncupo_to_pool(v);
    return tt;
  }

  virtual bool nb_get( T2 &t ) { 
    if (!this->id_is_valid()) { this->unconnected_error(); return false; }
    //nc_unilang_packed_obj v;
    nc_unilang_packed_obj& v = sc_unilang_utils::get_static_ncupo();
    sc_unilang_utils::allocate_ncupo(&v);
    unsigned connId = this->unilang_id();
    int ret = sc_unilang_trans::unilang_try_get_bitstream(
      connId, &v
    );
    if (ret == 0) {
      // do not touch the input argument
      return false;
    }
    T2* t1;
    ml_ovm_packer_unpack_create(&v, t1, t1);
    t = *t1;
    delete t1;
    return true;
  }

  virtual bool nb_can_get( tlm::tlm_tag<T2> *t = 0 ) const { 
    if (!this->id_is_valid()) { this->unconnected_error(); return false; }
    unsigned connId = this->unilang_id();
    int ret = sc_unilang_trans::unilang_can_get(connId);
    return (ret == 0) ? false : true;
  }

  virtual const sc_event &ok_to_get( tlm::tlm_tag<T2> *t = 0 ) const {
    char msg[1024];
    sprintf(msg, "\nTLM interface is 'ok_to_get' \n");
    SC_REPORT_ERROR(sc_core::ML_OVM_UNIMPLEMENTED_INTERFACE_, msg); 
    return dummy_event;
  }

  // the peek family

  virtual T2 peek( tlm::tlm_tag<T2> *tag = 0 ) const { 
    if (!this->id_is_valid()) { this->unconnected_error(); return T2(); }
    //nc_unilang_packed_obj v;
    // blocking call, need to use ncupo from pool
    nc_unilang_packed_obj* v = sc_unilang_utils::get_ncupo_from_pool();
    sc_unilang_utils::allocate_ncupo(v);
    unsigned connId = this->unilang_id();
    sc_unilang_trans::unilang_peek_bitstream_request(
      connId, v
    );
    T2* t;
    ml_ovm_packer_unpack_create(v, t, t);
    T2 tt = *t;
    delete t;
    sc_unilang_utils::release_ncupo_to_pool(v);
    return tt;
  }

  virtual bool nb_peek( T2 &t ) const { 
    if (!this->id_is_valid()) { this->unconnected_error(); return false; }
    //nc_unilang_packed_obj v;
    nc_unilang_packed_obj& v = sc_unilang_utils::get_static_ncupo();
    sc_unilang_utils::allocate_ncupo(&v);
    unsigned connId = this->unilang_id();
    int ret = sc_unilang_trans::unilang_try_peek_bitstream(
      connId, &v
    );
    if (ret == 0) {
      // do not touch the input argument
      return false;
    }
    T2* t1;
    ml_ovm_packer_unpack_create(&v, t1, t1);
    t = *t1;
    delete t1;
    return true;
  }

  virtual bool nb_can_peek( tlm::tlm_tag<T2> *t = 0 ) const { 
    if (!this->id_is_valid()) { this->unconnected_error(); return false; }
    unsigned connId = this->unilang_id();
    int ret = sc_unilang_trans::unilang_can_peek(connId);
    return (ret == 0) ? false : true;
  }

  virtual const sc_event &ok_to_peek( tlm::tlm_tag<T2> *t = 0 ) const {
    char msg[1024];
    sprintf(msg, "\nTLM interface is 'ok_to_peek' \n");
    SC_REPORT_ERROR(sc_core::ML_OVM_UNIMPLEMENTED_INTERFACE_, msg); 
    return dummy_event;
  }


  // analysis_if

  virtual void write( const T1 &t ) { 
    if (!this->id_is_valid()) { this->unconnected_error(); return; }
    //nc_unilang_packed_obj v;
    nc_unilang_packed_obj& v = sc_unilang_utils::get_static_ncupo();
    ml_ovm_packer_pack(t,&v);
    unsigned connId = this->unilang_id();
    sc_unilang_trans::unilang_write_bitstream(
      connId, &v
    );
  }

protected:
  sc_event dummy_event;
};

template <typename REQ, typename RSP>
class sc_unilang_transmitter_tlm_transport :
  virtual public sc_unilang_transmitter_base,
  virtual public tlm::tlm_transport_if<REQ,RSP>
{
public:
  sc_unilang_transmitter_tlm_transport(const char* name_) 
    : sc_unilang_transmitter_base(name_) { 
  }
  ~sc_unilang_transmitter_tlm_transport() { }
  virtual std::string interface_name() { return "tlm"; } // object->if_name()???
  unsigned connId;
  unsigned adapterId;
  //
  virtual RSP transport( const REQ &t ) { 
    if (!this->id_is_valid()) { this->unconnected_error(); return RSP(); }
    //nc_unilang_packed_obj req, rsp;
    // blocking call, need to use ncupo from pool
    nc_unilang_packed_obj* req = sc_unilang_utils::get_ncupo_from_pool();
    nc_unilang_packed_obj* rsp = sc_unilang_utils::get_ncupo_from_pool();
    sc_unilang_utils::allocate_ncupo(rsp);
    ml_ovm_packer_pack(t,req);
    unsigned connId = this->unilang_id();
    sc_unilang_trans::unilang_transport_bitstream_request(
      connId, req, rsp
    );
    RSP* t1;
    ml_ovm_packer_unpack_create(rsp, t1, t1);
    RSP tt = *t1;
    delete t1;
    sc_unilang_utils::release_ncupo_to_pool(req);
    sc_unilang_utils::release_ncupo_to_pool(rsp);
    return tt;
  }
};

////////////

template <typename T1, typename T2> class sc_unilang_receiver_tlm
    : public sc_unilang_receiver_base
{
public:

#define UMSG(f) \
  { \
  char msg[1024]; \
  sprintf(msg,"ovm function not implemented by receiver: %s",#f); \
  SC_REPORT_ERROR(OVM_RECEIVER_FUNC_NOT_IMPL_,msg); \
  }

  sc_unilang_receiver_tlm(const char* nm) 
    : sc_unilang_receiver_base(nm) { m_init_done = false; }
  ~sc_unilang_receiver_tlm() { } 
  void init_interfaces() {
    if (m_init_done) return;
    iface_put = DCAST<tlm::tlm_blocking_put_if<T1>*>(get_interface());
    iface_get = DCAST<tlm::tlm_blocking_get_if<T2>*>(get_interface());
    iface_peek = DCAST<tlm::tlm_blocking_peek_if<T2>*>(get_interface());
    iface_nb_put = DCAST<tlm::tlm_nonblocking_put_if<T1>*>(get_interface());
    iface_nb_get = DCAST<tlm::tlm_nonblocking_get_if<T2>*>(get_interface());
    iface_nb_peek = DCAST<tlm::tlm_nonblocking_peek_if<T2>*>(get_interface());
    iface_transport = DCAST<tlm::tlm_transport_if<T1,T2>*>(get_interface());
#ifdef __TLM_ANALYSIS_H__
    iface_analysis = DCAST<tlm::tlm_analysis_if<T1>*>(get_interface());
#endif
    m_init_done = true;
  }
  unsigned put_bitstream(
    unsigned stream_size, 
    void * stream
  ) { 
    init_interfaces();
    if (!iface_put) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T1* t;
    //
    //nc_unilang_packed_obj vt; 
    nc_unilang_packed_obj& vt = sc_unilang_utils::get_static_ncupo(); 
    sc_unilang_utils::fill_ncupo(vt,stream_size,stream);
    //
    ml_ovm_packer_unpack_create(&vt, t, t);
    iface_put->put(*t);
    delete t;
    return 0;
  } 
  void put_bitstream_request(
    unsigned call_id, 
    unsigned stream_size, 
    void * stream
  ) { 
    UMSG(put_bitstream_request); 
  } 
  int try_put_bitstream(
    unsigned stream_size , 
    void * stream
  ) { 
    init_interfaces();
    if (!iface_nb_put) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T1* t;
    //
    //nc_unilang_packed_obj vt; 
    nc_unilang_packed_obj& vt = sc_unilang_utils::get_static_ncupo(); 
    sc_unilang_utils::fill_ncupo(vt,stream_size,stream);
    //
    ml_ovm_packer_unpack_create(&vt, t, t);
    int i = iface_nb_put->nb_put(*t);
    delete t;
    return i;
  }
  int can_put() {
    init_interfaces();
    if (!iface_nb_put) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    int i = iface_nb_put->nb_can_put();
    return i;
  }
  //
  unsigned get_bitstream(
    unsigned* stream_size,
    void * stream
  ) { 
    init_interfaces();
    if (!iface_get) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T2 t;
    t = iface_get->get();
    //
    //nc_unilang_packed_obj vt;
    nc_unilang_packed_obj& vt = sc_unilang_utils::get_static_ncupo(); 
    ml_ovm_packer_pack(t,&vt);
    *stream_size = sc_unilang_utils::copy_from_ncupo(vt, stream);
    return 0; // ???
  }
  void get_bitstream_request(
    unsigned call_id
  ) { UMSG(get_bitstream_request); } 
  int try_get_bitstream(
    unsigned * stream_size,
    void * stream
  ) { 
    init_interfaces();
    if (!iface_nb_get) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T2 t;
    bool b = iface_nb_get->nb_get(t);
    //
    //nc_unilang_packed_obj vt;
    nc_unilang_packed_obj& vt = sc_unilang_utils::get_static_ncupo(); 
    ml_ovm_packer_pack(t,&vt);
    *stream_size = sc_unilang_utils::copy_from_ncupo(vt, stream);
    return b; 
  }
  int can_get() { 
    init_interfaces();
    if (!iface_nb_get) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T2 t;
    //
    bool b = iface_nb_get->nb_can_get();
    return b ? 1 : 0;
  }
  //
  unsigned peek_bitstream(
    unsigned* stream_size,
    void * stream
  ) { 
    init_interfaces();
    if (!iface_peek) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T2 t;
    //
    t = iface_peek->peek();
    //nc_unilang_packed_obj vt;
    nc_unilang_packed_obj& vt = sc_unilang_utils::get_static_ncupo(); 
    ml_ovm_packer_pack(t,&vt);
    *stream_size = sc_unilang_utils::copy_from_ncupo(vt, stream);
    return 0; // ???
  }
  void peek_bitstream_request(
    unsigned call_id
  ) { UMSG(peek_bitstream_request); } 
  int try_peek_bitstream(
    unsigned * stream_size,
    void * stream
  ) { 
    init_interfaces();
    if (!iface_nb_peek) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T2 t;
    //
    bool b = iface_nb_peek->nb_peek(t);
    //nc_unilang_packed_obj vt;
    nc_unilang_packed_obj& vt = sc_unilang_utils::get_static_ncupo(); 
    ml_ovm_packer_pack(t,&vt);
    *stream_size = sc_unilang_utils::copy_from_ncupo(vt, stream);
    return b; 
  }
  int can_peek() { 
    init_interfaces();
    if (!iface_nb_peek) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T2 t;
    //
    bool b = iface_nb_peek->nb_can_peek();
    return b ? 1 : 0;
  }
  //
  virtual unsigned transport_bitstream( 
    unsigned req_stream_size,
    void* req_stream,
    unsigned* rsp_stream_size,
    void* rsp_stream
  ) {
    init_interfaces();
    if (!iface_transport) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return 0; }
    T1* t1;
    //
    //nc_unilang_packed_obj vt1; 
    nc_unilang_packed_obj& vt1 = sc_unilang_utils::get_static_ncupo(); 
    sc_unilang_utils::fill_ncupo(vt1,req_stream_size,req_stream);
    //
    ml_ovm_packer_unpack_create(&vt1, t1, t1);
    //
    T2 t2;
    t2 = iface_transport->transport(*t1);
    delete t1;
    //
    //nc_unilang_packed_obj vt2;
    //
    nc_unilang_packed_obj& vt2 = sc_unilang_utils::get_static_ncupo(); 
    ml_ovm_packer_pack(t2,&vt2);
    *rsp_stream_size = sc_unilang_utils::copy_from_ncupo(vt2, rsp_stream);
    return 0;
  }
  //
  void write_bitstream(
    unsigned stream_size , 
    void * stream
  ) { 
#ifdef __TLM_ANALYSIS_H__
    init_interfaces();
    if (!iface_analysis) { SC_REPORT_ERROR(OVM_PORT_IFACE_,""); return; }
    T1* t;
    //
    //nc_unilang_packed_obj vt; 
    nc_unilang_packed_obj& vt = sc_unilang_utils::get_static_ncupo(); 
    sc_unilang_utils::fill_ncupo(vt,stream_size,stream);
    //
    ml_ovm_packer_unpack_create(&vt, t, t);
    iface_analysis->write(*t);
    delete t;
#endif
  }
  void ok_to_put() { UMSG(ok_to_put); } 
  void notify_ok_to_put() { UMSG(notify_ok_to_put); } 
protected:
  bool m_init_done;
  tlm::tlm_blocking_put_if<T1>* iface_put;
  tlm::tlm_nonblocking_put_if<T1>* iface_nb_put;
  tlm::tlm_blocking_get_if<T2>* iface_get;
  tlm::tlm_nonblocking_get_if<T2>* iface_nb_get;
  tlm::tlm_blocking_peek_if<T2>* iface_peek;
  tlm::tlm_nonblocking_peek_if<T2>* iface_nb_peek;
  tlm::tlm_transport_if<T1,T2>* iface_transport;
#ifdef __TLM_ANALYSIS_H__
  tlm::tlm_analysis_if<T1>* iface_analysis;
#endif
};

//////////

extern void notify_ml_ovm_register_called(); 

#define sc_unilang_declare_register_funcs(IF) \
template <typename T, int N, sc_core::sc_port_policy POL> \
void ml_ovm_register( \
  sc_core::sc_port<tlm::IF<T>,N,POL>* p \
) { \
  notify_ml_ovm_register_called(); \
  std::string s = std::string(p->basename()) + "_trans"; \
  sc_unilang_transmitter_tlm<T,T>* trans = \
    new sc_unilang_transmitter_tlm<T,T>(s.c_str()); \
  p->bind(*trans); \
  trans->object(p); \
  trans->set_intf_name(#IF); \
  trans->set_REQ_name(T().get_type_name()); \
  trans->set_RSP_name(T().get_type_name()); \
} \
\
template <typename T> \
void ml_ovm_register( \
  sc_core::sc_export<tlm::IF<T> >* p \
) { \
  notify_ml_ovm_register_called(); \
  std::string s = std::string(p->basename()) + "_rec"; \
  sc_unilang_receiver_tlm<T,T>* rec =  \
    new sc_unilang_receiver_tlm<T,T>(s.c_str()); \
  rec->bind_export(p); \
  rec->set_intf_name(#IF); \
  rec->set_REQ_name(T().get_type_name()); \
  rec->set_RSP_name(T().get_type_name()); \
}

sc_unilang_declare_register_funcs(tlm_blocking_put_if)
sc_unilang_declare_register_funcs(tlm_nonblocking_put_if)
sc_unilang_declare_register_funcs(tlm_put_if)

sc_unilang_declare_register_funcs(tlm_blocking_get_if)
sc_unilang_declare_register_funcs(tlm_nonblocking_get_if)
sc_unilang_declare_register_funcs(tlm_get_if)

sc_unilang_declare_register_funcs(tlm_blocking_peek_if)
sc_unilang_declare_register_funcs(tlm_nonblocking_peek_if)
sc_unilang_declare_register_funcs(tlm_peek_if)

sc_unilang_declare_register_funcs(tlm_blocking_get_peek_if)
sc_unilang_declare_register_funcs(tlm_nonblocking_get_peek_if)
sc_unilang_declare_register_funcs(tlm_get_peek_if)

#ifdef __TLM_ANALYSIS_H__

template <typename T, int N, sc_core::sc_port_policy POL> 
void ml_ovm_register( 
  sc_core::sc_port<tlm::tlm_analysis_if<T>,N,POL>* p 
) { 
  notify_ml_ovm_register_called();  
  std::string s = std::string(p->basename()) + "_trans"; 
  sc_unilang_transmitter_tlm<T,T>* trans = 
    new sc_unilang_transmitter_tlm<T,T>(s.c_str()); 
  p->bind(*trans); 
  trans->object(p); 
  trans->set_intf_name("tlm_analysis_if"); 
  trans->set_REQ_name(T().get_type_name()); 
  trans->set_RSP_name(T().get_type_name()); 
} 

template <typename T> 
void ml_ovm_register( 
  tlm::tlm_analysis_port<T>* p 
) { 
  notify_ml_ovm_register_called();  
  std::string s = std::string(p->basename()) + "_trans"; 
  sc_unilang_transmitter_tlm<T,T>* trans = 
    new sc_unilang_transmitter_tlm<T,T>(s.c_str()); 
  p->bind(*trans); 
  trans->object(p); 
  trans->set_intf_name("tlm_analysis_if"); 
  trans->set_REQ_name(T().get_type_name()); 
  trans->set_RSP_name(T().get_type_name()); 
} 

template <typename T> 
void ml_ovm_register( 
  sc_core::sc_export<tlm::tlm_analysis_if<T> >* p 
) { 
  notify_ml_ovm_register_called(); 
  std::string s = std::string(p->basename()) + "_rec"; 
  sc_unilang_receiver_tlm<T,T>* rec =  
    new sc_unilang_receiver_tlm<T,T>(s.c_str()); 
  rec->bind_export(p); 
  rec->set_intf_name("tlm_analysis_if"); 
  rec->set_REQ_name(T().get_type_name()); 
  rec->set_RSP_name(T().get_type_name()); 
}

#endif

//////////////

template <typename REQ, typename RSP, int N, sc_core::sc_port_policy POL> 
void ml_ovm_register( 
  sc_core::sc_port<tlm::tlm_transport_if<REQ,RSP>,N,POL>* p 
) { 
  notify_ml_ovm_register_called();  
  std::string s = std::string(p->basename()) + "_trans"; 
  sc_unilang_transmitter_tlm_transport<REQ,RSP>* trans = 
    new sc_unilang_transmitter_tlm_transport<REQ,RSP>(s.c_str()); 
  p->bind(*trans); 
  trans->object(p); 
  trans->set_intf_name("tlm_transport_if");
  trans->set_REQ_name(REQ().get_type_name());
  trans->set_RSP_name(RSP().get_type_name());
} 

template <typename REQ, typename RSP> 
void ml_ovm_register( 
  sc_core::sc_export<tlm::tlm_transport_if<REQ,RSP> >* p 
) { 
  notify_ml_ovm_register_called(); 
  std::string s = std::string(p->basename()) + "_rec"; 
  sc_unilang_receiver_tlm<REQ,RSP>* rec =  
    new sc_unilang_receiver_tlm<REQ,RSP>(s.c_str()); 
  rec->bind_export(p); 
  rec->set_intf_name("tlm_transport_if");
  rec->set_REQ_name(REQ().get_type_name());
  rec->set_RSP_name(RSP().get_type_name());
}

//////////////

template <typename REQ, typename RSP, int N, sc_core::sc_port_policy POL> 
void ml_ovm_register( 
  sc_core::sc_port<tlm::tlm_master_if<REQ,RSP>,N,POL>* p 
) { 
  notify_ml_ovm_register_called(); 
  std::string s = std::string(p->basename()) + "_trans"; 
  sc_unilang_transmitter_tlm<REQ,RSP>* trans = 
    new sc_unilang_transmitter_tlm<REQ,RSP>(s.c_str()); 
  p->bind(*trans); 
  trans->object(p); 
  trans->set_intf_name("tlm_master_if");
  trans->set_REQ_name(REQ().get_type_name());
  trans->set_RSP_name(RSP().get_type_name());
} 

template <typename REQ, typename RSP> 
void ml_ovm_register( 
  sc_core::sc_export<tlm::tlm_master_if<REQ,RSP> >* p 
) { 
  notify_ml_ovm_register_called(); 
  std::string s = std::string(p->basename()) + "_rec"; 
  sc_unilang_receiver_tlm<REQ,RSP>* rec =  
    new sc_unilang_receiver_tlm<REQ,RSP>(s.c_str()); 
  rec->bind_export(p); 
  rec->set_intf_name("tlm_master_if");
  rec->set_REQ_name(REQ().get_type_name());
  rec->set_RSP_name(RSP().get_type_name());
}

//////////////

template <typename REQ, typename RSP, int N, sc_core::sc_port_policy POL> 
void ml_ovm_register( 
  sc_core::sc_port<tlm::tlm_slave_if<REQ,RSP>,N,POL>* p 
) { 
  notify_ml_ovm_register_called(); 
  std::string s = std::string(p->basename()) + "_trans"; 
  // slave_if is templated by <REQ,RSP>, and it does put(RSP&) and
  // get(REQ&). A transmitter always does put(T1) and get(T2), so 
  // we need to instantiate transmitter templated by <RSP,REQ>
  sc_unilang_transmitter_tlm<RSP,REQ>* trans = 
    new sc_unilang_transmitter_tlm<RSP,REQ>(s.c_str()); 
  p->bind(*trans); 
  trans->object(p); 
  trans->set_intf_name("tlm_slave_if");
  // REQ_name and RSP_name are set according to the sc_port argument order
  // which is <REQ,RSP> because we will check compatibility of 
  // sc_port<tlm_slave_if<REQ,RSP> > with ovm_slave_imp#(REQ,RSP), and
  // that should match
  trans->set_REQ_name(REQ().get_type_name());
  trans->set_RSP_name(RSP().get_type_name());
} 

template <typename REQ, typename RSP> 
void ml_ovm_register( 
  sc_core::sc_export<tlm::tlm_slave_if<REQ,RSP> >* p 
) { 
  notify_ml_ovm_register_called(); 
  std::string s = std::string(p->basename()) + "_rec"; 
  //sc_unilang_receiver_tlm<REQ,RSP>* rec =  
  //  new sc_unilang_receiver_tlm<REQ,RSP>(s.c_str()); 
  // slave_if is templated by <REQ,RSP>, and it does put(RSP&) and
  // get(REQ&). A receiver always does put(T1) and get(T2), so 
  // we need to instantiate receiver templated by <RSP,REQ>
  sc_unilang_receiver_tlm<RSP,REQ>* rec =  
    new sc_unilang_receiver_tlm<RSP,REQ>(s.c_str()); 
  rec->bind_export(p); 
  // REQ_name and RSP_name are set according to the sc_port argument order
  // which is <REQ,RSP> because we will check compatibility of 
  // sc_export<tlm_slave_if<REQ,RSP> > with ovm_slave_port#(REQ,RSP), and that
  // should match
  rec->set_intf_name("tlm_slave_if");
  rec->set_REQ_name(REQ().get_type_name());
  rec->set_RSP_name(RSP().get_type_name());
}

//////////

// debugging aid: print_ovm works for both int* and ovm_object*
// find some better way to do this

template <class T> void print_ovm(std::ostream& os, T* val, void* t) {
  std::cerr << "print_ovm<T*>" << std::endl;
  os << *val << std::endl;
}

template <class T> void print_ovm(std::ostream& os, const T* val, const void* t) {
  std::cerr << "print_ovm<T*>" << std::endl;
  os << *val << std::endl;
}

template <class T> void print_ovm(std::ostream& os, T* val, ovm::ovm_object* t) {
  std::cerr << "print_ovm<ovm_object*>" << std::endl;
  val->print(os);
}

template <class T> void print_ovm(std::ostream& os, const T* val, const ovm::ovm_object* t) {
  std::cerr << "print_ovm<const ovm_object*>" << std::endl;
  val->print(os);
}

////////////////////////////

} // namespace ml_ovm

#endif
