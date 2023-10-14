; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_TAB_SELECTOR_ASM

::GUI_COMPONENTS_COMPONENTS_TAB_SELECTOR_ASM = 1

.include "common.asm"

.scope tab_selector
   .struct data_members
      pos_x .byte
      pos_y .byte
      number_of_tabs .byte
      active_tab .byte
   .endstruct

   .proc draw
      lda (components_common::data_pointer), y
      sta guiutils::draw_x
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_y
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_data1
      iny
      lda (components_common::data_pointer), y
      inc
      sta guiutils::draw_data2
      iny
      phy
      jsr guiutils::draw_tabs
      ply
      rts
   .endproc

   ; which tab clicked is returned in mouse_variables::curr_data_1
   .proc check_mouse
      ; check if mouse is over the tab selector area of the panel
      ; check x direction first
      ldx mouse_variables::curr_panel
      lda panels__px, x
      asl ; multiply by 2 to be 4 pixel multiple
      sec
      sbc components_common::mouse_downscaled_x ; now we have negative mouse offset, need to negate it
      eor #255
      ;inc ; belongs to negation, would be cancelled by dec
      ; now we got relative y position in 4 pixel multiples
      ; subtract 1 for the top margin
      ;dec ; cancelled by previous inc
      ; now compare with tab selector width, which is 4
      cmp #4
      bcc @horizontal_in ; if carry clear, we are in
      ; we are out
   @out:
      clc
      rts
   @horizontal_in:
      ; check y direction second
      lda panels__py, x
      asl ; multiply by 2 to be 4 pixel multiple
      sec
      sbc components_common::mouse_downscaled_y ; now we have negative mouse offset, need to negate it
      eor #255
      ;inc ; belongs to negation, would be cancelled by dec
      ; now we got relative y position in 4 pixel multiples
      ; subtract 1 for the top margin (half character at the top), and then divide by 4 because that's the height of each tab selector
      ;dec ; cancelled by previous inc
      lsr
      lsr
      ; now we have the index of the tab clicked
      ; compare it to number of tabs present
      iny
      iny
      cmp (components_common::data_pointer), y
      bcs @out ; if carry set, no tab has been clicked
      ; otherwise, tab has been selected
      sta mouse_variables::curr_data_1 ; store tab being clicked
      sec
      rts
   .endproc

   .proc event_click
      inc gui_variables::request_component_write
      ; put new tab into GUI component list
      lda mouse_variables::curr_data_1
      ldy mouse_variables::curr_component_ofs
      iny
      iny
      iny
      sta (components_common::data_pointer), y
      ; and redraw it
      ldy mouse_variables::curr_component_ofs
      jsr draw
      rts
   .endproc

   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_TAB_SELECTOR_ASM
