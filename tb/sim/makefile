#//--------------------------- IP_CORE_LABS-------------------------------------//
#//                        SPI_TX example project                               //
#//                        file -  makefile                                     //
#//                        makefile for example project                         //
#//                        author -  fputrya                                    //
#//-----------------------------------------------------------------------------//

#project home paths
PROJECT_RHOME:=./../../
PROJECT_HOME:=$(shell cd $(PROJECT_RHOME);pwd)
CURRENT_DIR =  $(shell pwd)

#RTL defines (define TOP_LEVEL_NAME and file with all RTL includes here)
RTL_TOP_LEVEL := spi_tx
RTL_FILENAME:= $(PROJECT_HOME)/rtl/spi_tx_all.v

#set to 1 if you want to print trace from RTL
RTL_TRACER_ENABLE:=1

#test list (define all your test names here)
TEST_LIST:=test_regs test_fifo test_tx test_shuf

#harness top level name
TOP_LEVEL_NAME := harness

#print verbosity level
#VERBOSITY_LEVEL := OVM_HIGH
#VERBOSITY_LEVEL := OVM_MEDIUM
#VERBOSITY_LEVEL := OVM_LOW
VERBOSITY_LEVEL := OVM_FULL
#VERBOSITY_LEVEL := OVM_NONE

#pathes
OVM_HOME :=$(PROJECT_HOME)/ovm-2.1.2_cdn

COMPILE_DIR:=$(CURRENT_DIR)
REPORT_FILE:=report.glog
OVM_TB_LIB_HOME = $(PROJECT_HOME)/lib

#HAL defines
HAL_DEF_FILE:=$(PROJECT_HOME)/tb/sim/hal_example.def
HAL_FILENAME:= $(RTL_FILENAME)


#compile parameters
VLOG_COMMAND=xrun -compile
VLOG_OPTIONS:= -cdslib $(PROJECT_HOME)/tb/sim/cds.lib -hdlvar $(PROJECT_HOME)/tb/sim/hdl.var -incdir $(PROJECT_HOME)/rtl -incdir $(OVM_TB_LIB_HOME)/ahb_vc/ -incdir $(OVM_TB_LIB_HOME)/spi_vc/ -incdir $(OVM_TB_LIB_HOME)/design_spec/ -incdir ../harness/ -incdir ../tests -errormax 1

#elaboration parameters
TIMESCALE :=-timescale 1ns/100ps
ELAB_COMMAND:=xmelab
ELAB_OPTIONS:=-cdslib $(PROJECT_HOME)/tb/sim/cds.lib -hdlvar $(PROJECT_HOME)/tb/sim/hdl.var -access +c -notimingchecks -no_tchk_msg -nowarn CUVWSP -nowarn CUSRCH -update -status -errormax 15
#simulations parameters
SIM_COMMAND:=xmsim
SIM_OPTIONS:=-logfile xmsim.log -errormax 15 -input simulate.tcl

#file name for automatically generated test list file 
TESTS_LIST_FILE_NAME:=tests.sv
TEST_ENV_FILE_NAME:=test_files.sv
TEST_ENV_PKG_FILE_NAME:=test_files_pkg.sv
# report options
REPORT_FILENAME=report.glog

#database and coverage enable
DUMPDB:=1
COV:=1

VIEW=v

#compile, elab and sim parameters modification in case of RTL TRACER enable
ifeq ($(RTL_TRACER_ENABLE), 1)
    VLOG_OPTIONS+=-define TRACER_ENABLE
else
    VLOG_OPTIONS+=
endif

#compile, elab and sim parameters modification in case of coverage enable
ifeq ($(COV), 1)
    COVTEST := $(TEST_NAME)
    ELAB_COV_OPTIONS := -COVDUT $(TOP_LEVEL_NAME) -covfile cover.cf
    SIM_COV_OPTIONS := -COVWORKDIR ./cov_work -COVSCOPE $(TOP_LEVEL_NAME) -COVTEST $(COVTEST) -covoverwrite
else
    ELAB_COV_OPTIONS :=
    SIM_COV_OPTIONS :=
endif

#compile, elab and sim parameters modification in case of linting analysis (HAL)
ifeq ($(HAL), 1)
    VLOG_OPTIONS+=-lexpragma
    DEFINE_TRACER_ENABLE=
else
    VLOG_OPTIONS+=
endif

#compile, elab and sim parameters modification in case of OVM native support mode (HAL)
ifeq ($(OVM), 1)
    VLOG_OPTIONS+=-ovm
else
    VLOG_OPTIONS+= -incdir $(OVM_HOME)/src
    VLOG_OVM_PKG_COMMAND:=vlog_ovm_pkg 
endif

#random SEED generation for test
ifndef SEED
    SEED:=$(shell date +%s )
endif

ifeq ($(GUI), 1)
    gui:=-gui
else
    gui:=
endif

# --------------  compile and simulation tools  -------------------------------------

all:compile sim

vlog_ovm_pkg:
	$(VLOG_COMMAND) $(VLOG_OPTIONS) $(OVM_HOME)/src/ovm_pkg.sv

