module test_M132;

    reg clk1,clk2;

    mips_32 M1(.clk1(clk1),.clk2(clk2));

    integer i;

   


// Dual-Clk
    initial
    begin
        clk1 = 0; clk2 = 0;

        repeat(50)
        begin
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;

        end
    end

    //initialisation
    initial
    begin
        for(i = 0;i<=31;i++)
        M1.Reg[i] = i;


        //Take Machine code from output.mem
        $readmemh("output.mem",M1.Mem);


//        M1.Mem[0] = 32'h28010009;  // ADDI  R1, R0, 9         --> R1 = 9
// M1.Mem[1] = 32'h40000008;  // JAL   8                 --> PC = 8, R31 = 2
// M1.Mem[2] = 32'h28020064;  // ADDI  R2, R0, 100       --> should be skipped due to jump
// M1.Mem[3] = 32'h0C631800;  // Dummy
// M1.Mem[4] = 32'h0C631800;  // Dummy
// M1.Mem[5] = 32'h44880000;  // JR    R1                --> PC = R1 = 9
// M1.Mem[6] = 32'h280400C8;  // ADDI  R4, R0, 200       --> should be skipped
// M1.Mem[7] = 32'h0C631800;  // Dummy
// M1.Mem[8] = 32'h28050037;  // ADDI  R5, R0, 55        --> should execute after JAL
// M1.Mem[9] = 32'h2806004D;  // ADDI  R6, R0, 77        --> should execute after JR
// M1.Mem[10] = 32'hFC000000; // HLT



//             M1.Mem[0] = 32'h280a00c8;  // ADDI  R10,R0,200 
// M1.Mem[1] = 32'h28020001;  // ADDI  R2,R0,1 
// M1.Mem[2] = 32'h0e94a000;  // OR    R20,R20,R20 -- dummy instr. 
// M1.Mem[3] = 32'h21430000;  // LW    R3,0(R10) 
// M1.Mem[4] = 32'h0e94a000;  // OR    R20,R20,R20 -- dummy instr. 
// M1.Mem[5] = 32'h14431000;  // Loop: MUL   R2,R2,R3 
// M1.Mem[6] = 32'h2c630001;  // SUBI  R3,R3,1 
// M1.Mem[7] = 32'h0e94a000;  // OR    R20,R20,R20 -- dummy instr. 
// M1.Mem[8] = 32'h3460fffc;  // BNEQZ R3,Loop  (i.e. -4 offset) 
// M1.Mem[9] = 32'h2542fffe;  // SW    R2,-2(R10) 
// M1.Mem[10] = 32'hfc000000; // HLT 








///This is for with handling hazards

//             M1.Mem[0] = 32'h280100C8;  // ADDI R1, R0, 200      ; R1 = 200
// M1.Mem[1] = 32'h28020032;  // ADDI R2, R0, 50       ; R2 = 50
// M1.Mem[2] = 32'h24220000;  // SW   R2, 0(R1)        ; MEM[200] = 50
// M1.Mem[3] = 32'h20230000;  // LW   R3, 0(R1)        ; R3 = MEM[200] = 50
// M1.Mem[4] = 32'h00632000;  // ADD  R4, R3, R3       ; R4 = R3 + R3 = 100
// M1.Mem[5] = 32'h04832800;  // SUB  R5, R4, R3       ; R5 = R4 - R3 = 50
// M1.Mem[6] = 32'h00000000;  // NOP / HLT (optional)  ; stop execution


//After assembly
// M1.Mem[0] = 32'h28010005;
// M1.Mem[1] = 32'h40000003;
// M1.Mem[2] = 32'hfc000000;
// M1.Mem[3] = 32'h2c210001;
// M1.Mem[4] = 32'h34200003;
// M1.Mem[5] = 32'hfc000000;







        M1.Mem[200] = 7;


        M1.HALTED = 0;
        M1.PC = 32'h0;
        M1.TAKEN_BRANCH = 0;

        #3000
        
        //  $display("R1 = %2d", M1.Reg[1]);
        //  $display("R2 = %2d", M1.Reg[2]); // Should be 0 (skipped)
        //  $display("R5 = %2d", M1.Reg[5]); // 55
        //  $display("R6 = %2d", M1.Reg[6]); // 77
        //  $display("R31 = %2d", M1.Reg[31]); // 2 (return address from JAL)
        //  $display("R4 = %2d", M1.Reg[4]);

        

        // for (i = 0; i <= 5; i = i + 1)
        // $display("Mem[%0d] = %h", i, M1.Mem[i]);

        // for (i=0; i<=6; i++) 
        // $display ("R%1d - %2d", i, M1.Reg[i]);

        // $display ("R1 - %2d", M1.Reg[1]);
        $display ("R31 - %2d", M1.Reg[31]);
         $display ("R12 - %2d", M1.Reg[12]);

        

        // $display ("Mem[200] = %2d,Mem[198] = %2d",M1.Mem[200],M1.Mem[198]);
        
    end

    initial
    begin
        $dumpfile("M1.vcd");
        $dumpvars(0,test_M132);
        $monitor("R3: %4d",M1.Reg[3]);
        #3000 $finish;

    end

endmodule