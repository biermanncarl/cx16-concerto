; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_max_ram_bank = 2 ; limit to two pages of memory -> maximum 64 chunks
.include "../heap.asm"

loop_variable:
   .byte 0
pointers_bank:
   .res heap_max_ram_bank * 32 + 1
pointers_high:
   .res heap_max_ram_bank * 32 + 1


start:
   START_TEST

@allocation_loop:
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR
   ldy loop_variable
   sta pointers_bank, y
   EXPECT_GE 1
   EXPECT_LE heap_max_ram_bank
   txa
   sta pointers_high, y
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)

   ; compare pointer to previous one (should be different)
   lda pointers_high, y
   cpy #0
   beq :+ ; skip for first pointer
   dey
   cmp pointers_high, y
   EXPECT_ZERO_CLEAR
:

   inc loop_variable
   lda loop_variable
   cmp #64
   bne @allocation_loop

   ; now we should have filled up the heap.
   jsr heap::allocate_chunk
   EXPECT_CARRY_SET ; carry should be set to indicate that memory is full

   FINISH_TEST
   rts
