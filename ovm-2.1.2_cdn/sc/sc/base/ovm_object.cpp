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


#include "base/ovm_object.h"
#include "base/ovm_factory.h"
#include "base/ovm_packer.h"

using namespace std;

namespace ovm {

//------------------------------------------------------------------------------
//
// ovm_object
//
//------------------------------------------------------------------------------


ovm_object::ovm_object() { m_name = ""; }

ovm_object::ovm_object(const std::string& name) { m_name = name; }

ovm_object::~ovm_object() { }

void ovm_object::set_name(const string& name) {
  m_name = name;
}

string ovm_object::get_name() const {
  return m_name;
}

std::string ovm_object::get_full_name() const {
  return m_name;
}

void ovm_object::print(ostream& os) const { 
  do_print(os);
}

ostream& operator<<( ostream& os, const ovm_object& obj ) {
  obj.print(os);
  return os;
}

ostream& operator<<( ostream& os, const ovm_object* obj ) {
  obj->print(os);
  return os;
}

// clone() first creates a new object and then copies the existing object
// into the new object.
// returns the new object

ovm_object* ovm_object::clone() const {
  ovm_object* obj = ovm_factory::create_object(get_type_name(),"","",true);
  obj->copy(this);
  return obj;
}

int ovm_object::pack(ovm_packer& p) const {
  do_pack(p);
  return p.get_remaining_unpacked_bits();
}

int ovm_object::unpack(ovm_packer& p) {
  do_unpack(p);
  return p.get_remaining_unpacked_bits();
}

void ovm_object::copy(const ovm_object* rhs) {
  do_copy(rhs);
}

bool ovm_object::compare(const ovm_object* rhs) const {
  bool b = do_compare(rhs);
  return b;
}

///////////

// default implementations of required overrides

void ovm_object::do_print(ostream& os) const {
  os << get_type_name() << endl;
}

void ovm_object::do_pack(ovm_packer& ) const { }

void ovm_object::do_unpack(ovm_packer& ) { }

void ovm_object::do_copy(const ovm_object* rhs) { }

bool ovm_object::do_compare(const ovm_object* rhs) const { return true; }

///////////

static ovm_packer pp;

int ovm_object::pack_bits(std::vector<bool>& v, ovm_packer* p) {
  //static ovm_packer pp;
  if (!p) { pp.reset(); p = &pp; }
  pack(*p);
  p->get_bits(v);
  int n = p->get_remaining_unpacked_bits();
  return n;
}

int ovm_object::unpack_bits(const std::vector<bool>& v, ovm_packer* p) {
  //static ovm_packer pp;
  if (!p) { pp.reset(); p = &pp; }
  p->put_bits(v);
  unpack(*p);
  return v.size();
}

int ovm_object::pack_bytes(std::vector<char>& v, ovm_packer* p) {
  //static ovm_packer pp;
  if (!p) { pp.reset(); p = &pp; }
  pack(*p);
  p->get_bytes(v);
  int n = p->get_remaining_unpacked_bits();
  return n;
}

int ovm_object::unpack_bytes(const std::vector<char>& v, ovm_packer* p) {
  //static ovm_packer pp;
  if (!p) { pp.reset(); p = &pp; }
  p->put_bytes(v);
  unpack(*p);
  return v.size();
}

int ovm_object::pack_ints(std::vector<int>& v, ovm_packer* p) {
  //static ovm_packer pp;
  if (!p) { pp.reset(); p = &pp; }
  pack(*p);
  p->get_ints(v);
  int n = p->get_remaining_unpacked_bits();
  return n;
}

int ovm_object::unpack_ints(const std::vector<int>& v, ovm_packer* p) {
  //static ovm_packer pp;
  if (!p) { pp.reset(); p = &pp; }
  p->put_ints(v);
  unpack(*p);
  return v.size();
}

///////////

} // namespace ovm
