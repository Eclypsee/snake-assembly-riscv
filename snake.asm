# register key
# s0 columns
# s1 rows
# s8 buttons address
# s9 score
# s10 old tail position post move
# s11 new head position post move
.data
direction: .word 0x1 
snake_length: .word 3  # Initially, the snake is 3 blocks long
apple: .word 0x0005000c  # Initially set the apple position to 0
# random number table, 240 nums
table: 
    .byte 0x19, 0x37, 0x28, 0x51, 0x02, 0x91, 0x83, 0x72, 0x7A, 0x9C, 0x3F, 0x2D, 0x4B, 0x16, 0x2E, 0x3F
    .byte 0x83, 0x91, 0xAB, 0x47, 0x2F, 0x6D, 0x3E, 0x9C, 0xC7, 0xA4, 0xB2, 0x3E, 0x98, 0xF1, 0xD2, 0x46
    .byte 0x57, 0xE3, 0xA9, 0xBC, 0x1D, 0x2F, 0x36, 0x48, 0xB4, 0xC8, 0x39, 0x1A, 0xA7, 0xD9, 0x2F, 0x6C
    .byte 0x6E, 0x4B, 0x3F, 0x1D, 0xC9, 0x1A, 0x7B, 0x2F, 0xF3, 0xD4, 0xE9, 0xC8, 0x21, 0xA4, 0xB6, 0x7E
    .byte 0x4F, 0x1D, 0x23, 0x9C, 0x87, 0xC3, 0xA5, 0xB6, 0x39, 0xA8, 0xF1, 0xD2, 0xB2, 0x46, 0x7E, 0x3C
    .byte 0xF1, 0x9C, 0x34, 0xB2, 0xA3, 0xD8, 0x27, 0x5E, 0x6B, 0x4E, 0x93, 0xF7, 0x9C, 0x21, 0xA5, 0x7D
    .byte 0xE7, 0xB1, 0xD4, 0x9A, 0x31, 0xF6, 0xC7, 0xE8, 0x84, 0xA9, 0x2D, 0x6B, 0x4F, 0x27, 0xE3, 0xA9
    .byte 0xA9, 0xC6, 0xF3, 0xD1, 0x57, 0xB4, 0xE2, 0x9F, 0x1D, 0x9A, 0x83, 0xC7, 0x6E, 0x23, 0xF4, 0xB8
    .byte 0xB4, 0x7A, 0x1D, 0x92, 0xF8, 0xC6, 0x39, 0xE1, 0x21, 0xA7, 0xB6, 0xC4, 0x7D, 0x3E, 0x9F, 0x2A
    .byte 0xB4, 0xC8, 0x9A, 0x76, 0x9E, 0x3F, 0x21, 0xD6, 0xA6, 0x3F, 0x1B, 0x49, 0xE7, 0xB9, 0xC8, 0xA2
    .byte 0x49, 0x37, 0xD2, 0xE6, 0xB2, 0xF1, 0xA8, 0xC9, 0x3C, 0x7D, 0x92, 0xF4, 0x1A, 0x4E, 0x6B, 0x39
    .byte 0x84, 0xB2, 0xF9, 0xC1, 0x57, 0xA3, 0xD6, 0xE8, 0x2F, 0x1B, 0x6C, 0x93, 0x93, 0xE7, 0xA4, 0xD2
    .byte 0x4B, 0x8C, 0x1A, 0x79, 0x7F, 0x2A, 0x6E, 0x39, 0xA9, 0x2D, 0x4F, 0x6C, 0x1C, 0x7B, 0x39, 0xE2
    .byte 0xF8, 0x4A, 0x9D, 0x6B, 0x6E, 0x2F, 0x1C, 0x93, 0xB7, 0xD4, 0xE9, 0xA3, 0x21, 0xF6, 0xC8, 0xB2
    .byte 0xA4, 0xD2, 0x9C, 0x7F, 0x5E, 0x3B, 0x1F, 0x94, 0x9A, 0x76, 0xE3, 0xF2, 0x4C, 0x8A, 0x21, 0xD7

table_idx: .byte 0

