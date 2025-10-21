OVM_HOME :=./../../ovm-2.1.2

DIR = $(shell pwd)
VLOG_COMMAND = irun -nclibdirpath $(DIR) -compile
VLOG_OPTIONS = -nolog -errormax 1 -incdir $(OVM_HOME)/src/

compile: vlog_design_spec_vc

full: vlog_ovm_pkg compile_addon vlog_design_spec_vc

vlog_design_spec_vc:
	$(VLOG_COMMAND) ovm_design_spec_pkg.sv $(VLOG_OPTIONS)

vlog_ovm_pkg:
	$(VLOG_COMMAND) $(VLOG_OPTIONS) $(OVM_HOME)/src/ovm_pkg.sv

compile_addon: 
	$(MAKE) -C ./../ahb_vc DIR=$(DIR)
	$(MAKE) -C ./../spi_vc DIR=$(DIR)