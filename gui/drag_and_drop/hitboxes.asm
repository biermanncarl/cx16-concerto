; Copyright 2023-2025 Carl Georg Biermann

.ifndef ::GUI_DRAG_AND_DROP_DRAG_AND_DROP_DEFINITIONS_ASM
::GUI_DRAG_AND_DROP_DRAG_AND_DROP_DEFINITIONS_ASM = 1

.include "dragables.asm"

.scope hitboxes

; enum for designating where the mouse got hold of a hitbox
.scope hitbox_handle
   none = 0
   bulk = 1
   right_end = 2
.endscope


; Hitbox lists make use of the v5b infrastructure.
; However, since the information about a hitbox doesn't fit inside 5 bytes, two consecutive entries
; correspond to one hitbox.
; First entry
hitbox_pos_x = v5b::value_0 ; on-screen-position in multiples of 4 pixels
hitbox_pos_y = v5b::value_1 ; on-screen-position in multiples of 4 pixels
hitbox_width = v5b::value_2 ; on-screen width in multiples of 4 pixels (height is implied by dragables::active_type)
; Second entry
hitbox_event_a = v5b::value_0 ; pointer to the note-on event
hitbox_event_x = v5b::value_1 ; pointer to the note-on event
hitbox_event_y = v5b::value_2 ; pointer to the note-on event
hitbox_event_selected = v5b::value_3 ; boolean whether the corresponding event is currently selected or not


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
   jsr v5b::new
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
   jsr v5b::clear
   rts
.endproc


; Add hitbox information to a list.
; Two calls to this are necessary to create a hitbox (first time: position and size, second time: pointer to corresponding event)
; Expects hitbox data in the API variables.
; If successful, carry is clear. Carry is set when the operation failed due to full heap.
; Preserves .X
.proc add_hitbox_data
   phx
   jsr load_hitbox_list
   jsr v5b::append_new_entry
   plx
   rts
.endproc

.endscope ; hitboxes

.endif ; .ifndef ::GUI_DRAG_AND_DROP_DRAG_AND_DROP_DEFINITIONS_ASM
