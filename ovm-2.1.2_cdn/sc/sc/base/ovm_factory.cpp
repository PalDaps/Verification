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
#include "base/ovm_config.h"

#include "sysc/utils/sc_hash.h"
#include "sysc/utils/sc_iostream.h"
#include "string.h"

using namespace std;
using namespace sc_core;

namespace ovm {

//------------------------------------------------------------------------------
//
// ovm_creator
// ovm_object_creator
// ovm_component_creator
// ovm_factory
//
//------------------------------------------------------------------------------


///////////

//------------------------------------------------------------------------------
// ovm_creator implementation 
//------------------------------------------------------------------------------

ovm_creator::ovm_creator() { }

ovm_creator::~ovm_creator() { }

ovm_object_creator* ovm_creator::as_object_creator() { return 0; }

ovm_component_creator* ovm_creator::as_component_creator() { return 0; }

///////////

//------------------------------------------------------------------------------
// ovm_object_creator implementation 
//------------------------------------------------------------------------------

ovm_object_creator::ovm_object_creator() { }

ovm_object_creator::~ovm_object_creator() { }

ovm_object_creator* ovm_object_creator::as_object_creator() { 
  return this; 
}

///////////

//------------------------------------------------------------------------------
// ovm_component_creator implementation 
//------------------------------------------------------------------------------

ovm_component_creator::ovm_component_creator() { }

ovm_component_creator::~ovm_component_creator() { }

ovm_component_creator* ovm_component_creator::as_component_creator() { 
  return this; 
}

///////////

//------------------------------------------------------------------------------
//
// CLASS: ovm_factory_rep
//
// Internal implementation class.
// ovm_factory delegetates to this class to do the real work.
//
//---------------------------------------------------------------------------

class ovm_factory_rep {
public:
  ovm_factory_rep();
  ~ovm_factory_rep();
  //
  int register_object_creator(
    string type_name,
    ovm_object_creator* creator
  );
  int register_component_creator(
    string type_name,
    ovm_component_creator* creator
  );
  //
  ovm_object* create_object(
    string type_name,
    string inst_path = "",
    string name = "",
    bool no_overrides = false
  );
  ovm_component* create_component(
    string type_name,
    string inst_path = "",
    string name = ""
  );
  //
  void set_type_override(
    string original_type_name,
    string replacement_type_name,
    bool replace
  );
  void set_inst_override(
    string inst_path,
    string original_type_name,
    string replacement_type_name
  );
  //
  string get_type_override(string type_name);
  string get_inst_override(string type_name, string inst_path);
  string get_override(string type_name, string inst_path);
  void print_all_overrides(); // for debugging use
  void print_registered_types();
  void print_type_overrides();
  void print_inst_overrides();
  //
  bool is_component_registered(string type_name);
  bool is_object_registered(string type_name);
protected:
  sc_strhash<ovm_creator*> creator_map;
  sc_strhash<string*> type_overrides;
  ovm_config inst_overrides;
};

//------------------------------------------------------------------------------
// ovm_factory_rep implementation 
//------------------------------------------------------------------------------

ovm_factory_rep::ovm_factory_rep() {
}

ovm_factory_rep::~ovm_factory_rep() {
}

int ovm_factory_rep::register_object_creator(
  string type_name,
  ovm_object_creator* creator
) { 
  creator_map.insert(strdup(type_name.c_str()), creator);
  return 1;
}

int ovm_factory_rep::register_component_creator(
  string type_name,
  ovm_component_creator* creator
) { 
  creator_map.insert(strdup(type_name.c_str()), creator);
  return 1; 
}

// return NULL if object cannot be created

ovm_object* ovm_factory_rep::create_object(
  string type_name,
  string inst_path,
  string name,
  bool no_overrides
) { 
  string typ;
  if (no_overrides) {
    typ = type_name;
  } else {
    string path = inst_path;
    if (name != "") {
      path = path + string(".") + name;
    }
    typ = get_override(type_name,path);
  }
  ovm_creator* c = creator_map[typ.c_str()];  
  if (!c) { 
    char msg[1024];
    sprintf(msg," Type = %s",typ.c_str());
    SC_REPORT_WARNING(OVM_CREATOR_NOT_FOUND_,msg);
    return 0; 
  }
  ovm_object_creator* cobj = c->as_object_creator();
  if (!cobj) { 
    char msg[1024];
    sprintf(msg," Type = %s",typ.c_str());
    SC_REPORT_WARNING(OVM_CREATOR_NOT_OBJECT_,msg);
    return 0; 
  }
  ovm_object* obj = cobj->create(name);
  return obj;
}

string ovm_factory_rep::get_type_override(string type_name) {
  string* t = type_overrides[type_name.c_str()];
  if (!t) return "";
  return *t;
}

string ovm_factory_rep::get_inst_override(string type_name, string inst_path) {
  string typ = "";
  ovm_config_item* item = inst_overrides.get_config_item(
      ovm_config_type_string,
      inst_path,type_name
  );
  if (!item) return "";
  ovm_config_item_string* item_s = item->as_string();
  return item_s->value();
}

string ovm_factory_rep::get_override(string type_name, string inst_path) {
  string typ = "";
  typ = get_inst_override(type_name,inst_path);
  if (typ.length()) {
    return typ;
  }
  typ = get_type_override(type_name);
  if (typ.length()) {
    return typ;
  }
  return type_name;
}

// return NULL if component cannot be created

ovm_component* ovm_factory_rep::create_component(
  string type_name,
  string inst_path,
  string name
) { 
  string path = inst_path + string(".") + name;
  string typ = get_override(type_name,path);
  ovm_creator* c = creator_map[typ.c_str()];  
  if (!c) { 
    char msg[1024];
    sprintf(msg," Type = %s",typ.c_str());
    SC_REPORT_WARNING(OVM_CREATOR_NOT_FOUND_,msg);
    return 0; 
  }
  ovm_component_creator* ccomp = c->as_component_creator();
  if (!ccomp) { 
    char msg[1024];
    sprintf(msg," Type = %s",typ.c_str());
    SC_REPORT_WARNING(OVM_CREATOR_NOT_COMP_,msg);
    return 0; 
  }
  ovm_component* comp = ccomp->create(name);
  return comp;
}

// if replacement type has not been registered with factory,
// then error out.
// if "replace" is false, and override already exists for 
// "original_type_name", then error out

void ovm_factory_rep::set_type_override(
  string original_type_name,
  string replacement_type_name,
  bool replace
) {
  // check replace_ment_type_name is registered
  if (!creator_map[(char*)(replacement_type_name.c_str())]) {
    char msg[1024];
    sprintf(msg,
      " Problem with replacement type in set_type_override. Type = %s",
      replacement_type_name.c_str()
    );
    SC_REPORT_ERROR(OVM_CREATOR_NOT_FOUND_,msg);
    return; 
  }
  if (!replace && type_overrides[(char*)(original_type_name.c_str())]) {
    char msg[1024];
    sprintf(msg," Type = %s", original_type_name.c_str());
    SC_REPORT_ERROR(OVM_OVERRIDE_EXISTS_,msg);
    return;
  }
  type_overrides.insert(
    strdup(original_type_name.c_str()), 
    new string(replacement_type_name)
  );
}

// if replacement type has not been registered with factory,
// then error out.

void ovm_factory_rep::set_inst_override(
  string inst_path,
  string original_type_name,
  string replacement_type_name
) {
  // check replace_ment_type_name is registered
  if (!creator_map[(char*)(replacement_type_name.c_str())]) {
    char msg[1024];
    sprintf(msg,
      " Problem with replacement type in set_inst_override. Type = %s",
      replacement_type_name.c_str()
    );
    SC_REPORT_ERROR(OVM_CREATOR_NOT_FOUND_,msg);
    return; 
  }
  ovm_config_item* item = new ovm_config_item_string(
    inst_path, original_type_name, 0, replacement_type_name
  );
  inst_overrides.add_config_item(item);
}
 
void ovm_factory_rep::print_all_overrides() {
  print_registered_types();
  print_type_overrides();
  print_inst_overrides();
}

void ovm_factory_rep::print_registered_types() {
  cerr << "OVM_FACTORY REGISTERED TYPES:" << endl;
  sc_strhash_iter<ovm_creator*> iter(creator_map);
  while (!iter.empty()) {
    const char* c = iter.key();
    cerr << c << endl;
    iter++;
  }
  cerr << endl << endl;
}

void ovm_factory_rep::print_type_overrides() {
  cerr << "OVM_FACTORY REGISTERED TYPES:" << endl;
  sc_strhash_iter<string*> iter(type_overrides);
  while (!iter.empty()) {
    const char* orig = iter.key();
    string* repl = iter.contents();
    cerr << orig << " --> " << *repl << endl;
    iter++;
  }
  cerr << endl << endl;
}

void ovm_factory_rep::print_inst_overrides() {
  cerr << "OVM_FACTORY INST OVERRIDES:" << endl;
  for (unsigned i = 0; i < inst_overrides.m_vec.size(); i++) {
    ovm_config_item* item = inst_overrides.m_vec[i];
    ovm_config_item_string* item_s = item->as_string();
    cerr << item_s->m_instname << " " << item_s->m_field 
      << " --> " << item_s->value() << endl; 
  }
}

bool ovm_factory_rep::is_component_registered(string type_name) {
  ovm_creator* c = creator_map[type_name.c_str()];
  if (c) {
    ovm_component_creator* ccomp = c->as_component_creator();
    if (ccomp) return true;
  }
  return false;
}

bool ovm_factory_rep::is_object_registered(string type_name) {
  ovm_creator* c = creator_map[type_name.c_str()];
  if (c) {
    ovm_object_creator* cobj = c->as_object_creator();
    if (cobj) return true;
  }
  return false;
}

///////////

//------------------------------------------------------------------------------
// ovm_factory implementation
//------------------------------------------------------------------------------

ovm_factory_rep* ovm_factory::m_rep = 0;

int ovm_factory::register_object_creator(
  string type_name,
  ovm_object_creator* creator
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  int r = m_rep->register_object_creator(
    type_name,
    creator
  );
  return r;
}

int ovm_factory::register_component_creator(
  string type_name,
  ovm_component_creator* creator
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  int r = m_rep->register_component_creator(
    type_name,
    creator
  );
  return r;
}

ovm_object* ovm_factory::create_object(
  string type_name,
  string inst_path,
  string name,
  bool no_overrides
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  ovm_object* obj = m_rep->create_object(
    type_name,
    inst_path,
    name,
    no_overrides
  );
  return obj;
}

ovm_component* ovm_factory::create_component(
  string type_name,
  string inst_path,
  string name
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  ovm_component* comp = m_rep->create_component(
    type_name,
    inst_path,
    name
  );
  return comp;
}

void ovm_factory::set_type_override(
   string original_type_name,
   string replacement_type_name,
   bool replace
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  m_rep->set_type_override(
    original_type_name,
    replacement_type_name,
    replace
  );
}

void ovm_factory::set_inst_override(
   string inst_path,
   string original_type_name,
   string replacement_type_name
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  m_rep->set_inst_override(
    inst_path,
    original_type_name,
    replacement_type_name
  );
}
 
string ovm_factory::get_type_override(
   string original_type_name
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  return m_rep->get_type_override(original_type_name);
}

string ovm_factory::get_inst_override(
   string inst_path,
   string original_type_name
) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  return m_rep->get_inst_override(inst_path, original_type_name);
}

