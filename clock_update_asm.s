.text                           # IMPORTANT: subsequent stuff is executable
.global  set_tod_from_ports
        
## ENTRY POINT FOR REQUIRED FUNCTION
set_tod_from_ports:
# %ecx = CLOCK_TIME_PORT  
# %rdi = tod_t *tod
    movl    CLOCK_TIME_PORT(%rip), %ecx #sets clock_time_port to ecx
    cmpl    $1382400, %ecx              #compares clock_time_port to 16 * # of seconds per day
    jg      .ERROR                        #jumps to out of bound 
    cmpl    $0, %ecx                    #compare clock_time_port to 0
    jl      .ERROR

    movb    $1,10(%rdi)                  # set am/pm to 1

    movl    %ecx,%eax       # eax now has CLOCK_TIME_PORT
    cqto                    # prep for division    
    movl    $16,%r8d        # set the number to divide by
    idivl    %r8d            # divides by 16

    cmpl    $8,%edx         # if(CLOCK_TIME_PORT % 16 >= 8) edx = CLOCK_TIME_PORT % 16
    jge     .SET            # go to SET

    shr     $4, %ecx        #else shift right 4 times
    movl    %ecx, 0(%rdi)

.COMEBACK2:
    movl    0(%rdi),%eax    #eax is now tod->day_secs
    cqto                    # prep for division
    movl    $60,%r8d        # set the number to divide by
    idivl    %r8d            #divides by 60
    movw    %ax,6(%rdi)    # sets tod->time_mins to tod->day_secs / 60
    movw    %dx,4(%rdi)    # sets tod->time_secs to tod->day_secs % 60
    
    cmpw    $60,6(%rdi)     #compares tod->time_mins to 60
    jge     .TIME_MIN_CHECK
    movw    $0, 8(%rdi)     # if tod->time_mins is less than 60 then tod->time_hours is 0
.COMEBACK3:
    cmpw    $0, 8(%rdi)     #if tod->time_hours is 0 jump to SET_TWELVE to set the time to 12
    je      .SET_TWELVE  
    jmp     .COMEBACK
.COMEBACK:
    movl    0(%rdi),%eax    #eax is now tod->day_secs
    cqto                    # prep for division
    movl    $3600,%r8d      # preps to divid by 3600
    idivl    %r8d
    cmpl    $12, %eax       #if tod->day_secs / 3600 >= 12 go to .SET_AMPM
    jge     .SET_AMPM       
.COMEBACK1:
    movl    $0,%eax         #end of function and returns 0 if all goes well
    ret
.ERROR:
    movl    $1, %eax 
    ret

.SET:
    shr     $4, %ecx       # tod->day_secs = (CLOCK_TIME_PORT >> 4)
    addl    $1, %ecx       #  tod->day_secs = tod->day_secs + 1;
    movl    %ecx, 0(%rdi)
    jmp     .COMEBACK2           # go back to the code

.TIME_MIN_CHECK:
    movw    6(%rdi),%ax    #ax is now tod->time_mins
    cqto                    # prep for division
    movw    $60,%r8w        # set to divide by 60
    idivw    %r8w
    movw    %ax,8(%rdi)     # sets tod->time_hours = tod->time_mins / 60
    movw    %dx,6(%rdi)     # tod->time_mins = tod->time_mins % 60

    movw    8(%rdi),%ax    #ax is now tod->time_hours
    cqto 
    movw    $12,%r8w        # set to divide by 12
    idivw    %r8w            # divides by 12
    movw    %dx, 8(%rdi)    # sets tod->time_hours to (tod->time_hours % 12)
    jmp     .COMEBACK3

.SET_TWELVE:
    movw    $12, 8(%rdi)    #sets tod->time_hours to 12
    jmp     .COMEBACK             # go back to finish the rest of the code

.SET_AMPM:
    movb    $2,10(%rdi)     #sets tod->ampm to 2 
    jmp     .COMEBACK1            # go back to the rest of the code
    

        ## assembly instructions here

        ## a useful technique for this problem
        # movX    SOME_GLOBAL_VAR(%rip), %reg
        # load global variable into register
        # Check the C type of the variable
        #    char / short / int / long
        # and use one of
        #    movb / movw / movl / movq 
        # and appropriately sized destination register                                            

        ## DON'T FORGET TO RETURN FROM FUNCTIONS

