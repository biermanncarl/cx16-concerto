; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_ARROWED_EDIT_ASM

::GUI_COMPONENTS_COMPONENTS_ARROWED_EDIT_ASM = 1

.include "common.asm"

.scope arrowed_edit
   .struct data_members
      pos_x .byte
      pos_y .byte
      min_value .byte
      max_value .byte
      value .byte
   .endstruct

   .proc draw
      lda (components_common::data_pointer), y
      sta guiutils::draw_x
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_y
      iny
      iny
      iny
      lda (components_common::data_pointer), y
      iny
      sta guiutils::draw_data1
      phy
      jsr guiutils::draw_arrowed_edit
      ply
      rts
   .endproc

   ; which arrow clicked is returned in mouse_variables::curr_data_1
   ; left: 1
   ; right: 2
   ; May clutter mouse_variables::curr_data_1, even if no click detected
   .proc check_mouse
      ; check if mouse is over the edit
      ; check x direction
      lda mouse_variables::curr_x_downscaled
      lsr ; we want cursor position in whole characters (8 pixel multiples), not half characters (4 pixel multiples)
      sec
      sbc (components_common::data_pointer), y ; subtract edit's position. so all valid values are smaller than edit size
   @check_left_arrow:
      ; correct x range. Now check for click on one of the arrows
      cmp #0 ; arrow to the left
      bne @check_right_arrow
      lda #1
      sta mouse_variables::curr_data_1
      bra @horizontal_in
   @out:
      clc
      rts
   @check_right_arrow:
      cmp #5
      bne @out ; the non-arrow inside of the arrowed edit is considered "out", i.e., a non-click
      lda #2
      sta mouse_variables::curr_data_1
   @horizontal_in:
      ; check y direction
      lda mouse_variables::curr_y_downscaled
      lsr
      iny
      cmp (components_common::data_pointer), y
      bne @out
      sec
      rts
   .endproc

   .proc event_click
      cae_value = gui_variables::mzpbe
      ; check if one of the arrows has been clicked
      lda mouse_variables::curr_data_1
      bne :+
      rts
   :  ; yes, one of the arrows has been clicked...
      inc gui_variables::request_component_write ; register a change on the GUI
      ; now, get value from edit
      lda mouse_variables::curr_component_ofs
      clc
      adc #data_members::value
      tay
      lda (components_common::data_pointer), y
      sta cae_value
      ; now, decide whether left or right was clicked
      dey
      lda mouse_variables::curr_data_1
      cmp #1
      bne @right
   @left:   ; decrement value
      ; get minimal value
      dey
      lda (components_common::data_pointer), y
      cmp cae_value
      bne :+
      ; if we're here, we're sitting at the bottom of valid range, need to wrap around
      ; need to get maximal value
      iny
      lda (components_common::data_pointer), y
      dey
      inc ; increment it to cancel upcoming decrement
      sta cae_value
   :  ; decrement
      lda cae_value
      dec
      ; and store it back
      iny
      iny
      sta (components_common::data_pointer), y
      bra @update_gui
   @right:   ; increment value
      ; get maximal value
      lda (components_common::data_pointer), y
      cmp cae_value
      bne :+
      ; if we're here, we're sitting at the top of the valid range, need to wrap around
      ; need to get minimal value
      dey
      lda (components_common::data_pointer), y
      iny
      dec ; decrement it to cancel upcoming increment
      sta cae_value
   :  ; increment
      lda cae_value
      inc
      ; and store it back
      iny
      sta (components_common::data_pointer), y
   @update_gui:
      ldy mouse_variables::curr_component_ofs
      jsr draw
      rts
   .endproc

   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_ARROWED_EDIT_ASM
