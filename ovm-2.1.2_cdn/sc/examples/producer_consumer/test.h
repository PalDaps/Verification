#include "parent_component.h"
#include "fifo_consumer.h"

// register the fifo_consumer templated by packet with the factory 
OVM_COMPONENT_REGISTER_T(fifo_consumer, packet)

// the test sets up a type override to replace consumer with 
// fifo_consumer and then creates the top level component through the factory
class top : public ovm_component 
{
public:
  ovm_component *component_p;
  top(sc_module_name nm) : ovm_component(nm), component_p(0) { }
  OVM_COMPONENT_UTILS(top)
  void build() {

    cout << "in top::build" << endl;

    // set up type override for consumer templated by packet
    // replace ordinary consumer with fifo_consumer
    set_type_override("consumer_packet", "fifo_consumer_packet");

    // create the top level component 
    ovm_component* c = create_component("parent_component", "parent_component");
    component_p = DCAST<ovm_component*>(c);
    assert(component_p);

    // the test can establish connection with the testbench here
    // using sc_find_object() to get access to the testbench.
    // testbench interaction is not shown in this example.
  }
};

OVM_COMPONENT_REGISTER(top)
