; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_min_ram_bank = 16
heap_max_ram_bank = 18
.include "../doubly_linked_list.asm"

list_a:
   .res 2

list_b:
   .res 2

loop_variable:
   .byte 0

num_elements = 67
max_elements = 32 * (heap_max_ram_bank - heap_min_ram_bank + 1)

start:
   START_TEST

   ; ===================
   ; Large Scale Testing
   ; ===================

   ; Agenda
   ; 1. create list that fills several banks of banked RAM
   ; 2. iterate over that list forwards and backwards
   ; 3. clear the list
   ; 4. fill the list up until the expected maximum capacity of the heap
   ; 5. check if the limit of the heap is indeed reached
   ; 6. clear the list
   ; 7. check if there's space again

   jsr dll::create_list
   EXPECT_CARRY_CLEAR
   sta list_a
   stx list_a+1

   ; add several pages worth of list elements
   lda #(num_elements - 1) ; subtract initial element
   sta loop_variable
   lda list_a
   ldx list_a+1
@append_loop:
   ; depend on append_new_element to always return the new element
   jsr dll::append_new_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_SET
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
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

   ; clear the list
   lda list_a
   ldx list_a+1
   jsr dll::destroy_list
   stz list_a
   stz list_a+1

   ; create new list and fill it until no more space
   lda #(max_elements - 1) ; leave out first element in the loop
   sta loop_variable
   jsr dll::create_list
   EXPECT_CARRY_CLEAR
   sta list_a
   stx list_a+1
@death_loop:
   lda list_a
   ldx list_a+1
   jsr dll::append_new_element
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @death_loop
   ; now try to add one more element -- should fail due to full heap
   lda list_a
   ldx list_a+1
   jsr dll::append_new_element
   EXPECT_CARRY_SET

   ; now clear complete list again ... there should be space again to allocate new elements
   lda list_a
   ldx list_a+1
   jsr dll::destroy_list
   jsr dll::create_list
   EXPECT_CARRY_CLEAR


   FINISH_TEST
   rts
