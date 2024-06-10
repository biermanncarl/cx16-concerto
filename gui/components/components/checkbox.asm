; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_CHECKBOX_ASM

::GUI_COMPONENTS_COMPONENTS_CHECKBOX_ASM = 1

.include "common.asm"

.scope checkbox
   .struct data_members
      pos_x .byte
      pos_y .byte
      width .byte
      checked .byte
   .endstruct

   ; For simplicity, checkboxes come without captions,
   ; just with a width. The caption can be drawn using
   ; the panel's list of captions.

   .proc draw
      lda (components_common::data_pointer), y
      sta guiutils::draw_x
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_y
      iny
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_data1
      phy
      jsr guiutils::draw_checkbox
      ply
      iny
      rts
   .endproc

   .proc check_mouse
      ccb_width = gui_variables::mzpbf
      ; this is basically a "mouse is inside box" check
      ; with variable width
      ; get the width of the checkbox
      iny
      iny
      lda (components_common::data_pointer), y
      sta ccb_width
      dey
      dey
      ; check x direction
      lda mouse_variables::curr_x_downscaled
      lsr
      sec
      sbc (components_common::data_pointer), y ; now we have the distance of the mouse pointer to the left side of the checkbox
      ; now A must be smaller than the checkbox' width.
      cmp ccb_width
      bcc @horizontal_in
   @out:
      clc
      rts
   @horizontal_in:  ; we're in
      ; check y direction
      lda mouse_variables::curr_y_downscaled
      lsr
      iny
      cmp (components_common::data_pointer), y
      bne @out
      ; we're in
      sec
      rts
   .endproc

   .proc event_click
      inc gui_variables::request_component_write ; register a change on the GUI
      ldy mouse_variables::curr_component_ofs
      iny
      iny
      iny
      lda (components_common::data_pointer), y
      beq @tick
   @untick:
      lda #0
      sta (components_common::data_pointer), y
      bra @update_gui
   @tick:
      lda #1
      sta (components_common::data_pointer), y
   @update_gui:
      ldy mouse_variables::curr_component_ofs
      jsr draw
      rts
   .endproc

   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_CHECKBOX_ASM
