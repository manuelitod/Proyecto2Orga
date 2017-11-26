
##################################
# Example of exception handling  #
# and memory-mapped I/O          #
##################################

##################################
# Must enable memory-mapped I/O! #
##################################


################
# Handler Data #
################

        .kdata
        .align  4
ktemp:  .space  16       # allocate 4 consecutive words, 
                         # with storage uninitialized,
                         # for temporary saving (stack can't be used)

hex:    .ascii  "0123456789ABCDEF"  # table for quick hex conversion

exc:    .ascii  "\texception type:" # not .ascizz!
spc:    .asciiz " "
epc:    .asciiz "EPC: "
status: .asciiz " Status: "
cause:  .asciiz " Cause: "
count:  .asciiz " Count: "
hw_int:          .asciiz "\tHardware Interrupt,  "
#hw_int_timer:    .asciiz "timer\n"
hw_int_keyboard: .asciiz "keyboard input\n"
#timer:  .asciiz "\ttimer expired... and reset\n"
key:    .ascii  "\t\tkey pressed: " # not .asciiz!
char:   .ascii  " "
nl:     .asciiz "\n"


##########################
# Handler Implementation #
##########################

        # Overwrites existing exception handler
        .ktext 0x80000180

        .set   noat     # tell assembler not to use $at (assembler temporary)
                        # and hence not to complain when we do
        move   $k0, $at # save $at in $k0
                        # $k0 and $k1 are reserved for 
                        # OS and Exception Handling
                        # programmer should not use them, so not saved
        .set   at       # tell assembler it may use $at again

        la     $k1, ktemp   # address of temporary save area
                            # in exception handler, can NOT use stack
                            # as stack pointer/stack may be corrupt!
                            # Consequence: exception handler NOT re-entrant!
        sw     $a0, 0($k1)  # save $a0 as we'll use it
        sw     $a1, 4($k1)  # save $a1 as we'll use it
        sw     $v0, 8($k1)  # save $v0 as we'll use it
        sw     $ra, 12($k1) # save $ra as we'll use it

 # coprocessor0 registers
 #
 #    Name     Register Description    (*) simulated by MARS
 #
 # (*)BadVAddr  $8 offending memory reference
 #    Count     $9 current timer ;incremented every 10ms
 #    Compare  $11 interrupt when Count = Compare
 # (*)Status   $12 controls which interrupts are enabled
 # (*)Cause    $13 exception type, and pending interrupts
 # (*)EPC      $14 PC where exception/interrupt occured
  
        la    $a0, epc       # "EPC: " 
        jal   print_string   # (no print syscall from exception handler!)

        mfc0  $a0, $14       # coprocessor0 EPC register: 
                             # address of instruction that caused exception
        jal   print_hex      

        la    $a0, status    # "Status: " 
        jal   print_string   

        mfc0  $a0, $12       # coprocessor0 Status register
        jal   print_hex         

        la    $a0, cause     # "Cause: " 
        jal   print_string   

        mfc0  $a0, $13       # coprocessor0 Cause register
        jal   print_hex      

        la    $a0, count     # "Count: " 
        jal   print_string   

      #  mfc0  $a0, $9        # coprocessor0 timer register
      #  jal   print_hex      

        la    $a0, nl        # "\n" 
        jal   print_string      

        mfc0  $a0, $13       # coprocessor0 Cause register
        andi  $v0, $a0, 0x7C # Cause bits [6:2] contain Exception type 
      
 # Exception type
 #                     
 # Number Name Description
 #
 #    0   Int  Hardware interrupt pending
 #
 #    4   AdEL Address error on load (or instruction fetch)
 #    5   AdES Address error on store
 #    6   IBE  Bus error on instruction fetch
 #    7   DBE  Bus error on data load or store
 #    8   Sys  syscall exception (but not in MARS!)
 #    9   Bp   Breakpoint (usually used by debuggers)
 # 
 #   12   Ov   Arithmetic overflow

        la    $a0, exc       # "\texception type:"
        jal   print_string

        mfc0  $a0, $13       # coprocessor0 Cause register
        srl   $a0, $a0, 2    # Exception code starts at bit 2
        andi  $a0, $a0, 0x1F # mask the 5 exception code bits
        jal   print_hex

        la    $a0, nl        # "\n"
        jal   print_string

        # following two lines need to be re-done as $v0 (and $a0) got over-written in print_hex/print_string
        mfc0  $a0, $13       # coprocessor0 Cause register 
        andi  $v0, $a0, 0x7C # Cause bits [6:2] contain Exception type 

        beq   $v0, $zero, e_int  # handle hardware interrupt (exception type 0)

        # Program exception (i.e., not hardware interrupt)

        # here: know what the cause was and could deal with it
        # ... 
        # for example, when cause was 4 (AdEL) or 5(AdES)
        # print offending memory address from coprocessor0 register $8 (BadVAddr)
        # ...

        # skip offending instruction
        mfc0  $v0, $14    # EPC: address of instruction that caused exception
        addiu $v0, $v0, 4 # next sequential instruction (caveat: delayed branch)
        mtc0  $v0, $14    # update EPC (needed for "exception return" eret)

        j     e_int_end

e_int:  # hardware interrupt handler

        la    $a0, hw_int # "\tHardware Interrupt,  " 
        jal   print_string   

        mfc0  $v0, $13                    # Cause
        andi  $v0, $v0, 0x8000            # mask pending interrupt bit 15
        beq   $v0, $zero, e_int_timer_end # not timer interrupt

        # handle timer interrupt
        # note: timer not supported by MARS (but it is by SPIM)!

     #   mfc0  $a0, $13      # coprocessor0 Cause register
     #   xor   $a0, $a0, $v0 # set pending interrupt bit 15 to 0
     #   mtc0  $a0, $13      # reset Cause (removing pending interrupt)

     #   la    $a0, hw_int_timer # "timer\n" 
     #   jal   print_string   

        # reset timer to 0
    #    mtc0  $zero, $9     # set Count

     #   la    $a0, timer    # timer reset notice
     #   jal   print_string

      #  j     e_int_end

