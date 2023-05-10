; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_min_ram_bank = 3
heap_max_ram_bank = 4 ; 64 chunks in total
.include "../heap.asm"

loop_variable:
   .byte 0
chunk_index:
   .byte 0
pointers_bank:
   .res heap_max_ram_bank * 64 + 1
pointers_high:
   .res heap_max_ram_bank * 64 + 1


.proc allocate_all
   stz loop_variable
@loop:
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR
   ldy loop_variable
   sta pointers_bank, y
   txa
   sta pointers_high, y
   iny
   sty loop_variable
   cpy #64
   bne @loop

   ; check if we indeed allocated all of them
   jsr heap::allocate_chunk
   EXPECT_CARRY_SET
   rts
.endproc




start:
   START_TEST

   jsr allocate_all

   ; first, release two chunks
   ldy #0
   lda pointers_high, y
   tax
   lda pointers_bank, y
   jsr heap::release_chunk

   ;.byte $db
   ldy #1
   lda pointers_high, y
   tax
   lda pointers_bank, y
   jsr heap::release_chunk

   ; now there should be room for two more chunks
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR  ; <<<<<<<<<<   THIS FAILS: DEBUG! maybe the logic for first_unused_chunk update is broken?

   ; and allocating one more should fail
   jsr heap::allocate_chunk
   EXPECT_CARRY_SET

   FINISH_TEST
   rts
