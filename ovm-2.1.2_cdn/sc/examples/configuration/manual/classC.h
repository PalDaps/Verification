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

#ifndef _packet_h_
#define _packet_h_

#include "ovm.h"

using namespace ovm;

class C : public ovm_component
{
  int v;
  int s;
  std::string myaa;

 public:
  C(sc_module_name name ) : ovm_component(name) , s(12345) {};

    void build()
    {
      ovm_component::build();
      get_config_int("v", v);
      get_config_int("s", s);
      get_config_string("myaa", myaa);
    }
   
    std::string get_type_name()
    {
	return "C";
    }

    void report()
    {
      cerr << name() << " myaa " << myaa << endl;
      cerr << name() << " v    " << v << endl;
      cerr << name() << " s    " << s << endl;
    }
    OVM_COMPONENT_UTILS(C);
};

OVM_COMPONENT_REGISTER(C);

#endif
