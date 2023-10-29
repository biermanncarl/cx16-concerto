; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_DRAG_AND_DROP_DRAG_AND_DROP_DEFINITIONS_ASM
::GUI_DRAG_AND_DROP_DRAG_AND_DROP_DEFINITIONS_ASM = 1

.include "dragables.asm"

.scope hitboxes



; variables to communicate hitboxes which are stored in the hitbox lists
hitbox_pos_x = v40b::value_0 ; on-screen-position in multiples of 4 pixels
hitbox_pos_y = v40b::value_1 ; on-screen-position in multiples of 4 pixels
hitbox_width = v40b::value_2 ; on-screen width in multiples of 4 pixels (height is implied by dragables::active_type)
object_id_l = v40b::value_3 ; identifier (low)
object_id_h = v40b::value_4 ; identifier (high)

.scope detail
   ; addresses to vectors of hitboxes which can be dragged (B/H)
   hitbox_vector_b:
      .res dragables::ids::end_id
   hitbox_vector_h:
      .res dragables::ids::end_id

   ; Move these to zeropage?
   temp_variable_a:
      .res 1
   temp_variable_b:
      .res 1

   .proc load_hitbox_list
      ldy dragables::active_type
      lda detail::hitbox_vector_h, y
      tax
      lda detail::hitbox_vector_b, y
      rts
   .endproc
.endscope


; This function sets up some things before drag and drop features can be used.
.proc initialize
   ldy #(dragables::ids::end_id-1)
@init_loop:
   phy
   ; create hitbox vectors
   jsr v40b::new
   ply
   sta detail::hitbox_vector_b, y
   txa
   sta detail::hitbox_vector_h, y
   dey
   cpy #255
   bne @init_loop
   rts
.endproc


; Remove all hitboxes from a hitbox list
.proc clear_hitboxes
   jsr detail::load_hitbox_list
   jsr v40b::clear
   rts
.endproc


; Add a hitbox to a list
; Expects hitbox data in the API variables.
; If successful, carry is clear. Carry is set when the operation failed due to full heap.
.proc add_hitbox
   jsr detail::load_hitbox_list
   jsr v40b::append_new_entry
   rts
.endproc

; Checks if the mouse is currently over a hitbox.
; Expects mouse position in .A/.X (x position in multiples of 4 pixel, y position in multiples of 4 pixel)
; Carry will be set if no match was found. If a match was found, carry is clear.
; Returns the id of the associated object in .A/.X (low/high).
.proc mouse_over
   sta detail::temp_variable_a
   stx detail::temp_variable_b
   jsr detail::load_hitbox_list
   jsr v40b::get_first_entry
   bcs @end
@loop:
   pha
   phx
   phy
   jsr v40b::read_entry
   ; Check Y coordinate
   lda detail::temp_variable_b
   cmp hitbox_pos_y ; carry will be set if mouse is at the height or below the hitbox
   bcc @continue
   ; Now check if mouse is at the height or above the hitbox. For that we subtract the hitbox height from the mouse coordinate and then compare
   ldy dragables::active_type
   sbc dragables::hitbox_heights, y ; carry is already set
   dec ; subtract one more than the hitbox height
   cmp hitbox_pos_y ; carry will be clear if mouse is above "one line below" the hitbox (that is, in other words, on the hitbox or above it)
   bcs @continue
   ; Check X coordinate (same formulas as above)
   sta detail::temp_variable_a
   cmp hitbox_pos_x
   bcc @continue
   sbc hitbox_width
   dec
   cmp hitbox_pos_x
   bcs @continue
   ; We got a hit!
   ply ; tidy up the stack
   plx
   pla
   lda object_id_l ; load the return value
   ldx object_id_h
   ; clc ; Carry needs to be cleared to signal success. (carry is already cleared as per branching condition above)
   rts

@continue:
   ply
   plx
   pla
   jsr v40b::get_next_entry
   bcc @loop
   ; sec ; No success - need to set carry to signal "no success". Luckily, carry is already set as per branching condition.

@end:
   rts
.endproc

.endscope ; hitboxes

.endif ; .ifndef ::GUI_DRAG_AND_DROP_DRAG_AND_DROP_DEFINITIONS_ASM
