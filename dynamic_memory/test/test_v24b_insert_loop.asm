; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_max_ram_bank = 2 ; limit to two pages of memory -> maximum 64 chunks
.include "../vector_24bit.asm"

loop_variable:
   .res 1
vec_a:
   .res 2
entry_a:
   .res 3
chunk_a:
   .res 2
chunk_b:
   .res 2

num_entries = 84

.macro EXPECT_ENTRY_EQUAL_TO l, m, h
   pha
   phx
   phy
   stz v24b::value_l
   stz v24b::value_m
   stz v24b::value_h
   jsr v24b::read_entry
   lda v24b::value_l
   EXPECT_EQ l
   lda v24b::value_m
   EXPECT_EQ m
   lda v24b::value_h
   EXPECT_EQ h
   ply
   plx
   pla
.endmacro

start:
   START_TEST

   ; first, we fill up heap completely, and then release one chunk from each RAM bank to be used by our vector
   ; first chunk (should be on the first bank)
   jsr heap::allocate_chunk
   stx chunk_a+1
   sta chunk_a
   EXPECT_EQ 1 ; should be on RAM bank 1
   ; allocate (and "leak") 62 chunks
   lda #62
   sta loop_variable
@fill_heap_loop:
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @fill_heap_loop
   ; and now allocate the last chunk (which should be on the second RAM bank)
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR ; heap should be full now
   stx chunk_b+1
   sta chunk_b
   EXPECT_EQ 2
   ; confirm the heap is full
   jsr heap::allocate_chunk
   EXPECT_CARRY_SET
   ; now we release the two chunks so that our vector can use them
   lda chunk_a
   ldx chunk_a+1
   jsr heap::release_chunk
   lda chunk_b
   ldx chunk_b+1
   jsr heap::release_chunk


   ; create a new vector
   jsr v24b::new
   EXPECT_CARRY_CLEAR
   sta vec_a
   stx vec_a+1

   ; append the first entry
   lda #$42
   sta v24b::value_l
   lda #$45
   sta v24b::value_m
   lda #$49
   sta v24b::value_h
   lda vec_a
   ldx vec_a+1
   jsr v24b::append_new_entry

   lda #(num_entries-1) ; fails at 124
   sta loop_variable
@insert_loop:
   lda loop_variable
   ; generate unique(ish) values to fill into the vector
   sta v24b::value_l
   asl
   sta v24b::value_m
   asl
   sta v24b::value_h
   lda vec_a
   ldx vec_a+1
   jsr v24b::get_first_entry
   jsr v24b::insert_entry
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @insert_loop


   ; Now check the content of the vector
   lda vec_a
   ldx vec_a+1
   ; check first entry
   jsr v24b::get_first_entry
   jsr v24b::is_first_entry
   EXPECT_CARRY_SET
   jsr v24b::is_last_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::get_next_entry
   pha
   phx
   phy
   jsr v24b::get_previous_entry
   EXPECT_ENTRY_EQUAL_TO 1, 2, 4
   lda #2
   sta loop_variable

@check_loop:
   ; expecting pointer to the next entry on the stack
   ply
   plx
   pla
   ; check basic properties of entry
   jsr v24b::is_last_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::is_first_entry
   EXPECT_CARRY_CLEAR
   ; push pointer to the next entry to the stack
   jsr v24b::get_next_entry
   EXPECT_CARRY_CLEAR
   pha
   phx
   phy
   ; now go back to the current entry and investigate further
   jsr v24b::get_previous_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::read_entry
   lda loop_variable
   EXPECT_EQ_MEM v24b::value_l
   asl
   EXPECT_EQ_MEM v24b::value_m
   asl
   EXPECT_EQ_MEM v24b::value_h

   lda loop_variable
   inc
   sta loop_variable
   cmp #(num_entries)
   bne @check_loop
   ply
   plx
   pla
   ; check last entry
   EXPECT_ENTRY_EQUAL_TO $42, $45, $49
   jsr v24b::is_first_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::is_last_entry
   EXPECT_CARRY_SET


   FINISH_TEST
   rts
