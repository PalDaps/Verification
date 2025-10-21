#ifndef ML_OVM_PACKER_H
#define ML_OVM_PACKER_H

#include "ml_ovm/sc_unilang.h"
#include "sysc/utils/sc_report.h"
#include "base/ovm_packer.h"

using namespace std;
using namespace sc_dt;

namespace sc_core {
  extern void ncsc_print_sc_report_message(const sc_core::sc_report& rep);
}

namespace ovm {

//#define ML_OVM_PACKING_BLOCK_SIZE_INT 4096 * 32
#define ML_OVM_PACKING_BLOCK_SIZE_INT 131072

class ml_ovm_packer_rep_int;

class ml_ovm_packer : public ovm_packer {
public:
  ml_ovm_packer();
  virtual ~ml_ovm_packer();
  virtual bool use_metadata() const;
  virtual void use_metadata(bool b);
  virtual void fill_nc_unilang_packed_obj(nc_unilang_packed_obj* v);
  virtual void set_from_nc_unilang_packed_obj(nc_unilang_packed_obj* v);

  static ml_ovm_packer& get_the_ml_ovm_packer();
};

class ml_ovm_packer_int : public ml_ovm_packer {
public:
  ml_ovm_packer_int(); 
  ~ml_ovm_packer_int(); 

  virtual bool use_metadata() const;
  virtual void use_metadata(bool b);

  virtual void fill_nc_unilang_packed_obj(nc_unilang_packed_obj* v);
  virtual void set_from_nc_unilang_packed_obj(nc_unilang_packed_obj* v);

  virtual void reset();
  virtual int get_remaining_unpacked_bits();

  virtual ml_ovm_packer_int& operator << (bool a);
  virtual ml_ovm_packer_int& operator << (char a);
  virtual ml_ovm_packer_int& operator << (unsigned char a);
  virtual ml_ovm_packer_int& operator << (short a);
  virtual ml_ovm_packer_int& operator << (unsigned short a);
  virtual ml_ovm_packer_int& operator << (int a);
  virtual ml_ovm_packer_int& operator << (unsigned int a);
  virtual ml_ovm_packer_int& operator << (long a);
  virtual ml_ovm_packer_int& operator << (unsigned long a);
  virtual ml_ovm_packer_int& operator << (long long a);
  virtual ml_ovm_packer_int& operator << (unsigned long long a);
  
  virtual ml_ovm_packer_int& operator << (std::string a);
  virtual ml_ovm_packer_int& operator << (const char*);
 
  virtual ml_ovm_packer_int& operator << (ovm_object* a);
  virtual ml_ovm_packer_int& operator << (const ovm_object& a);
  virtual ml_ovm_packer_int& operator << (const sc_logic& a);
  virtual ml_ovm_packer_int& operator << (const sc_bv_base& a);
  virtual ml_ovm_packer_int& operator << (const sc_lv_base& a);
  virtual ml_ovm_packer_int& operator << (const sc_int_base& a);
  virtual ml_ovm_packer_int& operator << (const sc_uint_base& a);
  virtual ml_ovm_packer_int& operator << (const sc_signed& a);
  virtual ml_ovm_packer_int& operator << (const sc_unsigned& a);
  //template <class T> ml_ovm_packer_int& operator << (const std::vector<T>& a) {
  //  return ovm_packer::operator << (a);
  //}
  virtual ml_ovm_packer_int& operator << (const std::vector<bool>& a); 

  virtual ml_ovm_packer_int& operator >> (bool& a);
  virtual ml_ovm_packer_int& operator >> (char& a);
  virtual ml_ovm_packer_int& operator >> (unsigned char& a);
  virtual ml_ovm_packer_int& operator >> (short& a);
  virtual ml_ovm_packer_int& operator >> (unsigned short& a);
  virtual ml_ovm_packer_int& operator >> (int& a);
  virtual ml_ovm_packer_int& operator >> (unsigned int& a);
  virtual ml_ovm_packer_int& operator >> (long& a);
  virtual ml_ovm_packer_int& operator >> (unsigned long& a);
  virtual ml_ovm_packer_int& operator >> (long long& a);
  virtual ml_ovm_packer_int& operator >> (unsigned long long& a);
  virtual ml_ovm_packer_int& operator >> (std::string& a);
  virtual ml_ovm_packer_int& operator >> (ovm_object*& a);
  virtual ml_ovm_packer_int& operator >> (sc_logic& a);
  virtual ml_ovm_packer_int& operator >> (sc_bv_base& a);
  virtual ml_ovm_packer_int& operator >> (sc_lv_base& a);
  virtual ml_ovm_packer_int& operator >> (sc_int_base& a);
  virtual ml_ovm_packer_int& operator >> (sc_uint_base& a);
  virtual ml_ovm_packer_int& operator >> (sc_signed& a);
  virtual ml_ovm_packer_int& operator >> (sc_unsigned& a);
  //template <class T> ml_ovm_packer_int& operator >> (std::vector<T>& a) {
  //  return ovm_packer::operator >> (a);
 // }
  virtual ml_ovm_packer_int& operator >> (std::vector<bool>& a);

protected:
  void set_bits(unsigned* bits, unsigned nwords);
  unsigned* get_packed_bits_int();

