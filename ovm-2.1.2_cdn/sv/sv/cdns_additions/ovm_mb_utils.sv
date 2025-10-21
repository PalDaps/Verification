/*------------------------------------------------------------------------- 
File name   : ovm_mb_utils.sv
Title       : OVM System Verilog Module-Based Utilities
Project     : Module-Based OVM 
Developers  : 
Created     : 
Description : This file holds the bulk of the Module-Based utilities
            : layered on top of OVM.
            :
Notes       : 

-------------------------------------------------------------------
Copyright (c) 2008 Cadence Design Systems, Inc. All rights reserved worldwide.
Please refer to the terms and conditions in $IPCM_HOME.
-------------------------------------------------------------------*/


`ifndef OVM_MB_UTILS_SV
`define OVM_MB_UTILS_SV


//--------------------------------------------
/*
       Test Start/End Utilities
 
The next section implements simple utilities to mark the start and end of a test.

start_test()
  Emits the start_of_test events which can be used as a hook to add more functionality,
  and prints a message similar to that in Specman.
 
end_test()
  Emits the end_of_test event which can be used as a hook to add more end-of-test
  checking functionality, and then prints the tally of errors and warnings during
  this simulation.
 

Two global test phase events are provided:
  start_of_test
  end_of_test
These can be used to add more logic to be executed when a test starts and ends. 
These events are emitted when either:
a. A Module-Based test calls the start_test() and end_test() tasks respectively, or
b. A mixed Class-Based and Module Based environment goes through its OVM phases.
   In this case, the start_of_test event is emitted after the pre_run phase ends,
   and end_of_test event is emitted after the run phase ends event.

*/



event start_of_test;
event end_of_test;
   

//--------------------------------------------
// start_test() - call as the first step in your test.
   
task start_test();
   if (ovm_top.get_num_children() > 0)  
            // Mixed MB and CB environment. We identify this if there are more than
            // one component (the command_line_processor component is always there)
      cb_start_test();
   else
      mb_start_test();
endtask


//--------------------------------------------
// end_test() - call as the last thing in your test. Takes two arguments:
//   stop_simulation -      when 1, will stop the simulation using $finish
//                          Default: 0
//   time_units_to_delay -  delay before stopping the simulation/returning
//                          Default: 1

task end_test(bit stop_simulation = 0,
              int time_units_to_delay = 1);
  
   if (ovm_top.get_num_children() > 0)  
            // Mixed MB and CB environment. We identify this if there are more than
            // one component (the command_line_processor component is always there)
      cb_end_test(stop_simulation, time_units_to_delay);
   else
      mb_end_test(0, stop_simulation, time_units_to_delay);
endtask



//--------------------------------------------
// Class-Library synchronization
// In mixed Class-Based and Module-Based environments, a Class-Based test is 
// expected, causing the components (instances of classes derived from ovm_component)
// in the verification environment to go through their phases.
// Since there might be Module-Based verification components involved as well, the
// following logic take care of informing about the start and end of test.

bit _ovm_fork_mb_sync_done = _ovm_fork_mb_sync();

function bit _ovm_fork_mb_sync();
   fork
      _ovm_mb_sync_to_ovm_phases();
   join_none
endfunction 


task _ovm_mb_sync_to_ovm_phases();
   fork
      begin    // wait for pre_run phase, call MB's start_test
         if(!pre_run_ph.is_in_progress() && !pre_run_ph.is_done())
            pre_run_ph.wait_done();
         mb_start_test(1);
      end

      begin   // wait for the end of run phase, call MB's end_test
         if(!run_ph.is_in_progress() && !run_ph.is_done())
            run_ph.wait_done();
         mb_end_test(1,0,0);
      end
   join_none
endtask 

 

//---------------------------------
// cb_start_test    [Do NOT call directly]
//
// Handles mixed Module-Based/Class-Based environments

