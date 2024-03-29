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

loop_variable:
   .byte 0

start:
   START_TEST

   ; prepare by filling the heap with 31 elements (so we will get cross-page links for the tests)
   lda #30 ; if in doubt, vary this number a bit to cover different cases of cross-page deleting
   sta loop_variable
   jsr dll::create_list
@fill_loop_1:
   jsr dll::insert_element_before
   dec loop_variable
   bne @fill_loop_1
   ; and ... ooops, let go of the pointer (aka memory leak) ...

   ; deleting the only element from a list should result in carry set
   jsr dll::create_list
   jsr dll::delete_element
   EXPECT_CARRY_SET


   ; deleting the first element in a two elements list
   ; create a list of two elements
   jsr dll::create_list
   sta list_a
   stx list_a+1
   jsr dll::append_new_element
   ; delete first element
   lda list_a
   ldx list_a+1
   jsr dll::delete_element
   ; do some checks
   EXPECT_CARRY_CLEAR
   lda list_a
   ldx list_a+1
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_SET
   ; tidy up
   lda list_a
   ldx list_a+1
   jsr dll::destroy_list

   ; deleting the second element in a two elements list
   ; create a list of two elements
   jsr dll::create_list
   sta list_a
   stx list_a+1
   jsr dll::append_new_element
   ; store pointer of second element
   sta list_b
   stx list_b+1
   ; delete second element
   jsr dll::delete_element
   EXPECT_CARRY_CLEAR
   ; check that former first element is now the first and last element
   lda list_a
   ldx list_a+1
   jsr dll::is_last_element
   EXPECT_CARRY_SET
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   ; tidy up
   jsr dll::destroy_list


   ; deleting the second element in a three element list
   ; create a list of three elements
   jsr dll::create_list
   sta list_a
   stx list_a+1
   jsr dll::append_new_element
   jsr dll::append_new_element
   ; save third element
   sta list_b
   stx list_b+1
   ; delete second element
   jsr dll::get_previous_element
   jsr dll::delete_element
   EXPECT_CARRY_CLEAR
   ; check the previous element
   lda list_b
   ldx list_b+1
   jsr dll::get_previous_element
   EXPECT_EQ_MEM list_a
   txa
   EXPECT_EQ_MEM list_a+1


   FINISH_TEST
   rts
