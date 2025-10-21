#ifndef _PRODUCER_H
#define _PRODUCER_H

#include "ovm.h"
using namespace ovm;
#include "tlm.h"

// define a proucer component that produces data at its output port
// by reading the data from a file; the file name is a configurable
// string paramater
template <typename T>
class producer : public ovm_component {
public:
  // output port
  sc_port<tlm::tlm_blocking_put_if<T > > out;

  // configurable string parameter
  std::string in_file;

  // constructor
  producer(sc_module_name nm) : ovm_component(nm), out("out") {
    // get parameter value for in_file through get_config
    get_config_string("in_file", in_file);
    cout << "in producer ctor, in_file is " << in_file << endl;
    in_file_strm = new ifstream(in_file.c_str());
  }

  // use macro to generate methods that the factory needs
  OVM_COMPONENT_UTILS(producer)

  // produce tokens in the run task
  void run() {
    int val;
    // generate data from file
    for (int i = 0; i < 5; i++) {
      wait(10, SC_NS);

      // read token from file
      *in_file_strm >> val;

      // use token to construct a data packet
      T data(val);

      // output data packet on output port
      cout << endl << "#####################" << endl;
      cout << sc_time_stamp() << ": producer sending " << val << endl;
      out->put(data);
    }

    // done producing tokens, wait a little, and then stop the test
    wait(100, SC_NS);
    cout << endl << "#####################" << endl;
    cout << sc_time_stamp() << ": issuing ovm_stop_request()" << endl;
    ovm_stop_request();
  }
protected:
  ifstream* in_file_strm;
};
#endif
