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
   EXPECT_EQ 1
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
   dec
   cmp pointers_high, y
   EXPECT_ZERO_SET
:

   inc loop_variable
   lda loop_variable
   cmp #32
   bne @allocation_loop

   ; now we should move on to the next memory bank
   jsr heap::allocate_chunk
   EXPECT_EQ 2
   txa
   EXPECT_EQ >RAM_WIN

   FINISH_TEST
   rts