# initialize snake last so other data is stored before snake in memory
snake: # 3 block long snake (position y, position x)
# head index is always the first word at the location of snake array
.word 0x00050008  # Position (5, 8)
.word 0x00050007  # Position (5, 7)
.word 0x00050006  # Position (5, 6)

.text
.eqv BTNS_ADDR, 0x11000060 # note that the last btns[0] up, btns[1] right, btns[2] down, btsn[3] left
.eqv SSEG_ADDR, 0x11000040
.eqv VG_ADDR, 0x11000120
.eqv VG_COLOR, 0x11000140
.eqv BG_COLOR, 0x555          #should be some type of grey
.eqv COLUMNS 160
.eqv ROWS 120

li sp, 0x10000 # stack pointer at 0x10_000
li s9, 0 #score

li s0, COLUMNS
li s1, ROWS

li s2, VG_ADDR     #load MMIO addresses 
li s3, VG_COLOR

#ISR PREP######################################
la t0, read_buttons_ISR # load isr addr
csrrw zero, mtvec, t0 # save isr to mtvec

# set mstatus bit 3 to 1
li t0, 0x8
csrrs zero, mstatus, t0
###############################################

j dead # reset all things

game_loop:


    set_new_head_pos:
        # Load the current direction
        la t0, direction       # Load address of direction
        lw t1, 0(t0)           # Load the current direction into t1

        # Load the current head position
        la t2, snake           # Load the base address of the snake array (head is at the first position)
        lw t3, 0(t2)           # Load the current head position into t3

        # Decode the current head position (row, col)
        srli t4, t3, 16        # Extract row (upper 16 bits) into t4
        li t0, 0xffff
        and t5, t3, t0    # Extract col (lower 16 bits) into t5

        # Update the position based on the direction
        # Direction 0: Up (row - 1)
        li t6, 0               # Direction 0
        beq t1, t6, move_up

        # Direction 1: Right (col + 1)
        li t6, 1               # Direction 1
        beq t1, t6, move_right

        # Direction 2: Down (row + 1)
        li t6, 2               # Direction 2
        beq t1, t6, move_down

        # Direction 3: Left (col - 1)
        li t6, 3               # Direction 3
        beq t1, t6, move_left

    move_up:
        addi t4, t4, -1        # Row - 1
        j encode_new_head

    move_right:
        addi t5, t5, 1         # Col + 1
        j encode_new_head

    move_down:
        addi t4, t4, 1         # Row + 1
        j encode_new_head

    move_left:
        addi t5, t5, -1        # Col - 1
        j encode_new_head

    encode_new_head:
        # Encode the new head position (row << 16 | col)
        slli t4, t4, 16        # Shift row to upper 16 bits
        or s11, t4, t5          # Combine row and col into t3 (new head position)

shift_snake:
    # Load the snake length
    la t0, snake_length       # Load address of snake_length
    lw t1, 0(t0)             # Load the snake length into t1 (snake_length)

    # Calculate the starting index of the tail
    addi t2, t1, -1          # t2 = snake_length - 1 (last index in the array)
    slli t2, t2, 2           # Multiply by 4 (word size) to get memory offset

    # Initialize loop variables
    la t3, snake             # Load base address of the snake array
    add t4, t3, t2           # t4 points to the last block of the snake (tail position)
    lw s10, 0(t4)
# currently chops off the tail, though
shift_loop:
    # Check if we've processed all body segments
    ble t4, t3, insert_head  # If t4 <= base address of snake, we're done shifting

    # Copy the value from the previous position to the current position
    lw t5, -4(t4)            # Load the value from the previous position
    sw t5, 0(t4)             # Store it at the current position

    # Move t4 to the previous position (step backward in the array)
    addi t4, t4, -4          # Decrement address by 4 bytes (word size)

    j shift_loop             # Repeat until all segments are shifted

insert_head:
    # Insert the new head position at the front of the array
    la t0, snake             # Load the base address of the snake array
    sw s11, 0(t0)             # Store the new head position at the front

