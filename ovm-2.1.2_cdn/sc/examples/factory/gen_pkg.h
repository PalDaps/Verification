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
#include "packet_pkg.h"

using namespace ovm;

class gen : public ovm_component
{
 public:
  OVM_COMPONENT_UTILS(gen);
  gen(sc_module_name name) : ovm_component(name)
    {
    };

    virtual packet* get_packet()
    {
      packet* p;
      p = DCAST<packet*>(ovm_create_object("packet", "packet"));
      return p;
    };
};
OVM_COMPONENT_REGISTER(gen);
