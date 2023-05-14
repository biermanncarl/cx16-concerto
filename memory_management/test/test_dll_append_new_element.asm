; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../doubly_linked_list.asm"

list_a:
   .res 2

list_b:
   .res 2

start:
   START_TEST

   jsr dll::create_list
   sta list_a
   stx list_a+1
   ; check pointer integrity
   EXPECT_GE heap_min_ram_bank
   EXPECT_LE heap_max_ram_bank
   txa
   EXPECT_GE >RAM_WIN
   EXPECT_LT >(RAM_WIN + RAM_WIN_SIZE)

   ; create new elements
   lda list_a
   ldx list_a+1
   jsr dll::append_new_element
   lda list_a
   ldx list_a+1
   jsr dll::append_new_element

   ; check that first/last elements are correctly identified
   lda list_a
   ldx list_a+1
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
   EXPECT_CARRY_CLEAR     ; THIS TEST FAILS
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   jsr dll::get_previous_element
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR

   ; first element should be the one we point at
   EXPECT_EQ_MEM list_a
   txa
   EXPECT_EQ_MEM list_a+1

   ; TODO: delete entire list, then add more than one RAM bank worth of elements to see whether bank transitions are also done correctly.
   lda list_a
   ldx list_a+1
   jsr dll::destroy_list

   FINISH_TEST
   rts
