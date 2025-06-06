module new_alu #(parameter WIDTH = 8, CMD_WIDTH = 4)(
  input clk, rst,
  input [WIDTH - 1:0] OPA, OPB,
  input [CMD_WIDTH - 1:0] CMD,
  input CE, CIN, MODE,
  input [1:0] INP_VALID,
//  output reg [WIDTH : 0] RES,
  output reg [(2*WIDTH) - 1: 0] RES,
  output reg OFLOW, COUT, ERR,
  output reg E, G, L);

  reg [WIDTH - 1:0] OPA_temp, OPB_temp;
  reg [WIDTH - 1:0] OPA_Buf, OPB_Buf;
  reg [CMD_WIDTH - 1:0] CMD_temp;
  reg CE_temp, CIN_temp, MODE_temp;
  reg [1:0] INP_VALID_temp;

//  reg [WIDTH : 0] RES_temp;
  reg [(2*WIDTH) - 1: 0] RES_temp;
  reg OFLOW_temp, COUT_temp, ERR_temp;
  reg E_temp, G_temp, L_temp;

  reg [(2*WIDTH) -1 : 0] MULT_RES;
  reg [(2*WIDTH) -1: 0] MULT_RES_2;

  localparam POW_2_N = $clog2(WIDTH);
  wire [POW_2_N - 1:0] SH_AMT = OPB[POW_2_N - 1:0];

// Arithematic Commands
  localparam  ADD = 0,
              SUB = 1,
              ADD_CIN = 2,
              SUB_CIN = 3,
              INC_A = 4,
              DEC_A = 5,
              INC_B = 6,
              DEC_B = 7,
              CMP = 8,
              ADD_MULT = 9,
              SH_MULT = 10,
              SP_1_ADD = 11,
              SP_2_SUB = 12;

