//----------------------------------------------------------------------
//   Copyright 2009 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------


#include "base/ovm_factory.h"
#include "base/ovm_packer.h"
#include "base/ovm_object.h"

#include "sysc/kernel/sc_simcontext.h"

#include <typeinfo>
#include <iostream>

using namespace std;
using namespace sc_dt;
using namespace sc_core;

namespace ovm {


//-----------------------------------------------------------------------------
//
// ovm_packer
//
//-----------------------------------------------------------------------------

/////////////////////////////

// debugging aid to print informative messages when packing/unpacking

bool print_pack_info = getenv("print_pack_info");

/////////////////////////////

// NOTE: unlimited max size 
// memory is allocated dynamically in chunks of 
// sc_bv_base(OVM_PACKING_BLOCK_SIZE)


//------------------------------------------------------------------------------
//
// CLASS: ovm_packer_rep
//
// Internal implementation class.
// ovm_packer delegetates to this class to do the real work.
//
//---------------------------------------------------------------------------

class ovm_packer_rep {
public:
  ovm_packer_rep(ovm_packer* packer);
  ~ovm_packer_rep();
  //
  void allocate(int nbits, bool copy = true);
  void reset();
  void set_size(int nbits);
  //
  void put_bits(const std::vector<bool>& v);
  void get_bits(std::vector<bool>& v);
  void put_bytes(const std::vector<char>& v);
  void get_bytes(std::vector<char>& v);
  void put_ints(const std::vector<int>& v);
  void get_ints(std::vector<int>& v);
  //
  bool use_metadata() const { return m_use_metadata; }
  void use_metadata(bool b) { m_use_metadata = b; }
  //
  void check_size(int nbits);

  //
  void pack_non_null();
  bool unpack_non_null();
  void pack_null();
  //
  void pack_int_n(uint64 k, unsigned nbits);
  uint64 unpack_int_n(unsigned nbits);
  //
  void pack_char(char);
  void unpack_char(char&);
  //
  void pack_string(std::string s);
  void unpack_string(std::string& s);
  //
  void pack_obj(ovm_object*);
  void unpack_obj(ovm_object*&);
  //
  void pack_sc_logic(const sc_logic&);
  void unpack_sc_logic(sc_logic&);
  void pack_sc_bv_base(const sc_bv_base&);
  void unpack_sc_bv_base(sc_bv_base&);
  void pack_sc_lv_base(const sc_lv_base&);
  void unpack_sc_lv_base(sc_lv_base&);
  void pack_sc_int_base(const sc_int_base&);
  void unpack_sc_int_base(sc_int_base&);
  void pack_sc_uint_base(const sc_uint_base&);
  void unpack_sc_uint_base(sc_uint_base&);
  void pack_sc_signed(const sc_signed&);
  void unpack_sc_signed(sc_signed&);
  void pack_sc_unsigned(const sc_unsigned&);
  void unpack_sc_unsigned(sc_unsigned&);
  //
  unsigned get_remaining_unpacked_bits() { return pack_index - unpack_index; }
  int get_size() { return size; }
  sc_bv_base* get_packed_bits() { return m_bits; }
  int get_pack_index() const { return pack_index; }
  void set_pack_index(int n) { pack_index = n; }
private:
  void inc_unpack_index(int n);
private:
  ovm_packer* m_packer;
  bool m_use_metadata;
  unsigned pack_index;
  unsigned unpack_index;

