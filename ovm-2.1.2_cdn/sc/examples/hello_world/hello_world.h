
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

#ifndef hello_world_h_
#define hello_world_h_

#include "ovm.h"

using namespace ovm;

class hello_world
{
 public:
  hello_world()
    {
      ovm_set_config_int("top.producer1","num_packets",2);
      ovm_set_config_int("top.producer2","num_packets",4);
      ovm_set_global_timeout(sc_time(1,SC_US));

      cerr << "Test passed..." << endl;

      sc_report_handler::set_actions("/IEEE_Std_1666/deprecated", SC_DO_NOTHING);
    }
};

#endif
