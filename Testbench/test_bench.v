`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 69
`include "new_alu.v"
//`include "stimulus.txt"

module test_bench();
        reg [57:0] curr_test_case = 58'b0;
        reg [57:0] stimulus_mem [0:`no_of_testcase-1];
        reg [72:0] response_packet;

//giving the Stimulus
        integer i, j;
        reg clk, rst, CE; //inputs
        event fetch_stimulus;
        reg [7:0] OPA, OPB; //inputs
        reg [3:0] CMD; //inputs
        reg MODE, CIN; //inputs
        reg [7:0] Feature_ID;
        reg [2:0] Comparison_EGL;  //expected output
        reg [8:0] Expected_RES; //expected output data
        reg err, cout, ov;
        reg [1:0] res1;
        reg [1:0] INP_VALID;

//Decl to Cop UP the DUT OPERATION
        wire [8:0] RES;
        wire ERR, OFLOW, COUT;
        wire [2:0] EGL;
        wire [14:0] expected_data;  
        reg [14:0] exact_data;   

        task read_stimulus();
                begin
                #10 $readmemb ("stimulus.txt",stimulus_mem);
    end
  endtask

        new_alu dut(.OPA(OPA), .OPB(OPB), .CIN(CIN), .clk(clk), .CMD(CMD), .CE(CE), .MODE(MODE), .COUT(COUT), .OFLOW(OFLOW), .RES(RES), .G(EGL[1]), .E(EGL[2]), .L(EGL[0]), .ERR(ERR), .rst(rst), .INP_VALID(INP_VALID));

        integer stim_mem_ptr = 0, stim_stimulus_mem_ptr = 0, fid =0, pointer =0 ;

        always@(fetch_stimulus)
                begin
                        curr_test_case = stimulus_mem[stim_mem_ptr];
                        $display("-------------------------------------------------------------");
                        $display ("stimulus_mem data = %0b \n",stimulus_mem[stim_mem_ptr]);
                        $display ("packet data = %0b \n",curr_test_case);
                        stim_mem_ptr = stim_mem_ptr + 1;
                end

//INITIALIZING CLOCK
        initial
                begin clk = 0;
                        forever #60 clk = ~clk;
                end

//DRIVER MODULE
        task driver ();
                begin
      ->fetch_stimulus;
                  @(posedge clk);
        Feature_ID = curr_test_case[57:50];
        res1 = curr_test_case[49:48];
                rst = curr_test_case[47];
                INP_VALID = curr_test_case[46:45];
                OPA     = curr_test_case[38:31];
            OPB = curr_test_case[30:23];
                CMD     = curr_test_case[42:39];
        CIN = curr_test_case[22];
        CE = curr_test_case[44];
                MODE = curr_test_case[43];
        Expected_RES = curr_test_case[13:5];
        cout = curr_test_case[3];
        Comparison_EGL = curr_test_case[2:0];
        ov = curr_test_case[4];
        err = curr_test_case[21];
                $display("driver at time (%0t)",$time);
                $display("Feature ID = %8b | Reserved bit = %2b",Feature_ID,res1);
                $display("I/P valid = %b | CMD = %4b | MODE = %b",INP_VALID,CMD,MODE);
                $display("OPA = %8b | OPB = %8b | CIN = %1b | CE = %1b",OPA,OPB,CIN,CE);
                $display("Expected result = %b | cout = %1b | Comp_EGL = %3b | oflow = %1b | err = %1b",Expected_RES,cout,Comparison_EGL,ov,err);
                      end
        endtask

//GLOBAL DUT RESET
        task dut_reset ();
                begin
                CE=1;
                #10 rst=1;
                #20 rst=0;
                end
        endtask

//GLOBAL INITIALIZATION
        task global_init ();
                begin
                curr_test_case = 58'b0;
                response_packet = 73'b0;
                stim_mem_ptr = 0;
                end
        endtask

//MONITOR PROGRAM
        task monitor ();
    begin
        repeat(5)@(posedge clk);
                        #5 response_packet[57:0] = curr_test_case;
                response_packet[58]     = ERR;
                        response_packet[68]     = OFLOW;
                        response_packet[72:70] = {EGL};
                        response_packet[69]     = COUT;
                        response_packet[67:59] = RES;
//      response_packet[]       = 0; // Reserved Bit
      $display("Monitor: At time (%0t)",$time);
          $display("RES = %b | COUT = %1b | EGL = %3b | OFLOW = %1b | ERR = %1b",RES,COUT,{EGL},OFLOW,ERR);
      exact_data = {ERR,RES,OFLOW,COUT,{EGL}};
                end
        endtask

        assign expected_data = {err,Expected_RES,ov,cout,Comparison_EGL};

        //SCORE BOARD PROGRAM TO CHECK THE DUT OP WITH EXPECTD OP
  reg [45:0] scb_stimulus_mem [0:`no_of_testcase-1];  

        task score_board();
        reg [14:0] expected_res;
        reg [7:0] feature_id;
        reg [14:0] response_data;
    reg [3:0] cmd_res;
        reg mode;
        begin
      #5;
      feature_id = curr_test_case[57:50];
      expected_res = curr_test_case[13:5];
      cmd_res = curr_test_case[42:39];
          mode = curr_test_case[43];
          response_data = response_packet[72:58];
      $display("expected result = %15b || response data = %15b",expected_data,exact_data);
          $display("test no - %d",feature_id);
        if(expected_data === exact_data)
          scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id,cmd_res,mode ,expected_res,response_data, 1'b0,`PASS};
                else
          scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id,cmd_res,mode ,expected_res,response_data, 1'b0,`FAIL};
      stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
    end
        endtask

//Generating the report `no_of_testcase-1
        task gen_report;
        integer file_id,pointer;
        reg [45:0] status;  
                begin
                file_id = $fopen("results.txt", "w");
      for(pointer = 0; pointer <= `no_of_testcase-1 ; pointer = pointer+1 )
        begin
                    status = scb_stimulus_mem[pointer];
                    if(status[0])
                    $fdisplay(file_id, "Feature ID %8b | MODE %1b | CMD %d: PASS", status[44:37], status[32], status[36:33]);
                    else
                    $fdisplay(file_id, "Feature ID %8b | MODE %1b | CMD %d: FAIL", status[44:37], status[32], status[36:33]);
        end
                end
        endtask

        initial
        begin
          #10;
                global_init();
//        dut_reset();
    read_stimulus();
        for(j=0;j<=`no_of_testcase-1;j=j+1)
                        begin
        fork
                driver();
          monitor();
        join
                        score_board();
      end

      gen_report();
      $fclose(fid);
            #300 $finish();
            end

endmodule
