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

start:
   START_TEST

   ; create the initial list element
   jsr dll::create_list
   sta list_a
   stx list_a+1

   ; insert element before first element (need to save it as it's the new anchor)
   jsr dll::insert_element_before
   sta list_b
   stx list_b+1

   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR

   ; second element should be the old anchor
   jsr dll::get_next_element
   pha
   phx
   EXPECT_EQ_MEM list_a
   txa
   EXPECT_EQ_MEM list_a+1
   plx
   pla
   ; check first/last properties
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_SET

   ; now insert element in the middle
   jsr dll::insert_element_before
   ; new element should neither be first nor last
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR

   ; previous element should be list_b (new anchor)
   pha
   phx
   jsr dll::get_previous_element
   jsr dll::is_first_element
   EXPECT_CARRY_SET
   jsr dll::is_last_element
   EXPECT_CARRY_CLEAR
   EXPECT_EQ_MEM list_b
   txa
   EXPECT_EQ_MEM list_b+1
   plx
   pla

   ; next element should be list_a (old anchor)
   pha
   phx
   jsr dll::get_next_element
   jsr dll::is_first_element
   EXPECT_CARRY_CLEAR
   jsr dll::is_last_element
   EXPECT_CARRY_SET
   EXPECT_EQ_MEM list_a
   txa
   EXPECT_EQ_MEM list_a+1
   plx
   pla


   FINISH_TEST
   rts
