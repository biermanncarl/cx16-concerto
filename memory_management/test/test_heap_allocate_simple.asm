; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_min_ram_bank = 3
.include "../heap.asm"

start:
   START_TEST

   jsr heap::allocate_chunk
   EXPECT_CFC
   EXPECT_GE heap_min_ram_bank
   EXPECT_LE 63
   txa
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)

   FINISH_TEST
   rts
