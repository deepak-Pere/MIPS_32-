    JUMP L1
    ADDI R1, R0, 100      # Skipped
L1:
    JUMP L2
    ADDI R1, R0, 200      # Skipped
L2:
    ADDI R1, R0, 300
    HLT
