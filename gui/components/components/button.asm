; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_BUTTON_ASM

::GUI_COMPONENTS_COMPONENTS_BUTTON_ASM = 1

; BUTTONS are actually height 2, and appear to be one below the position set in the GUI 
; component string. That is, because they have one row of characters above the actual
; text label to make them look nicer.
; However, click detection only recognizes the text label area, that is, one below the specified Y position.

.include "common.asm"

.scope button
   .struct data_members
      pos_x .byte
      pos_y .byte
      width .byte
      label_address .word
   .endstruct

   .proc draw
      lda (components_common::data_pointer), y
      sta guiutils::draw_x
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_y
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_width
      iny
      lda (components_common::data_pointer), y
      sta guiutils::str_pointer
      iny
      lda (components_common::data_pointer), y
      sta guiutils::str_pointer+1
      iny
      phy
      jsr guiutils::draw_button
      ply
      rts
   .endproc

   .proc check_mouse
      ; check if mouse is over the button
      ; this code is nearly identical to the check_checkbox bit,
      ; apart from the number of INYs required, and the different Y position (off by 1)
      cb_width = mzpbf
      ; this is basically a "mouse is inside box" check
      ; with variable width
      ; get the width of the button
      iny
      iny
      lda (components_common::data_pointer), y
      sta cb_width
      dey
      dey
      ; check x direction
      lda components_common::mouse_downscaled_x
      lsr
      sec
      sbc (components_common::data_pointer), y ; now we have the distance of the mouse pointer to the left side of the button
      ; now A must be smaller than the button's width.
      cmp cb_width
      bcc @horizontal_in
      ; we're out
   @out:
      clc
      rts
   @horizontal_in:  ; we're in
      ; check y direction
      lda components_common::mouse_downscaled_y
      lsr
      dec ; this is to make up for the button actually being in the line below
      iny
      cmp (components_common::data_pointer), y
      bne @out
      ; we're in
      sec
      rts
   .endproc

   .proc event_click
      ; register the click to trigger a write_...
      inc gui_definitions::request_component_write
      ; nothing else to be done here. click events are handled inside the panels'
      ; write_... subroutines, because they can identify individual buttons and know
      ; what actions to perform. (This here is just a generic button)
      rts
   .endproc

   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_BUTTON_ASM
