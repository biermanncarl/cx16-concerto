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


; Returns the .A/.X pointer to the active hitbox list
.proc load_hitbox_list
   ldy dragables::active_type
   lda detail::hitbox_vector_h, y
   tax
   lda detail::hitbox_vector_b, y
   rts
.endproc


; Remove all hitboxes from a hitbox list (TODO: clear all hitbox lists to preserve memory)
.proc clear_hitboxes
   jsr load_hitbox_list
   jsr v40b::clear
   rts
.endproc


; Add a hitbox to a list
; Expects hitbox data in the API variables.
; If successful, carry is clear. Carry is set when the operation failed due to full heap.
.proc add_hitbox
   jsr load_hitbox_list
   jsr v40b::append_new_entry
   rts
.endproc

.endscope ; hitboxes

.endif ; .ifndef ::GUI_DRAG_AND_DROP_DRAG_AND_DROP_DEFINITIONS_ASM
