//--------------------------- IP_CORE_LABS-------------------------------------//
//                        SPI_TX example project                               //
//                        file -  ahb_if.sv                                    //
//                        ahb interface                                        //
//                        author -  fputrya                                    //
//-----------------------------------------------------------------------------//

  //AHB PARAMETERS 
  parameter AHB_Data_Width = 32;
  parameter AHB_Addr_Width = 32;

  parameter ahb_input_del  = 1;
  parameter ahb_output_del = 1;

interface AHB_if (input CLK, input RST_N);

    logic                      HSEL;
    logic                      HTRANS;
    logic [AHB_Addr_Width-1:0] HADDR;
    logic                      HWRITE;
    logic                      HREADY;
    logic                      HREADY_RESP;
    logic [AHB_Data_Width-1:0] HWDATA; 
    logic [AHB_Data_Width-1:0] HRDATA;

    clocking CB @(posedge CLK);
        default input #ahb_input_del output #ahb_output_del;
        output  HSEL, HTRANS, HADDR, HWRITE, HREADY, HWDATA;
        input   HREADY_RESP, HRDATA;
    endclocking
    
    clocking MON_CB @(posedge CLK);
        default input #ahb_input_del;
        input   HSEL, HTRANS, HADDR, HWRITE, HREADY, HWDATA;
        input   HREADY_RESP, HRDATA;
    endclocking

endinterface