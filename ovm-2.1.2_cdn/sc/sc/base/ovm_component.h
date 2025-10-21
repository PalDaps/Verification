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


#ifndef OVM_COMPONENT_H
#define OVM_COMPONENT_H

#include "base/ovm_typed.h"
#include "base/ovm_config.h"

#include "sysc/kernel/sc_module.h"
#include "sysc/kernel/sc_process_handle.h"

//////////////

namespace ovm {

// forward declaration of necessary classes.

class ovm_config;
class ovm_config_mgr;
class ovm_manager;

//------------------------------------------------------------------------------
//
// CLASS: ovm_component
//
// Base class for structural OVM elements.
// Derives from sc_module, and provides name, and hierarchy information.
//
//------------------------------------------------------------------------------


class ovm_component : public sc_core::sc_module, public ovm_typed {
public:
  friend class ovm_config_mgr;
  friend class ovm_manager;

  //----------------------------------------------------------------------------
  // Constructors and destructor
  //----------------------------------------------------------------------------

  ovm_component(sc_core::sc_module_name nm);
  virtual ~ovm_component();

  //----------------------------------------------------------------------------
  // get_type_name   -- Required override
  //
  // Return the type name of this class - e.g., "my_component".
  // Inherits this pure virtual method from base class ovm_typed.
  //----------------------------------------------------------------------------

  virtual std::string get_type_name() const = 0;

  //----------------------------------------------------------------------------
  // Find out if a child with this leaf name exists.
  //----------------------------------------------------------------------------

  bool has_child(const char* leaf_name);
  
  //----------------------------------------------------------------------------
  // Set up configuration.
  //
  // The configuration settings will be stored in a table inside
  // this component.
  //----------------------------------------------------------------------------

  template <typename T> void set_config_int(
    const std::string& instname,
    const std::string& field,
    const T& val
  );
  void set_config_string(
    const std::string& instname,
    const std::string& field,
    const std::string& val
  );
  void set_config_object(
    const std::string& instname,
    const std::string& field,
    ovm_object* val,
    bool clone = true
  );

  //----------------------------------------------------------------------------
  // Get configurations.
  //
  // A get_config_xxx() call will look for a corresponding set_confiog_xxx()
  // call. The search will be done starting from the global configuration
  // table, and continuing in each component's configuration table in 
  // the parent hierarchy, in a top-down order.
  //----------------------------------------------------------------------------

  template <class T> bool get_config_int(
    const std::string& field,
    T& val
  );
  bool get_config_string(
    const std::string& field,
    std::string& val
  );
  bool get_config_object(
    const std::string& field,
    ovm_object*& val,
    bool clone = true
  );

  //----------------------------------------------------------------------------
  // Interfaces to OVM factory.
  //
  // These interfaces provide convenient access to member methods of
  // ovm_factory.
  //----------------------------------------------------------------------------

  ovm_component* create_component(
    std::string type_name,
    std::string name
  );
  ovm_object* create_object(
    std::string type_name,
    std::string name = ""
  );

  void set_type_override(
    std::string orignal_type_name,
    std::string replacement_type_name,
    bool replace = true
  );
  void set_inst_override(
    std::string inst_path,    
    std::string orignal_type_name,
    std::string replacement_type_name
  );

  //----------------------------------------------------------------------------
  // Pre-run phase - build().
  //
  // build() is an alias for the existing sc_module phase
  // before_end_of_elaboration().
  // Other pre-run phases are inherited from sc_module.
  //----------------------------------------------------------------------------

  virtual void before_end_of_elaboration(); 
  virtual void build(); // synonym for before_end_of_elaboration;
  virtual void end_of_construction(); // synonym for before_end_of_elaboration;

  //----------------------------------------------------------------------------
  // The run phase.
  //
  // The main thread of execution.
  // The component should not declare run as a thread process - it is
  // automatically spawned by ovm_component's constructor.
  // Run phase ends either by the ovm_stop_request() protocol
  // or by a timeout that can be customized by calling
  // ovm_set_global_timeout().
  //----------------------------------------------------------------------------

  virtual void run(); 

  //----------------------------------------------------------------------------
  // Stop mechanism to veto termination triggered by ovm_stop_request().
  //
  // If enable_stop_interrupt() returns true, then the stop() member method 
  // will be spawned as a thread process when ovm_stop_request() is 
  // invoked in the design.
  // Simulation will not stop until all the stop process return.
  // The component should not declare stop() explicitly as a thread process.
  //----------------------------------------------------------------------------

  virtual void stop(); 
  virtual bool enable_stop_interrupt();

  //----------------------------------------------------------------------------
  // Post-run phases.
  //
  // These phases will trigger after the run phase ends.
  // Usually after the post-run phases are over, sc_stop() is  
  // issued, which wll trigger the end_of_simulation() phase also. 
  //----------------------------------------------------------------------------

  virtual void extract();
  virtual void check();
  virtual void report();

  //----------------------------------------------------------------------------
  // Issue process control constructs on run() process.
  //
  // For those simulators that support process control constructs, 
  // the corresponding construct will be issued on the run() process
  // handle. A value of false is returned if a simulator does not
  // support process control constructs.
  //----------------------------------------------------------------------------

