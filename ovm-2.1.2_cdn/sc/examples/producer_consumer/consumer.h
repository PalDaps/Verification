#ifndef _CONSUMER_H
#define _CONSUMER_H

#include "ovm.h"
using namespace ovm;
#include "tlm.h"

// define a basic consumer that does not process the 
// input tokens; implement put() to simply print the
// token to screen
template <typename T>
class consumer : public ovm_component, public tlm::tlm_blocking_put_if<T> {
public:
  // output port
  sc_export<tlm::tlm_blocking_put_if<T > > in;

  // constructor
  consumer(sc_module_name nm) : ovm_component(nm), in("in") {  
    // bind export to itself
    in(*this);
  }
  // use macro to generate methods that the factory requires

  OVM_COMPONENT_UTILS(consumer)

  // implement put() and consume tokens 
  void put(const T& t) {
    t.print(cout);
    // process token t
      cout << sc_time_stamp() << ": consumer received" << endl;
    wait(5, SC_NS);
  }
};

#endif
