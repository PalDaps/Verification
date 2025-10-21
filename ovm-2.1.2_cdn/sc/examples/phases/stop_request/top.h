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
/*
About: phases/stop_request
This test case will test a hierarchy that contains ovm_components.

The topmost ovm_component calls the global_stop_request


To get detailed information about the ovm_components, you may check the following file:
	- ovm/src/base/ovm_component.cpp
*/


#include "ovm.h"
#include <unistd.h>

using namespace ovm;

class B : public ovm_component
{
  int delay;
 public:
  B(sc_module_name x) : ovm_component(x)
    {
      delay = 50;
      if (name() == std::string("top.a1.b1")) delay = 205;
      if (name() == std::string("top.a2.b1")) delay = 176;
    };

    void build()
    {
      cerr << sc_time_stamp() << ": " << name() << ": In build phase" << endl;
    }

    void run()
    {
      cerr << sc_time_stamp() << ": " << name() << ": start run phase" << endl;
      wait(delay, SC_NS);
      cerr << sc_time_stamp() << ": " << name() << ": end run phase" << endl;
    }

    void report()
    {
      cerr << sc_time_stamp() << ": " << name() << ": In report phase" << endl;
    }

    bool enable_stop_interrupt()
    {
      return true;
    }

    OVM_COMPONENT_UTILS(B)
      };

OVM_COMPONENT_REGISTER(B)

class A  : public ovm_component
{
  class B b1;
  int delay;
  //bool alldone;
  sc_semaphore alldone;
 public:
  A(sc_module_name x) : ovm_component(x), b1("b1"), alldone(0)
    {
      delay = 75;
      if (name() == std::string("top.a1")) delay = 19;
      if (name() == std::string("top.a2")) delay = 200;
    };

    bool enable_stop_interrupt()
    {
      return true;
    }

    void build()
    {
      cerr << sc_time_stamp() << ": " << name() << ": In build phase" << endl;
    }

    void run()
    {
      cerr << sc_time_stamp() << ": " << name() << ": start run phase" << endl;
      wait(delay, SC_NS);
      cerr << sc_time_stamp() << ": " << name() << ": end run phase" << endl;
      alldone.post();
    }

    void stop()
    {
      cerr << sc_time_stamp() << ": " << name() << ":  In the stop interrupt, waiting for alldone" << endl;
      alldone.wait();
      cerr << sc_time_stamp() << ": " << name() << ":  Done with the stop interrupt" << endl;
    }
    OVM_COMPONENT_UTILS(A)
      };
OVM_COMPONENT_REGISTER(A)


class top : public ovm_component
{
  class A a1; 
  class A a2; 

 public:

  bool enable_stop_interrupt() 
  {
    return true;
  };
  
  top(sc_module_name x) : ovm_component(x), a1("a1"), a2("a2")   
  { 
  };

    void run() 
    {
      cerr << sc_time_stamp() << ": " << name() << ":  start run phase" << endl;
      wait(75, SC_NS);
      ovm_stop_request();
      wait(1000, SC_NS);
      cerr << sc_time_stamp() << ": " << name() << ":  shouldn't get here." << endl;
    };
    OVM_COMPONENT_UTILS(top);
};
OVM_COMPONENT_REGISTER(top)