// Logical Commands
  localparam AND = 0,
             NAND = 1,
             OR = 2,
             NOR = 3,
             XOR = 4,
             XNOR = 5,
             NOT_A = 6,
             NOT_B = 7,
             SHR1_A = 8,
             SHL1_A = 9,
             SHR1_B = 10,
             SHL1_B = 11,
             ROL_A_B = 12,
             ROR_A_B = 13;

  always @(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      OPA_Buf <= 'b0;
      OPB_Buf <= 'b0;
      CMD_temp <= 'b0;
      CE_temp <= 'b0;
      CIN_temp <= 'b0;
      MODE_temp <= 'b0;
      INP_VALID_temp <= 'b0;
    end

  else
    begin
      OPA_Buf <= OPA;
      OPB_Buf <= OPB;
      CMD_temp <= CMD;
      CE_temp <= CE;
      CIN_temp <= CIN;
      MODE_temp <= MODE;
      INP_VALID_temp <= INP_VALID;
    end
  end

  always @(*)
  begin
    if(rst)
    begin
      RES_temp = 'b0;
      ERR_temp = 1'b0;
      {COUT_temp,OFLOW_temp} = 2'b0;
      {E_temp,G_temp,L_temp} = 3'b000;
      MULT_RES = 0;
    end

    else
    begin
      if(CE_temp)
      begin
        RES_temp = 'b0;
        ERR_temp = 1'b0;
        {COUT_temp,OFLOW_temp} = 2'b0;
        {E_temp,G_temp,L_temp} = 3'b000;
        MULT_RES = 0;

        case (INP_VALID_temp)
          2'b00: begin
                    OPA_temp = 'b0;
                    OPB_temp = 'b0;
                   end

          2'b01: begin
                    OPA_temp = OPA_Buf;
                    OPB_temp = 'b0;
                    end

          2'b10: begin
                    OPA_temp = 'b0;
                    OPB_temp = OPB_Buf;
                   end

          2'b11: begin
                    OPA_temp = OPA_Buf;
                    OPB_temp = OPB_Buf;
//                    RES_temp = 0;
                   end

          default: begin
                      RES_temp = 'b0;
                      {COUT_temp,OFLOW_temp} = 'b0;
                      ERR_temp = 1'b1;
                     end
          endcase

          if(MODE_temp)
          begin
              case (CMD_temp)
                      ADD: begin
                            RES_temp = OPA_temp + OPB_temp;
                            COUT_temp = RES_temp[WIDTH];
                           end

                      SUB: begin
                             RES_temp = OPA_temp - OPB_temp;
                             OFLOW_temp = OPA_temp < OPB_temp;
                           end

                      ADD_CIN: begin
                                RES_temp = OPA_temp + OPB_temp + CIN_temp;
                                COUT_temp = RES_temp[WIDTH];
                               end

                      SUB_CIN: begin
                                RES_temp = OPA_temp - OPB_temp - CIN_temp;
                                OFLOW_temp = OPA_temp < OPB_temp || ((OPA_temp == OPB_temp) && (CIN_temp));
                               end

                      INC_A: begin
                              RES_temp = OPA_temp + 1;
                              COUT_temp = RES_temp[WIDTH];
                             end

                      DEC_A: begin
                              RES_temp = OPA_temp - 1;
                              OFLOW_temp = OPA_temp == 1'b0;
                             end

                      INC_B: begin
                              RES_temp = OPB_temp + 1;
                              COUT_temp = RES_temp[WIDTH];
                             end

                      DEC_B: begin
                              RES_temp = OPB_temp - 1;
                              OFLOW_temp = OPB_temp == 1'b0;
                             end

                      CMP: begin
                            E_temp = OPA_temp == OPB_temp;
                            G_temp = OPA_temp > OPB_temp;
                            L_temp = OPA_temp < OPB_temp;
                           end

                      ADD_MULT: begin
                                  MULT_RES = (OPA_temp + 1) * (OPB_temp + 1);
                                end

                      SH_MULT: begin
                                MULT_RES = (OPA_temp << 1) * OPB_temp;
                               end
// yet to check for
                      SP_1_ADD: begin
                                  RES_temp = $signed(OPA_temp) + $signed(OPB_temp);
                                  COUT_temp = RES_temp[WIDTH];
                                  //OFLOW_temp = (OPA_temp[WIDTH - 1] == OPB_temp[WIDTH - 1]) & (OPB_temp[WIDTH - 1] != RES_temp[WIDTH - 1]);
                                  OFLOW_temp = ~(OPA_temp[WIDTH - 1] ^ OPB_temp[WIDTH - 1]) & (OPA_temp[WIDTH - 1] ^ RES_temp[WIDTH - 1]);

                                  E_temp = $signed(OPA_temp) == $signed(OPB_temp);// yet to check for other conditions
                                  G_temp = $signed(OPA_temp) > $signed(OPB_temp);
                                  L_temp = $signed(OPA_temp) < $signed(OPB_temp);
                                end
//// yet to check for
                      SP_2_SUB: begin
                                  RES_temp = $signed(OPA_temp) - $signed(OPB_temp);
                                  COUT_temp = RES_temp[WIDTH];
                                  //check the overflow condition again
                                  //OFLOW_temp = (OPA_temp[WIDTH - 1] == OPB_temp[WIDTH - 1]) & ( ~RES_temp[WIDTH]);
                                  OFLOW_temp = (OPA_temp[WIDTH - 1] ^ OPB_temp[WIDTH - 1]) & (OPA_temp[WIDTH - 1] ^ RES_temp[WIDTH - 1]);

                                  E_temp = $signed(OPA_temp) == $signed(OPB_temp);// yet to check for other conditions
                                  G_temp = $signed(OPA_temp) > $signed(OPB_temp);
                                  L_temp = $signed(OPA_temp) < $signed(OPB_temp);
                                end

                      default: begin
                                RES_temp = 'b0;
                                {COUT_temp,OFLOW_temp} = 'b0;
                                ERR_temp = 1'b1;
                                MULT_RES = 0;
                               end
                    endcase
          end
          else
          begin
              case(CMD_temp)
                        AND: RES_temp = {1'b0,OPA_temp & OPB_temp};
                        NAND: RES_temp = {1'b0,~(OPA_temp & OPB_temp)};
                        OR: RES_temp = {1'b0,OPA_temp | OPB_temp};
                        NOR: RES_temp = {1'b0,~(OPA_temp | OPB_temp)};
                        XOR: RES_temp = {1'b0,OPA_temp ^ OPB_temp};
                        XNOR: RES_temp = {1'b0,~(OPA_temp ^ OPB_temp)};
                        NOT_A: RES_temp = {1'b0,~OPA_temp};
                        NOT_B: RES_temp = {1'b0,~OPB_temp};
                        SHR1_A: RES_temp = OPA_temp >> 1;
                        SHL1_A: RES_temp = OPA_temp << 1;
                        SHR1_B: RES_temp = OPB_temp >> 1;
                        SHL1_B: RES_temp = OPB_temp << 1;

                        ROL_A_B: begin
                                  RES_temp = {1'b0,OPA_temp << SH_AMT | OPA_temp >> (WIDTH - SH_AMT)};
                                  ERR_temp = |OPB_temp[WIDTH - 1 : POW_2_N +1];
                                 end

                        ROR_A_B: begin
                                  RES_temp = {1'b0,OPA_temp << (WIDTH - SH_AMT) | OPA_temp >> SH_AMT};
                                  ERR_temp = |OPB_temp[WIDTH - 1 : POW_2_N +1];
                                 end

                        default: begin
                                  RES_temp = 'b0;
                                  {COUT_temp,OFLOW_temp} = 'b0;
                                  ERR_temp = 1'b1;
                                  MULT_RES = 0;
                                 end
                      endcase
          end
      end

      else
      begin
        RES_temp = 'b0;
        ERR_temp = 1'b0;
        {COUT_temp,OFLOW_temp} = 2'b0;
        {E_temp,G_temp,L_temp} = 3'b000;
        MULT_RES = 0;
      end
    end
    end

  always @(posedge clk or posedge rst)
  begin
    if(rst)
      MULT_RES_2 <= 'b0;
    else
      MULT_RES_2 <= MULT_RES;
  end

  always @(posedge clk or posedge rst)
  begin
    if(rst) begin
      RES = 'b0;
      OFLOW = 'b0;
      COUT = 'b0;
      ERR = 1'b0;
      {E,G,L} = 'b0;
    end

    else
    begin
      if((CMD_temp == ADD_MULT || CMD_temp == SH_MULT) && (MODE_temp == 1))
                RES <= MULT_RES_2;
      else
        RES <= RES_temp;

      OFLOW <= OFLOW_temp;
      COUT <= COUT_temp;
      ERR <= ERR_temp;
      {E,G,L} <= {E_temp,G_temp,L_temp};
    end
  end
endmodule
