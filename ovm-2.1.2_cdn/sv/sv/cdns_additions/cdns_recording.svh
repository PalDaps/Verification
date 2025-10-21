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

// This file layers on top of OVM to provide transaction recording. OVM provides 
// transaction hooks, but does not implement any transaction recording features.

`ifndef CDNS_RECORDING_SVH
`define CDNS_RECORDING_SVH

`define OVM_RECORD_INTERFACE

`ifdef CDNS_RECORD_TEXT

class ovm_text_recorder;
  static int fp=1;

  static function int open_db (string name, bit stdout=0);
    int curr;
    int std;

    if(fp[0] == 1 && fp != 1) std = 1;
    else std = 0;

    if(name != "") begin
      curr = $fopen(name);
      $fdisplay(curr, "SDI Text Recorder, database %0s opened at ",
        name, "simulation time %0t", $realtime);
    end
    if(!std && stdout==1) begin
      $fdisplay(1, "SDI Text Recorder, opening stdout for writing ",
        "at simulation time %0t", $realtime);
    end
    fp[0] = 0;
    fp = fp | curr | stdout | std;
    return curr;
  endfunction
  static function void close_db (int db);
    int toclose;
    toclose = db; toclose[0] = 0;
    if(toclose) begin
      $fdisplay(toclose, "SDI Text Recorder, database closed at ",
        "simulation time %0t", $realtime);
      $fclose(toclose);
    end
    else if(db[0] == 1) begin
      $fdisplay(1, "SDI Text Recorder, closing stdout for ",
        "writing simulation time %0t", $realtime);
    end
    db = ~db;
    fp &= db;
  endfunction
endclass
//----------------------------------------------------------------------------
//
// CLASS- stream_info
//
//----------------------------------------------------------------------------

class stream_info;
    protected string m_name;
    protected string m_type;
    protected string m_scope; 
              int    handle;

    function new(string nm, string t, string s);
      m_name = nm; m_type = t; m_scope = s;
    endfunction
    function string fullname();
      if(m_scope!="")
        fullname = {m_scope, "."};
      fullname = {fullname, m_name};
    endfunction 
endclass

//----------------------------------------------------------------------------
//
// CLASS- tx_handle
//
//----------------------------------------------------------------------------

class tx_handle;
    protected bit m_active;
    protected integer m_stream;
    protected string m_name;
    function new (string nm, integer stream, bit active);
      m_active = active;
      m_stream = stream;
      m_name = nm;
    endfunction
    function string name();
      return m_name;
    endfunction
    function bit is_active();
      return m_active;
    endfunction
    function integer stream();
      return m_stream;
    endfunction
endclass
   
  tx_handle   active_handles  [integer];
  stream_info streams         [integer];

  int next_stream = 1;
  int next_tx = 1;
`endif

//----------------------------------------------------------------------------


// ovm_create_fiber
// ----------------

function integer ovm_create_fiber (string name,
                                   string t,
                                   string scope);
`ifdef CDNS_RECORD_TEXT
  stream_info si;
  ovm_create_fiber = next_stream++;
  si = new(name, t, scope); 
  si.handle = ovm_create_fiber;
  streams[si.handle] = si;
`else
  if(scope != "")
    ovm_create_fiber = $sdi_create_fiber(name,
                             t,
                             scope);
  else
    ovm_create_fiber = $sdi_create_fiber(name,
                             t,
                             "Transactions");
`endif
endfunction

// ovm_set_index_attribute_by_name
// -------------------------------

function void ovm_set_index_attribute_by_name (integer txh,
                                         string nm,
                                         int index,
                                         logic [1023:0] value,
                                         string radix,
                                         integer numbits=32);
  $swrite(nm, "%s[%0d]", nm, index);
  ovm_set_attribute_by_name(txh, nm, value, radix, numbits);
endfunction


// ovm_set_attribute_by_name
// -------------------------

function void ovm_set_attribute_by_name (integer txh,
                                         string nm,
                                         logic [1023:0] value,
                                         string radix,
                                         integer numbits=0);
