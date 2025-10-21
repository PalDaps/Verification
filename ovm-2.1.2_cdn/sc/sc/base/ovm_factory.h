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


#ifndef OVM_FACTORY_H
#define OVM_FACTORY_H

#include "base/ovm_ids.h"

#include <string>
#include <iostream>

//////////////////////

namespace ovm {

//////////////////////

// forward declarartions of necessary classes

class ovm_object;
class ovm_component;
class ovm_factory_rep;
class ovm_object_creator;
class ovm_component_creator;

//////////////////////

//------------------------------------------------------------------------------
//
// CLASS: ovm_creator
//
// Provides the interface used for registering proxy classes with the
// factory which is necessary for creating such proxy classes from 
// the factory.
// The two different kinds of classes that are supported by the factory
// are ovm_component and ovm_object.
//
//------------------------------------------------------------------------------

class ovm_creator {
public:
  virtual ~ovm_creator();
  virtual ovm_object_creator* as_object_creator();
  virtual ovm_component_creator* as_component_creator();
protected:
  ovm_creator();
};

//------------------------------------------------------------------------------
//
// CLASS: ovm_object_creator
//
// Implements the interface used by the factory to create an ovm_object.
// Derives from ovm_creator.
// Usually, the OVM_OBJECT_UTILS macro in an ovm_object defines the
// corresponding ovm_object_creator class. 
//
//------------------------------------------------------------------------------

class ovm_object_creator : public ovm_creator {
public:
  ovm_object_creator();
  virtual ovm_object* create(
    const std::string& name = ""
  ) = 0;
  virtual ~ovm_object_creator();
  virtual ovm_object_creator* as_object_creator();
};

//------------------------------------------------------------------------------
//
// CLASS: ovm_component_creator
//
// Implements the interface used by the factory to create an ovm_component.
// Derives from ovm_creator.
// Usually, the OVM_COMPONENT_UTILS macro in an ovm_object defines the
// corresponding ovm_component_creator class. 
//
//------------------------------------------------------------------------------

class ovm_component_creator : public ovm_creator {
public:
  ovm_component_creator();
  virtual ovm_component* create(
    const std::string& name = ""
  ) = 0;
  virtual ~ovm_component_creator();
  virtual ovm_component_creator* as_component_creator();
};

//////////////////////

//------------------------------------------------------------------------------
//
// CLASS: ovm_factory
//
// Class for creating ovm_objects and ovm_components. 
// Before creation, the factory processes any overrides, if applicable. 
// Class types  have to be registered with the factory using the 
// ovm_creator class.
// A singleton factory instance is created for a given simulation run.
//
//------------------------------------------------------------------------------

class ovm_factory {
public:

  //----------------------------------------------------------------------------
  // Register an object or a component with the factory. 
  //
  // Usually, the OVM_OBJECT_REGISTER and OVM_COMPONENT_REGISTER macros 
  // will invoke these factory member methods to register a particular 
  // object or component with the factory.
  //----------------------------------------------------------------------------

  static int register_object_creator(
    std::string type_name, 
    ovm_object_creator* creator
  );
  static int register_component_creator(
    std::string type_name, 
    ovm_component_creator* creator
  );
  
  //----------------------------------------------------------------------------
  // Create an ovm_object or an ovm_component through the factory.
  //
  // Overrides are applied before creation.
  //----------------------------------------------------------------------------

  static ovm_object* create_object(
    std::string type_name,
    std::string inst_path = "",
    std::string name = "",
    bool no_overrides = false
  );
  static ovm_component* create_component(
    std::string type_name,
    std::string inst_path = "",
    std::string name = ""
  );
  
  //----------------------------------------------------------------------------
  // Set up type overrides or instance overrides through the factory.
  //
  // Wildcards('*' and '?') are allowed in "inst_path" of instance overrides.
  // Instance overrides have precedence over type overrides.
  //----------------------------------------------------------------------------

  static void set_type_override(
    std::string orignal_type_name,
    std::string replacement_type_name,
    bool replace = true
  );
  static void set_inst_override(
    std::string inst_path,
    std::string orignal_type_name,
    std::string replacement_type_name
  );

  //----------------------------------------------------------------------------
  // Print all overrides in the factory.
  //
  // Useful for debugging purposes.
  //----------------------------------------------------------------------------

  static void print_all_overrides(); // for debugging use

  // methods primarily for internal use

  static std::string get_type_override(
    std::string orignal_type_name
  );
  static std::string get_inst_override(
    std::string inst_path,
    std::string orignal_type_name
  );
  //
  static bool is_component_registered(std::string type_name);
  static bool is_object_registered(std::string type_name);
protected:
  static ovm_factory_rep* m_rep; // internal implementation class
};

//////////////////////

} // namespace ovm

//////////////////////

#endif