vlog_rtl: cds.lib hdl.var
	#$(MAKE) -C  ./../../rtl DIR=$(COMPILE_DIR)
	$(VLOG_COMMAND) $(RTL_FILENAME) $(VLOG_OPTIONS)

## to kill begin ----------------------------------------------
vlog_ovm_ahb_vc_pkg:
	$(MAKE) -C  $(OVM_TB_LIB_HOME)/ahb_vc/ DIR=$(COMPILE_DIR) VLOG_OPTIONS="$(VLOG_OPTIONS)"

vlog_ovm_spi_vc_pkg:
	$(MAKE) -C  $(OVM_TB_LIB_HOME)/spi_vc/ DIR=$(COMPILE_DIR) VLOG_OPTIONS="$(VLOG_OPTIONS)"

vlog_ovm_design_spec_pkg:
	$(MAKE) -C  $(OVM_TB_LIB_HOME)/design_spec/ DIR=$(COMPILE_DIR) VLOG_OPTIONS="$(VLOG_OPTIONS)"

vlog_harness:
	$(VLOG_COMMAND) $(TEST_ENV_PKG_FILE_NAME) $(VLOG_OPTIONS)

cds.lib:
	echo "define worklib $(COMPILE_DIR)/worklib" > cds.lib
	mkdir worklib

hdl.var:
	echo "define WORK worklib" > hdl.var

## to kill end -----------------------------------

