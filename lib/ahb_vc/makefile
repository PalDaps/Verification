OVM_HOME :=./../../ovm-2.1.2

DIR = $(shell pwd)
VLOG_COMMAND = irun -nclibdirpath $(DIR) -compile
VLOG_OPTIONS = -nolog -errormax 1 -incdir $(OVM_HOME)/src/

compile: vlog_ovm_ahb_vc

full: vlog_ovm_pkg vlog_ovm_ahb_vc

vlog_ovm_ahb_vc:
	$(VLOG_COMMAND) ovm_ahb_vc_pkg.sv  $(VLOG_OPTIONS)

vlog_ovm_pkg:
	$(VLOG_COMMAND) $(VLOG_OPTIONS) $(OVM_HOME)/src/ovm_pkg.sv