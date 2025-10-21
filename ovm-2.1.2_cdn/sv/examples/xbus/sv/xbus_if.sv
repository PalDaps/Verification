//----------------------------------------------------------------------
//   Copyright 2007-2008 Mentor Graphics Corporation
//   Copyright 2007-2008 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------
/******************************************************************************

  FILE : xbus_bus_monitor_if.sv

 ******************************************************************************/

interface xbus_if ();

  // Control flags
  bit                has_checks = 1;
  bit                has_coverage = 1;

  // Actual Signals
  logic              sig_clock;
  logic              sig_reset;
  logic       [15:0] sig_request;
  logic       [15:0] sig_grant;
  logic       [15:0] sig_addr;
  logic        [1:0] sig_size;
  logic              sig_read;
  logic              sig_write;
  logic              sig_start;
  logic              sig_bip;
  wire logic   [7:0] sig_data;
  logic        [7:0] sig_data_out;
  logic              sig_wait;
  logic              sig_error;

  logic              rw;

assign sig_data = rw ? sig_data_out : 8'bz;

`ifndef IFV
import ovm_pkg::*;
`endif

// Coverage and assertions to be implemented here.
// SVA default clocking
wire ovm_assert_clk = sig_clock & has_checks;
default clocking master_clk @(negedge ovm_assert_clk);
endclocking

// SVA default reset
wire ovm_assert_reset = sig_reset | !has_checks;
default disable iff (ovm_assert_reset);

`ifndef IFV

// Address must not be X or Z during Address Phase
master_AddrUnknown:assert property (
                  ((|sig_grant) |-> !$isunknown(sig_addr)))
                  else
                  ovm_report_error("XBUS Interface","Address went to X or Z during Address Phase");

// Read must not be X or Z during Address Phase
master_ReadUnknown:assert property ( 
                  ((|sig_grant) |-> !$isunknown(sig_read)))
                  else
                  ovm_report_error("XBUS Interface","READ went to X or Z during Address Phase");

// Write must not be X or Z during Address Phase
master_WriteUnknown:assert property ( 
                  ((|sig_grant) |-> !$isunknown(sig_write)))
                  else
                  ovm_report_error("XBUS Interface","WRITE went to X or Z during Address Phase");

// Size must not be X or Z during Address Phase
master_SizeUnknown:assert property ( 
                  ((|sig_grant) |-> !$isunknown(sig_size)))
                  else
                  ovm_report_error("XBUS Interface","SIZE went to X or Z during Address Phase");

// Wait must not be X or Z during Data Phase
slave_WaitUnknown:assert property ( 
                  ((|sig_grant) |=> !$isunknown(sig_wait)))
                  else
                  ovm_report_error("XBUS Interface","WAIT went to X or Z during Data Phase");

// Error must not be X or Z during Data Phase
slave_ErrorUnknown:assert property ( 
                  ((|sig_grant) |=> !$isunknown(sig_error)))
                  else
                  ovm_report_error("XBUS Interface","ERROR went to X or Z during Data Phase");

`endif

// Only one grant is asserted
master_SingleGrant: assert property (
                  ($onehot0(sig_grant)))
                  else
                  ovm_report_error("XBUS Interface","More that one grant asserted");

// Read and write never true at the same time
master_ReadOrWrite: assert property (
                  ((|sig_grant) |-> !(sig_read && sig_write)))
                  else
                  ovm_report_error("XBUS Interface","Read and Write true at the same time");

// Auxiliary code for bus operation
  typedef enum bit[1:0] {ARB_PHASE, ADDR_PHASE, WR_PHASE, RD_PHASE} phase_t;
  phase_t phase_fsm, phase_fsm_r;
  wire data_phase = phase_fsm_r[1];

always @(posedge sig_clock or posedge sig_reset)
begin
 if (sig_reset)
   phase_fsm_r <= ARB_PHASE;
 else
   phase_fsm_r <= phase_fsm;
end

always @(phase_fsm_r or sig_grant or sig_write or sig_read or sig_bip or sig_wait)
begin
  phase_fsm = phase_fsm_r;
  case (phase_fsm_r) 
    ARB_PHASE : begin 
       if (|sig_grant) phase_fsm = ADDR_PHASE;
     end
    ADDR_PHASE : begin 
       if (sig_write) phase_fsm = WR_PHASE;
       else phase_fsm = RD_PHASE;
     end
    WR_PHASE : begin 
       if (!sig_bip && !sig_wait) phase_fsm = ARB_PHASE;
     end
    RD_PHASE : begin 
       if (!sig_bip && !sig_wait) phase_fsm = ARB_PHASE;
     end
  endcase
end
   
// If write and wait then data must remain stable on the next cycle
master_DataStable: assert property (
                  (((phase_fsm_r == WR_PHASE) && sig_wait) |=> ($stable(sig_data))))
                  else
                  ovm_report_error("XBUS Interface","Master Data changed with Wait asserted");

// If error asserted then wait must be low
slave_ErrorWait : assert property (
                  (data_phase && sig_error |-> !sig_wait))
                  else
                  ovm_report_error("XBUS Interface","Error asserted with Wait during transfer");

endinterface : xbus_if

