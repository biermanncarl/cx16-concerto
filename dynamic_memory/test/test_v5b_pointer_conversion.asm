; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_max_ram_bank = 2 ; 64 chunks
.include "../vector_5bytes.asm"

loop_variable:
   .res 2
vec_a:
   .res 2

num_entries = 640 ; tickle the high byte a bit

.macro END_LOOP return_point
   inc loop_variable
   bne :+
   inc loop_variable+1
:  ; check for loop end
   lda loop_variable
   cmp #<num_entries
   bne return_point
   lda loop_variable+1
   cmp #>num_entries
   bne return_point
.endmacro

.macro CALL_CONVERT_VECTOR_AND_INDEX_TO_DIRECT_POINTER
   lda loop_variable
   sta v5b::value_0
   lda loop_variable+1
   sta v5b::value_1
   lda vec_a
   ldx vec_a+1
   jsr v5b::convert_vector_and_index_to_direct_pointer
.endmacro

start:
   START_TEST

   ; create a new vector
   jsr v5b::new
   sta vec_a
   stx vec_a+1

   ; We fill a vector with entries whose content is their index
   stz loop_variable
   stz loop_variable+1
@fill_loop:
   lda loop_variable
   sta v5b::value_0
   lda loop_variable+1
   sta v5b::value_1
   lda vec_a
   ldx vec_a+1
   jsr v5b::append_new_entry
   END_LOOP @fill_loop


   ; now go through all entries and check if their content is indeed their index
   stz loop_variable
   stz loop_variable+1
@check_loop:
   CALL_CONVERT_VECTOR_AND_INDEX_TO_DIRECT_POINTER
   EXPECT_CARRY_CLEAR
   ; read entry and check it's the correct one
   jsr v5b::read_entry
   lda v5b::value_0
   EXPECT_EQ_MEM loop_variable
   lda v5b::value_1
   EXPECT_EQ_MEM loop_variable+1
   END_LOOP @check_loop

   ; check out-of-range functionality
   inc loop_variable
   bne :+
   inc loop_variable+1
:  CALL_CONVERT_VECTOR_AND_INDEX_TO_DIRECT_POINTER
   EXPECT_CARRY_SET

   FINISH_TEST
   rts