task cb_start_test();
   `ovm_warning("OVMMB01", $sformatf("%s", { 
       "\n\tThe module-based 'start_test' utility task was called in a mixed\n",
       "\tmodule+class based environment. The task will return at the end of\n",
       "\tthe 'pre_run' phase. Make sure you also have a valid class-based test\n",
       "\tand a call to 'run_test' in your verification environment.\n"}))
   if(!pre_run_ph.is_in_progress() && !pre_run_ph.is_done())
      pre_run_ph.wait_done();
endtask

//---------------------------------
// mb_start_test    [Do NOT call directly]
//
// Handles Module-Based environments

task mb_start_test(bit silent=0);
   if (!silent) 
      $display("Running the test ...\n");
   
   #0; // allow other modules to start waiting for the start of test event

   // Inform everyone about the start of test
   ->start_of_test;

   #0;    // give a chance to logic that depends on the event to execute
endtask





//---------------------------------
// cb_end_test    [Do NOT call directly]
//
// Handles mixed Module-Based/Class-Based environments


task cb_end_test(bit stop_simulation = 0,
                 int time_units_to_delay = 1);

   `ovm_warning("OVMMB02", $sformatf("%s", { 
        "\n\tThe module-based 'end_test' utility task was called in a mixed\n",
        "\tmodule+class based environment. The task will return at the end of\n",
        "\tthe 'run' phase. Make sure you also have a valid class-based test\n",
        "\tand a call to 'run_test' in your verification environment.\n"}))

   if (stop_simulation) begin
       fork 
          ovm_top.stop_request();
       join_none
   end

   if(!run_ph.is_in_progress() && !run_ph.is_done())
      run_ph.wait_done();

   // delay extra cycles
   if (time_units_to_delay > 0)
      repeat (time_units_to_delay) #1;
endtask



//---------------------------------
// mb_end_test    [Do NOT call directly]
//
// Handles Module-Based environments

task mb_end_test(bit silent = 0,
                 bit stop_simulation = 0,
                 int time_units_to_delay = 1);

   if (!silent) 
       $display("Checking the test ...\n");

   // Report all entities about end of test, and allow them one cycle for
   // end of test activities (check, report, etc).
   ->end_of_test;
   #0;    // give a chance to logic that depends on the event to execute

   // delay extra cycles 
   if (time_units_to_delay > 0)
      repeat (time_units_to_delay) #1;
      
   if (!silent)
      $display("Checking is complete - %0d DUT errors, %0d DUT warnings.\n",
               get_num_of_dut_errors(), get_num_of_dut_warnings());

   if (stop_simulation) begin
      fork
         $finish;
      join_none
   end
endtask




   
//--------------------------------------------
//         Thread Seeding


// Main entry function - calculates a seed as a function of the simulation
// seed and an RTL path that is assumed to be stored in module_path_str.
   
string ovm_seed_module_path_str;

function automatic int ovm_get_rtl_path_seed ();
   // combine global seed with RTL path of the caller
   $sformat(ovm_seed_module_path_str, 
            "%0d%0s", 
            ovm_global_random_seed, 
            ovm_seed_module_path_str);
   return ( ovm_oneway_hash(ovm_seed_module_path_str) );
endfunction
 



       
//--------------------------------------------
//         Trace Messages
 
typedef ovm_verbosity message_verbosity_e;             // for backward compatibility




//--------------------------------------------
//         DUT Error Reporting
 


//--------------------------------------------
// get_num_of_dut_errors - use this function to get the current count of DUT errors
// reported in the current simulation.
// The errors counter is incremented every time a `DUT_ERROR action is executed
// with the severity being OVM_ERROR.
      
function int get_num_of_dut_errors();
   return(ovm_report_global_server::global_report_server.get_severity_count(OVM_ERROR)
          + ovm_report_global_server::global_report_server.get_severity_count(OVM_FATAL));
endfunction


//--------------------------------------------
// get_num_of_dut_warnings - use this function to get the current count of warnings
// reported in the current simulation.
// The warnings counter is incremented every time a `DUT_ERROR action is executed
// with the severity being OVM_WARNING.
      
function int get_num_of_dut_warnings();
   return(ovm_report_global_server::global_report_server.get_severity_count(OVM_WARNING));
endfunction


`endif   // OVM_MB_UTILS_SV


