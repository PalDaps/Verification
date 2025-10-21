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

#ifndef OVM_IDS_H
#define OVM_IDS_H

#include "sysc/utils/sc_report.h"


//-----------------------------------------------------------------------------
// Report ids (ovm) following the style of SystemC kernel message reporting.
//
// Report ids in the range of 1-100.

// If SystemC kernel is modified to be aware of the OVM message ids,
// then sysc/utils/sc_utils_ids.cpp has to include this file, and 
// has to define OVM_DEFINE_MESSAGE suitably with an offset added 
// to the message id such that the id does not clash with any id 
// already used by the SystemC kernel.  
//-----------------------------------------------------------------------------

#ifndef OVM_DEFINE_MESSAGE
#define OVM_DEFINE_MESSAGE(id, unused, text) \
 namespace sc_core { extern const char id[]; }
#endif

//
// OVM-SC messages
//

OVM_DEFINE_MESSAGE(OVM_MULTIPLE_STOP_PROCS_    , 1,
        "ovm_component has multiple children named 'stop'; did you mistakenly declare 'SC_THREAD(stop)'?")
OVM_DEFINE_MESSAGE(OVM_PACKER_UNPACK_INDEX_, 2,
        "ovm_packer unpack_index > pack_index")
OVM_DEFINE_MESSAGE(OVM_PACKER_UNPACK_OBJECT_, 3,
        "ovm_packer unpack_object failed")
OVM_DEFINE_MESSAGE(OVM_CREATOR_NOT_FOUND_, 4,
        "ovm creator not found for type")
OVM_DEFINE_MESSAGE(OVM_CREATOR_NOT_OBJECT_, 5,
        "ovm creator is not an object creator")
OVM_DEFINE_MESSAGE(OVM_CREATOR_NOT_COMP_, 6,
        "ovm creator is not a component creator")
OVM_DEFINE_MESSAGE(OVM_OVERRIDE_EXISTS_, 7,
        "ovm type override already exists")
OVM_DEFINE_MESSAGE(OVM_CONFIG_INTERNAL_, 8,
        "ovm config internal error")
OVM_DEFINE_MESSAGE(OVM_UNPACK_DCAST_, 9,
        "DCAST from ovm_object failed in ovm_packer operator >>")
OVM_DEFINE_MESSAGE(OVM_PACK_NULL_, 10,
        "Attempt to pack null ovm_object")
OVM_DEFINE_MESSAGE(OVM_UNPACK_OBJ_NO_METADATA_, 11,
        "Attempt to unpack ovm_object without metadata")

#endif
