; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../heap.asm"

start:
   START_TEST

   jsr heap::allocate_chunk
   EXPECT_GE 1
   EXPECT_LE 63
   txa
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)

   FINISH_TEST
   rts
