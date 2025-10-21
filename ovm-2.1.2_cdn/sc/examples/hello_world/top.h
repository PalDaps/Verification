
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
#include <systemc.h>
#include "hello_world.h"
#include "packet.h"
#include "producer.h"
#include "consumer.h"
#include "packet.h"
#include "tlm.h"


using namespace ovm;

class top : public ovm_component
{
  hello_world hw;
  producer<packet> p1;
  producer<packet> p2;
  tlm_fifo<packet> fifo;
  consumer<packet> c;

public:
  OVM_COMPONENT_UTILS(top)
    
    top(sc_module_name name) : ovm_component(name), p1("producer1"), p2("producer2"), c("consumer"), fifo("fifo")
  {
    c.in(fifo);
    p1.out(fifo);
    p2.out(fifo);
  };

};

OVM_COMPONENT_REGISTER(top)
