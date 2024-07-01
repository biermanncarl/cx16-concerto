; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../vector_5bytes.asm"

vec_a:
   .res 2
entry_a:
   .res 3

start:
   START_TEST

   ; create a new vector
   jsr v5b::new
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
   jsr v5b::is_empty
   EXPECT_CARRY_SET
   jsr v5b::get_first_entry
   EXPECT_CARRY_SET

   ; append an element
   lda #$42
   sta v5b::value_0
   lda #$45
   sta v5b::value_1
   lda #$49
   sta v5b::value_2
   lda #$4B
   sta v5b::value_3
   lda #$4E
   sta v5b::value_4
   lda vec_a
   ldx vec_a+1
   jsr v5b::append_new_entry
   EXPECT_CARRY_CLEAR

   ; vector shouldn't be empty anymore
   lda vec_a
   ldx vec_a+1
   jsr v5b::is_empty
   EXPECT_CARRY_CLEAR
   ; is_empty shouldn't mess with the input
   EXPECT_EQ_MEM vec_a
   txa
   EXPECT_EQ_MEM vec_a+1

   ; check out first entry
   lda vec_a
   ldx vec_a+1
   jsr v5b::get_first_entry
   EXPECT_EQ 0 ; index should be 0
   tya
   EXPECT_EQ_MEM vec_a
   txa
   EXPECT_EQ_MEM vec_a+1

   lda vec_a
   ldx vec_a+1
   jsr v5b::get_first_entry
   jsr v5b::is_first_entry
   EXPECT_CARRY_SET
   ; is_first_entry shouldn't mess with the input
   EXPECT_EQ 0 ; index should be 0
   tya
   EXPECT_EQ_MEM vec_a
   txa
   EXPECT_EQ_MEM vec_a+1

   lda vec_a
   ldx vec_a+1
   jsr v5b::get_first_entry
   jsr v5b::is_last_entry
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
   jsr v5b::get_first_entry
   stz v5b::value_0
   stz v5b::value_1
   stz v5b::value_2
   stz v5b::value_3
   stz v5b::value_4
   jsr v5b::read_entry
   lda v5b::value_0
   EXPECT_EQ $42
   lda v5b::value_1
   EXPECT_EQ $45
   lda v5b::value_2
   EXPECT_EQ $49
   lda v5b::value_3
   EXPECT_EQ $4B
   lda v5b::value_4
   EXPECT_EQ $4E

   ; add another entry
   lda #$52
   sta v5b::value_0
   lda #$55
   sta v5b::value_1
   lda #$59
   sta v5b::value_2
   lda #$5B
   sta v5b::value_3
   lda #$5E
   sta v5b::value_4
   lda vec_a
   ldx vec_a+1
   jsr v5b::append_new_entry

   ; check basic properties of vector with 2 entries
   lda vec_a
   ldx vec_a+1
   jsr v5b::is_empty
   EXPECT_CARRY_CLEAR
   jsr v5b::get_first_entry
   jsr v5b::is_first_entry
   EXPECT_CARRY_SET
   jsr v5b::is_last_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::get_next_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::is_first_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::is_last_entry
   EXPECT_CARRY_SET
   sta entry_a
   stx entry_a+1
   sty entry_a+2

   ; check contents of second entry
   stz v5b::value_0
   stz v5b::value_1
   stz v5b::value_2
   stz v5b::value_3
   stz v5b::value_4
   jsr v5b::read_entry
   lda v5b::value_0
   EXPECT_EQ $52
   lda v5b::value_1
   EXPECT_EQ $55
   lda v5b::value_2
   EXPECT_EQ $59
   lda v5b::value_3
   EXPECT_EQ $5B
   lda v5b::value_4
   EXPECT_EQ $5E
   ; write content of second entry
   lda #$62
   sta v5b::value_0
   lda #$65
   sta v5b::value_1
   lda #$69
   sta v5b::value_2
   lda #$6B
   sta v5b::value_3
   lda #$6E
   sta v5b::value_4
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v5b::write_entry

   ; check contents of first and second entries
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v5b::get_previous_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::read_entry
   lda v5b::value_0
   EXPECT_EQ $42
   lda v5b::value_1
   EXPECT_EQ $45
   lda v5b::value_2
   EXPECT_EQ $49
   lda v5b::value_3
   EXPECT_EQ $4B
   lda v5b::value_4
   EXPECT_EQ $4E
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v5b::read_entry
   lda v5b::value_0
   EXPECT_EQ $62
   lda v5b::value_1
   EXPECT_EQ $65
   lda v5b::value_2
   EXPECT_EQ $69
   lda v5b::value_3
   EXPECT_EQ $6B
   lda v5b::value_4
   EXPECT_EQ $6E


   ; check positive carry flags on get_next_entry and get_previous_entry
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v5b::get_next_entry
   EXPECT_CARRY_SET
   lda entry_a
   ldx entry_a+1
   ldy entry_a+2
   jsr v5b::get_previous_entry
   EXPECT_CARRY_CLEAR
   jsr v5b::get_previous_entry
   EXPECT_CARRY_SET


   FINISH_TEST
   rts
