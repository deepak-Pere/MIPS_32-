module mips_32 (clk1,clk2);

    input clk1,clk2;

    reg[2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
    reg[31:0] PC, IF_ID_IR, IF_ID_NPC;    //first stage
    reg[31:0] ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_IMM, ID_EX_IR;
    reg[31:0] EX_MEM_IR, EX_MEM_B, EX_MEM_ALUout;
    reg EX_MEM_cond;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUout, MEM_WB_LMD;
    reg [31:0] ID_EX_RA, EX_MEM_RA , MEM_WB_RA;

    reg [31:0] Reg [0:31];
    reg [31:0] Mem [0:1023];


    parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011,
              SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000,  
              SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011,SLTI=6'b001100, 
              BNEQZ=6'b001101, BEQZ=6'b001110, JUMP = 6'b001111, JAL = 6'b010000, JR = 6'b010001;


    parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011,
                BRANCH = 3'b100, HALT = 3'b101, JMP = 3'b110;

    reg HALTED;
    reg TAKEN_BRANCH;
    reg JUMPER;
    reg STALL;



    always @(*)
    begin
        STALL = 0;
        if((EX_MEM_type == LOAD) && ((EX_MEM_IR[20:16] == IF_ID_IR[25:21]) || (EX_MEM_IR[20:16] == IF_ID_IR[20:16])))
        begin
            STALL = 1;
        end
    end


    // IF
    always @(posedge clk1)
    begin
        if(HALTED == 0)
        begin

            if(STALL)
            begin
                // IF_ID_IR        <= #1 Mem[PC-1];
                // IF_ID_NPC       <= #1 PC - 1;
                // PC              <= #1 PC - 1;
                
                IF_ID_IR  <= #1 IF_ID_IR;
                IF_ID_NPC <= #1 IF_ID_NPC;
                PC        <= #1 PC;
            end
            else if(((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)))
            begin
                IF_ID_IR        <= #1 Mem[EX_MEM_ALUout];
                TAKEN_BRANCH    <= #1 1'b1;
                IF_ID_NPC       <= #1 EX_MEM_ALUout + 1;
                PC              <= #1 EX_MEM_ALUout + 1;
            end
            else
            begin
                IF_ID_IR        <= #1 Mem[PC];
                IF_ID_NPC       <= #1 PC + 1;
                PC              <= #1 PC + 1;
            end
            

        end
    end


    // ID
    always @(posedge clk2)
    begin

        
        
        if(HALTED == 0)
        begin


// stall for lw

        // STALL <= 0;
        // if((EX_MEM_type == LOAD) && ((EX_MEM_IR[20:16] == IF_ID_IR[26:21]) || (EX_MEM_IR[20:16] == IF_ID_IR[20:16])))
        // begin
        //     STALL = 1;
        // end


        
        if(STALL)
        begin
            ID_EX_IR <= #1 32'h0;
            ID_EX_A <= #1 0;
            ID_EX_B <= #1 0;
            ID_EX_NPC <= #1 0;
        end

        else begin

        //rs
        if(IF_ID_IR[25:21] == 5'b00000)
            ID_EX_A <= 0;
        else
            ID_EX_A <= #1 Reg[IF_ID_IR[25:21]];

        //rt
        if(IF_ID_IR[20:16] == 5'b00000)
            ID_EX_B <= 0;
        else
            ID_EX_B <= #1 Reg[IF_ID_IR[20:16]];


        ID_EX_NPC <= #1 IF_ID_NPC;
        ID_EX_IR <= #1 IF_ID_IR;
        
        ID_EX_IMM <= #1 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};

        case(IF_ID_IR[31:26])
            ADD,SUB,AND,OR,SLT,MUL : ID_EX_type <= #1 RR_ALU;
            ADDI,SUBI,SLTI         : ID_EX_type <= #1 RM_ALU;
            LW                     : ID_EX_type <= #1 LOAD;
            SW                     : ID_EX_type <= #1 STORE;
            BNEQZ,BEQZ             : ID_EX_type <= #1 BRANCH;
            JUMP,JAL,JR            : ID_EX_type <= #1 JMP;
            HLT                    : ID_EX_type <= #1 HALT;
            default                : ID_EX_type <= #1 HALT;
        endcase

        if(IF_ID_IR[31:26] == JUMP || IF_ID_IR[31:26] == JAL)
        begin
            PC <= #1 IF_ID_IR[25:0];
            ID_EX_RA <= #1 IF_ID_NPC;
            // TAKEN_BRANCH <= #1 1'b1;
        end
        else if(IF_ID_IR[31:26] == JR)
        begin
            PC <= #1 Reg[IF_ID_IR[25:21]];  
            // TAKEN_BRANCH <= #1 1'b1;
        end


        // Data forwarding
                    if(EX_MEM_type == RR_ALU && (EX_MEM_IR[15:11]) != 5'd0) 
                begin
                    if(EX_MEM_IR[15:11] == IF_ID_IR[25:21])
                    ID_EX_A <= #1 EX_MEM_ALUout;
                    if(EX_MEM_IR[15:11] == IF_ID_IR[20:16])
                    ID_EX_B <= #1 EX_MEM_ALUout;
                end
                
                if(EX_MEM_type == RM_ALU && (EX_MEM_IR[20:16]) != 5'd0)
                begin
                    if(EX_MEM_IR[20:16] == IF_ID_IR[25:21])
                    ID_EX_A <= #1 EX_MEM_ALUout;
                    if(EX_MEM_IR[20:16] == IF_ID_IR[20:16])
                    ID_EX_B <= #1 EX_MEM_ALUout;
                end

//LOAD data forwarding
            //  if (EX_MEM_type == LOAD && (EX_MEM_type[20:16] != 5'd0)) 
            // begin
            //     if (EX_MEM_IR[20:16] == IF_ID_IR[25:21])  
            //         ID_EX_A <= #1 MEM_WB_LMD;
            //     if (EX_MEM_IR[20:16] == IF_ID_IR[20:16])  
            //         ID_EX_B <= #1 MEM_WB_LMD;
            // end 
            
        
        end

        end

        
    end

    //EX
    always @(posedge clk1)
    begin
        if(HALTED == 0)
        begin
            EX_MEM_type <= #1 ID_EX_type;
            EX_MEM_IR <= #1 ID_EX_IR;
            EX_MEM_RA <= #1 ID_EX_RA;
            TAKEN_BRANCH <= #1 1'b0;

               
            // if (MEM_WB_type == LOAD && (MEM_WB_IR[20:16] != 5'd0)) 
            // begin
            //     if (MEM_WB_IR[20:16] == ID_EX_IR[25:21])  
            //         ID_EX_A <= #1 MEM_WB_LMD;
            //     if (MEM_WB_IR[20:16] == ID_EX_IR[20:16])  
            //         ID_EX_B <= #1 MEM_WB_LMD;
            // end 
            

              

            case(ID_EX_type)
                RR_ALU :begin
                        case(ID_EX_IR[31:26])
                            ADD:    EX_MEM_ALUout <= #1 ID_EX_A + ID_EX_B;
                            SUB:    EX_MEM_ALUout <= #1 ID_EX_A - ID_EX_B;
                            AND:    EX_MEM_ALUout <= #1 ID_EX_A & ID_EX_B;
                            OR:     EX_MEM_ALUout <= #1 ID_EX_A | ID_EX_B;
                            SLT:    EX_MEM_ALUout <= #1 ID_EX_A < ID_EX_B;
                            MUL:    EX_MEM_ALUout <= #1 ID_EX_A * ID_EX_B;
                            default:EX_MEM_ALUout <= #1 32'hxxxxxxxx;
                        endcase
                        end

                RM_ALU :begin
                        case(ID_EX_IR[31:26])
                            ADDI:   EX_MEM_ALUout <= #1 ID_EX_A + ID_EX_IMM;
                            SUBI:   EX_MEM_ALUout <= #1 ID_EX_A - ID_EX_IMM;
                            SLTI:   EX_MEM_ALUout <= #1 ID_EX_A < ID_EX_IMM;
                            default:EX_MEM_ALUout <= #1 32'hxxxxxxxx;
                        endcase
                        end

                LOAD,STORE :begin
                            EX_MEM_ALUout <= #1 ID_EX_A + ID_EX_IMM;
                            EX_MEM_B <= #1 ID_EX_B;
                            end

                BRANCH :    begin  //doubt
                            EX_MEM_ALUout <= #1 ID_EX_NPC + ID_EX_IMM;
                            EX_MEM_cond <= #1 (ID_EX_A == 0);
                            end

                // JMP    :    begin
                //             case(ID_EX_IR[31:26])
                            
                //             // JUMP    :  begin   EX_MEM_ALUout <= #1 {ID_EX_NPC[31:28],ID_EX_IR[25:0],2'b00}; end
                //             // JAL     :  begin   EX_MEM_ALUout <= #1 {ID_EX_NPC[31:28],ID_EX_IR[25:0],2'b00}; end
                //             // JR      :  begin   EX_MEM_ALUout <= #1 ID_EX_A; end
                //             endcase
                //             end

                            

            endcase
        end
    end
    

    //MEM
    always @(posedge clk2)
    begin
        if(HALTED == 0)
        begin
            MEM_WB_type <= #1 EX_MEM_type;
            MEM_WB_IR <= #1 EX_MEM_IR;
            MEM_WB_RA <= #1 EX_MEM_RA;

            case(EX_MEM_type)
                RR_ALU,RM_ALU : MEM_WB_ALUout <= #1 EX_MEM_ALUout;
                LOAD          : MEM_WB_LMD <= #1 Mem[EX_MEM_ALUout];
                STORE         : if(TAKEN_BRANCH == 0)
                                Mem[EX_MEM_ALUout] <= #1 EX_MEM_B;
            endcase
        end
    end


    //WB
    always @(posedge clk1)
    begin
        if(TAKEN_BRANCH == 0)
        begin
            if(MEM_WB_IR[31:26] == JAL)
            Reg[31] <= #1 MEM_WB_RA;
            else begin
            case(MEM_WB_type)
                RR_ALU : Reg[MEM_WB_IR[15:11]] <= #1 MEM_WB_ALUout;
                RM_ALU : Reg[MEM_WB_IR[20:16]] <= #1 MEM_WB_ALUout;
                LOAD   : Reg[MEM_WB_IR[20:16]] <= #1 MEM_WB_LMD;
                
                HALT   : HALTED                <= #1 1'b1;
            endcase
            end
            
        end
            
    end


endmodule