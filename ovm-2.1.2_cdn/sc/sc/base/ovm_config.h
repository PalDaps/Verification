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


#ifndef OVM_CONFIG_H
#define OVM_CONFIG_H

#include "sysc/datatypes/bit/sc_lv.h"

#include <string>

//////////////

namespace ovm {

//------------------------------------------------------------------------------
//
// Internal implementation classes for configuration.
//
//------------------------------------------------------------------------------


// forward declaration of necessary classes.

class ovm_object;
class ovm_component;

class ovm_config_item_int;
class ovm_config_item_string;
class ovm_config_item_object;

typedef enum { 
  ovm_config_type_int, 
  ovm_config_type_string, 
  ovm_config_type_object 
} ovm_config_type;

////////////

//------------------------------------------------------------------------------
//
// CLASS: ovm_config_item
//
// Internal implementation class.
// Base class to represent a configuration setting.
//------------------------------------------------------------------------------

class ovm_config_item {
public:
  friend class ovm_config;
  friend class ovm_config_mgr;
  friend class ovm_factory_rep;
  ovm_config_item(
    const std::string& instname,
    const std::string& field,
    ovm_component* inst_set_by,
    ovm_config_type type
  );
  virtual ~ovm_config_item();
  virtual ovm_config_item_int* as_int();
  virtual ovm_config_item_string* as_string();
  virtual ovm_config_item_object* as_object();
  virtual void print() const = 0;
  void print_match(
    ovm_component* inst_getting,
    std::string instname_req,
    std::string field_req
  ) const;
protected:
  ovm_config_type m_type;
  std::string m_instname;
  std::string m_field;
  ovm_component* m_inst_set_by;
};

//------------------------------------------------------------------------------
//
// CLASS: ovm_config_item_int
//
// Internal implementation class.
// Represents a configuration setting specified by set_config_int().
// Stores the specified value as a sc_lv<4096>.
//------------------------------------------------------------------------------

class ovm_config_item_int : public ovm_config_item {
public:
  ovm_config_item_int(
    const std::string& instname,
    const std::string& field,
    ovm_component* inst_set_by,
    sc_dt::sc_lv<4096> val
  );
  virtual ~ovm_config_item_int();
  virtual ovm_config_item_int* as_int();
  sc_dt::sc_lv<4096> value() const;
  virtual void print() const;
protected:
  sc_dt::sc_lv<4096> m_val;
};

//------------------------------------------------------------------------------
//
// CLASS: ovm_config_item_string
//
// Internal implementation class.
// Represents a configuration setting specified by set_config_string().
//------------------------------------------------------------------------------

class ovm_config_item_string : public ovm_config_item {
public:
  ovm_config_item_string(
    const std::string& instname,
    const std::string& field,
    ovm_component* inst_set_by,
    const std::string& val
  );
  ~ovm_config_item_string();
  virtual ovm_config_item_string* as_string();
  std::string value() const;
  virtual void print() const;
protected:
  std::string m_val;
};

//------------------------------------------------------------------------------
//
// CLASS: ovm_config_item_object
//
// Internal implementation class.
// Represents a configuration setting specified by set_config_object().
//------------------------------------------------------------------------------

class ovm_config_item_object : public ovm_config_item {
public:
  ovm_config_item_object(
    const std::string& instname,
    const std::string& field,
    ovm_component* inst_set_by,
    ovm_object* val
  );
  ~ovm_config_item_object();
  virtual ovm_config_item_object* as_object();
  ovm_object* value() const;
  virtual void print() const;
protected:
  ovm_object* m_val;
};

/////////////////////

typedef std::vector<ovm_config_item*> ovm_config_item_vector;

//------------------------------------------------------------------------------
//
// CLASS: ovm_config
//
// Internal implementation class.
// Represents a table of configuration settings specified inside an 
// ovm_component or at the global level. 
//------------------------------------------------------------------------------

class ovm_config {
public:
  friend class ovm_factory_rep;
  ovm_config();
  ~ovm_config();
  void add_config_item(ovm_config_item* item);
  ovm_config_item* get_config_item(
    ovm_config_type type,
    const std::string& instname, 
    const std::string& field
  );
private:  
  ovm_config_item_vector m_vec;
};

/////////

typedef std::vector<ovm_config*> ovm_config_stack;

//------------------------------------------------------------------------------
//
// CLASS: ovm_config_mgr
//
// Internal implementation class.
// Stores the  configuration table for global configuration settings.
// Implements the global configuration interface and the configuration
// interface in ovm_component.
// 
//------------------------------------------------------------------------------

class ovm_config_mgr {
public:
  friend class ovm_component;
  //
  ovm_config_mgr();
  ~ovm_config_mgr();
  //
  // set/get routines for the global config table
  //
  bool print_config_matches() const;
  void print_config_matches(bool b);

