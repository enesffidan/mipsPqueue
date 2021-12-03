.data
unorderedList: .word 13, 26, 44, 8, 16, 37, 23, 67, 90, 87, 29, 41, 14, 74, 39, -1

insertValues: .word 46, 85, 24, 25, 3, 33, 45, 52, 62, 17

space: .asciiz " "
newLine: .asciiz "\n"



####################################
#   4 Bytes - Value
#   4 Bytes - Address of Left Node
#   4 Bytes - Address of Right Node
#   4 Bytes - Address of Root Node
####################################

.text 
main:

la $a0, unorderedList


jal build
move $s3, $v0

move $a0, $s3
jal print

li $s4, 8
li $s5, 0
la $s6, insertValues
li $s7, 2 #--> $s7 register value use for recognation where to call insert procedure
insertLoopMain: 
beq $s4, $s5, insertLoopMainDone

lw $a0, ($s6)
move $a1, $s3
jal insert

addi $s6, $s6, 4
addi $s5, $s5, 1 
j insertLoopMain

insertLoopMainDone:



move $a0, $s3
jal print


move $a0, $s3
jal remove


move $a0, $s3
jal print


li $v0, 10
syscall 



####################################
# Build Procedure
####################################
build:

    #::Store address of first element from unorderedList into to stack memory.
    addi $sp, $sp, -4 #--> increment stack pointer for store address
    sw $a0, ($sp)     #--> store address

    #:Allocate memory for rootNode
    li $v0, 9
    li $a0, 16
    syscall

    #::Restore $a0 register after syscall
    lw $a0 ($sp)


    #::Store base address of rootNode address as constant
    addi $sp, $sp, -4
    sw $v0, ($sp)
    



    #::Insert root node 
    lw $t0, ($a0) 
    sw $t0, ($v0)    #--> value
    addi $t0, $v0, 16
    sw $t0, 4($v0)   #--> left node address
    addi $t0, $v0, 32
    sw $t0, 8($v0)   #--> right node address
    sw $zero, 12($v0)#--> parent node address


    insertLabel:
        #::Update address for read next value.
        addi $a0, $a0, 4 #--> For take the address of next value increment by 4
        sw $a0, 4($sp)   #--> Update address of the current value in stack for insertion

        #::Check current value for finish build procedure.
        lw $t0, ($a0)           #--> Current value
        beq $t0, -1, endOfBuild #--> If current value is -1 finish build procedure

        j insert #--> Insert call

        endOfBuild:
            addi $a0, $a0, 4#--> For take the address of next value increment by 4
            sw $a0, 4($sp)  #--> Store last inserted value address for next insertions   
            jr $ra          #--> Jump link into the main flow.




