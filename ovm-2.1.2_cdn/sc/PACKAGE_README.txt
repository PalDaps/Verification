OVM Lib
Copyright (c) 2009 Cadence Design Systems, 
Inc. All rights reserved worldwide.
******************************************************************************
* Title: OVM-SC 
* Name: ovm_lib
* Version: 2.0.1
* Modified: January-2009
* Description:

The package contains SystemC open source class library and usage examples.
The SystemC files should be usable with any SystemC simulator conforming to
IEEE Std 1666.

It has been particularly verified using the Cadence IES/IUS 8.2-s003 release
and the OSCI SystemC 2.2 distribution.

Examples are available under the examples directory and are
delivered with a run_osci and run_ius script.

Note that if you are an IES or Specman user, you already have this library files installed.
We recommend using the installed versions as many of the installation and path concerns
Are already resolved there.


* Documentation:

   The documentation for all the above is provided in 
   PDF format in docs/ directory.


* Installation :


   The Cadence IES/IUS 8.2 distribution already includes this package so
   no further set up is required or recommended for Cadence IES/IUS users.

   However this open source version can be substituted and used directly
   for SystemC only designs in IES/IUS if desired by adding the appropriate
   options to reference the open source install. Thus, if this package is
   installed at /packages, and a SystemC only design is run
   with IUS using the command:

   ncsc_run -top dut -ovmtop SC:test *.cpp

   then the open source installation can be substituted by modifying
   the command to be:

   ncsc_run -top dut -ovmtop SC:TEST *.cpp -I/packages/ovm_ml/ovm_lib/ovm_sc/sc  /packages/ovm_ml/ovm_lib/ovm_sc/sc/*/*.cpp

   1) Outside of IUS, the package can be pre-compiled by referencing
	the appropriate C++ compiler (gcc 3.2.3 and gcc 4.1 have been
	verified in both -m32 and -m64 modes) and appropriate SystemC 2.2,
	TLM 1.0 and TLM 2.0 installations.

	In particular for OSCI usage, the following
	environment variables can be set-up to pre-compile the
	package and run using the run_osci scripts provided in the examples:

OVMSC_INSTALL - location of ovm_sc directory within this package
	(e.g. if package is rooted at /packages, then OVMSC_INSTALL
	would be set to /packages/ovm_ml/ovm_lib/ovm_sc)
OSCI_INSTALL - OSCI installation root (location of "include" directory)
TLM1_INSTALL - TLM 1.0 installation root
TLM2_INSTALL - TLM 2.0 installation root

	Then to pre-compile this package for use with the OSCI simulator:
	
	cd $OVMSC_INSTALL/sc
	g++ -I. -m32 -c */*.cpp -I$OSCI_INSTALL/include; ar crl libovm.a *.o 

   2.   Illustrations of usage are given in the examples directory
        and usage should be further guided by the reference and
	methodology documents provided under the docs directory in the
	package.
