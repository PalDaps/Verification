/*******************************************************************************
         
  Copyright (c) 2006 Cadence Design Systems, Inc. All rights reserved worldwide.
         
  This software is licensed under the Apache license, version 2.0 ("License"). 
  This software may only be used in compliance with the terms of the License.
  Any other use is strictly prohibited. You may obtain a copy of the License at 

    http://www.apache.org/licenses/LICENSE-2.0
         
        The software distributed under the License is provided  "AS IS" WITHOUT
  WARRANTY, EXPRESS OR IMPLIED, OF ANY KIND, INCLUDING, WITHOUT LIMITATION ANY
  WARRANTY AS TO PERFORMANCE, NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS
  FOR ANY PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE RESULTS AND PERFORMANCE
  OF THE PRODUCT IS ASSUMED BY YOU.  TO THE MAXIMUM EXTENT PERMITTED BY LAW,
  IN NO EVENT SHALL CADENCE BE LIABLE TO YOU OR ANY THIRD PARTY FOR ANY
  INCIDENTAL, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES, OR ANY OTHER DAMAGES,
  INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS
  INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS ARISING
  OUT OF THE USE OFTHIS SOFTWARE.
         
        See the License terms for the specific language governing the permissions
  and limitations under the License.
         
*******************************************************************************/

`ifndef CDNS_TCL_INTERFACE_SVH
`define CDNS_TCL_INTERFACE_SVH


`ifdef OVM_URM_PLI
`define cdns_ovm_access(ARG1) $ovm_set_access(ARG1);
`else
`define cdns_ovm_access(ARG1)
`endif

`define TCL_FILENAME ".ovmtclcomm.txt"

//------------------------------------------------------------------------------
//
// CLASS - cdns_hierarchy_only_printer
//
//------------------------------------------------------------------------------

class cdns_hierarchy_only_printer extends ovm_table_printer;
  function void print_object (string name, ovm_object value,
                              byte scope_separator=".");
    ovm_component no;
    if($cast(no, value)) super.print_object(name, value, scope_separator);
  endfunction
  function void print_string (string name, string value,
                              byte scope_separator="."); 
    return;
  endfunction
  function void print_time   (string name, time value,
                              byte scope_separator=".");
    return;
  endfunction
  function void print_field  ( string      name,
                               ovm_bitstream_t value,
                               int         size,
                               ovm_radix_enum  radix=OVM_NORADIX,
                               byte        scope_separator=".",
                               string      type_name="");
    return;
  endfunction
  function void print_generic (string name, string  type_name, 
                               int    size, string  value,
                              byte scope_separator=".");
    return;
  endfunction

  function new();
    super.new();
    knobs.size_width = 0;
    knobs.show_root = 1;
    knobs.reference=1;
    knobs.print_fields=0;
  endfunction
endclass


//------------------------------------------------------------------------------
//
// CLASS - cdns_list_printer
//
//------------------------------------------------------------------------------

class cdns_list_printer extends ovm_printer;

  function void print_object (string name, ovm_object value,
                              byte scope_separator=".");
    ovm_component no;
    if($cast(no, value)) super.print_object(name, value, scope_separator);
  endfunction
  function void print_string (string name, string value,
                              byte scope_separator="."); 
    return;
  endfunction
  function void print_time   (string name, time value,
                              byte scope_separator=".");
    return;
  endfunction
  function void print_field  ( string      name,
                               ovm_bitstream_t value,
                               int         size,
                               ovm_radix_enum  radix=OVM_NORADIX,
                               byte        scope_separator=".",
                               string      type_name="");
    return;
  endfunction
  function new();
    super.new();
    knobs.full_name = 1;
    knobs.depth = 0;
    knobs.reference=1;
  endfunction
endclass


cdns_hierarchy_only_printer cdns_tcl_printer;
ovm_table_printer cdns_tcl_all_printer;

// All of these tcl functions are exported for dpi to allow direct tcl
// access.

// cdns_tcl_print_component
// --------------

export "DPI" function cdns_tcl_print_component;

