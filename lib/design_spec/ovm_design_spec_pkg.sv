`ifndef OVM_DESIGN_SPEC_PKG
`define OVM_DESIGN_SPEC_PKG

package ovm_design_spec_pkg;

  import ovm_pkg::*;
  `include "ovm_macros.svh"

  import ovm_ahb_vc_pkg::*;
  import ovm_spi_vc_pkg::*;

  `include "ovm_design_spec_class_files.sv"

endpackage

`endif