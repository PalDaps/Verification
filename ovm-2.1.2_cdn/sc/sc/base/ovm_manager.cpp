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
#include "base/ovm_manager.h"
#include "base/ovm_ids.h"

using namespace sc_core;

namespace ovm {

//------------------------------------------------------------------------------
//
// ovm_manager
//
// Internal implementation class.
//
//------------------------------------------------------------------------------

ovm_manager* ovm_manager::m_mgr = 0;

ovm_manager* ovm_manager::get_manager() {
  if (m_mgr == 0) {
    m_mgr = new ovm_manager();
  }
  return m_mgr;
}

ovm_manager::ovm_manager() {
  m_stop_mode = OVM_SC_STOP;

  sc_time max_time; // the time at which sc_start() returns
  sc_time smallest_time = sc_get_time_resolution();

#ifdef NC_SYSTEMC
  max_time = sc_cosim::max_time_that_wont_overflow_in_nc_resolution();
#else
  max_time = sc_time(~sc_dt::UINT64_ZERO, false); 
#endif
  // make the OVM timeouts be slightly less than when sc_start() returns
  // such that OVM is able to end the run phase
  m_global_timeout = max_time - smallest_time;
  m_stop_timeout = max_time - smallest_time;
}
 
ovm_manager::~ovm_manager() {
}

ovm_component* ovm_manager::find_component(const char* name) {
  sc_object* obj = sc_find_object(name);
  ovm_component* comp = DCAST<ovm_component*>(obj);
  return comp;
}

void ovm_manager::set_stop_mode(stop_mode_enum mode) {
  m_stop_mode = mode;
}

void ovm_manager::set_global_timeout(sc_time t) {
  m_global_timeout = t;
}

void ovm_manager::set_global_stop_timeout(sc_time t) {
  m_stop_timeout = t;
}

void ovm_manager::wait_for_global_timeout() {
  
  sc_time tdur = m_global_timeout - sc_time_stamp();

  wait(tdur);

  // global timeout has expired => run phase has ended

  end_run_phase();
}

void ovm_manager::stop_request() {

  sc_spawn_options o;
#ifdef NC_SYSTEMC
    o.hide_from_nc();
#endif

  // first spawn thread that will wait for m_stop_timeout to expire
  sc_spawn(sc_bind(&ovm_manager::wait_for_stop_timeout, this),
           "ovm_wait_for_stop_timeout",
            &o
  );

  // spawn helper process that will spawn all the stop tasks
  // and wait for spawned hierarchy to terminate
 
  sc_spawn(sc_bind(&ovm_manager::stop_spawner, this),
           "ovm_stop_spawner",
           &o
  );
}

void ovm_manager::wait_for_stop_timeout() {

  sc_time tdur = m_stop_timeout - sc_time_stamp();

  wait(tdur);

  // stop timeout has expired => run phase has ended

  end_run_phase();

}

void ovm_manager::stop_spawner() {

  // find all top-level modules and spawn stop on each top module hierarchy

  const std::vector<sc_object*>& tops = sc_get_top_level_objects();
  for (unsigned i = 0; i < tops.size(); i++) {
    sc_object* top = tops[i];
    sc_module* top_mod = DCAST<sc_module*>(top);
    if (top_mod) {
      spawn_stop(top_mod);
    }
  }

  // wait for all stop processes to terminate

  if (m_join_stop.process_count() > 0) {
    m_join_stop.wait();
  }

  // all stop tasks have returned => 
  // 1. call kill() on all ovm_components 
  // 2. end run phase

  do_kill_all();
  end_run_phase();
}

void ovm_manager::spawn_stop(sc_module* mod) {

  sc_simcontext* context = sc_get_curr_simcontext();

  // spawn mod::stop() if mod is an ovm_component, and
  // it overrode enable_stop_interrupt() to return true;
  // spawn mod::stop() as a child of mod

  ovm_component* comp = DCAST<ovm_component*>(mod);
  if (comp && comp->enable_stop_interrupt()) {

    // check if this component already has a child called "stop"

    std::string nm = std::string(mod->name()) + std::string(".stop");
    if (sc_find_object(nm.c_str())) {
      char msg[1048];
      sprintf(msg, "\novm_component is %s", mod->name()); 
      SC_REPORT_ERROR(OVM_MULTIPLE_STOP_PROCS_, msg);
    }

    sc_process_b* proc = sc_get_current_process_b();
    context->hierarchy_push(mod);
#ifdef NC_SYSTEMC
    if (proc) 
      context->reset_curr_proc_extern();
#endif
    sc_process_handle stop_handle = 
      sc_spawn(sc_bind(&ovm_component::stop, comp), "stop");
    context->hierarchy_pop();
#ifdef NC_SYSTEMC
    if (proc) 
      context->set_curr_proc_extern(proc);
#endif
    m_join_stop.add_process(stop_handle);
  }

  // recurse over children

  const std::vector<sc_object*>& children = mod->get_child_objects();
  for (unsigned i = 0; i < children.size(); i++) {
    sc_object* child = children[i];
    sc_module* mod_child = DCAST<sc_module*>(child);
    if (mod_child) {
      spawn_stop(mod_child);
    }
  }
}

void ovm_manager::end_run_phase() {

  static bool invoked = false; 

  if (!invoked) {
    invoked = true;
  } else {
    // end_run_phase() has already been called;
    // this can happen if ovm_stop_request has been called 
    // but the stop processes do not all return; then global_timeout and
    // stop_timeout will expire at same time, and both will call 
    // end_run_phase() 
    return;
  }

  // do the post-run phases

  do_extract_all();
  do_check_all();
  do_report_all();

  // call sc_stop() if m_stop_mode is set appropriately 

  if (m_stop_mode == OVM_SC_STOP) {
    sc_stop();
  }
  
}

void ovm_manager::do_kill_all() {

  // find all top-level modules and call kill on each top module hierarchy

  const std::vector<sc_object*>& tops = sc_get_top_level_objects();
  for (unsigned i = 0; i < tops.size(); i++) {
    sc_object* top = tops[i];
    sc_module* top_mod = DCAST<sc_module*>(top);
    if (top_mod) {
      do_kill(top_mod);
    }
  }
}

void ovm_manager::do_kill(sc_module* mod) {

  // call mod::kill() if mod is an ovm_component

  ovm_component* comp = DCAST<ovm_component*>(mod);
  if (comp) {
    comp->kill();
  }

  // recurse over children

  const std::vector<sc_object*>& children = mod->get_child_objects();
  for (unsigned i = 0; i < children.size(); i++) {
    sc_object* child = children[i];
    sc_module* mod_child = DCAST<sc_module*>(child);
    if (mod_child) {
      do_kill(mod_child);
    }
  }
}

void ovm_manager::do_extract_all() {

  // find all top-level modules and call extract on each top module hierarchy

  const std::vector<sc_object*>& tops = sc_get_top_level_objects();
  for (unsigned i = 0; i < tops.size(); i++) {
    sc_object* top = tops[i];
    sc_module* top_mod = DCAST<sc_module*>(top);
    if (top_mod) {
      do_extract(top_mod);
    }
  }
}

void ovm_manager::do_extract(sc_module* mod) {

  // call mod::extract() if mod is an ovm_component

  ovm_component* comp = DCAST<ovm_component*>(mod);
  if (comp) {
    comp->extract();
  }

  // recurse over children

  const std::vector<sc_object*>& children = mod->get_child_objects();
  for (unsigned i = 0; i < children.size(); i++) {
    sc_object* child = children[i];
    sc_module* mod_child = DCAST<sc_module*>(child);
    if (mod_child) {
      do_extract(mod_child);
    }
  }
}

void ovm_manager::do_check_all() {

  // find all top-level modules and call check on each top module hierarchy

  const std::vector<sc_object*>& tops = sc_get_top_level_objects();
  for (unsigned i = 0; i < tops.size(); i++) {
    sc_object* top = tops[i];
    sc_module* top_mod = DCAST<sc_module*>(top);
    if (top_mod) {
      do_check(top_mod);
    }
  }
}

void ovm_manager::do_check(sc_module* mod) {

  // call mod::check() if mod is an ovm_component

  ovm_component* comp = DCAST<ovm_component*>(mod);
  if (comp) {
    comp->check();
  }

  // recurse over children

  const std::vector<sc_object*>& children = mod->get_child_objects();
  for (unsigned i = 0; i < children.size(); i++) {
    sc_object* child = children[i];
    sc_module* mod_child = DCAST<sc_module*>(child);
    if (mod_child) {
      do_check(mod_child);
    }
  }
}

void ovm_manager::do_report_all() {

  // find all top-level modules and call report on each top module hierarchy

  const std::vector<sc_object*>& tops = sc_get_top_level_objects();
  for (unsigned i = 0; i < tops.size(); i++) {
    sc_object* top = tops[i];
    sc_module* top_mod = DCAST<sc_module*>(top);
    if (top_mod) {
      do_report(top_mod);
    }
  }
}

void ovm_manager::do_report(sc_module* mod) {

  // call mod::report() if mod is an ovm_component

  ovm_component* comp = DCAST<ovm_component*>(mod);
  if (comp) {
    comp->report();
  }

  // recurse over children

  const std::vector<sc_object*>& children = mod->get_child_objects();
  for (unsigned i = 0; i < children.size(); i++) {
    sc_object* child = children[i];
    sc_module* mod_child = DCAST<sc_module*>(child);
    if (mod_child) {
      do_report(mod_child);
    }
  }
}

//////////

} // namespace ovm

