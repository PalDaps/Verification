
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



#ifndef _consumer_h_
#define _consumer_h_

#include "ovm.h"

using namespace ovm;
using namespace tlm;

template<class T> class consumer : public ovm_component
{
 protected:
  int count;
 public:
  OVM_COMPONENT_UTILS(consumer)
    sc_port<tlm_fifo_get_if< T > > in;

  consumer(sc_module_name name) : ovm_component(name), in("in"), count(0)
    {
    }

    void run()
    {
      T p;
      while(in.size())
	{
	  T p;
	  count++;
	  wait(10, SC_NS);
	  in->get(p);
	  wait(30, SC_NS);
	  cout << "[" << sc_time_stamp() << "] hier=" << name() << ":  Received " << p.get_name() << " local_count=" << count << endl;
	}
    }


};

OVM_COMPONENT_REGISTER_T(consumer, packet)

#endif
