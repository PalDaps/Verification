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


#ifndef OVM_GLOBALS_H
#define OVM_GLOBALS_H

#include "base/ovm_manager.h"
#include "base/ovm_factory.h"
#include "base/ovm_config.h"

//////////////

namespace ovm {

//------------------------------------------------------------------------------
//
// Global OVM functions.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Functions to control termination behavior.
//
//------------------------------------------------------------------------------

void ovm_set_stop_mode(stop_mode_enum mode = OVM_SC_STOP);
void ovm_set_global_timeout(sc_core::sc_time t);
void ovm_set_global_stop_timeout(sc_core::sc_time t);
void ovm_stop_request();

//------------------------------------------------------------------------------
//
// Global function to look up an ovm_component with a given name.
//
//------------------------------------------------------------------------------

ovm_component* ovm_find_component(const char* name);


//------------------------------------------------------------------------------
//
// Global configuration set-up functions.
//
//------------------------------------------------------------------------------

template <typename T> 
void 
ovm_set_config_int(
  const std::string& instname,
  const std::string& field,
  const T& val
) {
  sc_dt::sc_lv<4096> lv = ovm_convert_to_lv(val);
  ovm_get_config_mgr()->set_config_int(0,instname,field,lv);
}
void ovm_set_config_string(
  const std::string& instname,
  const std::string& field,
  const std::string& val
);
void ovm_set_config_object(
  const std::string& instname,
  const std::string& field,
  ovm_object* val,
  bool clone = true
);

//------------------------------------------------------------------------------
//
// Function to control additional debugging message generation during 
// get_config_xxx() calls. 
//
//------------------------------------------------------------------------------

void ovm_print_config_matches(bool b);

///////////////

//------------------------------------------------------------------------------
//
// Global factory interface functions.
//
//------------------------------------------------------------------------------

ovm_object* ovm_create_object(
  std::string type_name,
  std::string inst_path = "",
  std::string name = "",
  bool no_overrides = false 
);

ovm_component* ovm_create_component(
  std::string type_name,
  std::string inst_path = "",
  std::string name = ""
);

void ovm_set_type_override(
  std::string orignal_type_name,
  std::string replacement_type_name,
  bool replace = true
);
void ovm_set_inst_override(
  std::string inst_path,
  std::string orignal_type_name,
  std::string replacement_type_name
);


} // namespace ovm

#endif