check_bounds:
    # load head position row (encoded as row << 16 | col) in s11
    srli t0, s11, 16
    # load head position col (encoded as row << 16 | col) in s11
    li t1, 0xFFFF            # Load a mask for the lower 16 bits into t1
    and t1, s11, t1          # Mask s11 with 0xFFFF, store the result in t1 (col)

    chk_max_horiz: # col > 15
        li t2, 15
        bgt t1, t2, dead
    check_min_horiz: # col < 0
        li t2, 0
        blt t1, t2, dead
    chk_max_vert: # row > 11
        li t2, 11
        bgt t0, t2, dead
    chk_min_vert: # row < 0
        li t2, 0
        blt t0, t2, dead
check_hit_self:
    la t0, snake
    lw t1, 0(t0) # snake head value

    la t2, snake_length
    lw t3, 0(t2) # snake length value
    slli t3, t3, 2 # x4 for the snake length per word

    li t4, 4 # offset per word
    head_in_snake:
        # t4<t3 keep looping, else we end
        bge t4, t3, check_ate_appl

        add t2, t4, t0 # location of the block at index t4
        lw t2, 0(t2) # coord pair of the block
        beq s11, t2, dead # if the coord pair is = to the head's coord pair
        addi t4, t4, 4

        j head_in_snake
    
check_ate_appl:
    la t0, apple
    lw t0, 0(t0) # the apple's coord pair
    beq t0, s11, grow_snake # if apple coords = head coords
    j end_collision_checks

grow_snake:
    # increase score in sseg
    addi s9, s9, 1

    # rest of grow snake
    la t0, snake
    la t1, snake_length
    lw t2, 0(t1)
    slli t2, t2, 2 # x4 for offset for where to place the tail
    add t3, t0, t2 # the calculated location in the arry to place the tail
    mv t4, s10  # register that stores tail position is moved to t4
    sw t4, 0(t3)

    # increment snake length
    la t1, snake_length
    lw t2, 0(t1)
    addi t2, t2, 1
    sw t2, 0(t1)

    jal scale_apple_coords

    j end_collision_checks
    
dead: # reset everyting
    li sp, 0x10000 # stack pointer at 0x10_000
    li ra, 0x0 # reset ra pointer

    #reset buttons address
    li t0, BTNS_ADDR
    sw zero, 0(t0)

    # reset new head, old tail, score
    li s11, 0xdeadbeef
    li s10, 0xdeadbeef
    li s9, 0

    # reset apple to be to the right of snake(hardcoded)
    la t0, apple
    li t1, 0x0005000c
    sw t1, 0(t0)

    # reset direction to right 
    la t0, direction
    li t1, 0x1
    sw t1, 0(t0)

    # reset snake length to 3
    la t0, snake_length
    li t1, 3
    sw t1, 0(t0)

    # reset snake
    la t0, snake
    li t1, 0x00050008
    li t2, 0x00050007
    li t3, 0x00050006
    sw t1, 0(t0)
    sw t2, 4(t0)
    sw t3, 8(t0)

    # reset table index to 0
    la t0, table_idx
    li t1, 0
    sw t1, 0(t0)

    j game_loop



