; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../vector_24bit.asm"

vec_a:
   .res 2

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

   ; create a new vector
   jsr v24b::new
   sta vec_a
   stx vec_a+1

   ; append a few entries
   lda #$42
   sta v24b::value_l
   lda #$45
   sta v24b::value_m
   lda #$49
   sta v24b::value_h
   lda vec_a
   ldx vec_a+1
   jsr v24b::append_new_entry
   lda #$52
   sta v24b::value_l
   lda #$55
   sta v24b::value_m
   lda #$59
   sta v24b::value_h
   lda vec_a
   ldx vec_a+1
   jsr v24b::append_new_entry

   ; delete the first entry
   lda vec_a
   ldx vec_a+1
   jsr v24b::get_first_entry
   jsr v24b::delete_entry

   ; check basic properties of the vector
   lda vec_a
   ldx vec_a+1
   jsr v24b::get_first_entry
   jsr v24b::is_first_entry
   EXPECT_CARRY_SET
   jsr v24b::is_last_entry
   EXPECT_CARRY_SET
   EXPECT_ENTRY_EQUAL_TO $52, $55, $59

   FINISH_TEST
   rts