void ovm_factory::print_all_overrides() {
  if (!m_rep) m_rep = new ovm_factory_rep();
  m_rep->print_all_overrides();
}

bool ovm_factory::is_component_registered(string type_name) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  return m_rep->is_component_registered(type_name);
}

bool ovm_factory::is_object_registered(string type_name) {
  if (!m_rep) m_rep = new ovm_factory_rep();
  return m_rep->is_object_registered(type_name);
}

///////////

//------------------------------------------------------------------------------
// implementation of global functions to create ovm_object/ovm_component,
// and to set up overrides.
//------------------------------------------------------------------------------

ovm_object* ovm_create_object(
  std::string type_name,
  std::string inst_path,
  std::string name,
  bool no_overrides 
) {
  return ovm_factory::create_object(type_name, inst_path, name, no_overrides);
}

ovm_component* ovm_create_component(
  std::string type_name,
  std::string inst_path = "",
  std::string name = ""
) {
  return ovm_factory::create_component(type_name, inst_path, name);
}

void ovm_set_type_override(
  std::string original_type_name,
  std::string replacement_type_name,
  bool replace 
) {
  ovm_factory::set_type_override(
    original_type_name, replacement_type_name, replace
  );
}

void ovm_set_inst_override(
  std::string inst_path,
  std::string original_type_name,
  std::string replacement_type_name
) {
  ovm_factory::set_inst_override(
    inst_path, original_type_name, replacement_type_name
  );
}


///////////


} // namespace ovm
