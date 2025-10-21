#ifndef _FIFO_CONSUMER_H
#define _FIFO_CONSUMER_H

#include "consumer.h"

// define a fifo_consumer that derives from consumer
// and uses a fifo internally to process the tokens;
// implement put() to dump tokens to the fifo, that the run
// process gets out
template <typename T>
class fifo_consumer : public consumer<T> {
public:
  tlm_fifo<packet> f;

  // constructor
  fifo_consumer(sc_module_name nm) : 
    consumer<T>(nm), 
    f("f", 20) // create a fifo of size 20, the default size is 1
  {  
    cout << "In fifo_consumer ctor" << endl;
  }
  // use macro to generate methods that the factory requires
  OVM_COMPONENT_UTILS(fifo_consumer)


  // implement put() and consume tokens 
  void put(const T& t) {
    // process token t
    cout << sc_time_stamp() << ": fifo_consumer received" << endl;
    doit(t);
  }

  void doit(const T& t) {
     wait(5, SC_NS);
    cout << sc_time_stamp() << ": fifo_consumer putting to fifo" << endl;
    f.put(t);
  }

  void run() {
    for (;;) {
      T t = f.get();
      cout << sc_time_stamp() << ": fifo_consumer got from fifo" << endl;
      t.print(cout);
    }
  }
      
};

#endif