####################################
# Insert Procedure
####################################
insert:


    #::Allocate memory for insert
    li $v0, 9
    li $a0, 16
    syscall

    #::Restore address of value from stack memory after syscall.
    lw $a0, 4($sp)

    #::Store last inserted value address.
    la $t4, ($v0)   #-->(use for print procedure)

    #::Store value into the node 1st 4-byte
    lw $t0, ($a0)
    sw $t0, ($v0)

    #::Calculate and store left node address into the 2nd 4-byte of node.
    lw $t1 ($sp)        #--> Load root node address from stack memory
    sub $t0, $v0, $t1   #--> currentValueAddress - rootAddress
    sll $t0, $t0, 1     #--> (currentValueAddress - rootAddress) * 2
    addi $t0, $t0, 16   #--> [(currentValueAddress - rootAddress) * 2] +16  
    add $t0, $t0, $t1   #--> $t0 = left node address
    sw $t0 4($v0)       #--> Store left node address into the node.

    #::Store right node address into the 3rd 4-byte of node.
    addi $t0, $t0, 16 #--> Left node address + 16
    sw $t0, 8($v0)    #--> Store right node address into the node.

    #::Calculate parent node address and store into the 4th 4-byte of node.
    sub $t0, $v0, $t1   #--> currentValueAddress - rootAddress
    addi $t0, $t0, -16  #--> (currentValueAddress - rootAddress) - 16
    srl $t0, $t0, 1     #--> [(currentValueAddress - rootAddress) - 16] / 2
    
    div $s0, $t0, 16    #--> (Parent node address / 16) for checking is it right node or left node
    mfhi $s1            #--> Remainder from divide by 16
    beq $s1, 8, rightNodeParentAddress   #--> If remainder equal to 8 it is right node. Then jump to calculate parent node for right node.

    #::If current value is left node store parent node address directly.
    add $t0, $t0, $t1
    sw $t0, 12($v0)     #--> Store parent node address if current node is left node

    

    j heapify #--> Jump directly to heapify skip rightNodeParentAddress procedure for leftNode 

    rightNodeParentAddress:
        #::Store parent node address if current node is right node.
        addi $t0, $t0, -8
        add $t0, $t0, $t1
        sw $t0, 12($v0)

    heapify:
        #::Check current value is in the root address
        lw $t3, ($sp)               #--> $t3 has root node address
        beq $v0, $t3, heapifyDone   #--> If current value reach the root node address
                                    # after heapify, then exit heapify and jump for next insertion. 


        #::Load value for comparing parent and child values.
        lw $t0, ($v0)   #--> Node value
        lw $t2, 12($v0) #--> Parent Address
        lw $t1, ($t2)   #--> Parent value

        #::Check if child value greater than parent value.
        bgt $t0, $t1, exchangeValues 
        j heapifyDone

        exchangeValues:
            #::Exchanege child value and parent value
            sw $t1, ($v0)       #--> Move parent value to current address
            add $v0, $zero, $t2 #--> $v0 has parent address
            sw $t0, ($v0)       #--> Move child value to parent address
            j heapify           #--> Recursive call



        heapifyDone:
            la $s2, ($t4)       #--> Store last inserted value address
            beq $s7, 2, jumpMain#--> Check if insert call from main or from build procedure 
            j insertLabel
        
        jumpMain:
            #::Update address for read next value.
            addi $a0, $a0, 4 #--> For take the address of next value increment by 4
            sw $a0, 4($sp)   #--> Update address of the current value in stack for insertion
            jr $ra
        





####################################
# Remove Procedure
####################################
remove:
    #::Store root node address
    lw $a0, ($sp)
    #::Store last inserted value address
    la $a1, ($s2)

    
    lw $t0, ($a1) #--> $t0 has last inserted value

    #::Delete root node value move last inserted value to root node.
    sw $t0, ($a0) 
    sw $zero, ($a1)


    heapifyLoop:
    #::Store left node address and value
    la $t1, 4($a0)  #--> Load address of left node address
    lw $t1, ($t1)   #--> Load left node address ($t1 hast left node address)
    lw $t3, ($t1)   #--> Load left node valye ($t3 has left node value)

    la $t2, 8($a0)  #--> Load address of right node address
    lw $t2, ($t2)   #--> Load right node address ($t2 has right node address)
    lw $t4, ($t2)   #--> Load right node value ($t4 has right node value)


    #::Decide which child node greater. Heapify direction should be direction of greater child node.
    bgt $t3, $t4, leftGreater   #--> If leftNode > rightNode jump leftGreater label
    bgt $t4, $t3, rightGreater  #--> If rightNode > leftNode jump rightGreater label

    leftGreater:
        bgt $t3, $t0, swapLeft  #--> If root node less than left node then swap.
        j removeDone            #--> Else remove operation done.

    rightGreater:
        bgt $t4, $t0, swapRight #--> If root node less than right node then swap.
        j removeDone            #--> Else remove operation done.


    swapLeft:
        sw $t0, ($t1) #--> Root value store in the left node.
        sw $t3, ($a0) #--> Left value store in the parent node.
        la $a0, ($t1) #--> For next heapify root address set as left node address
        j heapifyLoop

    swapRight:
        sw $t0, ($t2) #--> Root value store in the right node.
        sw $t4, ($a0) #--> Right value store in the parent node.
        la $a0, ($t2) #--> For next heapify root address set as right node address
        j heapifyLoop
    
    removeDone:

        jr $ra


####################################
# Print Procedure
####################################
print:
    lw $t0, ($sp)   #--> t0 has root address
    lw $t4, ($s2)   #--> t4 has last inserted value
    loop:
        
        #::Print value
        li $v0, 1
        lw $a0, ($t0)
        syscall

        beq $a0, $t4, endPrint #-->Compare readed value to last inserted value

         #::Print space between each value.
         li $v0, 4
         la $a0, space
         syscall


        addi $t0, $t0, 16        #--> Add 16 for read next value
        j loop

    endPrint:

        #Print new line at the end of print procedure.
         li $v0, 4
         la $a0, newLine
         syscall

        jr $ra



