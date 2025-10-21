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

class packet : public ovm_object
{
  int addr;
  int data;
 public:

  packet() : ovm_object(), addr(12345), data(67890)
    {};

  void do_print(ostream& os) const
  {
    os << "addr: " << addr << endl;
    os << "data: " << data << endl;
  }

  void do_copy(const ovm_object* rhs)
  {
    const packet* drhs = DCAST<const packet*>(rhs);
    addr = drhs->addr;
    data = drhs->data;
  }

  bool do_compare(const ovm_object* rhs) const
  {
    const packet* drhs = DCAST<const packet*>(rhs);
    if (!(addr == drhs->addr))
      return 0;
    if (!(data == drhs->data))
      return 0;
    return 1;
  };
  
  void do_pack(ovm_packer& p) const 
  {
    p << addr << data;
  }
  void do_unpack(ovm_packer& p) 
  {
    p >> addr >> data;
  }

  OVM_OBJECT_UTILS(packet);
};
OVM_OBJECT_REGISTER(packet)