function void cdns_tcl_print_component(string name,
                             int depth=1,
                             output bit [OVM_LARGE_STRING:0] rval,
                             input bit nooutput=0);
  ovm_component cq[$];
  ovm_printer p;
  ovm_component c;
  ovm_root top;
  integer fp;

  fp = $fopen(`TCL_FILENAME, "w");
  `cdns_ovm_access(rval)
  top = ovm_root::get();

  cq.delete();
  top.find_all(name, cq);

  if(!cq.size()) begin
    $fwrite(fp, "No components matching name %s were found", name);
    $fclose(fp);
    return;
  end

  if(! cdns_tcl_all_printer) cdns_tcl_all_printer = new;
  cdns_tcl_all_printer.knobs.show_root = 1;
  p = cdns_tcl_all_printer;

  p.knobs.sprint = 1;
  p.knobs.depth = depth;
  p.knobs.header = 1;

  p.print_header();
  
  $fwrite(fp,"%s",p.m_string);
  p.knobs.header = 0;
  p.knobs.footer = 0;

  for(int i=0; i<cq.size(); ++i) begin
    if(cq[i].print_enabled) begin
      p.print_object("", cq[i]);
      $fwrite(fp,"%s",p.m_string);
    end
  end

  p.m_string = "";
  p.knobs.footer = 1;
  p.print_footer();
  $fwrite(fp,"%s",p.m_string);

  $fclose(fp);
endfunction


// cdns_tcl_print_components
// ---------------

export "DPI" function cdns_tcl_print_components;

function void cdns_tcl_print_components(int depth=0,
                              bit all=0,
                              bit nooutput=1,
                              output bit [OVM_LARGE_STRING:0] rval);
  ovm_component c, cq[$];
  ovm_printer p;
  string cs;
  ovm_root top;
  integer fp;
  fp = $fopen(`TCL_FILENAME, "w");
  `cdns_ovm_access(rval)
  top = ovm_root::get();
  if(all) begin
    if(!cdns_tcl_all_printer) cdns_tcl_all_printer = new;
    cdns_tcl_all_printer.knobs.show_root = 1;
    p = cdns_tcl_all_printer;
  end
  else begin
    if(!cdns_tcl_printer) cdns_tcl_printer = new;
    p = cdns_tcl_printer;
  end

  cq.delete();
  if(top.get_first_child(cs)) 
    do begin
       c = top.get_child(cs);
       if(c.print_enabled)
         cq.push_back(c);
    end while(top.get_next_child(cs));

  if(cq.size() == 0)
    $fwrite(fp,"No ovm_component objects found in the design\n");
  else begin
    p.m_string = "";
  
    p.knobs.depth = depth;
    p.knobs.header = 1;
    p.knobs.sprint = 1;
    p.print_header();
    $fwrite(fp,"%s", p.m_string);
    p.knobs.header = 0;
    p.knobs.footer = 0;

    foreach(cq[i]) begin
      $fwrite(fp,"%s", cq[i].sprint(p));
    end

    p.m_string = "";
    p.knobs.footer = 1;
    p.print_footer();
    $fwrite(fp,"%s", p.m_string);
  end

  $fclose(fp);
endfunction


// cdns_tcl_list_components
// --------------

export "DPI" function cdns_tcl_list_components;

function void cdns_tcl_list_components(nooutput = 0,
                             output bit [OVM_LARGE_STRING:0] rval);
  ovm_component cq[$];
  ovm_root top;
  integer fp;

  fp = $fopen(`TCL_FILENAME, "w");

  cq.delete();
  top = ovm_root::get();
  rval = "";

  top.find_all("*",cq);

  if(cq.size() != 0) begin
    $fwrite(fp,"List of ovm components\n");
    // List is in bottom up order, but we want it in topdown order, so
    // traverse from back to front.
    for(int i=cq.size()-1; i>=0; --i) begin
      $fwrite(fp,"%s  (%s)(@%0d)\n",cq[i].get_full_name(), cq[i].get_type_name(), cq[i]);
    end
  end
  else begin
    $fwrite(fp,"No ovm components found");
  end

  $fdisplay(fp);
  $fclose(fp);
endfunction

// cdns_tcl_set
// -------

export "DPI" function cdns_tcl_set;

function void cdns_tcl_set(string component, 
   string field, ovm_bitstream_t value,
   bit do_config=0);

  ovm_root top;
  ovm_component cq[$];
  string f;
  top = ovm_root::get();
  if(do_config) begin
    set_config_int(component, field, value);
  end
  else begin
    cq.delete();
    top.find_all(component, cq);

    if(!cq.size())
      ovm_report_error("TCLSET",  $psprintf("No components matched the string %0s", component));

    for(int i=0; i<cq.size(); ++i) begin
      cq[i].set_int_local(field, value);
    end
  end
endfunction

// cdns_tcl_set_string
// ---------------

export "DPI" function cdns_tcl_set_string;

function void cdns_tcl_set_string(string component, 
   string field, string value,
   bit do_config);

  ovm_root top;
  ovm_component cq[$];
  string f;

  top = ovm_root::get();
  if(do_config) begin
    set_config_string(component, field, value);
  end
  else begin
    cq.delete();
    top.find_all(component, cq);
    if(!cq.size())
      ovm_report_error("TCLSET", $psprintf("No components matched the string %0s", component));

    for(int i=0; i<cq.size(); ++i) begin
      cq[i].set_string_local(field,value);
    end
  end
endfunction

// Messaging interface
parameter OVM_SET_VERBOSITY = 0;
parameter OVM_GET_VERBOSITY = 1;
parameter OVM_SET_ACTIONS   = 2;
parameter OVM_GET_ACTIONS   = 3;
parameter OVM_SET_STYLE     = 4;
parameter OVM_GET_STYLE     = 5;
parameter OVM_SET_SEVERITY  = 6;
parameter OVM_GET_SEVERITY  = 7;

export "DPI" function cdns_tcl_set_message;

function automatic bit cdns_get_reporter_matches (string name, ref ovm_report_object rq[$]);
  ovm_root top = ovm_root::get();
  ovm_component cq[$];
  rq.delete();
  if(name == "" || name == "*")
    rq.push_back(top);
  if(name != "") begin
    top.find_all(name, cq);
    foreach(cq[i]) rq.push_back(cq[i]);
  end
  if(rq.size()) return 1;
  else return 0;
endfunction
 
function void cdns_tcl_set_message ( int value_type, string hier,
    string scope, string name, string file, int line, string text, string tag,
    bit remove, int value, int sev = 0 );
  ovm_report_object cq[$];
  ovm_root top;
  void'(ovm_status_container::init_scope());
  void'(ovm_object::init_status());
  void'(ovm_comparer::init());
  void'(ovm_options_container::init());
  top = ovm_root::get();
  case (value_type)
    OVM_SET_VERBOSITY:
      begin
        ovm_urm_report_server::set_message_verbosity ( hier, scope, name, file, line, text, tag, remove, ovm_verbosity'(value) ); 
        if(cdns_get_reporter_matches(hier, cq))
          foreach(cq[i]) cq[i].set_report_verbosity_level(value);
      end
    OVM_SET_SEVERITY:
      begin
        ovm_urm_report_server::set_message_severity ( hier, scope, name, file, line, text, tag, remove, ovm_severity'(value) ); 
      end
    OVM_SET_STYLE:
      begin
        ovm_urm_report_server::set_message_debug_style ( hier, scope, name, file, line, text, tag, remove, value ); 
      end
    OVM_SET_ACTIONS:
      begin
        ovm_urm_report_server::set_message_actions ( hier, scope, name, file, line, text, tag, remove, ovm_severity'(sev), ovm_action'(value) ); 
        if(cdns_get_reporter_matches(hier, cq))
          foreach(cq[i]) 
            if(tag == "*")
              cq[i].set_report_severity_action(sev, value);
            else
              cq[i].set_report_severity_id_action(sev, tag, value);
      end
    default:
      begin
        ovm_report_fatal("TCLSET", $psprintf("In cdns_tcl_set_message with unexpected value type: %0d", value_type));
      end
  endcase 
endfunction

export "DPI" function cdns_tcl_set_handler_message;

function void cdns_tcl_set_handler_message ( int value_type, string hier,
  int value, int sev = 0, bit recurse=0 );
  ovm_report_object cq[$];
  ovm_component c;
  ovm_root top;

  void'(ovm_status_container::init_scope());
  void'(ovm_object::init_status());
  void'(ovm_comparer::init());
  void'(ovm_options_container::init());
  top = ovm_root::get();

  void'(cdns_get_reporter_matches(hier, cq));
  if(hier != "" && cq.size() == 0) begin  
    ovm_report_error("CPNTF",$psprintf("No report handlers match the name %s", hier));
    return;
  end
 
  case (value_type)
    OVM_SET_VERBOSITY:
    begin
      if(hier=="")
      begin
        ovm_urm_report_server::set_global_verbosity ( ovm_verbosity'(value) ); 
      end
      foreach(cq[i])
        if(recurse == 1 && $cast(c,cq[i]))
          c.set_report_verbosity_level_hier(value);
        else
          cq[i].set_report_verbosity_level(value);
    end
    OVM_SET_SEVERITY:
      if(hier=="")
      begin
        ovm_urm_report_server::set_global_severity ( ovm_severity'(value) ); 
      end
      else
        ovm_report_error("NTSUP","Setting severity is only legal for global message server");
    OVM_SET_STYLE:
      if(hier=="")
      begin
        ovm_urm_report_server::set_global_debug_style ( value ); 
      end
      else
        ovm_report_error("NTSUP","Setting style is only legal for global message server");
    OVM_SET_ACTIONS:
      if(hier=="")
      begin
        ovm_urm_report_server::set_global_actions ( ovm_severity'(sev), ovm_action'(value) ); 
      end
      else
        ovm_report_error("NTSUP","Setting action is only legal for global message server");
    default:
      begin
        ovm_report_fatal("TCLSET", $psprintf("In cdns_tcl_set_handler_message with unexpected value type: %0d", value_type));
      end
  endcase 
endfunction


export "DPI" function cdns_tcl_get_message;

function void cdns_tcl_get_message ( input  int value_type, 
                                output bit [OVM_LARGE_STRING:0] rval);

  integer fp;
  fp = $fopen(`TCL_FILENAME, "w");

  void'(ovm_root::get());
  case (value_type)
    OVM_GET_VERBOSITY:
      $fwrite(fp, "%s", ovm_urm_report_server::m_dump_rules_verbosity()); 
    OVM_GET_SEVERITY:
      $fwrite(fp, "%s", ovm_urm_report_server::m_dump_rules_severity()); 
    OVM_GET_STYLE:
      $fwrite(fp, "%s", ovm_urm_report_server::m_dump_rules_debug_style()); 
    OVM_GET_ACTIONS:
      $fwrite(fp, "%s", ovm_urm_report_server::m_dump_rules_actions()); 
    default:
      begin
        ovm_report_fatal("TCLGET", $psprintf("In cdns_tcl_get_message with unexpected value type: %0d", value_type));
      end
  endcase 
  $fclose(fp);
endfunction


export "DPI" function cdns_tcl_get_phase;

function void cdns_tcl_get_phase (output bit [OVM_SMALL_STRING:0] rval);
  ovm_phase ph;
  ovm_root top;
  integer fp;
  fp = $fopen(`TCL_FILENAME, "w");
  top = ovm_root::get();
  ph = top.get_current_phase();
  if(ph == null)
    $fwrite(fp, "Phasing not started");
  else
    $fwrite(fp, "%s", ph.get_name());
  $fclose(fp);
endfunction

export "DPI" function cdns_tcl_global_stop_request;

function void cdns_tcl_global_stop_request ();
  ovm_phase ph;
  ovm_root top;
  top = ovm_root::get();
  ph = top.get_current_phase();
  if(ph.is_task())
    top.stop_request();
  else if(ph == null)
    ovm_report_warning("PHNST", $psprintf("Phasing has not started for the environment, stop request is ignored"));
  else
    ovm_report_warning("FNCPH", $psprintf("The current phase %s is a function phase, stop request is ignored", ph.get_name()));
endfunction

export "DPI" function cdns_tcl_global_run_phase;
function void cdns_tcl_global_run_phase (string phase);
  ovm_phase ph;
  ovm_root top;
  top = ovm_root::get();
  ph = top.get_phase_by_name(phase);
  if(ph == null) begin
    ovm_report_error("ILLPHS", $psprintf("Phase %0s was not found in the phase list", phase));
    return;
  end
  fork
    top.run_global_phase(ph);
  join_none
endfunction

// API for user defined phases. Built-in phases will use direct
// event objects for greater user control.
//export "DPI" function cdns_tcl_break_at_phase;

event ovm_build_complete;
string ovm_break_phase="none";
bit   ovm_phase_is_start;

// Create a class with a process so it can run in a package
class cdns_phase_process_watcher;
  static cdns_phase_process_watcher phase_watcher = new;
  function new;
    fork
      watch_phases;
    join_none
  endfunction
  task watch_phases;
  ovm_phase ph;
  `cdns_ovm_access(ovm_build_complete)
  `cdns_ovm_access(ovm_break_phase)
  `cdns_ovm_access(ovm_phase_is_start)
  #0 ph = ovm_top.get_phase_by_name("end_of_elaboration");
  fork
    cdns_tcl_break_at_phase_task(build_ph, 1);  
    cdns_tcl_break_at_phase_task(build_ph, 0);  
    cdns_tcl_break_at_phase_task(connect_ph, 1);  
    cdns_tcl_break_at_phase_task(connect_ph, 0);  
    cdns_tcl_break_at_phase_task(end_of_elaboration_ph, 1);  
    cdns_tcl_break_at_phase_task(end_of_elaboration_ph, 0);  
    cdns_tcl_break_at_phase_task(start_of_simulation_ph, 1);  
    cdns_tcl_break_at_phase_task(start_of_simulation_ph, 0);  
    cdns_tcl_break_at_phase_task(run_ph, 1);  
    cdns_tcl_break_at_phase_task(run_ph, 0);  
    cdns_tcl_break_at_phase_task(extract_ph, 1);  
    cdns_tcl_break_at_phase_task(extract_ph, 0);  
    cdns_tcl_break_at_phase_task(check_ph, 1);  
    cdns_tcl_break_at_phase_task(check_ph, 0);  
    cdns_tcl_break_at_phase_task(report_ph, 1);  
    cdns_tcl_break_at_phase_task(report_ph, 0);  
    if(ph != null) begin
      ph.wait_done();
      ->ovm_build_complete;
    end
  join
  endtask
endclass

task automatic cdns_tcl_break_at_phase_task(ovm_phase phase, bit at_start);
  void'(ovm_root::get());
  if(phase == null) return;
  if(at_start) phase.wait_start();
  else phase.wait_done();
  ovm_phase_is_start = at_start;
  ovm_break_phase = phase.get_name();
//  $stop;
endtask


//
// cdns_tcl_ovm_version
// ---------------

export "DPI" function cdns_tcl_ovm_version;

function void cdns_tcl_ovm_version (output bit [OVM_SMALL_STRING:0] rval);
  integer fp;
  fp = $fopen(`TCL_FILENAME, "w");
  $fwrite(fp,"%s",ovm_revision_string());
  $fclose(fp);
endfunction

// URM Wrappers so that the liburmpli.so can be loaded. It is used for both
// ovm and urm.

export "DPI" function tcl_print_unit;
function void tcl_print_unit(bit [OVM_SMALL_STRING:0] name,
                             int depth=1,
                             output bit [OVM_LARGE_STRING:0] rval,
                             input bit nooutput=0);
  begin end
endfunction


export "DPI" function tcl_print_units;
function void tcl_print_units(int depth=0,
                              bit all=0,
                              bit nooutput=1,
                              output bit [OVM_LARGE_STRING:0] rval);
  begin end
endfunction

export "DPI" function tcl_list_units;
function void tcl_list_units(nooutput = 0,
                             output bit [OVM_LARGE_STRING:0] rval);
  begin end
endfunction

export "DPI" function tcl_set;
function void tcl_set(bit [OVM_SMALL_STRING:0] unit, 
   bit [OVM_SMALL_STRING:0] field, ovm_bitstream_t value,
   bit do_config=0);
  begin end
endfunction

export "DPI" function tcl_set_message;
function void tcl_set_message ( int value_type, bit [OVM_SMALL_STRING:0] hier,
    bit [OVM_SMALL_STRING:0] scope, bit [OVM_SMALL_STRING:0] file,
    int line, bit [OVM_SMALL_STRING:0] text, bit [OVM_SMALL_STRING:0] tag,
    bit remove, int value, int sev = 0 );
  begin end
endfunction


export "DPI" function tcl_get_message;

function void tcl_get_message ( input  int value_type, 
                                output bit [OVM_LARGE_STRING:0] rval);
  begin end
endfunction

export "DPI" function tcl_get_handler_message;
function void tcl_get_handler_message ( int value_type, bit [OVM_SMALL_STRING:0] hier,
  output bit [OVM_LARGE_STRING:0] rval);
  begin end
endfunction

export "DPI" function tcl_get_phase;
function void tcl_get_phase (output bit [OVM_SMALL_STRING:0] rval);
  begin end
endfunction

export "DPI" function tcl_global_stop_request;
function void tcl_global_stop_request ();
  begin end
endfunction

export "DPI" function tcl_global_run_phase;
function void tcl_global_run_phase (bit [OVM_SMALL_STRING:0] phase);
  begin end
endfunction

export "DPI" function tcl_break_at_phase;
function void tcl_break_at_phase (bit [OVM_SMALL_STRING:0] phase, bit at_start=1);
  begin end
endfunction

export "DPI" function tcl_urm_version;
function void tcl_urm_version (output bit [OVM_SMALL_STRING:0] rval);
  begin end
endfunction


`endif //CDNS_TCL_INTERFACE_SVH
