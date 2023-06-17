; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../vector_40bit.asm"

vec_a:
   .res 2

.macro EXPECT_ENTRY_EQUAL_TO v0, v1, v2, v3, v4
   pha
   phx
   phy
   stz v40b::value_0
   stz v40b::value_1
   stz v40b::value_2
   stz v40b::value_3
   stz v40b::value_4
   jsr v40b::read_entry
   lda v40b::value_0
   EXPECT_EQ v0
   lda v40b::value_1
   EXPECT_EQ v1
   lda v40b::value_2
   EXPECT_EQ v2
   lda v40b::value_3
   EXPECT_EQ v3
   lda v40b::value_4
   EXPECT_EQ v4
   ply
   plx
   pla
.endmacro

start:
   START_TEST

   ; create a new vector
   jsr v40b::new
   sta vec_a
   stx vec_a+1

   ; append the first entry
   lda #$42
   sta v40b::value_0
   lda #$45
   sta v40b::value_1
   lda #$49
   sta v40b::value_2
   lda #$4B
   sta v40b::value_3
   lda #$4E
   sta v40b::value_4
   lda vec_a
   ldx vec_a+1
   jsr v40b::append_new_entry

   ; now insert another entry in front of it
   lda #$52
   sta v40b::value_0
   lda #$55
   sta v40b::value_1
   lda #$59
   sta v40b::value_2
   lda #$5B
   sta v40b::value_3
   lda #$5E
   sta v40b::value_4
   lda vec_a
   ldx vec_a+1
   jsr v40b::get_first_entry
   pha
   phx
   phy
   jsr v40b::insert_entry
   EXPECT_CARRY_CLEAR

   ; check basic properties of the vector
   ply
   plx
   pla
   jsr v40b::is_first_entry
   EXPECT_CARRY_SET
   jsr v40b::is_last_entry
   EXPECT_CARRY_CLEAR
   EXPECT_ENTRY_EQUAL_TO $52, $55, $59, $5B, $5E
   jsr v40b::get_next_entry
   EXPECT_CARRY_CLEAR
   jsr v40b::is_first_entry
   EXPECT_CARRY_CLEAR
   jsr v40b::is_last_entry
   EXPECT_CARRY_SET
   EXPECT_ENTRY_EQUAL_TO $42, $45, $49, $4B, $4E

   ; insert another element
   pha
   lda #$62
   sta v40b::value_0
   lda #$65
   sta v40b::value_1
   lda #$69
   sta v40b::value_2
   lda #$6B
   sta v40b::value_3
   lda #$6E
   sta v40b::value_4
   pla
   jsr v40b::insert_entry
   EXPECT_CARRY_CLEAR

   ; now go through the vector and check each element
   lda vec_a
   ldx vec_a+1
   jsr v40b::get_first_entry
   jsr v40b::is_first_entry
   EXPECT_CARRY_SET
   jsr v40b::is_last_entry
   EXPECT_CARRY_CLEAR
   EXPECT_ENTRY_EQUAL_TO $52, $55, $59, $5B, $5E

   jsr v40b::get_next_entry
   jsr v40b::is_first_entry
   EXPECT_CARRY_CLEAR
   jsr v40b::is_last_entry
   EXPECT_CARRY_CLEAR
   EXPECT_ENTRY_EQUAL_TO $62, $65, $69, $6B, $6E

   jsr v40b::get_next_entry
   jsr v40b::is_first_entry
   EXPECT_CARRY_CLEAR
   jsr v40b::is_last_entry
   EXPECT_CARRY_SET
   EXPECT_ENTRY_EQUAL_TO $42, $45, $49, $4B, $4E

   FINISH_TEST
   rts
