//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ovm_ahb_master_driver.sv                     //
//                        ahb driver class                                     //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

`ifndef AHB_IF_WRAPPER
`define AHB_IF_WRAPPER ahb_wrapper.ahb_vif 
`endif

class ovm_ahb_master_driver extends ovm_driver #(ovm_ahb_tran_item);

  // interface wrapper (configured with ovm_configure_object..) 
  ovm_ahb_if_wrapper ahb_wrapper;

  // mailbox #(ovm_ahb_tran_item) rsp_tr_queue; // - removed to simplify driver code

  //ovm stuff for factory, funct override, ovm fields etc
   `ovm_component_utils_begin ( ovm_ahb_master_driver )	// Register with factory
     `ovm_field_object( ahb_wrapper, OVM_ALL_ON )
   `ovm_component_utils_end

  function new(string name, ovm_component parent);
    super.new(name, parent);
    // rsp_tr_queue=new; // - removed to simplify driver code
  endfunction
 
  // forever dirve transactions
  virtual task run();
    fork
      drive_transactions();
    join
  endtask: run

  extern task drive_transactions();
  extern task reset();
  extern task reset_monitor();
  //extern task drive_data_ph(); // - removed to simplify driver code
  extern task drive_addr_ph();

endclass : ovm_ahb_master_driver

//------------------------------------------------------------------------------------------//
task ovm_ahb_master_driver::drive_transactions();
  // forever process transactions from sequencer and listern for external reset event
  fork 
    reset_monitor();
    drive_addr_ph();
    //drive_data_ph();
  join
endtask : drive_transactions
//------------------------------------------------------------------------------------------//
/*
//------------------------------------------------------------------------------------------//
  task ovm_ahb_master_driver::drive_data_ph();
    ovm_ahb_tran_item rsp;
    forever
      begin
        rsp_tr_queue.get(rsp);
        `AHB_IF_WRAPPER.CB.HREADY <= 1;
        @(`AHB_IF_WRAPPER.CB);
        while (!`AHB_IF_WRAPPER.CB.HREADY_RESP) begin
          @(`AHB_IF_WRAPPER.CB);
        end
        if (rsp.read_write == READ) rsp.data=`AHB_IF_WRAPPER.CB.HRDATA;
        `AHB_IF_WRAPPER.CB.HWDATA <= 32'hxxxxxxxx;
        seq_item_port.item_done(rsp);
      end
  endtask:drive_data_ph
//------------------------------------------------------------------------------------------//
*/
//------------------------------------------------------------------------------------------//
  task  ovm_ahb_master_driver::drive_addr_ph();
    ovm_ahb_tran_item req;
    ovm_ahb_tran_item rsp;

    @(`AHB_IF_WRAPPER.CB);
    forever
      begin
        if (`AHB_IF_WRAPPER.RST_N!=1) begin
          wait(`AHB_IF_WRAPPER.RST_N==1);
          @(`AHB_IF_WRAPPER.CB);
        end

        // while parallel not enabled
        /*
        do begin
          seq_item_port.try_next_item(req);
          @(`AHB_IF_WRAPPER.CB);
        end while (req==null);
        */
        // while parallel not enabled

        // get transaction from aequencer
        seq_item_port.get_next_item(req);
        // for response
        $cast(rsp, req.clone());
        rsp.set_id_info(req);
 
        // `AHB_IF_WRAPPER ADDR CYCLE
        // drive address signals
        `AHB_IF_WRAPPER.CB.HSEL   <= 1;
        `AHB_IF_WRAPPER.CB.HADDR  <= req.addr;
        `AHB_IF_WRAPPER.CB.HTRANS <= 1;
        `AHB_IF_WRAPPER.CB.HREADY <= 1;
        if (req.read_write == WRITE) begin
          `AHB_IF_WRAPPER.CB.HWRITE <= 1;
        end

        @(`AHB_IF_WRAPPER.CB);
        // `AHB_IF_WRAPPER DATA CYCLE
        `AHB_IF_WRAPPER.CB.HSEL   <= 0;
        `AHB_IF_WRAPPER.CB.HTRANS <= 0;
        `AHB_IF_WRAPPER.CB.HWRITE <= 0;

        if (req.read_write == WRITE) begin
          `AHB_IF_WRAPPER.CB.HWDATA <= req.data;
        end
 
        // READ DATA precessed in address phase to symplify driver code
        // (while parallel not enabled)
        `AHB_IF_WRAPPER.CB.HREADY <= 1;
        @(`AHB_IF_WRAPPER.CB);
        while (!`AHB_IF_WRAPPER.CB.HREADY_RESP) begin
          @(`AHB_IF_WRAPPER.CB);
        end
        if (rsp.read_write == READ) rsp.data=`AHB_IF_WRAPPER.CB.HRDATA;
        //`AHB_IF_WRAPPER.CB.HWDATA <= 32'hxxxxxxxx;
	`AHB_IF_WRAPPER.CB.HWDATA <= 32'h00000000; // do not use xx for coverage purpose

        // send response to sequencer
        seq_item_port.item_done(rsp);

        // (while parallel not enabled)

        // (while parallel not enabled)
        // rsp_tr_queue.put(rsp);
        // (while parallel not enabled)

      end
  endtask:drive_addr_ph
//------------------------------------------------------------------------------------------//

//------------------------------------------------------------------------------------------//
task ovm_ahb_master_driver::reset();
  // action on reset event
  `AHB_IF_WRAPPER.HADDR <= 0;
  `AHB_IF_WRAPPER.HREADY <= 0;
  `AHB_IF_WRAPPER.HSEL <= 0;
  `AHB_IF_WRAPPER.HTRANS <= 0;
  `AHB_IF_WRAPPER.HWDATA <= 0;
  `AHB_IF_WRAPPER.HWRITE <= 0;
endtask : reset
//------------------------------------------------------------------------------------------//

//------------------------------------------------------------------------------------------//
task ovm_ahb_master_driver::reset_monitor();
  // listerning for interface reset event (external event for driver)
  forever begin
    wait(`AHB_IF_WRAPPER.RST_N==0);
    reset();
    @(`AHB_IF_WRAPPER.CB);
  end
endtask : reset_monitor
//------------------------------------------------------------------------------------------//