e_int_timer_end: 

        mfc0  $v0, $13                      # Cause
        andi  $v0, $v0, 0x0100              # mask pending interrupt bit 8 
       beq   $v0, $zero, e_int_keyrecv_end # not keyboard interrupt

        # handle keyboard receive interrupt

        mfc0  $a0, $13        # coprocessor0 Cause register
        xor   $a0, $a0, $v0   # set pending interrupt bit 8 to 0
        mtc0  $a0, $13        # reset Cause (removing pending interrupt)

        la    $a0, hw_int_keyboard # "keyboard input\n" 
        jal   print_string   

        li    $a0, 0xFFFF0004 # Receiver data address (interrupt based, so don't need to check Receiver control)
        lw    $v0, 0($a0)     # Receiver data 
        la    $a0, char       # space for one character
        sb    $v0, 0($a0)     # store Received data (key pressed) 
                              # note: accessing data re-sets Ready bit 
                              # in Receiver control

        la    $a0, key        # key pressed message/character
        jal   print_string

e_int_keyrecv_end:

e_int_end:

        # restore saved values
        la    $k1, ktemp
        lw    $a0, 0($k1)
        lw    $a1, 4($k1)
        lw    $v0, 8($k1)
        lw    $ra, 12($k1)

        .set  noat      # tell assembler not to use $at 
                        # and hence not to complain when we do
        move  $at, $k0  # restore $at
        .set  at        # tell assembler it may use $at again

        mtc0  $zero, $13# re-set Cause, including all pending interrupts

        mfc0  $k0, $12  # Status
        ori   $k0, 0x01 # re-enable interrupts
        mtc0  $k0, $12  # update Status
        eret  # return from exception, PC <- EPC


###############################
# print_string implementation #
###############################

print_string: # $a0: address of zero-terminated string (.asciiz) to print
        j ps_cond                 # jump to code to
                                  #  * check if end of string
                                  #  * load next character to print
ps_loop:
        lw    $v0, 0xFFFF0008     # Transmitter control
        andi  $v0, $v0, 0x01      # mask Ready bit
        beq   $v0, $zero, ps_loop # loop until ready to print
        sw    $a1, 0xFFFF000C     # data (byte) to print into Transmitter data
ps_cond:
        lbu   $a1, ($a0)          # load character to print
        addi  $a0, $a0, 1         # increment char pointer
        bne   $a1, $zero, ps_loop # loop as long as not EndOfString (0x00) found
        jr    $ra                 # return from subroutine


############################
# print_hex implementation #
############################

print_hex:  # $a0: word (32 bits long) to print
        la    $a1, hex            # address of hex conversion table
        li    $v0, 28             # printing a word (32 bits)
                                  # per nibble (4 bits = 1 hex character)
                                  # from leftmost to rightmost nibble
ph_loop:
        lw    $k1, 0xFFFF0008     # Transmitter control
        andi  $k1, $k1, 0x01      # mask (select only the) Ready bit
        beq   $k1, $zero, ph_loop # (busy) loop until ready to print

        srlv  $k1, $a0, $v0       # shift right logical variable (in reg) amount
        andi  $k1, $k1, 0x0f      # mask bits [3:0] 
        add   $k1, $a1, $k1       # use $k1 as index in hex conversion table
        lbu   $k1, ($k1)          # load that character into $k1
        sw    $k1, 0xFFFF000C     # data (byte) to print into Transmitter data

        addi  $v0, $v0, -4        # next nibble (4 bits = 1 hex character)
        bge   $v0, $zero, ph_loop # loop until nothing left
        jr    $ra                 # return from subroutine

#######################
# Program Entry Point #
#######################
	.data 

        .text
        .globl main
main:
     

         
        li    $a0, 0xFFFF0000 # Receiver control
        lw    $t0, 0($a0)
        ori   $t0, 0x02       # set bit 1 to enable input interrupts
                              # such a-synchronous I/O (handling of keyboard input in this case) 
                              # this is much more efficient than the "polling" we use for output
                              # In particular, it does not "block" the main program in case there is no input
        sw     $t0, 0($a0)    # update Receiver control

        
        mfc0   $t0, $12   # load coprocessor0 Status register
        ori    $t0, 0x01  # set interrupt enable bit 
        mtc0   $t0, $12   # move into Status register

       # li     $t0, 100
       # mtc0   $t0, $11   # coprocessor0 Compare register
                          # value is compared against timer
                          # interrupt when Compare ($11) and Count ($9) match
       # mtc0   $zero, $9  # Count = 0
                          # Count (timer) will be incremented every 10ms
                          # hence, a timeout interrupt will occur after
                          # 100 x 10ms = 1s
                          # This should catch an infinite loop ...
                          # ... 1s = 1ns x 10^9
        
        # divide by zero
        div    $t0, $t0, $zero

        
        # arithmetic overflow
        li     $t1, 0x7FFFFFFF
        addi   $t1, $t1, 1

        # non-existing memory address -- address error store 
        sw     $t2, 124($zero)

        # non-aligned address -- address error load
        lw     $t2, 125($zero)

        # illegal instruction 
        #.word 0xDEADBEEF  # hexspeak, "magic" value on some platforms :)

# infinite loop

forever:      
        nop
        nop
        j forever
