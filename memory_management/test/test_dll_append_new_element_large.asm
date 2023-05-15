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

num_elements = 67

start:
   START_TEST

   ; ===================
   ; Large Scale Testing
   ; ===================

   jsr dll::create_list
   sta list_a
   stx list_a+1

   ; add several pages worth of list elements
   lda #(num_elements - 1) ; subtract initial element
   sta loop_variable
@append_loop:
   lda list_a
   ldx list_a+1
   jsr dll::append_new_element
   dec loop_variable
   bne @append_loop

   ; now check what we've got
   ; go through complete list from beginning to end
   lda #(num_elements - 2) ; leave out first and last element in the loop
   sta loop_variable
   ; check first element
   lda list_a
   ldx list_a+1
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   ; check all except first and last element
@test_forward_loop:
   jsr dll::get_next_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @test_forward_loop
   ; check last element
   jsr dll::get_next_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_SET
   ; remember last element
   sta list_b
   stx list_b+1

   ; go through complete list from end to beginning
   lda #(num_elements - 2) ; leave out first and last element in the loop
   sta loop_variable
   ; check last element
   lda list_b
   ldx list_b+1
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_SET
   ; check all except first and last element
@test_backward_loop:
   jsr dll::get_previous_element
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @test_backward_loop
   ; check first element
   jsr dll::get_previous_element
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR

   ; now we need to end up at the initial element
   EXPECT_EQ_MEM list_a
   txa
   EXPECT_EQ_MEM list_a+1

   FINISH_TEST
   rts
