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


#include "systemc.h"

#include "base/ovm_globals.h"
#include "base/ovm_manager.h"

using namespace sc_core;

namespace ovm {

//------------------------------------------------------------------------------
//
// Implementation of some of the global OVM functions.
//
// Delegates to the internal class ovm_manager to do the real work.
//
//------------------------------------------------------------------------------

ovm_component* ovm_find_component(const char* name) {
  return get_ovm_manager()->find_component(name); 
}

void ovm_set_stop_mode(stop_mode_enum mode) {
  get_ovm_manager()->set_stop_mode(mode); 
}

void ovm_set_global_timeout(sc_time t) {
  get_ovm_manager()->set_global_timeout(t); 
}

void ovm_set_global_stop_timeout(sc_time t) {
  get_ovm_manager()->set_global_stop_timeout(t); 
}

void ovm_stop_request() {
  get_ovm_manager()->stop_request(); 
}

} // namespace ovm
