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

   ; first, release one chunk to make room for stuff to shuffle around
   ldy #0
   lda pointers_high, y
   tax
   lda pointers_bank, y
   jsr heap::release_chunk

   ; now keep releasing and freeing memory
   lda #70 ; number of loop iterations
   sta loop_variable
   lda #13
   sta chunk_index
@release_allocate_loop:
   ; advance chunk index
   lda chunk_index
   clc
   adc #29 ; prime number for "chaotic" behavior
   and #%00111111 ; wrap around to the range 0 to 63
   bne :+ ; the zeroth pointer was released before this loop, so we cannot release it again
   inc
:  sta chunk_index
   
   ; load the pointer
   tay
   lda pointers_high, y
   tax
   lda pointers_bank, y

   ; release and reallocate (possibly the other remaining chunk)
   jsr heap::release_chunk
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR
   EXPECT_GE heap_min_ram_bank
   EXPECT_LE heap_max_ram_bank
   ldy chunk_index
   sta pointers_bank, y
   txa
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)
   sta pointers_high, y

   ; TODO: check that there are no duplicate pointers

   dec loop_variable
   bne @release_allocate_loop

   ; eventually, check that we preserved the total number of chunks
   jsr heap::allocate_chunk
   EXPECT_CARRY_CLEAR
   jsr heap::allocate_chunk
   EXPECT_CARRY_SET

   FINISH_TEST
   rts
