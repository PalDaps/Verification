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


#ifndef OVM_OBJECT_H
#define OVM_OBJECT_H

#include "base/ovm_typed.h"
#include "base/ovm_ids.h"

#include "sysc/utils/sc_hash.h"

#include <string>
#include <iostream>
#include <vector>

//////////////

namespace ovm {

// forward declaration of ovm_packer used in ovm_object

class ovm_packer;


//------------------------------------------------------------------------------
//
// CLASS: ovm_object
//
// Base class for data objects. 
//
//------------------------------------------------------------------------------

class ovm_object : public ovm_typed {
public:

  //----------------------------------------------------------------------------
  // Constructors and destructor
  //----------------------------------------------------------------------------

  ovm_object();
  ovm_object(const std::string& name);
  virtual ~ovm_object();

  //----------------------------------------------------------------------------
  // functions relating to name
  //
  // get_full_name() returns get_name()
  //----------------------------------------------------------------------------

  virtual void set_name(const std::string& name);
  virtual std::string get_name() const;
  virtual std::string get_full_name() const;
 
  //----------------------------------------------------------------------------
  // print, pack, unpack, copy, compare
  //
  // ovm_object methods that call the corresponding required overrides 
  // do_print(), do_pack(), do_unpack(), do_copy(), and do_compare()
  //----------------------------------------------------------------------------

  virtual void print(std::ostream& os) const;
  int pack(ovm_packer& p) const;
  int unpack(ovm_packer& p);
  void copy(const ovm_object* rhs);
  bool compare(const ovm_object* rhs) const;

  //----------------------------------------------------------------------------
  // clone
  //
  // Creates a clone by doing a create followed by a copy 
  //----------------------------------------------------------------------------

  ovm_object* clone() const;
  
  //----------------------------------------------------------------------------
  // get_type_name   -- Required override
  //
  // Return the type name of this class - e.g., "my_object".
  // Inherits this pure virtual method from base class ovm_typed.
  //----------------------------------------------------------------------------
 
  virtual std::string get_type_name() const = 0;
  
  //----------------------------------------------------------------------------
  // do_print  -- Required override
  //
  // Print the object to a stream
  //----------------------------------------------------------------------------

  virtual void do_print(std::ostream& os) const = 0;

  //----------------------------------------------------------------------------
  // do_pack, do_unpack  -- Required overrides
  //
  // Pack/unpack the object using an ovm_packer
  //----------------------------------------------------------------------------

  virtual void do_pack(ovm_packer& p) const = 0;
  virtual void do_unpack(ovm_packer& p) = 0;

  //----------------------------------------------------------------------------
  // do_copy  -- Required override
  //
  // Copy the data from another object into this one.
  //----------------------------------------------------------------------------
 
  virtual void do_copy(const ovm_object* rhs) = 0;

  //----------------------------------------------------------------------------
  // do_compare  -- Required override
  //
  // Compare the data of another object with this one. Return true if equal.
  //----------------------------------------------------------------------------

  virtual bool do_compare(const ovm_object* rhs) const = 0;

  //----------------------------------------------------------------------------
  // Commands to pack the object to vectors of bool, char, or int.
  // Each returns the number of bits in the packed object.
  //----------------------------------------------------------------------------

  int pack_bits(std::vector<bool>& v, ovm_packer* p = 0);
  int pack_bytes(std::vector<char>& v, ovm_packer* p = 0);
  int pack_ints(std::vector<int>& v, ovm_packer* p = 0);

  //----------------------------------------------------------------------------
  // Commands to unpack the object from vectors of bool, char, or int.
  // Each returns the size of the given vector.
  //----------------------------------------------------------------------------

  int unpack_bits(const std::vector<bool>& v, ovm_packer* p = 0);
  int unpack_bytes(const std::vector<char>& v, ovm_packer* p = 0);
  int unpack_ints(const std::vector<int>& v, ovm_packer* p = 0);

  friend std::ostream& operator<<( std::ostream& os, const ovm_object& obj );
  friend std::ostream& operator<<( std::ostream& os, const ovm_object* obj );

protected:

