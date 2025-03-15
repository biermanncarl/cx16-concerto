; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_max_ram_bank = 17 ; goal: have more than 256 chunks
.include "../heap.asm"

loop_variable:
   .word 0

num_chunks = 32 * heap_max_ram_bank

start:
   START_TEST

@allocation_loop:
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR
   ldy loop_variable
   EXPECT_GE 1
   EXPECT_LE heap_max_ram_bank
   txa
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)

@skip_pointer:

   inc loop_variable
   bne :+
   inc loop_variable+1
:
   lda loop_variable+1
   cmp #>num_chunks
   bne @allocation_loop
   lda loop_variable
   cmp #<num_chunks
   bne @allocation_loop

   ; now we should have filled up the heap.
   jsr heap::allocate_chunk
   EXPECT_CARRY_SET ; carry should be set to indicate that memory is full

   FINISH_TEST
   rts