end_collision_checks:
    jal draw_background


    # Draw red border (RGB: 12'hF00)
    li a3, 0xF00       # Red color
    li a0, 0           # Start at x = 0
    li a1, 0           # Start at y = 0
    addi a2, s0,-1   # End at the last column (horizontal line)

    # Top border
    call draw_horizontal_line

    # Bottom border
    li a0, 0 # reset x coord
    addi a1, s1,-1      # Move to the last row
    call draw_horizontal_line

    # Left border
    li a0, 0           # X = 0
    li a1, 0           # Reset Y to the top
    addi a2, s1-1      # End at the bottom row
    call draw_vertical_line

    # Right border
    addi a0, s0,-1   # Move to the last column
    li a1, 0           # Reset Y to the top
    addi a2, s1, -1      # End at the bottom row
    call draw_vertical_line


    la t0, apple
    lw t1, 0(t0)
    # load apple position row (encoded as row << 16 | col) in s11
    srli a1, t1, 16
    # load apple position col (encoded as row << 16 | col) in s11
    li t2, 0xFFFF            # Load a mask for the lower 16 bits into t1
    and a0, t1, t2 

    li a3, 0xf00 # red
    jal draw_block


    la t0, snake_length
    lw t0, 0(t0) # snake length
    slli t0, t0, 2 # snake length in bytes, which is word*4

    la t1, snake # snake addr
    li t2, 0 # offset, in bytes, increments by 4 each loop
    draw_snake:
        # draw snake
        add t3, t2, t1 # block location
        lw t4, 0(t3) # the coordinate pair
        srli a1, t4, 16 # load head position row (encoded as row << 16 | col) in s11
        li t5, 0xFFFF   # Load a mask for the lower 16 bits into t1
        and a0, t5, t4  # load head position col (encoded as row << 16 | col) in s11
        li a3, 0x0f0 # green

        addi t2, t2, 4
        bgt t2, t0, exit
        jal draw_block
        j draw_snake
    exit:
        # write out score
        li t0, SSEG_ADDR
        sw s9, 0(t0)

    clock_divider:
        # Load the total number of iterations into a register
        li t0, 2500000    # Total number of iterations (2,500,000)

        delay_loop:
            addi t0, t0, -1  # Decrement the counter by 1
            bnez t0, delay_loop  # If t0 != 0, branch back to delay_loop

        j game_loop


# subroutine: scale_apple_coords
# description: generate apple coordinates 0-15x, 0-11y. it checks if apple is inside snake, if it is, regenerate location
# inputs: none
# outputs: none, but we store apple coords in memory
scale_apple_coords:
    # Generate random row
    call rng                # Generate random number
    li a1, 11               # Set row limit (12 rows)
    call div_and_rem        # Scale RNG output
    mv t0, a1               # t0 = scaled row (remainder)

    # Generate random column
    call rng                # Generate random number
    li a1, 15               # Set column limit (16 columns)
    call div_and_rem        # Scale RNG output
    mv t2, a1               # t2 = scaled column (remainder)

    # Combine row and column into a single coordinate
    slli t0, t0, 16          # Shift row left by 4 bits (multiplied by 16)
    or a0, t2, t0           # Combine row and column into t2
 
    call chk_appl_in_snake  # Check if apple overlaps with snake
    move_on:
        la t0, apple
        sw a0, 0(t0)
        
        j end_collision_checks

chk_appl_in_snake:
    
    la t0, snake
    lw t1, 0(t0) # snake head value

    la t2, snake_length
    lw t3, 0(t2) # snake length value
    slli t3, t3, 2 # x4 for the snake length per word

    li t4, 0 # offset per word
    apple_in_snake:
        add t2, t4, t0 # location of the block at index t4
        lw t2, 0(t2) # coord pair of the block
        beq a0, t2, scale_apple_coords
        addi t4, t4, 4

        # t4<=t3 keep looping, else we end
        bgt t4, t3, move_on
        j apple_in_snake


# subroutine: rng
# description: generates a random number in the format of 0xff
# inputs: none
# outputs: a0 in the style of a 8 bit hex number
rng: 
    addi sp, sp, -24
    sw t0, 0(sp)            # Save t0 to stack
    sw t1, 4(sp)            # Save t1 to stack
    sw t2, 8(sp)            # Save t2 to stack
    sw t3, 12(sp)           # Save t3 to stack
    sw t4, 16(sp)           # Save t4 to stack
    sw t5, 20(sp)

    la t0, table_idx       # Load address of table_idx
    lbu t1, 0(t0)           # Load the current index

    la t2, table           # Load base address of table
    add t3, t2, t1         # Compute table address + index

    lbu t4, 0(t3)           # Load the value from the table at the computed address

    # Increment the index
    addi t1, t1, 1         # Increment index
    li t5, 230             # Maximum index value 230
    bgt t1, t5, max_table  # If index > 230, jump to max_table
    sb t1, 0(t0)           # Store the updated index
    j end_rng              # Skip resetting index

max_table:
    li t1, 0               # Reset index to 0
    sb t1, 0(t0)           # Store the reset index

