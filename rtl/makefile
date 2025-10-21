DIR =
VLOG_COMMAND = irun -nclibdirpath $(DIR) -compile
VLOG_OPTIONS = -nolog -errormax 1
RTL_LIST = spi_tx_all.v

vlog_ovm_ahb_vc:
	$(VLOG_COMMAND) $(RTL_LIST) $(VLOG_OPTIONS)
