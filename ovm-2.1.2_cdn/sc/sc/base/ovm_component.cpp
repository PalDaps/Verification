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


#define SC_INCLUDE_DYNAMIC_PROCESSES
#include "systemc.h"

#include "base/ovm_component.h"
#include "base/ovm_config.h"
#include "base/ovm_factory.h"
#include "base/ovm_manager.h"

using namespace std;
using namespace sc_core;

namespace ovm {

//------------------------------------------------------------------------------
//
// ovm_component
//
//------------------------------------------------------------------------------

static bool global_timeout_spawned_ = false;

// constructor of ovm_component spawns run() member method as a thread process

ovm_component::ovm_component(sc_module_name nm) : sc_module(nm) { 
  m_config = 0;
  sc_process_handle run_handle =
    sc_spawn(sc_bind(&ovm_component::run, this), "run");
  this->set_run_handle(run_handle);

  if (!global_timeout_spawned_) {
    // spawn thread that will wait for m_global_timeout to expire
    sc_spawn_options o;
#ifdef NC_SYSTEMC
    o.hide_from_nc();
#endif 
    sc_spawn(sc_bind(&ovm_manager::wait_for_global_timeout, get_ovm_manager()),
             "ovm_wait_for_global_timeout",
             &o
    );
    global_timeout_spawned_ = true;
  }
}

ovm_component::~ovm_component() { }

bool ovm_component::has_child(const char* leaf_name) {
  string full_name = prepend_name(string(leaf_name));
  if (sc_find_object(full_name.c_str())) 
    return true;
  return false; 
}

void ovm_component::set_config_string(
  const string& instname,
  const string& field,
  const string& val
) {
  std::string path = prepend_name(instname);
  ovm_get_config_mgr()->set_config_string(this,path,field,val);
}

void ovm_component::set_config_object(
  const string& instname,
  const string& field,
  ovm_object* val,
  bool clone 
) {
  std::string path = prepend_name(instname);
  ovm_get_config_mgr()->set_config_object(this,path,field,val,clone);
}

bool ovm_component::get_config_string(
  const string& field,
  string& val
) {
  bool b = ovm_get_config_mgr()->get_config_string(this,std::string(name()),field,val);
  return b;
}

bool ovm_component::get_config_object(
  const string& field,
  ovm_object*& val,
  bool clone
) {
  bool b = ovm_get_config_mgr()->get_config_object(this,std::string(name()),field,val,clone);
  return b;
}

ovm_component* ovm_component::create_component(
  std::string type_name,
  std::string leaf
) {
  return ovm_factory::create_component(type_name, std::string(name()), leaf);
}

ovm_object* ovm_component::create_object(
  std::string type_name,
  std::string leaf 
) {
  return ovm_factory::create_object(type_name, std::string(name()), leaf);
}

void ovm_component::set_type_override(
  std::string original_type_name,
  std::string replacement_type_name,
  bool replace 
) {
  ovm_factory::set_type_override(
    original_type_name, replacement_type_name, replace
  );
}

void ovm_component::set_inst_override(
  std::string inst_path,    
  std::string original_type_name,
  std::string replacement_type_name
) {
  std::string path = prepend_name(inst_path);
  ovm_factory::set_inst_override(
    path, original_type_name, replacement_type_name
  );
}

// called by SC kernel

void ovm_component::before_end_of_elaboration() { 
  build();
}

// called by before_end_of_elaboration()

void ovm_component::build() { 
  end_of_construction();
}

// called by build()

void ovm_component::end_of_construction() { 
}

void ovm_component::run() { 
}

void ovm_component::stop() { 
}

void ovm_component::extract() { 
}

void ovm_component::check() { 
}

void ovm_component::report() { 
}

//
bool ovm_component::kill() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.kill();
  }
  return true;
#endif
  // no process control construct support
  return false;
}

bool ovm_component::reset() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.reset(SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

bool ovm_component::suspend() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.suspend(SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

bool ovm_component::resume() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.resume(SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

bool ovm_component::disable() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.disable(SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

bool ovm_component::enable() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.enable(SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

bool ovm_component::sync_reset_on() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.sync_reset_on(SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

bool ovm_component::sync_reset_off() {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.sync_reset_off(SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

template <typename T>
bool ovm_component::throw_it(T& t) {
#ifdef NC_SYSTEMC
  if (m_run_handle.valid() && !m_run_handle.terminated()) {
    m_run_handle.throw_it(t, SC_INCLUDE_DESCENDANTS);
  }
  return true;
#endif
  // no process control construct support
  return false;
}

//
bool ovm_component::enable_stop_interrupt() {
  return false;
}

// internal methods

void ovm_component::set_run_handle(sc_process_handle h) {
  m_run_handle = h;
}

ovm_config* ovm_component::config() {
  if (!m_config) {
    m_config = new ovm_config();
  }
  return m_config;
}

string ovm_component::prepend_name(string s) {
  string n = name();
  if (s != "") {
    n += string(".");
    n += s;
  }
  return n;
}


} // namespace ovm
