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


#ifndef OVM_TYPED_H
#define OVM_TYPED_H

#include "base/ovm_void.h"

#include <string>

namespace ovm {

//------------------------------------------------------------------------------
//
// CLASS: ovm_typed
//
// Root base class for objects that can be created by the factory. 
//
//------------------------------------------------------------------------------

class ovm_typed : virtual public ovm_void {
public:
  ovm_typed();
  virtual ~ovm_typed();
  virtual std::string get_type_name() const;
};

} // namespace ovm

#endif
