; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_max_ram_bank = 2 ; limit to two pages of memory -> maximum 64 chunks
.include "../vector_5bytes.asm"

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

num_entries = v5b::max_entries_per_chunk+1

.macro EXPECT_ENTRY_EQUAL_TO v0, v1, v2, v3, v4
   pha
   phx
   phy
   stz v5b::value_0
   stz v5b::value_1
   stz v5b::value_2
   stz v5b::value_3
   stz v5b::value_4
   jsr v5b::read_entry
   lda v5b::value_0
   EXPECT_EQ v0
   lda v5b::value_1
   EXPECT_EQ v1
   lda v5b::value_2
   EXPECT_EQ v2
   lda v5b::value_3
   EXPECT_EQ v3
   lda v5b::value_4
   EXPECT_EQ v4
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
   jsr v5b::new
   EXPECT_CARRY_CLEAR
   sta vec_a
   stx vec_a+1

   ; append the first entry
   lda #$42
   sta v5b::value_0
   lda #$45
   sta v5b::value_1
   lda #$49
   sta v5b::value_2
   lda #$4B
   sta v5b::value_3
   lda #$4E
   sta v5b::value_4
   lda vec_a
   ldx vec_a+1
   jsr v5b::append_new_entry

   lda #(num_entries-1)
   sta loop_variable
@insert_loop:
   lda loop_variable
   ; generate unique(ish) values to fill into the vector
   sta v5b::value_0
   asl
   sta v5b::value_1
   asl
   sta v5b::value_2
   asl
   clc
   adc loop_variable
   sta v5b::value_3
   asl
   clc
   adc loop_variable
   sta v5b::value_4
   lda vec_a
   ldx vec_a+1
   jsr v5b::get_first_entry
   jsr v5b::insert_entry
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @insert_loop


   ; Now check the content of the vector
   lda vec_a
   ldx vec_a+1
   ; check first entry
   jsr v5b::get_first_entry
   jsr v5b::is_first_entry
   EXPECT_CARRY_SET
   jsr v5b::is_last_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::get_next_entry
   pha
   phx
   phy
   jsr v5b::get_previous_entry
   EXPECT_ENTRY_EQUAL_TO 1, 2, 4, 9, 19
   lda #2
   sta loop_variable

@check_loop:
   ; expecting pointer to the next entry on the stack
   ply
   plx
   pla
   ; check basic properties of entry
   jsr v5b::is_last_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::is_first_entry
   EXPECT_CARRY_CLEAR
   ; push pointer to the next entry to the stack
   jsr v5b::get_next_entry
   EXPECT_CARRY_CLEAR
   pha
   phx
   phy
   ; now go back to the current entry and investigate further
   jsr v5b::get_previous_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::read_entry
   lda loop_variable
   EXPECT_EQ_MEM v5b::value_0
   asl
   EXPECT_EQ_MEM v5b::value_1
   asl
   EXPECT_EQ_MEM v5b::value_2
   asl
   clc
   adc loop_variable
   EXPECT_EQ_MEM v5b::value_3
   asl
   clc
   adc loop_variable
   EXPECT_EQ_MEM v5b::value_4

   lda loop_variable
   inc
   sta loop_variable
   cmp #(num_entries)
   beq :+
   jmp @check_loop
:
   ply
   plx
   pla
   ; check last entry
   EXPECT_ENTRY_EQUAL_TO $42, $45, $49, $4B, $4E
   jsr v5b::is_first_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::is_last_entry
   EXPECT_CARRY_SET


   FINISH_TEST
   rts