### Change to definint semi-global variables used with the next function 
### via the '.data' directive
.data                           # IMPORTANT: use .data directive for data section
	
min_ones:                         # declare location an single int
        .int 0               # value 0

min_tens:
        .int 0
int_0b0000000:                      # declare another accessible via name 'other_int'
        .int 0b0000000             # binary value as per C '0b' convention

masks:                       # declare multiple ints sequentially starting at location
        .int 0b1110111            # 'my_array' for an array. Each are spaced 4 bytes from the (masks[0])
        .int 0b0100100            # next and can be given values using the same prefixes as (masks[1])
        .int 0b1011101            # are understood by gcc.  (masks[2])
        .int 0b1101101          # masks[3]
        .int 0b0101110          # masks[4]
        .int 0b1101011          # masks[5]
        .int 0b1111011          # masks[6]
        .int 0b0100101          # masks[7]
        .int 0b1111111          # masks[8]
        .int 0b1101111          # masks[9]


## WARNING: Don't forget to switch back to .text as below
## Otherwise you may get weird permission errors when executing 

.text
.global  set_display_from_tod

## ENTRY POINT FOR REQUIRED FUNCTION
set_display_from_tod:
# %rdi = tod.day_sec, tod.time_secs, tod.time_mins
# %rsi = tod.time_hours, tox.ampm
# %rdx = *dispint = %r9
    movq    %rsi, %r8  # %r8 now equals %rsi
    movq    %rdx, %r9  # rdx = *dispint = %r9
    andq    $0xFFFF, %r8  # %r8 now equals tod.time_hours
    cmpq    $0, %r8    # if (tod.time_hours < 0)
    jl      .ARG_ERROR
    cmpq    $12, %r8     # if (tod.time_hours > 12)
    jg      .ARG_ERROR 

    movq    %rdi, %r8   # %r8 now equals %rdi
    sarq    $48, %r8    # shift right by 48 bits
    andq    $0x7F, %r8  # %r8 now equals tod.time_mins
    cmpq    $59, %r8    # compare tod.time_mins and 59 
    jg      .ARG_ERROR
    cmpq    $0, %r8     # compare tod.time_mins and 0
    jl      .ARG_ERROR

    movq    %rdi, %r8   # %r8 now equals %rdi
    sarq    $32, %r8    # shift right by 32 bits
    andq    $0x7F, %r8  # %r8 now equals tod.time_secs
    cmpq    $59, %r8    # compare tod.time_secs and 59 
    jg      .ARG_ERROR
    cmpq    $0, %r8     # compare tod.time_secs and 0
    jl      .ARG_ERROR

    movq    %rsi, %r8   # %r8 now equals %rsi
    sarq    $16, %r8    # shift right by 16 bits
    andq    $0x2F, %r8  # %r8 now equals tod.ampm
    cmpq    $1, %r8     # compare tod.ampm and 1
    jl      .ARG_ERROR
    cmpq    $2, %r8     # compare tod.ampm and 2
    jg      .ARG_ERROR

    movl    $0, %r10d      # %r10d = dis = 0
    andl    $0x7FFFFFFF, %r10d 
    movq    %rdi, %rax   # %rax now equals %rdi
    sarq    $48, %rax    # shift right by 48 bits
    andq    $0x7F, %rax  # %rax now equals tod.time_mins
    cqto                  # prep for division
    movl    $10,%r8d      # preps to divid by 10
    divl    %r8d            # divides by ten i want %rdx as it tod.time_mins % 10 or min_ones
    leaq    masks(%rip), %r11 # %r11 is now masks[]

    movl    (%r11, %rdx, 4), %ecx # %ecx = masks[min_ones]
    orl     %ecx, %r10d    # dis = dis | (masks[min_ones] << 0);
    movl    (%r11, %rax, 4), %ecx # %ecx = masks[min_tens]
    shll    $7, %ecx       #shift left seven bits
    orl     %ecx, %r10d    # dis = dis | (masks[min_tens] << 7);

    movq    %rsi, %rax  # %ax now equals %rsi
    andq    $0xFFFF, %rax  # %rax now equals tod.time_hours
    cqto                  # prep for division
    movl    $10,%r8d      # preps to divid by 10
    idivl    %r8d            # divides by ten i want %rdx as it is tod.time_hours % 10 or hr_ones %rax = tod.time_hours / 10
    movl    (%r11, %rdx, 4), %ecx # %ecx = masks[hr_ones]
    shll    $14, %ecx       #shift left 14 bits
    orl     %ecx, %r10d    # dis = dis | (masks[hr_ones] << 14);

    cmpq    $0, %rax        # if (hr_tens == 0)
    je      .EQUALS_ZERO

    movl    (%r11, %rax, 4), %ecx # %ecx = masks[hr_tens]
    shll    $21, %ecx      # shift left 21 bits
    orl     %ecx, %r10d    #   dis = dis | (masks[hr_tens] << 21);