  std::string m_name; // the full name 
};

//////////////////////

//------------------------------------------------------------------------------
// Registration macros to register an ovm_object with the factory.
// 
// A registration macro should be invoked outside the ovm_object class
// declaration.
// A registration macro registers the given ovm_object with the factory, and
// defines the get_type_name() member method of the registered object.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Use the macro below to register a simple non-templated ovm_object.
// The macro argument is the name of the class.
// The registered name with the factory is the same as the macro argument.
//------------------------------------------------------------------------------

#define OVM_OBJECT_REGISTER(t) \
static int ovm_object_register_dummy_##t = \
  ovm::ovm_factory::register_object_creator( #t,new t::ovm_object_creator_##t()); \
inline std::string t::get_type_name() const { return #t; }

//------------------------------------------------------------------------------
// Use the macro below to register a simple non-templated ovm_object, 
// with a different registered name (first argument) than its 
// class name (second argument).
// The registered name with the factory is the same as the first macro argument.
//------------------------------------------------------------------------------

#define OVM_OBJECT_REGISTER_ALIAS(name,t) \
static int ovm_object_register_dummy_##name##_##t = \
  ovm::ovm_factory::register_object_creator( #name,new t::ovm_object_creator_##t()); \
inline std::string t::get_type_name() const { return #name; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_objects with 
// one template parameter.
// The first macro argument is the class name, and the second macro argument
// is a specific value of the template parameter.
// Example usage: "OVM_OBJECT_REGISTER_T(myobj, int)".
// The registered name with the factory is a concatenation of the first
// and second arguments, separated by "_".
// e.g., "myobj_int".
//------------------------------------------------------------------------------

#define OVM_OBJECT_REGISTER_T(t,T) \
static int ovm_object_register_dummy_##t##_##T = \
  ovm::ovm_factory::register_object_creator( #t "_" #T, new t<T>::ovm_object_creator_##t()); \
template<> inline std::string t<T>::get_type_name() const { return #t "_" #T; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_objects with 
// one template parameter, when you do not want the default registered name.
// Specify the alternate registration name as the first macro argument.
// Example usage: "OVM_OBJECT_REGISTER_T_ALIAS(myname, myobj, int)".
// The registered name with the factory is the same as the first macro argument.
//------------------------------------------------------------------------------

#define OVM_OBJECT_REGISTER_T_ALIAS(name,t,T) \
static int ovm_object_register_dummy_##name##_##t = \
  ovm::ovm_factory::register_object_creator( #name, new t<T>::ovm_object_creator_##t()); \
template<> inline std::string t<T>::get_type_name() const { return #name; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_objects with 
// two template parameters.
// The first macro argument is the class name. 
// The second and third macro arguments are specific values of the 
// two template parameters.
// Example usage: "OVM_OBJECT_REGISTER_T2(myotherobj, int, int)".
// The registered name with the factory is a concatenation of the first,
// second, and third arguments, separated by "_". 
// e.g., "myotherobj_int_int".
//------------------------------------------------------------------------------

#define OVM_OBJECT_REGISTER_T2(t,T1,T2) \
static int ovm_object_register_dummy_##t##_##T1##_##T2 = \
  ovm::ovm_factory::register_object_creator( #t "_" #T1 "_" #T2, new t<T1,T2>::ovm_object_creator_##t()); \
template<> inline std::string t<T1,T2>::get_type_name() const { return #t "_" #T1 "_" #T2; }

//------------------------------------------------------------------------------
// Use the macro below for registering templated ovm_objects with 
// two template parameters, when you do not want the default registered name.
// Specify the alternate registration name as the first macro argument.
// Example usage: "OVM_OBJECT_REGISTER_T2_ALIAS(myname, myotherobj, int, int)".
// The registered name with the factory is the same as the first macro argument.
//------------------------------------------------------------------------------

#define OVM_OBJECT_REGISTER_T2_ALIAS(name,t,T1,T2) \
static int ovm_object_register_dummy_##name##_##t = \
  ovm::ovm_factory::register_object_creator( #name, new t<T1,T2>::ovm_object_creator_##t()); \
template<> inline std::string t<T1,T2>::get_type_name() const { return #name; }

//------------------------------------------------------------------------------
// Utility macro to instrument an ovm_object such that it can be registered
// with the factory.
// 
// The utility macro should be invoked inside the ovm_object class
// declaration.
// The utility macro
// - declares the ovm_object_creator_<classname> class used by the factory
//   to create an instance of this object. 
// - declares the get_type_name() member method inside the ovm_object class.
// - defines the << operator to print the ovm_object to a stream.
// - defines ovm_packer >> operators necessary for unpacking this object.
//------------------------------------------------------------------------------

#define OVM_OBJECT_UTILS(t) \
class ovm_object_creator_##t : public ovm::ovm_object_creator { \
public: \
  ovm::ovm_object* create(const std::string& name) { \
    ovm::ovm_object* _ovmsc_obj = new t(); \
    _ovmsc_obj->set_name(name); \
    return _ovmsc_obj; \
  } \
}; \
virtual std::string get_type_name() const; \
static ovm::ovm_object* create() { return new t(); } \
friend std::ostream& operator << (std::ostream& os, const t& h) { \
  h.print(os); \
  return os; \
} \
friend std::ostream& operator << (std::ostream& os, const t*& h) { \
  h->print(os); \
  return os; \
} \
friend ovm::ovm_packer& operator >> (ovm::ovm_packer& p, t*& h) { \
  if (p.use_metadata()) { \
    ovm::ovm_object* ovmsc_obj; \
    p >> ovmsc_obj; \
    if (!ovmsc_obj) { \
      h = new t(); \
      return p; \
    } \
    h = DCAST<t*>(ovmsc_obj); \
    if (!h) {  \
      SC_REPORT_ERROR(sc_core::OVM_UNPACK_DCAST_,""); \
    } \
  } else { \
    h = new t(); \
    h->unpack(p); \
  }   \
  return p; \
} \
friend ovm::ovm_packer& operator >> (ovm::ovm_packer& p, t& h) { \
  if (p.use_metadata()) { \
    t* pt; \
    p >> pt; \
    h = *pt; \
    delete pt; \
  } else { \
    h.unpack(p); \
  } \
  return p; \
}
} // namespace ovm

#endif