  virtual bool kill();
  virtual bool reset();
  virtual bool suspend();
  virtual bool resume();
  virtual bool disable();
  virtual bool enable();
  virtual bool sync_reset_on();
  virtual bool sync_reset_off();
  // cannot use virtual with templated member method
  template <typename T>
  //virtual bool throw_it(T& t);
  bool throw_it(T& t);

protected:
  void set_run_handle(sc_core::sc_process_handle h);

protected:
  sc_core::sc_process_handle m_run_handle;

private: 
  std::string prepend_name(std::string s);
  ovm_config* config();
  ovm_config* m_config;
};

//////////////

// implementation of templated member methods

template <typename T> void ovm_component::set_config_int(
  const std::string& instname,
  const std::string& field,
  const T& val
) {
  std::string path = prepend_name(instname);
  ovm_get_config_mgr()->set_config_int(this,path,field,val);
}

template <typename T> bool ovm_component::get_config_int(
  const std::string& field,
  T& val
) {
  bool b = ovm_get_config_mgr()->get_config_int(this,std::string(name()),field,val);
  return b;
}

//////////////

//------------------------------------------------------------------------------
// Registration macros to register an ovm_component with the factory.
// 
// A registration macro should be invoked outside the ovm_component class
// declaration.
// A registration macro registers the given ovm_component with the factory, and
// defines the get_type_name() member method of the registered component.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Use the macro below to register a simple non-templated ovm_component.
// The macro argument is the name of the class.
// The registered name with the factory is the same as the macro argument.
//------------------------------------------------------------------------------

#define OVM_COMPONENT_REGISTER(t) \
static int ovm_component_register_dummy_##t = \
  ovm::ovm_factory::register_component_creator( #t,new t::ovm_component_creator_##t()); \
inline std::string t::get_type_name() const { return #t; }

//------------------------------------------------------------------------------
// Use the macro below to register a simple non-templated ovm_component,
// with a different registered name (first argument) than its
// class name (second argument).
// The registered name with the factory is the same as the first macro argument.
//------------------------------------------------------------------------------

#define OVM_COMPONENT_REGISTER_ALIAS(name,t) \
static int ovm_component_register_dummy_##name##_##t = \
  ovm::ovm_factory::register_component_creator( #name,new t::ovm_component_creator_##t()); \
inline std::string t::get_type_name() const { return #name; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_components with
// one template parameter.
// The first macro argument is the class name, and the second macro argument
// is a specific value of the template parameter.
// Example usage: "OVM_COMPONENT_REGISTER_T(mycomp, int)".
// The registered name with the factory is a concatenation of the first
// and second arguments, separated by "_".
// e.g., "mycomp_int".
//------------------------------------------------------------------------------

#define OVM_COMPONENT_REGISTER_T(t,T) \
static int ovm_component_register_dummy_##t##_##T = \
  ovm::ovm_factory::register_component_creator( #t "_" #T, new t<T>::ovm_component_creator_##t()); \
template<> inline std::string t<T>::get_type_name() const { return #t "_" #T; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_components with
// one template parameter, when you do not want the default registered name.
// Specify the alternate registration name as the first macro argument.
// Example usage: "OVM_COMPONENT_REGISTER_T_ALIAS(myname, mycomp, int)".
// The registered name with the factory is the same as the first macro 
// argument.
//------------------------------------------------------------------------------

#define OVM_COMPONENT_REGISTER_T_ALIAS(name,t,T) \
static int ovm_component_register_dummy_##name##_##t = \
  ovm::ovm_factory::register_component_creator( #name, new t<T>::ovm_component_creator_##t()); \
template<> inline std::string t<T>::get_type_name() const { return #name; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_components with
// two template parameters.
// The first macro argument is the class name. 
// The second and third macro arguments are specific values of the
// two template parameters.
// Example usage: "OVM_COMPONENT_REGISTER_T2(myothercomp, int, int)".
// The registered name with the factory is a concatenation of the first,
// second, and third arguments, separated by "_". 
// e.g., "myothercomp_int_int".
//------------------------------------------------------------------------------

#define OVM_COMPONENT_REGISTER_T2(t,T1,T2) \
static int ovm_component_register_dummy_##t##_##T1##_##T2 = \
  ovm::ovm_factory::register_component_creator( #t "_" #T1 "_" #T2, new t<T1,T2>::ovm_component_creator_##t()); \
template<> inline std::string t<T1,T2>::get_type_name() const { return #t "_" #T1 "_" #T2; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_components with 
// two template parameters, when you do not want the default registered name.
// Specify the alternate registration name as the first macro argument.
// Example usage: 
//   "OVM_COMPONENT_REGISTER_T2_ALIAS(myname, myothercomp, int, int)".
// The registered name with the factory is the same as the first macro argument.
//------------------------------------------------------------------------------

#define OVM_COMPONENT_REGISTER_T2_ALIAS(name,t,T1,T2) \
static int ovm_component_register_dummy_##name##_##t = \
  ovm::ovm_factory::register_component_creator( #name, new t<T1,T2>::ovm_component_creator_##t()); \
template<> inline std::string t<T1,T2>::get_type_name() const { return #name; }

//------------------------------------------------------------------------------
// Utility macro to instrument an ovm_component such that it can be registered
// with the factory.
// 
// The utility macro should be invoked inside the ovm_component class
// declaration.
// The utility macro declares
// - the ovm_component_creator_<classname> class used by the factory
//   to create an instance of this component.
// - the get_type_name() member method inside the ovm_component class.
//------------------------------------------------------------------------------

#define OVM_COMPONENT_UTILS(t) \
class ovm_component_creator_##t : public ovm::ovm_component_creator { \
public: \
  ovm::ovm_component* create(const std::string& name) { \
    ovm::ovm_component* _ncsc_comp = new t(name.c_str()); \
    return _ncsc_comp; \
  } \
}; \
virtual std::string get_type_name() const;

//////////////

} // namespace ovm

#endif
