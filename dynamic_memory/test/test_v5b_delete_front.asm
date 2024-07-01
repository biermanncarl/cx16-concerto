; Copyright 2023 Carl Georg Biermann

.code
   jmp start

.include "../../testing/testing.asm"
.include "../../common/x16.asm"
.include "../vector_5bytes.asm"

vec_a:
   .res 2

counter:
   .res 2

n_entries = 400 ; fill more than one page worth of entries

start:
   START_TEST

   ; as deleting from the start of a vector is very slow,
   ; we have to fill up heap memory to get close to a banked RAM page crossing
   ; to be able to test that (within the time constraints of a unit test)
   ; prepare by filling the heap with 31 elements (so we will get cross-page links for the tests)
   lda #29 ; if in doubt, vary this number a bit to cover different cases of cross-page deleting
   sta counter
   jsr dll::create_list
@fill_loop_1:
   jsr dll::insert_element_before
   ; and ... ooops, let go of the pointer (aka memory leak) ...
   dec counter
   bne @fill_loop_1

   ; create a new vector
   jsr v5b::new
   sta vec_a
   stx vec_a+1

   ; fill the vector
   stz counter
   stz counter+1
@fill_loop:
   lda counter
   sta v5b::value_0
   lda counter+1
   sta v5b::value_1

   lda vec_a
   ldx vec_a+1
   jsr v5b::append_new_entry

   inc counter
   bne :+
   inc counter+1
:  lda counter+1
   cmp #>n_entries
   bne @fill_loop
   lda counter
   cmp #<n_entries
   bne @fill_loop


   ; delete entries from the front, one by one
   stz counter
   stz counter+1
@delete_loop:
   lda vec_a
   ldx vec_a+1
   jsr v5b::is_empty
   EXPECT_CARRY_CLEAR
   jsr v5b::get_first_entry
   pha
   phx
   phy
   jsr v5b::read_entry
   lda v5b::value_0
   ldx v5b::value_1
   EXPECT_EQ_MEM_16 counter

   inc counter
   bne :+
   inc counter+1
:
   ply
   plx
   pla
   jsr v5b::delete_entry
   bcc @delete_loop


   lda counter
   ldx counter+1
   EXPECT_EQ_16 n_entries

   FINISH_TEST
   rts
