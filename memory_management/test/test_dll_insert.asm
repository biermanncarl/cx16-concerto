; Copyright 2023 Carl Georg Biermann

; This test is not super thorough, but makes it plausible that insert_element_before works as intended.

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
heap_min_ram_bank = 42
heap_max_ram_bank = 44
.include "../doubly_linked_list.asm"

list_a:
   .res 2

list_b:
   .res 2

loop_variable:
   .byte 0

num_elements = 34 ; feel free to reduce this number to simplify debugging

.macro EXPECT_NOT_FIRST_NOT_LAST
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
.endmacro

start:
   START_TEST

   ; create the initial list
   lda #(num_elements-1) ; account for the initial list element
   sta loop_variable
   jsr dll::create_list
   sta list_a
   stx list_a+1
@add_loop:
   lda list_a
   ldx list_a+1
   jsr dll::append_new_element
   dec loop_variable
   bne @add_loop

   ; now move along the elements of the chain (start with the second one) and call insert_element_before
   lda list_a
   ldx list_a+1
   jsr dll::get_next_element
@insert_loop_1:
   ; insert new element
   jsr dll::insert_element_before
   EXPECT_CARRY_CLEAR
   EXPECT_NOT_FIRST_NOT_LAST
   ; insert_element_before should return the pointer to the new element, so will have to move forward twice, to get ahead on the list
   jsr dll::get_next_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   ; could be the last list element
   jsr dll::is_last_element
   bcs @finish_insert_loop
   ; if it's not the last element, let's move on
   jsr dll::get_next_element
   bra @insert_loop_1
@finish_insert_loop:

   ; Check forward links
   ; added list elements in between the other ones --> yields 2*num_elements-1 elements in the list
   lda #(2*num_elements - 2)
   sta loop_variable
   lda list_a
   ldx list_a+1
   jsr dll::is_first_element
   EXPECT_CARRY_SET
@forward_check_loop_1:
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   jsr dll::get_next_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @forward_check_loop_1
   ; check last element
   jsr dll::is_last_element
   EXPECT_CARRY_SET

   ; Check backward links
   pha ; store pointer to last element
   phx
   lda #(2*num_elements - 2)
   sta loop_variable
   plx
   pla
   jsr dll::is_last_element
   EXPECT_CARRY_SET
@backward_check_loop_1:
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::get_previous_element
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   dec loop_variable
   bne @backward_check_loop_1
   ; check first element
   jsr dll::is_first_element
   EXPECT_CARRY_SET

   ; TODO: test special case where we insert before the first element (many times)

   FINISH_TEST
   rts



; Create a list by appending
; Iterate over the list and add a new element every time
; check length of the list --> should be twice as long
; Also create a list and insert_before more than a page worth of list elements --> cross page operation is forced 
;
;
; 
; Delete test:
; create a list
; iterate over list: delete one element, skip one element etc. --> should have half the length
; Create a list more than one page long, keep deleting e.g. the second element (also first)
;
; in both cases, the list should be more than one page long
; 