.BACK:
    movl    $1, %ecx   # %ecx = 1
    shll    $28, %ecx  #shift 28 bits
    orl     %ecx, %r10d    #   dis = dis | (1 << 28);

    movq    %rsi, %r8   # %r8 now equals %rsi
    sarq    $16, %r8    # shift right by 16 bits
    andq    $0x2F, %r8  # %r8 now equals tod.ampm
    cmpq    $2, %r8     # if (tod.ampm == 2)
    je      .EQUALS_TWO
.BACK2:
    movl    %r10d, (%r9)     #  *display = dis;
    movq    %r9, %rdx
    movl    $0,%eax         #end of function and returns 0 if all goes well
    ret
.ARG_ERROR:
    movl    $1, %eax #sets %eax to 1 to return 1 given an out of bounds entry
    ret     
.EQUALS_ZERO:
    movl    $0b0000000, %ecx  # %ecx = 0b0000000
    shll    $21, %ecx      # shift left 21 bits
    orl     %ecx, %r10d    #  dis = dis | (0b0000000 << 21); 
    jmp     .BACK           # upon further review i can see how this part of the code is useless but i will still include to maintain the integrity of the original C code
.EQUALS_TWO:
    movl    $1, %ecx   # %ecx = 1
    shll    $28, %ecx  # shift left 28 
    notl    %ecx       # ~(1 << 28)
    andl    %ecx, %r10d # dis = dis & ~(1 << 28)

    movl    $1, %ecx   # %r15d = 1
    shll    $29, %ecx  # shift left 28 
    orl    %ecx, %r10d #  dis = dis | (1 << 29)
    jmp     .BACK2

        ## assembly instructions here

	## two useful techniques for this problem
        // movl    my_int(%rip),%eax    # load my_int into register eax
        // leaq    my_array(%rip),%rdx  # load pointer to beginning of my_array into rdx


.text
.global clock_update
        
## ENTRY POINT FOR REQUIRED FUNCTION
clock_update:
    movl    CLOCK_TIME_PORT(%rip), %ecx #sets clock_time_port to ecx
    cmpl    $1382400, %ecx              #compares clock_time_port to 16 * # of seconds per day
    jg      .UPDATE_ERROR                        #jumps to out of bound 
    cmpl    $0, %ecx                    #compare clock_time_port to 0
    jl      .UPDATE_ERROR               
    # %rsp = tod
    subq    $40, %rsp    #subq instruction to expand stack for locals + alignment padding %rsp
    movl    $0, 0(%rsp)  #tod.day_secs = 0;
    movw    $0, 4(%rsp)    #tod.time_secs = 0;
    movw    $0, 6(%rsp)     #tod.time_mins = 0;
    movw    $0, 8(%rsp)     #tod.time_hours = 0;
    movb    $0, 10(%rsp)    #tod.ampm = 0;
    leaq    (%rsp), %rdi    # i make the first argument for set_tod_from_ports the tod struct
    call    set_tod_from_ports

    movq    $0, 11(%rsp)   # 11(%rsp) = update = 0
    movq    (%rsp), %rdi    # i make the first argument for set_tod_from_ports the tod struct
    movq    8(%rsp), %rsi
    leaq    11(%rsp) , %rdx # &update = %rdx    
    call    set_display_from_tod
    je     .UPDATE_ERROR        #checks if the cuntion returns 1
    movl    11(%rsp), %ecx      
    movl    %ecx, CLOCK_DISPLAY_PORT(%rip)
    je     .UPDATE_ERROR        #checks if the cuntion returns 1
    addq    $40, %rsp

    movl    $0, %eax 
    ret 
.UPDATE_ERROR:
    movl    $1, %eax 
    ret
	## assembly instructions here 