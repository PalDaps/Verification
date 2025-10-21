/*------------------------------------------------------------------------- 
File name   : ovm_mb_defines.svh
Title       : OVM System Verilog Module-Based Macros
Project     : Module-Based OVM
Developers  : 
Created     : 
Description : This file defines Module-Based specific macros on top of those
            : in OVM.
            :
Notes       : 

-------------------------------------------------------------------
Copyright (c) 2008 Cadence Design Systems, Inc. All rights reserved worldwide.
Please refer to the terms and conditions in $IPCM_HOME.
-------------------------------------------------------------------*/


`ifndef OVM_MB_DEFINES_SVH
`define OVM_MB_DEFINES_SVH



 
`define ovm_set_thread_seed \
    begin  \
       $sformat(ovm_pkg::ovm_seed_module_path_str, "%m");   \
       process::self.srandom( ovm_pkg::ovm_get_rtl_path_seed() ); \
    end



`endif // OVM_MB_DEFINES_SVH

