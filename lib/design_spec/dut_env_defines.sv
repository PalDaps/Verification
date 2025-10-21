`ifndef DUT_ENV_DEFINES
`define DUT_ENV_DEFINES

// DUT reg adresses
`define TX_ADDR        0
`define CR_ADDR        4
`define SR_ADDR        8

// DUT parameters
`define FIFO_DEPTH     4

// system and target interface types defines
// write here your system or target interface type
`define SYSTEM_IF_TYPE ovm_ahb_tran_item
`define TARGET_IF_TYPE ovm_spi_tran_item

// system if sequencer type
`define SYTEM_IF_SEQUENCER ovm_ahb_master_sequencer

`define SYTEM_IF_SEQUENCER_PATH "dut_env.ovm_ahb_agent.ovm_ahb_master_sequencer"

`endif
