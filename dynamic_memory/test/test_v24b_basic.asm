; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../vector_24bit.asm"

vec_a:
   .res 2
entry_a:
   .res 3

start:
   START_TEST

   ; create a new vector
   jsr v24b::new
   sta vec_a
   stx vec_a+1
   ; check basic pointer properties
   EXPECT_EQ 1
   EXPECT_LE heap_max_ram_bank
   txa
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)

   ; should be empty
   lda vec_a
   ldx vec_a+1
   jsr v24b::is_empty
   EXPECT_CARRY_SET
   jsr v24b::get_first_entry
   EXPECT_CARRY_SET

   ; append an element
   lda #$42
   sta v24b::value_l
   lda #$45
   sta v24b::value_m
   lda #$49
   sta v24b::value_h
   lda vec_a
   ldx vec_a+1
   jsr v24b::append_new_entry
   EXPECT_CARRY_CLEAR

   ; vector shouldn't be empty anymore
   lda vec_a
   ldx vec_a+1
   jsr v24b::is_empty
   EXPECT_CARRY_CLEAR
   ; is_empty shouldn't mess with the input
   EXPECT_EQ_MEM vec_a
   txa
   EXPECT_EQ_MEM vec_a+1

   ; check out first entry
   lda vec_a
   ldx vec_a+1
   jsr v24b::get_first_entry
   EXPECT_EQ 0 ; index should be 0
   tya
   EXPECT_EQ_MEM vec_a
   txa
   EXPECT_EQ_MEM vec_a+1

   lda vec_a
   ldx vec_a+1
   jsr v24b::get_first_entry
   jsr v24b::is_first_entry
   EXPECT_CARRY_SET
   ; is_first_entry shouldn't mess with the input
   EXPECT_EQ 0 ; index should be 0
   tya
   EXPECT_EQ_MEM vec_a
   txa
   EXPECT_EQ_MEM vec_a+1

   lda vec_a
   ldx vec_a+1
   jsr v24b::get_first_entry
   jsr v24b::is_last_entry
   EXPECT_CARRY_SET
   ; is_last_entry shouldn't mess with the input
   EXPECT_EQ 0 ; index should be 0
   tya
   EXPECT_EQ_MEM vec_a
   txa
   EXPECT_EQ_MEM vec_a+1

   ; check content
   lda vec_a
   ldx vec_a+1
   jsr v24b::get_first_entry
   stz v24b::value_l
   stz v24b::value_m
   stz v24b::value_h
   jsr v24b::read_entry
   lda v24b::value_l
   EXPECT_EQ $42
   lda v24b::value_m
   EXPECT_EQ $45
   lda v24b::value_h
   EXPECT_EQ $49

   ; add another entry
   lda #$52
   sta v24b::value_l
   lda #$55
   sta v24b::value_m
   lda #$59
   sta v24b::value_h
   lda vec_a
   ldx vec_a+1
   jsr v24b::append_new_entry

   ; check basic properties of vector with 2 entries
   lda vec_a
   ldx vec_a+1
   jsr v24b::is_empty
   EXPECT_CARRY_CLEAR
   jsr v24b::get_first_entry
   jsr v24b::is_first_entry
   EXPECT_CARRY_SET
   jsr v24b::is_last_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::get_next_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::is_first_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::is_last_entry
   EXPECT_CARRY_SET
   sta entry_a
   stx entry_a+1
   sty entry_a+2

   ; check contents of second entry
   stz v24b::value_l
   stz v24b::value_m
   stz v24b::value_h
   jsr v24b::read_entry
   lda v24b::value_l
   EXPECT_EQ $52
   lda v24b::value_m
   EXPECT_EQ $55
   lda v24b::value_h
   EXPECT_EQ $59
   ; write content of second entry
   lda #$62
   sta v24b::value_l
   lda #$65
   sta v24b::value_m
   lda #$69
   sta v24b::value_h
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v24b::write_entry

   ; check contents of first and second entries
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v24b::get_previous_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::read_entry
   lda v24b::value_l
   EXPECT_EQ $42
   lda v24b::value_m
   EXPECT_EQ $45
   lda v24b::value_h
   EXPECT_EQ $49
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v24b::read_entry
   lda v24b::value_l
   EXPECT_EQ $62
   lda v24b::value_m
   EXPECT_EQ $65
   lda v24b::value_h
   EXPECT_EQ $69


   ; check positive carry flags on get_next_entry and get_previous_entry
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v24b::get_next_entry
   EXPECT_CARRY_SET
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v24b::get_previous_entry
   EXPECT_CARRY_CLEAR
   jsr v24b::get_previous_entry
   EXPECT_CARRY_SET


   FINISH_TEST
   rts
