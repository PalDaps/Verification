OVM Lib
Copyright (c) 2009-2011 Cadence Design Systems, 
Inc. All rights reserved worldwide.
******************************************************************************
* Title: OVM-SV 
* Name: ovm_lib
* Version: 2.1.2
* Modified: May-2011
* Description:

The package contains SystemVerilog open source class library and usage examples.
The SystemVerilog files should be usable with any SystemVerilog simulator 
conforming to IEEE Std 1364.

It has been particularly verified using the Cadence IES/IUS 9.2-s044 release.

Examples are available under the examples directory and are
delivered with a compile_ius.f file that can be used with irun (using the -f
switch).

Note that if you are an IES or Specman user, you already have this library
installed.  We recommend using the installed versions as many of the installation 
and path concerns Are already resolved there.


* Documentation:

   The documentation for all the above is provided in 
   PDF format in docs/ directory.


* Installation :


   The Cadence IES/IUS 9.2 distribution already includes this package so
   no further set up is required or recommended for Cadence IES/IUS users.

   However this open source version can be substituted and used directly,
   using the -ovmhome option to irun.  Thus, if this package is
   installed at /packages it can be used with IUS using the command:

   irun -ovmhome /packages/ovm_lib <files.sv>

