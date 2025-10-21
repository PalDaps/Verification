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

#include "classA.h"
#include "classB.h"
  
class top : public ovm_component
{
  bool debug;
  A inst1;
  B inst2;
 public: 
  top(sc_module_name name) : ovm_component(name), inst1("inst1"), inst2("inst2"), debug(0) 
{
};
  
    void build()
    {
      int rv;
      ovm_component::build();
 
  
      ovm_set_config_int("inst1.u2", "v", 5);
      ovm_set_config_int("inst2.u1", "v", 3);
      ovm_set_config_int("*.inst1.*", "s", 0x10);
      ovm_set_config_int("top.*.u1", "v", 30);
      ovm_set_config_int("top.inst2.u1", "v", 10);
      ovm_set_config_int("top.*", "debug", 1);
      ovm_set_config_string("*", "myaa", "howdy");
      ovm_set_config_string("top.inst1.u1", "myaa", "boobah");
      ovm_set_global_timeout(sc_time(1,SC_NS));

      get_config_int("debug", debug);

      cout << name() << ": In Build: debug = " << debug << endl;
  
      inst1.build();
      inst2.build();
    }
    OVM_COMPONENT_UTILS(top)
    std::string get_type_name() {return "top";}
      
};

OVM_COMPONENT_REGISTER(top)
