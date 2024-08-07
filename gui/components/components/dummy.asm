; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_DUMMY_ASM

::GUI_COMPONENTS_COMPONENTS_DUMMY_ASM = 1

.include "common.asm"

.scope dummy
   ; The dummy component simply registers a click event, so that its parent panel
   ; can detect a click somewhere (useful e.g. for popups which close when one clicks anywhere on screen).

   .struct data_members
      pos_x .byte
      pos_y .byte
      width .byte
      height .byte
   .endstruct

   .proc draw
      iny
      iny
      iny
      iny
      rts
   .endproc

   .proc check_mouse
      ; this is basically a "mouse is inside box" check
      ; check x direction
      lda mouse_variables::curr_x_downscaled
      lsr
      sec
      sbc (components_common::data_pointer), y ; now we have the distance of the mouse pointer to the left side of the box
      ; now A must be smaller than the box's width.
      iny
      iny
      cmp (components_common::data_pointer), y
      bcc @horizontal_in
      ; we're out
   @out:
      clc
      rts
   @horizontal_in:  ; we're in
      ; check y direction
      lda mouse_variables::curr_y_downscaled
      lsr
      sec
      dey
      sbc (components_common::data_pointer), y
      iny
      iny
      cmp (components_common::data_pointer), y
      bcs @out
      ; we're in
   @vertical_in:
      ; get mouse coordinates (in 8 pixel multiples) and put them into data
      lda mouse_variables::curr_x_downscaled
      lsr
      sta mouse_variables::curr_data_1
      lda mouse_variables::curr_y_downscaled
      lsr
      sta mouse_variables::curr_data_2
      sec
      rts
   .endproc

   .proc event_click
      ; Similar to a button. Just tell the panel that it needs to do *something* (it will know what to do when it is told *which* dummy was clicked)
      inc gui_variables::request_component_write
      rts
   .endproc

   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DUMMY_ASM
