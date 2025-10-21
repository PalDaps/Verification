#ifndef PACKET_H
#define PACKET_H

using namespace tlm;
using namespace ovm;

/////////////////

// define your own data object that derives from ovm_object;
class packet : public ovm_object {
public:

  // use macro to generate necessary methods that factory needs
  OVM_OBJECT_UTILS(packet)

  packet() { data = 17; }
  packet(int i) { data = i; }
  virtual ~packet() { }

  // implement mandatory pure virtual methods

  virtual void do_print(ostream& os) const {
    os << "packet: " << data << endl;
  }
  virtual void do_pack(ovm_packer& p) const {
    p << data;
  }
  virtual void do_unpack(ovm_packer& p) {
    p >> data;
  }
  virtual void do_copy(const ovm_object* rhs) {
    const packet* drhs = DCAST<const packet*>(rhs);
    if (!drhs) { cerr << "ERROR in do_copy" << endl; return; }
    data = drhs->data;
  }
  virtual bool do_compare(const ovm_object* rhs) const {
    const packet* drhs = DCAST<const packet*>(rhs);
    if (!drhs) { cerr << "ERROR in do_compare" << endl; return true; }
    if (!(data == drhs->data)) return false;
    return true;
  }
public:
  int data;
};

// register the data object with the factory
OVM_OBJECT_REGISTER(packet)

/////////////////

#endif