end_rng:
    mv a0, t4              # Move the random value to a0 for return
    lw t4, 16(sp)           # Restore t4 from stack
    lw t3, 12(sp)           # Restore t3 from stack
    lw t2, 8(sp)            # Restore t2 from stack
    lw t1, 4(sp)            # Restore t1 from stack
    lw t0, 0(sp)            # Restore t0 from stack
    addi sp, sp, 24
    ret                    # Return


# subroutine: div_and_rem
# description: divides two numbers and gets result and remainder. do not divide by 0 or use signed numbers here
# inputs: a0, a1 (a0/a1)
# outputs: a0(quotient), a1(remainder)
div_and_rem:
    addi sp, sp, -4
    sw t1, 0(sp)
    li t1, 0
    div_and_rem_loop: 
        bge a0, a1, div_and_rem_continue      # if dividend >= divisor, continue division
        j div_and_rem_end                     # otherwise, jump to end
    div_and_rem_continue:
        sub a0, a0, a1            # subtract dividend-=divisor
        addi t1, t1, 1            # increment quotient
        j div_and_rem_loop                    # repeat loop
        
    div_and_rem_end:
        mv a1, a0                 # Store the remainder in a1 (final dividend)
        mv a0, t1                 # Store the quotient in a0
        lw t1, 0(sp)
        addi sp, sp, 4
        ret


# draw block, at a0 col, a1 row, color is a3
draw_block:
    addi sp, sp, -40
    sw a0, 0(sp)
    sw a1, 4(sp)
    sw a2, 8(sp)
    sw t0, 12(sp)
    sw t1, 16(sp)
    sw t2, 20(sp)
    sw t3, 24(sp)
    sw t4, 28(sp)
    sw ra, 32(sp)
    sw t6, 36(sp)


    # scale start coords
    slli t0, a0, 3 # a0 multiply by 8
    slli t1, a0, 1 # a0 multiply by 2
    add a0, t0, t1

    mv t2, a0

    slli t0, a1, 3 # a1 multiply by 8
    slli t1, a1, 1 # a1 multiply by 2
    add a1, t0, t1
    mv t6, a1   # save og top row coords

    # get end col coord 
    addi a2, a0, 9 # we starting at coord->coord+9, 10 blocks wide
    
    li t3, 0# set count
    li t4, 10 # max count
    draw_block_loop:
        call draw_horizontal_line
        mv a0, t2
        addi a1, a1, 1
        addi t3, t3 1
        blt t3, t4, draw_block_loop

    # draw a cyan square
    mv t0, a3
    li a3, 0x0ff
    
    # bottom line
    mv a0, t2
    mv a1, t6
    addi a1, a1, 9
    addi a2, a0, 9 # we starting at coord->coord+9, 10 blocks wide
    call draw_horizontal_line

    # top line
    mv a0, t2
    mv a1, t6
    addi a2, a0, 9 # we starting at coord->coord+9, 10 blocks wide
    call draw_horizontal_line
    
    # left vertical line
    mv a0, t2
    addi a1, a1, 0
    addi a2, a1, 9
    call draw_vertical_line

    # right vertical line
    mv a0, t2
    addi a0, a0, 9 # move to the right
    addi a1, a1, -9 # reset start y coord to 0
    call draw_vertical_line

    mv a3, t0
    lw a0, 0(sp)
    lw a1, 4(sp)
    lw a2, 8(sp)
    lw t0, 12(sp)
    lw t1, 16(sp)
    lw t2, 20(sp)
    lw t3, 24(sp)
    lw t4, 28(sp)
    lw ra, 32(sp)
    lw t6, 36(sp)
    addi sp, sp, 40
    ret