  ovm_config* global_config();
  template <typename T> void set_config_int(
    const std::string& instname,
    const std::string& field,
    const T& val
  );
  void set_config_string(
    const std::string& instname,
    const std::string& field,
    const std::string& val
  );
  void set_config_object(
    const std::string& instname,
    const std::string& field,
    ovm_object* val,
    bool clone = true
  );
  template <class T> bool get_config_int(
    const std::string& instname,
    const std::string& field,
    T& val
  );
  bool get_config_string(
    const std::string& instname,
    const std::string& field,
    std::string& val
  );
  bool get_config_object(
    const std::string& instname,
    const std::string& field,
    ovm_object*& val,
    bool clone = true
  );
public: // for internal use
  template <typename T> void set_config_int(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    const T& val
  );
  void set_config_int(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    const sc_dt::sc_lv<4096>& val
  );
  void set_config_string(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    const std::string& val
  );
  void set_config_object(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    ovm_object* val,
    bool clone
  );
private:
  template <class T> bool get_config_int(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    T& val
  );
  ovm_config_item_int* get_config_int_internal(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    sc_dt::sc_lv<4096>& val
  );
  ovm_config_item_string* get_config_string(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    std::string& val
  );
  ovm_config_item_object* get_config_object(
    ovm_component* inst,
    const std::string& instname,
    const std::string& field,
    ovm_object*& val,
    bool clone = true
  );
  //
  void set_config_item(
    ovm_component* inst,
    ovm_config_item* item
  );
  ovm_config_item* get_config_item(
    ovm_config_type type,    
    ovm_component* inst,
    const std::string& instname,
    const std::string& field
  );
  //
private:
  ovm_config* m_global_config;
  bool m_print_config_matches;
};

ovm_config_mgr* ovm_get_config_mgr();

/////////////

//------------------------------------------------------------------------------
// Templated functions necessary to support get_config_int()
//
//------------------------------------------------------------------------------

template <typename T> void ovm_convert_from_lv(T& v, sc_dt::sc_lv<4096> lv) {
  v = lv; 
}
inline void ovm_convert_from_lv(sc_dt::sc_logic& v, const sc_dt::sc_lv<4096>& lv) { \
  v = lv.get_bit(0);
}
#define ovm_convert_from_lv_int_type(t) \
inline void ovm_convert_from_lv(t& v, const sc_dt::sc_lv<4096>& lv) { \
  sc_dt::uint64 u = lv.to_uint64(); \
  v = u;  \
}
ovm_convert_from_lv_int_type(bool)
ovm_convert_from_lv_int_type(char)
ovm_convert_from_lv_int_type(sc_dt::uchar)
ovm_convert_from_lv_int_type(short)
ovm_convert_from_lv_int_type(ushort)
ovm_convert_from_lv_int_type(int)
ovm_convert_from_lv_int_type(uint)
ovm_convert_from_lv_int_type(long)
ovm_convert_from_lv_int_type(ulong)
ovm_convert_from_lv_int_type(sc_dt::int64)
ovm_convert_from_lv_int_type(sc_dt::uint64)
// and similarly for char, unsigned, ...

/////////////

//------------------------------------------------------------------------------
// Templated functions necessary to support set_config_int()
//
//------------------------------------------------------------------------------

template <typename T> sc_dt::sc_lv<4096> ovm_convert_to_lv(const T& v) {
  sc_dt::sc_lv<4096> lv = v;
  return lv;
}
inline sc_dt::sc_lv<4096> ovm_convert_to_lv(const sc_dt::sc_logic& v) {
  sc_dt::sc_lv<4096> lv = 0;
  lv.set_bit(0,v.value());
  return lv;
}

/////////////

//------------------------------------------------------------------------------
// Implementation of templated functions set_config_int() and get_config_int()
//
//------------------------------------------------------------------------------

template <typename T> void ovm_config_mgr::set_config_int(
  ovm_component* inst,
  const std::string& instname,
  const std::string& field,
  const T& val
) {
  sc_dt::sc_lv<4096> lv = ovm_convert_to_lv(val);
  set_config_int(inst,instname,field,lv);
}

template <typename T> void ovm_config_mgr::set_config_int(
  const std::string& instname,
  const std::string& field,
  const T& val
) {
  set_config_int(0,instname,field,val);
}

template <typename T> bool ovm_config_mgr::get_config_int(
  ovm_component* inst,
  const std::string& instname,
  const std::string& field,
  T& val
) {
  sc_dt::sc_lv<4096> lv;
  ovm_config_item_int* b = get_config_int_internal(inst,instname,field,lv);
  if (!b) {
    return false;
  }
  ovm_convert_from_lv(val,lv);
  if (print_config_matches()) {
    b->print_match(inst,instname,field);
    std::cout << "Value: " << val << std::endl;
  }
  return b;
}

template <typename T> bool ovm_config_mgr::get_config_int(
  const std::string& instname,
  const std::string& field,
  T& val
) {
  return get_config_int(0,instname,field,val);
}

/////////////

} // namespace ovm

#endif
