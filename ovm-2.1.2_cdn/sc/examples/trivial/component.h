
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


#include "ovm.h"

using namespace ovm;

class my_component : public ovm_component
{
public:
  OVM_COMPONENT_UTILS(my_component)

  my_component(sc_module_name name) : ovm_component(name)
  {};

  void run()
  {
    // ovm_report_info("component", "hello out there!");
    cerr << "my_component " << "hello out there!" << endl;
  }
};

OVM_COMPONENT_REGISTER(my_component)

class top : public ovm_component
{
  class my_component* component;
public:
  OVM_COMPONENT_UTILS(top)
  top(sc_module_name name) : ovm_component(name)
  {
    component = new my_component("component");
  };
  void report()
  {
    cerr << "Test passed..." << endl;
  }
};

OVM_COMPONENT_REGISTER(top)
