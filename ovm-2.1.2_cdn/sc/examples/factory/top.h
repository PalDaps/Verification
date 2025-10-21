
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

#include "gen_pkg.h"

/*
About: factory

This example will illustrate the usage of ovm_factory methods.
To get more details about the factory related methods, check the file:
	- ovm/src/base/ovm_factory.h
*/

class mygen : public gen
{
 public:
  mygen(sc_module_name name) : gen(name) 
    {
    }
    packet* get_packet()
      {
	cerr << "Getting a packet from " << name() << " (" << get_type_name() << ")" << endl;
	return gen::get_packet();
      }
    OVM_COMPONENT_UTILS(mygen)
};
OVM_COMPONENT_REGISTER(mygen);

class mypacket : public  packet
{
public:
  mypacket() : packet() 
  {
  }
  OVM_OBJECT_UTILS(mypacket);
};
OVM_OBJECT_REGISTER(mypacket);



class top : public ovm_component
{
 public:
  //env e; 
  gen* gen1;
  top(sc_module_name name) : ovm_component(name)
    {
      ovm_set_inst_override( "top.gen1","gen", "mygen");
      set_type_override("packet","mypacket");

      ovm_factory::print_all_overrides();
      ovm_set_global_stop_timeout(sc_time(100, SC_NS));
      gen1 = DCAST<gen*>(ovm_create_component("gen", "top", "gen1"));
    }

    void run()
    {
      int i;
      packet* p;
      for(i=0;i<5;i++)
	{
	  wait(15, SC_NS);
	  p = gen1->get_packet();
	  cerr << "Got packet: " << p->get_type_name() << " " << (*p) << endl;
	}
    }
    OVM_COMPONENT_UTILS(top);
};
OVM_COMPONENT_REGISTER(top);
