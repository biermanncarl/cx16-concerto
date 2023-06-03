; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../doubly_linked_list.asm"

list:
   .res 2

loop_variable:
   .byte 0

start:
   START_TEST

   ; ===================
   ; Small Scale Testing
   ; ===================

   jsr dll::create_list
   sta list
   stx list+1
   ; check pointer integrity
   EXPECT_GE heap_min_ram_bank
   EXPECT_LE heap_max_ram_bank
   txa
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)

   ; create new elements
   lda list
   ldx list+1
   jsr dll::append_new_element
   EXPECT_CARRY_CLEAR
   ; should have returned pointer to new element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_SET
   jsr dll::append_new_element
   EXPECT_CARRY_CLEAR

   ; check that first/last elements are correctly identified
   lda list
   ldx list+1
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   jsr dll::get_next_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   jsr dll::get_next_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_SET

   ; go back in the list
   jsr dll::get_previous_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   jsr dll::get_previous_element
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR

   ; first element should be the one we point at
   EXPECT_EQ_MEM list
   txa
   EXPECT_EQ_MEM list+1


   FINISH_TEST
   rts