# draws a dot on the display at the given coordinates:
# (X,Y) = (a0,a1) with a color stored in a3
# (col, row) = (a0,a1)
# Modifies (directly or indirectly): t0, t1
draw_dot:
    addi sp, sp, -12
    sw t1, 0(sp)
    sw t0, 4(sp)
    sw ra, 8(sp)

    andi t0,a0,0xFF    # select bottom 8 bits (col)
    andi t1,a1,0x7F    # select bottom 7 bits  (row)
    slli t1,t1,8    #  {a1[6:0],a0[7:0]} 
    or t0,t1,t0        # 15-bit address
    sw t0, 0(s2)    # write 15 address bits to register
    sw a3, 0(s3)    # write color data to frame buffer

    lw t1, 0(sp)
    lw t0, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    ret


# Fills the 60x80 grid with one color using successive calls to draw_horizontal_line
# Modifies (directly or indirectly): t0, t1, t4, a0, a1, a2, a3
draw_background:
    addi sp,sp,-4
    sw ra, 0(sp)
    li a3, BG_COLOR    # use default color
    li a1, 0    # a1= row_counter
    li t4, ROWS     # max rows
    li a2, COLUMNS     # total number of columns
    addi a2, a2, -1 # last column index
start:    li a0, 0
    call draw_horizontal_line  # must not modify: t4, a1, a3
    addi a1,a1, 1
    bne t4,a1, start    #branch to draw more rows
    lw ra, 0(sp)
    addi sp,sp,4
    ret


# draws a horizontal line from (a0,a1) to (a2,a1) using color in a3
# Modifies (directly or indirectly): a0
draw_horizontal_line:
    addi sp,sp,-8
    sw ra, 0(sp)
    sw a0, 4(sp)
draw_horiz1:
    call draw_dot  # must not modify: a0, a1, a2, a3
    addi a0,a0,1
    ble a0,a2, draw_horiz1
    lw ra, 0(sp)
    lw a0, 4(sp)
    addi sp,sp,8
    ret

# Draws a vertical line from (a0, a1) to (a0, a2) using color in a3
# Modifies: a1
draw_vertical_line:
    addi sp, sp, -4
    sw ra, 0(sp)
vertical_loop:
    call draw_dot      # Must not modify a0, a3
    addi a1, a1, 1
    ble a1, a2, vertical_loop
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

read_buttons_ISR:
    # Load the BTNS register
    li s8, BTNS_ADDR      # Address of BTNS
    lw s8, 0(s8)           # Load button states into s8

    # stack prep
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)

    mv t1, s8

    # Check for no button press
    beqz t1, endpresses    # If no buttons are pressed, jump to default movement

    # Check for Up (btns[0], bit 0)
    andi t2, t1, 0x1       # Mask bit 0 (Up button)
    bnez t2, update_up     # If Up is pressed, jump to update_up

    # Check for Right (btns[1], bit 1)
    andi t2, t1, 0x2       # Mask bit 1 (Right button)
    bnez t2, update_right  # If Right is pressed, jump to update_right

    # Check for Down (btns[2], bit 2)
    andi t2, t1, 0x4       # Mask bit 2 (Down button)
    bnez t2, update_down   # If Down is pressed, jump to update_down

    # Check for Left (btns[3], bit 3)
    andi t2, t1, 0x8       # Mask bit 3 (Left button)
    bnez t2, update_left   # If Left is pressed, jump to update_left

    # If no valid button was pressed (fallback case)
    j endpresses
        
    update_left:
        li t2, 3             # Direction for left
        la t3, direction     # Load address of DIRECTION variable
        sw t2, 0(t3)         # Update DIRECTION = 3
        j endpresses         # Jump to endpresses

    update_right:
        li t2, 1             # Direction for right
        la t3, direction     # Load address of DIRECTION variable
        sw t2, 0(t3)         # Update DIRECTION = 1
        j endpresses         # Jump to endpresses

    update_up:
        li t2, 0             # Direction for up
        la t3, direction     # Load address of DIRECTION variable
        sw t2, 0(t3)         # Update DIRECTION = 0
        j endpresses         # Jump to endpresses

    update_down:
        li t2, 2             # Direction for down
        la t3, direction     # Load address of DIRECTION variable
        sw t2, 0(t3)         # Update DIRECTION = 2
        j endpresses         # Jump to endpresses
endpresses:
    # unstack the stack
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    addi sp, sp, 16
    mret
    