  ml_ovm_packer_rep_int* m_rep_int;
};



//////////////

template <class T> void ml_ovm_packer_pack(
  const T& val,
  nc_unilang_packed_obj* p
) {
  //ml_ovm_packer pkr;
  static ml_ovm_packer& pkr = ml_ovm_packer::get_the_ml_ovm_packer();
  pkr << val;
  int packed_size = pkr.get_remaining_unpacked_bits();
  int max_size = ml_ovm::sc_unilang_utils::get_max_bits();
  if (packed_size > max_size) {
    char msg[1024];
    sprintf(msg,"\novm_object size is %d\n"
            "Max size is %d\n"
            "ovm_object type is '%s'\n"
            "Consider increasing the maximum size limit with the "
            "irun option '-defineall OVM_PACK_MAX_SIZE=<size>'.",
             packed_size, max_size, val.get_type_name().c_str()
           );
    SC_REPORT_ERROR(ML_OVM_SIZE_LIMIT_,msg);
  }
  pkr.fill_nc_unilang_packed_obj(p);
  pkr.reset();
}

template <class T> void ml_ovm_packer_unpack_create(
  nc_unilang_packed_obj* p,
  T*& val,
  void*
) {
  val = new T();
  //ml_ovm_packer pkr;
  static ml_ovm_packer& pkr = ml_ovm_packer::get_the_ml_ovm_packer();
  pkr.set_from_nc_unilang_packed_obj(p);
  pkr >> *val;
  pkr.reset();
}

template <class T> void ml_ovm_packer_unpack_create(
  nc_unilang_packed_obj* p,
  T*& val,
  ovm_object*
) {
  T dummy;
  try {
    //ml_ovm_packer pkr;
    static ml_ovm_packer& pkr = ml_ovm_packer::get_the_ml_ovm_packer();
    pkr.set_from_nc_unilang_packed_obj(p);
    pkr >> val;
    // check if any unpack error happened;
    // only 2 kinds of errors are flagged:
    // too few bits or too many bits;
    // check for too few bits here, for
    // too many bits exception is thrown
    // which needs to be caught
    if (int rem = pkr.get_remaining_unpacked_bits()) { // implies too few bits
      char msg[1024];
      sprintf(msg,"\nFewer bits unpacked in SystemC than were packed "
              "for this ovm_object in foreign language. "
              "This may be due to a mismatch in class definitions "
              "across languages - the SystemC "
              "ovm_object is smaller in size\n"
              "ovm_object type is '%s'\n"
              "Number of remaining bits is %d\n",
               dummy.get_type_name().c_str(), rem 
             );
      SC_REPORT_ERROR(OVM_PACKER_UNPACK_OBJECT_,msg);
    }
    pkr.reset();
  }
  // check if "too may bits" error happened
  catch( const sc_report& ex ) {
    if (strcmp(OVM_PACKER_UNPACK_INDEX_, ex.get_msg_type()) == 0) {
      // implies too may bits error
      sc_core::ncsc_print_sc_report_message(ex);
      //ml_ovm_packer epkr;
      char msg[1024];
      sprintf(msg,"\nMore bits unpacked in SystemC than were packed "
              "for this ovm_object in foreign language. "
              "This may be due to a mismatch in class definitions "
              "across languages - the SystemC "
              "ovm_object is larger in size\n"
              "ovm_object type is '%s'\n",
               dummy.get_type_name().c_str()
             );
      SC_REPORT_ERROR(OVM_PACKER_UNPACK_OBJECT_,msg);
    } else  {
      // not the error we are looking for, throw back
      throw(ex);
    }
  }
}


////////////////////////////////////

} // namespace ovm

#endif
