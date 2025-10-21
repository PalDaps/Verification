#ifndef _ENV_H
#define _ENV_H

#include "producer.h"
#include "consumer.h"
#include "packet.h" // packet is an ovm_object

// use macro to register templated child components with the factory
OVM_COMPONENT_REGISTER_T(producer, packet)
OVM_COMPONENT_REGISTER_T(consumer, packet)

class parent_component : public ovm_component {
public:

  // declare child components as pointers
  producer<packet> *prod_p;
  consumer<packet> *cons_p;

  // constructor
  parent_component(sc_module_name nm) : ovm_component(nm), prod_p(0), cons_p(0) {  }

  // use macro to generate member methods that the factory requires
  OVM_COMPONENT_UTILS(parent_component)

  void build() {

    cout << "in parent_component::build" << endl;
    
    // setup configurations
    set_config_string("producer", "in_file", "stimulus.txt");

    // build hierarchy
    // use factory to create each component, and then dynamic cast
    // to right type
    ovm_component *c = create_component("producer_packet", "producer");
    prod_p = DCAST<producer<packet>*>(c);
    assert(prod_p);
    c = create_component("consumer_packet", "consumer");
    cons_p = DCAST<consumer<packet>*>(c);
    assert(cons_p);
     
    // do bindings in usual SystemC fashion
    prod_p->out(cons_p->in);    
  }
};

// register the component with the factory
OVM_COMPONENT_REGISTER(parent_component)

#endif