  sc_bv_base* m_bits;
  int size;
  int max_size;
};

//------------------------------------------------------------------------------
// ovm_packer_rep implementation
//------------------------------------------------------------------------------

ovm_packer_rep::ovm_packer_rep(ovm_packer* packer) {
  //cout << "in packer ctor " << endl;
  m_packer = packer;
  m_use_metadata = false;

  pack_index = 0;
  unpack_index = 0;

  size = 0;
  max_size = 0;
  m_bits = 0;
}

ovm_packer_rep::~ovm_packer_rep() {
  //cout << "in packer dtor " << endl;
  if (m_bits)
    delete m_bits;
}

void ovm_packer_rep::allocate(int nbits, bool copy_) {
  // allocate new sc_bv_base with new size, and copy over contents from
  // old sc_bv_base

  int total_bits = pack_index + nbits;
  int new_size = 
    ((total_bits - 1)/OVM_PACKING_BLOCK_SIZE + 1) * OVM_PACKING_BLOCK_SIZE;
#ifdef _NCSC_DEBUG
  assert((new_size % OVM_PACKING_BLOCK_SIZE) == 0);
#endif
  size = new_size;
  if (size > max_size) { // need to allocate
    max_size = size;
    sc_bv_base* new_bv = new sc_bv_base(size);
    if (m_bits) {
      if (copy_) { 
        *new_bv = *m_bits;
      }
      delete m_bits;
    }
    m_bits = new_bv;
  }
}
  
void ovm_packer_rep::set_size(int nbits) {
  // check that we are in a "fresh" packer, e.g. one that has been reset
#ifdef _NCSC_DEBUG  
  assert(size == 0);
  assert(pack_index == 0);
#endif
  // no need to copy over from old sc_bv_base
  allocate(nbits, false);  
}

void ovm_packer_rep::reset() {

  pack_index = 0;
  unpack_index = 0;
  size = 0;
}

void ovm_packer_rep::inc_unpack_index(int n) {
  unpack_index += n;
  if (unpack_index > pack_index) {
    char msg[1024];
    sprintf(msg,"unpack_index=%d, pack_index=%d",unpack_index,pack_index);
    SC_REPORT_ERROR(OVM_PACKER_UNPACK_INDEX_,msg);
  }
}

/////////////////

// put_xxx() and get_xxx() are internal ovm_packer member methods
// called from the user-visible API in ovm_object:
// pack_bits, pack_bytes(), pack_ints(), and
// unpack_bits(), unpack_bytes(), unpack_ints()

// put_xxx() is just like packing, including incrementing the packing index;
// get_xxx() is not like unpacking - all the info is extracted into the 
// given vector, but unpacking index is not incremented
  
void ovm_packer_rep::put_bits(const std::vector<bool>& v) {
  reset();
  int n = v.size();
  set_size(n);
  for (int i = 0; i < n; i++) {
    (*m_bits)[i] = v[i];
  }
  pack_index = n;
}

void ovm_packer_rep::get_bits(std::vector<bool>& v) {
  unsigned n = get_remaining_unpacked_bits();
  for (unsigned i = 0; i < n; i++) {
    bool b = (*m_bits)[i].to_bool();
    v.push_back(b);
  }
}

void ovm_packer_rep::put_bytes(const std::vector<char>& v) {
  reset();
  int n = v.size();
  set_size(n*8);
  for (int i = 0; i < n; i++) {
    (*m_bits).range(8*i+7,8*i) = v[i];
  }
  pack_index = 8*n;
}

void ovm_packer_rep::get_bytes(std::vector<char>& v) {
  unsigned n = get_remaining_unpacked_bits();
  unsigned nbytes = 1 + (n-1)/8;
  for (unsigned i = 0; i < nbytes; i++) {
    char b = (*m_bits).range(8*i+7,8*i).to_int();
    v.push_back(b);
  }
}

void ovm_packer_rep::put_ints(const std::vector<int>& v) {
  reset();
  int n = v.size();
  set_size(n*32);
  for (int i = 0; i < n; i++) {
    (*m_bits).range(32*i+31,32*i) = v[i];
  }
  pack_index = 32*n;
}

void ovm_packer_rep::get_ints(std::vector<int>& v) {
  unsigned n = get_remaining_unpacked_bits();
  unsigned nints = 1 + (n-1)/32;
  for (unsigned i = 0; i < nints; i++) {
    int b = (*m_bits).range(32*i+31,32*i).to_int();
    v.push_back(b);
  }
}

////////

void ovm_packer_rep::check_size(int nbits) {
  int capacity = size - pack_index;
  if (nbits >= capacity) {
    allocate(nbits);
  }
}

// put a 8-bit 1 meaning non-null for ovm_objects

void ovm_packer_rep::pack_non_null() {
  int nbits = 8;
  check_size(nbits);
  (*m_bits)(pack_index + nbits - 1, pack_index) = 1;
  pack_index += nbits;
  if (print_pack_info) cerr << "ovm_packer_rep::pack_non_null " << endl;
}

// put 8-bit 0 meaning null for ovm_objects

void ovm_packer_rep::pack_null() {
  int nbits = 8;
  check_size(nbits);
  (*m_bits)(pack_index + nbits - 1, pack_index) = 0;
  pack_index += nbits;
  if (print_pack_info) cerr << "ovm_packer_rep::pack_null " << endl;
}

bool ovm_packer_rep::unpack_non_null() {
  int nbits = 8;
  int a = (*m_bits)(unpack_index + nbits - 1, unpack_index).to_int();
  inc_unpack_index(nbits);
  if (!a) { 
    if (print_pack_info) cerr << "ovm_packer_rep::unpack_non_null FALSE " << endl;
    return false;
  }
  if (print_pack_info) cerr << "ovm_packer_rep::unpack_non_null true " << endl;
  return true;
}

////////

void ovm_packer_rep::pack_char(char a) {
  int nbits = 8;
  check_size(nbits);
  (*m_bits)(pack_index + nbits - 1, pack_index) = a;
  pack_index += nbits;
  if (print_pack_info) cerr << "ovm_packer_rep::pack_char " << a << endl;
}

void ovm_packer_rep::unpack_char(char& a) {
  unsigned nbits = 8;
  a = (*m_bits)(unpack_index + nbits - 1, unpack_index).to_int();
  inc_unpack_index(nbits);
  if (print_pack_info) cerr << "ovm_packer_rep::unpack_char -> " << a << endl;
}

////////

void ovm_packer_rep::pack_int_n(unsigned long long a, unsigned nbits) {
  check_size(nbits);
  (*m_bits)(pack_index + nbits - 1, pack_index) = a;
  pack_index += nbits;
  if (print_pack_info) cerr << "ovm_packer_rep::pack_int_n " << a 
    << " " << nbits << endl;
}

uint64 ovm_packer_rep::unpack_int_n(unsigned nbits) {
  uint64 a;
  a = (*m_bits)(unpack_index + nbits - 1, unpack_index).to_uint64();
  inc_unpack_index(nbits);
  if (print_pack_info) cerr << "ovm_packer_rep::unpack_int_n " 
    << nbits << " -> " << a << endl;
  return a;
}

// after packing a string, pack a null byte at the end 

void ovm_packer_rep::pack_string(std::string a) {
  int nchars = a.length();
  for (int i = 0; i < nchars; i++) {
    pack_char(a[i]);
  }
  pack_char(0);
  if (print_pack_info) cerr << "ovm_packer_rep::pack_string " << a << endl;
}

void ovm_packer_rep::unpack_string(std::string& a) {
  a = "";
  std::string cs;
  while (1) {
    char c;
    unpack_char(c);
    if (!c) break;
    cs = c;
    a = a + cs;
  }
  if (print_pack_info) 
    cerr << "ovm_packer_rep::unpack_string: " << a << endl;
}

// metadata affects how a nested ovm_object is packed.
// if metadata is included, then before packing the ovm_object, pack 2
// additional items:
// 1) 8 bits set to 1 if the ovm_object is non-null, and set 
// to 0 if ovm_object is null
// 2) the string name of the ovm_object, as returned by get_type_name()

void ovm_packer_rep::pack_obj(ovm_object* a) {
  if (use_metadata()) {
    if (!a) {
      if (print_pack_info) cerr << "ovm_packer_rep::pack_obj packing null"
        << endl;
      pack_null();
      return;
    }
    pack_non_null();
    std::string s = a->get_type_name();
    pack_string(s);
    //unsigned id = ovm_get_type_id(s);
    //pack_int_n(id, 8*sizeof(id));
  }
  if (!a) {
    SC_REPORT_ERROR(OVM_PACK_NULL_,"");
    return;
  }
  a->pack(*m_packer);
  if (print_pack_info) cerr << "ovm_packer_rep::pack_obj " 
    << a->get_type_name() << endl;
}

// metadata affects how a nested ovm_object is unpacked.
// metadata must have been packed during the corresponding packing
// operation, as the packer allocates/creates the ovm_object from the
// factory using the packed type name.
// if metadata was not packed, then the packer errors out.

void ovm_packer_rep::unpack_obj(ovm_object*& a) {
  if (!use_metadata()) {
    SC_REPORT_ERROR(OVM_UNPACK_OBJ_NO_METADATA_,"");
    a = 0;
    return;
  }
  std::string s;
  if (!unpack_non_null()) {
    if (print_pack_info) {
      cerr << "ovm_packer_rep::unpack unpack_non_null FALSE" << endl;
    }
    a = 0;
    return;
  }
  unpack_string(s);
  //unsigned id = 0;
  //unpack_int_n(id, 8*sizeof(id));
  //s = ovm_get_type_name(id);
  ovm_object* obj = ovm_factory::create_object(s,"","",true);
  if (!obj) {
    char msg[1024];
    sprintf(msg,"Unpack ovm_object failed. Type = %s",s.c_str());
    SC_REPORT_ERROR(OVM_PACKER_UNPACK_OBJECT_,msg);
    return;
  }
  obj->unpack(*m_packer);
  a = obj;
  if (print_pack_info) cerr << "ovm_packer_rep::unpack_obj " << endl;
}

void ovm_packer_rep::pack_sc_logic(const sc_logic& a) {
  check_size(1);
  (*m_bits).set_bit(pack_index, a.value());
  pack_index++;
}

void ovm_packer_rep::unpack_sc_logic(sc_logic& a) {
  sc_dt::sc_logic_value_t val = (*m_bits).get_bit(unpack_index);
  a = val;
  inc_unpack_index(1);
}

void ovm_packer_rep::pack_sc_bv_base(const sc_bv_base& a) {
  int nbits = a.length();
  check_size(nbits);
  (*m_bits)(pack_index + nbits - 1, pack_index) = a;
  pack_index += nbits;
}

void ovm_packer_rep::unpack_sc_bv_base(sc_bv_base& a) {
  int nbits = a.length();
  a = (*m_bits)(unpack_index + nbits - 1, unpack_index);
  inc_unpack_index(nbits);
}

void ovm_packer_rep::pack_sc_lv_base(const sc_lv_base& a) {
  int n = a.length();
  check_size(n);
  for (int i = 0; i < n; i++) {
    sc_dt::sc_logic_value_t val = a.get_bit(i);
    (*m_bits).set_bit(pack_index, val);
    pack_index++;
  }
}

void ovm_packer_rep::unpack_sc_lv_base(sc_lv_base& a) {
  int n = a.length();
  for (int i = 0; i < n; i++) {
    sc_dt::sc_logic_value_t val = (*m_bits).get_bit(unpack_index);
    a.set_bit(i, val);
    unpack_index++;
  }
}

void ovm_packer_rep::pack_sc_int_base(const sc_int_base& a) {
  int n = a.length();
  check_size(n);
  for (int i = 0; i < n; i++) {
    bool val = a.test(i);
    if (val) {
      (*m_bits).set_bit(pack_index, sc_dt::Log_1);
    } else {
      (*m_bits).set_bit(pack_index, sc_dt::Log_0);
    }
    pack_index++;
  }
}

void ovm_packer_rep::unpack_sc_int_base(sc_int_base& a) {
  int n = a.length();
  for (int i = 0; i < n; i++) {
    sc_dt::sc_logic_value_t val = (*m_bits).get_bit(unpack_index);
    if (int(val) == int(sc_dt::Log_1)) {
      a.set(i, true);
    } else {
      a.set(i, false);
    }
    unpack_index++;
  }
}

void ovm_packer_rep::pack_sc_uint_base(const sc_uint_base& a) {
  int n = a.length();
  check_size(n);
  for (int i = 0; i < n; i++) {
    bool val = a.test(i);
    if (val) {
      (*m_bits).set_bit(pack_index, sc_dt::Log_1);
    } else {
      (*m_bits).set_bit(pack_index, sc_dt::Log_0);
    }
    pack_index++;
  }
}

void ovm_packer_rep::unpack_sc_uint_base(sc_uint_base& a) {
  int n = a.length();
  for (int i = 0; i < n; i++) {
    sc_dt::sc_logic_value_t val = (*m_bits).get_bit(unpack_index);
    if (int(val) == int(sc_dt::Log_1)) {
      a.set(i, true);
    } else {
      a.set(i, false);
    }
    unpack_index++;
  }
}

void ovm_packer_rep::pack_sc_signed(const sc_signed& a) {
  int n = a.length();
  check_size(n);
  for (int i = 0; i < n; i++) {
    bool val = a.test(i);
    if (val) {
      (*m_bits).set_bit(pack_index, sc_dt::Log_1);
    } else {
      (*m_bits).set_bit(pack_index, sc_dt::Log_0);
    }
    pack_index++;
  }
}

void ovm_packer_rep::unpack_sc_signed(sc_signed& a) {
  int n = a.length();
  for (int i = 0; i < n; i++) {
    sc_dt::sc_logic_value_t val = (*m_bits).get_bit(unpack_index);
    if (int(val) == int(sc_dt::Log_1)) {
      a.set(i, true);
    } else {
      a.set(i, false);
    }
    unpack_index++;
  }
}

void ovm_packer_rep::pack_sc_unsigned(const sc_unsigned& a) {
  int n = a.length();
  check_size(n);
  for (int i = 0; i < n; i++) {
    bool val = a.test(i);
    if (val) {
      (*m_bits).set_bit(pack_index, sc_dt::Log_1);
    } else {
      (*m_bits).set_bit(pack_index, sc_dt::Log_0);
    }
    pack_index++;
  }
}

void ovm_packer_rep::unpack_sc_unsigned(sc_unsigned& a) {
  int n = a.length();
  for (int i = 0; i < n; i++) {
    sc_dt::sc_logic_value_t val = (*m_bits).get_bit(unpack_index);
    if (int(val) == int(sc_dt::Log_1)) {
      a.set(i, true);
    } else {
      a.set(i, false);
    }
    unpack_index++;
  }
}

/////////////////////////////

//----------------------------------------------------------------------
// ovm_packer implementation
//----------------------------------------------------------------------

ovm_packer::ovm_packer() {
  m_rep = new ovm_packer_rep(this);
  m_rep->use_metadata(false);
}

ovm_packer::~ovm_packer() { 
  delete m_rep;
}

////////

void ovm_packer::reset() { m_rep->reset(); }
void ovm_packer::put_bits(const std::vector<bool>& v) { m_rep->put_bits(v); }
void ovm_packer::get_bits(std::vector<bool>& v) { m_rep->get_bits(v); }
void ovm_packer::put_bytes(const std::vector<char>& v) { m_rep->put_bytes(v); }
void ovm_packer::get_bytes(std::vector<char>& v) { m_rep->get_bytes(v); }
void ovm_packer::put_ints(const std::vector<int>& v) { m_rep->put_ints(v); }
void ovm_packer::get_ints(std::vector<int>& v) { m_rep->get_ints(v); }

bool ovm_packer::use_metadata() const {
  return m_rep->use_metadata();
}

void ovm_packer::use_metadata(bool b) {
  m_rep->use_metadata(b);
}

int ovm_packer::get_remaining_unpacked_bits() {
  return m_rep->get_remaining_unpacked_bits();
}

int ovm_packer::get_size() {
  return m_rep->get_size();
}

void ovm_packer::set_size(int nbits) {
  m_rep->set_size(nbits);
}

sc_bv_base* ovm_packer::get_packed_bits() {
  return m_rep->get_packed_bits();
}

int ovm_packer::get_pack_index() const {
  return m_rep->get_pack_index();
}

void ovm_packer::set_pack_index(int n) {
  m_rep->set_pack_index(n);
}

////////

ovm_packer& ovm_packer::operator << (bool a) { 
  int i = a ? 1 : 0;
  m_rep->pack_int_n(i,1);
  return *this;
}

ovm_packer& ovm_packer::operator >> (bool& a) { 
  a = (bool)(m_rep->unpack_int_n(1));
  return *this;
}

/////////////////////////////

#define def_pack_int_operators(T) \
ovm_packer& ovm_packer::operator << (T a) { \
  m_rep->pack_int_n(a,8*sizeof(T));\
  return *this;\
} \
ovm_packer& ovm_packer::operator >> (T& a) {  \
  a = (T)(m_rep->unpack_int_n(8*sizeof(T))); \
  return *this; \
}

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;

def_pack_int_operators(char)
def_pack_int_operators(uchar)
def_pack_int_operators(short)
def_pack_int_operators(ushort)
def_pack_int_operators(int)
def_pack_int_operators(uint)
def_pack_int_operators(long)
def_pack_int_operators(ulong)
def_pack_int_operators(int64)
def_pack_int_operators(uint64)

////////////////////////////////////

ovm_packer& ovm_packer::operator << (const char* a) { 
  if (!a) {
    m_rep->pack_string("");
  } else {
    m_rep->pack_string(a);
  }
  return *this;
}

ovm_packer& ovm_packer::operator << (std::string a) { 
  m_rep->pack_string(a);
  return *this;
}

ovm_packer& ovm_packer::operator >> (std::string& a) { 
  m_rep->unpack_string(a);
  return *this;
}

ovm_packer& ovm_packer::operator << (ovm_object* a) {
  m_rep->pack_obj(a);
  return *this;
}

ovm_packer& ovm_packer::operator >> (ovm_object*& a) {
  m_rep->unpack_obj(a);
  return *this;
}

ovm_packer& ovm_packer::operator << (const ovm_object& a) {
  m_rep->pack_obj((ovm_object*)(&a));
  return *this;
}

#define def_pack_sctype_operators(T) \
ovm_packer& ovm_packer::operator << (const T& a) { \
  m_rep->pack_##T(a);\
  return *this;\
} \
ovm_packer& ovm_packer::operator >> (T& a) {  \
  m_rep->unpack_##T(a); \
  return *this; \
}

def_pack_sctype_operators(sc_logic)
def_pack_sctype_operators(sc_bv_base)
def_pack_sctype_operators(sc_lv_base)
def_pack_sctype_operators(sc_int_base)
def_pack_sctype_operators(sc_uint_base)
def_pack_sctype_operators(sc_signed)
def_pack_sctype_operators(sc_unsigned)

////////////


} // namespace ovm 

