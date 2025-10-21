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

#ifndef _classA_h_
#define _classA_h_

#include "ovm.h"
#include "classC.h"

using namespace ovm;

class A : public ovm_component
{
  bool debug;
  C u1;
  C u2;

 public:

  A(sc_module_name name) : ovm_component(name), u1("u1"), u2("u2"), debug(0)
    {
    }

    void build()
    {
      ovm_component::build();
      set_config_int("*", "v", 0);
      get_config_int("debug", debug);
      cout << name() << ": In Build: debug = " << debug << endl;

      u1.build();
      u2.build();
    }

    std::string get_type_name()
      {
	return "A";
      }
  
    virtual void do_print(ostream& os) const
    {
      os << "debug" << debug << endl;
    }
    OVM_COMPONENT_UTILS(A)
      };
OVM_COMPONENT_REGISTER(A)

#endif
