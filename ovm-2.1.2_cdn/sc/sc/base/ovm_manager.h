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


#ifndef OVM_MANAGER_H
#define OVM_MANAGER_H

#include "base/ovm_component.h"

#include "sysc/kernel/sc_event.h"
#include "sysc/kernel/sc_join.h"

//////////////

namespace ovm {

typedef enum {
  OVM_SC_STOP,
  OVM_NO_SC_STOP
} stop_mode_enum;

//------------------------------------------------------------------------------
//
// CLASS: ovm_manager
//
// Internal implementation class.
// Stores global settings, and implements most of the global functions.
// A singleton instance of this class is created for a given simulation run.
//
//------------------------------------------------------------------------------

class ovm_manager {
public:

  friend class ovm_component;

  static ovm_manager* get_manager();
 
  void set_stop_mode(stop_mode_enum mode = OVM_SC_STOP);

  void set_global_timeout(sc_core::sc_time t);
  void set_global_stop_timeout(sc_core::sc_time t);
  
  void stop_request();

  ovm_component* find_component(const char* name);

protected:

  ovm_manager();
  ~ovm_manager();

  void wait_for_global_timeout();
  void wait_for_stop_timeout();

  void stop_spawner();
  void spawn_stop(sc_core::sc_module* mod);
  void end_run_phase();

  void do_kill_all();
  void do_kill(sc_core::sc_module* mod);
  
  void do_extract_all();
  void do_extract(sc_core::sc_module* mod);
  
  void do_check_all();
  void do_check(sc_core::sc_module* mod);
  
  void do_report_all();
  void do_report(sc_core::sc_module* mod);

protected:

  static ovm_manager*         m_mgr;
         
  stop_mode_enum              m_stop_mode;
  sc_core::sc_time            m_global_timeout;
  sc_core::sc_time            m_stop_timeout;
  sc_core::sc_join            m_join_stop;
};

inline
ovm_manager* get_ovm_manager() {
  return ovm_manager::get_manager();
}

} // namespace ovm

#endif
