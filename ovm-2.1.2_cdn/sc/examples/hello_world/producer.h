
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


#ifndef _producer_h_
#define _producer_h_

#include "ovm.h"
#include "tlm.h"

using namespace ovm;
using namespace tlm;

template<class T> class producer : public ovm_component
{
protected:
  T proto;
  int num_packets;
  int count;

public:
  OVM_COMPONENT_UTILS(producer)

    sc_port<tlm::tlm_fifo_put_if<T> >out;

  producer(sc_module_name name) : ovm_component(name), num_packets(1), count(0)
  {
    get_config_int("num_packets", num_packets);
  };

  void run()
  {
    std::string image;
    std::string num;
    cout << "[" << sc_time_stamp() << "] hier=" << name() << ": Starting." << endl;
    for(count = 0; count < num_packets; count++)
      {
	T p;
	char count_ascii[10];
        sprintf(count_ascii, "%d", count);
	p.name_ = name() + std::string("-") + std::string(count_ascii);
	cout << "[" << sc_time_stamp() << "] hier=" << name() <<": Sending " << p.get_name() << endl;
        out->put(p);
        wait(10, SC_NS);
      }
    cout << "[" << sc_time_stamp() << "] hier=" << name() <<": Exiting " << endl;
  }
};

OVM_COMPONENT_REGISTER_T(producer, packet)

#endif