include_tests:
	rm -rf $(TESTS_LIST_FILE_NAME)
	touch $(TESTS_LIST_FILE_NAME)
	for k in $(TEST_LIST); do\
		echo \`include \"$$k.sv\" >> $(TESTS_LIST_FILE_NAME); \
	done;

include_tests_pkg:
	rm -rf $(TESTS_LIST_FILE_NAME)
	touch $(TESTS_LIST_FILE_NAME)
	echo  import ovm_pkg::*\; >> $(TESTS_LIST_FILE_NAME); \
	echo  \`include \"ovm_macros.svh\" >> $(TESTS_LIST_FILE_NAME); \
	echo  import ovm_ahb_vc_pkg::*\; >> $(TESTS_LIST_FILE_NAME); \
	echo  import ovm_spi_vc_pkg::*\; >> $(TESTS_LIST_FILE_NAME); \
	echo  import ovm_design_spec_pkg::*\; >> $(TESTS_LIST_FILE_NAME); \
	for k in $(TEST_LIST); do\
		echo \`include \"$$k.sv\" >> $(TESTS_LIST_FILE_NAME); \
	done;

vlog_tests: include_tests
	$(VLOG_COMMAND) $(TEST_ENV_FILE_NAME) $(TESTS_LIST_FILE_NAME) $(VLOG_OPTIONS)

vlog_tests_pkg: include_tests_pkg vlog_ovm_ahb_vc_pkg vlog_ovm_spi_vc_pkg vlog_ovm_design_spec_pkg
	$(VLOG_COMMAND) $(TEST_ENV_PKG_FILE_NAME) $(TESTS_LIST_FILE_NAME) $(VLOG_OPTIONS)

#vlog_tests_pkg: include_tests_pkg
#	$(VLOG_COMMAND) $(TEST_ENV_PKG_FILE_NAME) $(TESTS_LIST_FILE_NAME) $(VLOG_OPTIONS)

vlog: vlog_rtl $(VLOG_OVM_PKG_COMMAND) vlog_tests

vlog_pkg: vlog_rtl $(VLOG_OVM_PKG_COMMAND) vlog_tests_pkg

elab:
	$(ELAB_COMMAND) \
        $(TOP_LEVEL_NAME) \
        $(TIMESCALE) \
        -snapshot $(TOP_LEVEL_NAME):$(VIEW) \
        $(ELAB_OPTIONS) \
        $(ELAB_COV_OPTIONS)

clean:
	clear
	xmrm -FORCE -library worklib
	rm -rvf /worklib/*
	rm -rvf xcelium.d
	rm -rvf .simvision
	rm -vf *.key
	rm -vf *.log
	rm -rf cov_work
	rm -rf hal.design_facts
	rm -rf harness.shm
	rm -rf *~
	rm -rf $(TESTS_LIST_FILE_NAME)

#compile: clean vlog elab
compile:clean compile_wo_clean

compile_wo_clean: vlog_pkg elab

sim:
	if [ "$(TEST_NAME)" = "$(NONE)" ]; then \
		for k in $(TEST_LIST); do\
			$(MAKE) sim TEST_NAME=$$k; \
		done; \
	else \
		echo SEED==$(SEED); \
		DUMPDB=$(DUMPDB) \
		$(SIM_COMMAND) $(SIM_OPTIONS) $(SIM_COV_OPTIONS) $(TOP_LEVEL_NAME) $(gui) -svseed $(SEED) +OVM_TESTNAME=$(TEST_NAME) +OVM_VERBOSITY=$(VERBOSITY_LEVEL) ; \
		$(MAKE) report TEST_NAME=$(TEST_NAME) SEED=$(SEED) COV=$(COV);\
	fi;

# --------------  report tool  -------------------------------------
COV_ALLTEST:=ALL_TESTS
COV_TEST_NAME:=$(TEST_NAME)
append_coverage:
	if [ -d cov_work/$(TOP_LEVEL_NAME)/$(COV_ALLTEST) ]; then \
		mv -vf cov_work/$(TOP_LEVEL_NAME)/$(COV_ALLTEST) cov_work/$(TOP_LEVEL_NAME)/$(COV_ALLTEST)_temp; \
		printf " merge  cov_work/$(TOP_LEVEL_NAME)/$(COV_ALLTEST)_temp cov_work/$(TOP_LEVEL_NAME)/$(COV_TEST_NAME) -out cov_work/$(TOP_LEVEL_NAME)/$(COV_ALLTEST)\n" | imc -batch; \
	else \
		cp -r cov_work/$(TOP_LEVEL_NAME)/$(COV_TEST_NAME) cov_work/$(TOP_LEVEL_NAME)/$(COV_ALLTEST);\
		echo "CREATE ALL from test";\
	fi
	rm -rf cov_work/$(TOP_LEVEL_NAME)/$(COV_ALLTEST)_temp

report: rpt_date=$(shell date +%F_%H_%M_%S)
report: res=S
report: wres=$(shell if [ "$$(grep "WARNING" xmsim.log)" != "OVM_WARNING :    0" ]; then echo W; else echo $(res); fi)
report: eres=$(shell if [ "$$(grep "ERROR" xmsim.log)"   != "OVM_ERROR :    0"   ]; then echo E; else echo $(wres) ;fi)
report: rpt_status=$(shell if [ "$$(grep "FATAL" xmsim.log)"   != "OVM_FATAL :    0"   ]; then echo F; else echo $(eres); fi)
report:
	cp xmsim.log $(TEST_NAME)_$(rpt_date).log
	echo DATE=$(rpt_date) :: TEST_NAME=$(TEST_NAME) SEED=$(SEED) :: STATUS=$(rpt_status) >> $(REPORT_FILENAME)
	if [ "$(COV)" = "1" ]; then \
		if [ "$(rpt_status)" = "S" ]; then \
			$(MAKE) append_coverage TEST_NAME=$(TEST_NAME) SEED=$(SEED);\
		fi;\
	fi

# --------------  coverage tools  -------------------------------------

cov_view:
	imc -gui -load cov_work/$(TOP_LEVEL_NAME)/$(TEST_NAME) &

clean_cov:
	-rm -rvf cov_work/$(TOP_LEVEL_NAME)/*


# --------------  linting tools  -------------------------------------

hal:
	$(MAKE) vlog_rtl RTL_TRACER=0 COV=0 HAL=1
	$(MAKE) elab TOP_LEVEL_NAME=$(RTL_TOP_LEVEL)
	hal -RULEFILE $(HAL_DEF_FILE) -lexpragma -INCDIR $(PROJECT_HOME)/rtl -NCELABARGS "$(TIMESCALE)" $(HAL_FILENAME)

hal_view:
	ncbrowse -rulefile $(HAL_DEF_FILE) -sortby file -sortby severity -sortby category -sortby tag hal.log &

# --------------  test debuf tools  -------------------------------------

view:
	simvision -nocopyright $(TOP_LEVEL_NAME).shm/ -snapshot $(TOP_LEVEL_NAME):$(VIEW) -title $(VIEW) &


# --------------  other  tools  -------------------------------------
#DEPTH={1,2,3,4....} -
ifndef DEPTH
 DEPTH=4
endif
printprojecttree:
	@cd ./../../; \
	find . -maxdepth $(DEPTH) -path '*.svn' -prune -o -print 2>/dev/null|sort|awk '!/\.$$/ {for (i=1;i<NF;i++){d=length($$i);if ( d < 5  && i != 1 )d=5;printf("%"d"s","|")}print "---"$$NF}'  FS='/'

help:
	@printf "\n\033[1mcomp prepare tools: \033[0m\n"
	@printf "make cds.lib - generate cds.lib\n"
	@printf "make hdl.var - generate hdl.var\n"
	@printf "\n\033[1mRTL analize tools: \033[0m\n"
	@printf "make vlog_rtl  - compile RTL\n"  
	@printf "make hal       - start linting\n"
	@printf "make hal_view  - view linting results\n"
	@printf "\n\033[1mcompile and run tools: \033[0m \n"
	@printf "make compile   - compile RTL and tests\n"  
	@printf "make compile OVM=1  - compile RTL and tests whith native ovm support (needed for transaction coolection)\n"
	@printf "make compile   - compile RTL and tests in package mode\n"
	@printf "make sim       - run all tests\n"
	@printf "make sim TEST_NAME=name  - run test name\n"
	@printf "make view      - view waveforms\n"  
	@printf "make cov_view  - view test coverage\n"
	@printf "make cov_view TEST_NAME=name - view test coverage for test name\n"