`ifdef CDNS_RECORD_TEXT
  logic[1023:0] v;
  v = 0; 
  for(int i=0; i<numbits; ++i) v[i] = value[i];
  case(radix)
    "'b": $fdisplay(ovm_text_recorder::fp,"    %0s: %0b", nm, v);
    "'o": $fdisplay(ovm_text_recorder::fp,"    %0s: %0o", nm, v);
    "'u": $fdisplay(ovm_text_recorder::fp,"    %0s: %0d", nm, v);
    "'s": begin
            if(v[numbits-1] == 1) for(int i=numbits; i<1023; ++i) v[i]=1;
            $fdisplay(ovm_text_recorder::fp,"    %0s: %0d", nm, v);
          end
    "'h": $fdisplay(ovm_text_recorder::fp,"    %0s: %0x", nm, v);
    "'x": $fdisplay(ovm_text_recorder::fp,"    %0s: %0x", nm, v);
    "'a": $fdisplay(ovm_text_recorder::fp,"    %0s: %0s", nm, v);
  endcase
`else
  if(radix.len() != 2) radix = "`h";
  radix[0] = "`";
  if(radix == "`r") begin
    real rval;
    rval = $bitstoreal(value);
    $sdi_set_attribute_by_name(txh, nm, rval, "`s");
  end 
  else begin
    $sdi_set_attribute_by_name(txh, nm, value, radix,,,numbits);
  end
`endif
endfunction


// ovm_check_handle_kind
// ---------------------

function integer ovm_check_handle_kind (string htype, integer handle);
`ifdef CDNS_RECORD_TEXT
  int h;
  h = handle; //convert any 4 state values to 2 state
  case(htype)
    "TRANSACTION": return active_handles[h] != null;
    "Transaction": return active_handles[h] != null;
    "transaction": return active_handles[h] != null;
    "FIBER": return streams[h] != null;
    "Fiber": return streams[h] != null;
    "fiber": return streams[h] != null;
    "STREAM": return streams[h] != null;
    "Stream": return streams[h] != null;
    "stream": return streams[h] != null;
    default: return 0;
  endcase
`else
  return $sdi_check_handle_kind(htype, handle);
`endif
endfunction


// ovm_begin_transaction
// ---------------

function integer ovm_begin_transaction(string txtype,
                                 integer stream,
                                 string nm
                                 , string label="",
                                 string desc="",
                                 time begin_time=0
                                 );

`ifdef CDNS_RECORD_TEXT
  tx_handle h;
  stream_info s;
  if(!streams.exists(stream)) return 0;
  s = streams[stream];
  if(s==null)
    return 0;
  h = new(nm, stream, 1);
  ovm_begin_transaction = next_tx++;
  active_handles[ovm_begin_transaction] = h;
  $fdisplay(ovm_text_recorder::fp,"%0t: Starting transaction %s on stream %s (%0d)",
           $realtime, nm, s.fullname(), ovm_begin_transaction);
`else
  if (label == "") begin
    if (desc == "") begin
       if (begin_time == $realtime || begin_time == 0)
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm);
       else
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm,,,
                                 begin_time);
    end
    else begin
       if (begin_time == $realtime || begin_time == 0)
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm,,
                                 desc);
       else
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm,,
                                 desc,begin_time);
    end
  end
  else begin
    if (desc == "") begin
       if (begin_time == $realtime || begin_time == 0)
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm,
                                 label);
       else
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm,
                                 label,,begin_time);
    end
    else begin
       if (begin_time == $realtime || begin_time == 0)
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm,
                                 label,desc);
       else
         return $sdi_transaction(ovm_string_to_bits(txtype), stream, nm,
                                 label,desc,
                                 begin_time);
    end
  end
`endif
endfunction


// ovm_end_transaction
// -------------------

function void ovm_end_transaction (integer handle
                                 , time end_time=0
);
`ifdef CDNS_RECORD_TEXT
  tx_handle h;
  stream_info s;
  int hi;
  hi = handle; //convert 2state values
  h = active_handles[hi];
  if(h!=null) begin
    s = streams[h.stream()];
    active_handles[hi] = null;
    if(s==null) 
      return;
    $fdisplay(ovm_text_recorder::fp,"%0t: Ending transaction %s on stream %s",
             $realtime, h.name(), s.fullname());
  end
`else
   if (end_time == $realtime || end_time == 0)
     $sdi_end_transaction(handle);
   else
     $sdi_end_transaction(handle, end_time);
`endif
endfunction


// ovm_link_transaction
// --------------------

function void ovm_link_transaction(integer h1, integer h2,
                                   string relation="");
`ifdef CDNS_RECORD_TEXT
  $fdisplay(ovm_text_recorder::fp,"Link tx %0d to tx %0d using relation %0s", h1, h2, relation);
`else
  if (relation == "")
    $sdi_link_transaction(h2,h1);
  else
    $sdi_link_transaction(h2,h1,ovm_string_to_bits(relation));
`endif
endfunction



// ovm_free_transaction_handle
// ---------------------------

function void ovm_free_transaction_handle(integer handle);
`ifndef CDNS_RECORD_TEXT
  $sdi_free_transaction_handle(handle);
`endif
endfunction

`endif //CDSN_RECORDING_SVH
