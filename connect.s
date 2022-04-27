li s11 0   # register to store win state
li s10 0   # keep track of player turn
li s9 0    # reg to store color

gameLoop:
    jal getInput

    # convert ascii to int
    li t0 48
    sub a1 a1 t0

    li a0 0x100     # turn led matrix on
    la s0 board     # load address of the board
    li s2, 0        # data col shift
    li s7, 7        # board size
    slli s8 s7 2    # board size in bytes
    li s6 4         # to compare streak against

    # a1 col a3 row
    jal placeChip
    srai a1 a1 16
    
    jal verticle    # check col for win
    jal horizontal  # check row for win
    jal downRight   # check down right diagonal
    jal downLeft    # check down left for win

    # if player won output player won
    bne s11 x0 winner

    # check to see if board full
    la s1 board
    li t1 0
    loopf:
        lw t0 0(s1)
        beq t1 s7 tie
        beq t0 x0 nextTurn
        addi s1 s1 1
        j loopf
        
getInput:
    li a0 4
    beq s10 x0 p1Input   # if p1s turn get p1 input
    bne s10 x0 p2Input   # if p2s turn get p2 input

    nullcheck:
    beq a1 x0 getInput
    ret

    p1Input:
        li s9 0x0002a52be   # player 1 is blue
        la a1 p1msg
        ecall
        j inputProbe
    p2Input:
        li s9 0x00be0032   # player 2 is red 
        la a1 p2msg
        ecall
        j inputProbe
    
    inputProbe:
    li a0 0x130
    li a1 0
    ecall
        probe:
            li a0 0x131
            ecall
            li t0 1
            beq a0 t0 probe
            j nullcheck

placeChip:
    # move mem pointer to col
    slli t0 a1 2
    add s0 s0 t0

    li a3 0
    findRow:
        lw t0 0(s0) # load color at row n of input col

        # if color not black or bottm of col reached break loop
        bne t0 x0 endr
        beq a3 s7 endr

        # increment counter and mem pointer
        add s0 s0 s8
        addi a3 a3 1
        j findRow
    endr:

    # if col is full restart loop
    beq a3 x0 gameLoop

    # format index of led
    addi a3 a3 -1 
    slli a1 a1 16
    add a1 a1 a3

    sub s0 s0 s8    # move address up one row
    sw s9 0(s0)     # store color into mem    
    addi a2 s9 0    # turn on led at pos
    ecall

    ret
verticle:
    mv s1 s0 # mutable freference to pos in mem
    mv t1 a3 # row ref and counter
    li t2 0
    loopv:
        # if row counter reaches end of board exit loop
        beq t1 s7 return

        lw t0 0(s1)     # load color
        add s1 s1 s8    # move mem pointer down a row
        addi t1 t1 1    # add to row counter
        addi t2 t2 1    # add to streak counter

        # if color not player color reset streak and restart loop
        bne t0 s9 breakv

        # if streak 4 set win to true and exit loop
        beq t2 s6 win

        j loopv

    breakv:
        li t2 0
        j loopv

horizontal:
    slli t0 a1 2
    sub s1 s0 t0    # set pointer to beginning of row
    li t2 0         # set streak counter to 0
    li t1 0         # col counter set to 0

    looph:
        # if row counter reaches end of board exit loop
        beq t1 s7 return 

        lw t0 0(s1)
        addi s1 s1 4    # move pointer over 1
        addi t1 t1 1    # add to col counter 
        addi t2 t2 1    # add to streak counter

        # if color not player color reset streak and restart loop
        bne t0 s9 breakh

        # if streak 4 set win to true and exit loop
        beq t2 s6 win

        j looph

    breakh:
        li t2 0
        j looph

downRight:
    li t2 0
    addi t3 s8 4

    sub t1 a1 a3
    la s1 board

    bge t1 x0 topdr
    ble t1 x0 left

    topdr:
        add s1 s1 t1
        j loopdr

    left:
        neg t1 t1
        mul t4 t1 s8
        add s1 s1 t4
        j loopdr

    loopdr:
        # if row counter reaches end of board exit loop
        beq t1 s7 return

        lw t0 0(s1)
        add s1 s1 t3
        addi t1 t1 1
        addi t2 t2 1

        # if color not player color reset streak and restart loop
        bne t0 s9 breakdr

        # if streak 4 set win to true and exit loop
        beq t2 s6 win

        j loopdr

    breakdr:
        li t2 0
        j loopdr

downLeft:
    li t2 0
    addi t3 s8 -4

    addi t4 s7 -1
    sub t1 t4 a1
    sub t1 t1 a3

    la s1 board
    add s1 s1 t3

    bge t1 x0 topDL
    ble t1 x0 right

    topDL:
        sub s1 s1 t1
        j loopdl
    
    right:
        neg t1 t1
        mul t4 t1 s8
        add s1 s1 t4
        j loopdl

    loopdl:
        # if row counter reaches end of board exit loop
        beq t1 s7 return

        lw t0 0(s1)
        add s1 s1 t3
        addi t1 t1 1
        addi t2 t2 1

        # if color not player color reset streak and restart loop
        bne t0 s9 breakdl

        # if streak 4 set win to true and exit loop
        beq t2 s6 win

        j loopdl

    breakdl:
        li t2 0
        j loopdl
        
win:
    ori s11 s11 1 
    ret
tie:
    li a0 4
    la a1 nowin
    ecall
    j exit    
winner:
    li a0 4
    beq s10 x0 p1win
    bne s10 x0 p2win
    p1win:
        la a1 p1won
        ecall
        j exit
    p2win:
        la a1 p2won
        ecall
        j exit

nextTurn:
    not s10 s10
    j gameLoop
return:
    ret

exit:
    li a0, 10
    li a1, 0
    ecall
.data
p1msg:
    .string "Player 1:\n"
p2msg:
    .string "Player 2:\n"
p1won:
    .string "Player 1 has won \n"
p2won:
    .string "Player 2 has won \n"
nowin:
    .string "Tie, no one wins \n"
board:
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
