; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_COMBOBOX_POPUP_ASM

::GUI_PANELS_PANELS_COMBOBOX_POPUP_ASM = 1

.include "common.asm"

; combobox popup. shows up when a combobox was clicked.
.scope combobox_popup
   ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
   px = 0
   py = 0
   wd = 80
   hg = 60
   comps:
   .scope comps
      COMPONENT_DEFINITION dummy, click_catcher, 0, 0, 80, 60
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 0
   ; data specific to the combobox-popup panel
   strlist: .word 0
   ; this is the position where the popup is actually drawn
   box_x: .byte 0
   box_y: .byte 0
   box_width: .byte 0
   box_height: .byte 0
   lb_panel: .byte 0 ; panel index of the combobox, so the popup knows which writing-function to call when done.
   lb_addr: .word 0 ; address and offset of the combobox that was causing the popup
   lb_ofs: .byte 0
   lb_id: .byte 0

   .proc draw
      dlbp_pointer = gui_variables::mzpwd
      lda box_x
      sta guiutils::draw_x
      lda box_y
      sta guiutils::draw_y
      lda box_width
      sta guiutils::draw_width
      lda box_height
      sta guiutils::draw_height
      lda strlist
      sta guiutils::str_pointer
      lda strlist+1
      sta guiutils::str_pointer+1
      jsr guiutils::draw_lb_popup
      rts
   .endproc

   .proc write
      ; since there is only the dummy component on the popup,
      ; this subroutine doesn't have to deal with the component id, but it interprets the click event itself

      clbp_pointer = gui_variables::mzpwa ; mzpwa is already used in the click_event routine, but once we get to this point, it should have served its purpose, so we can reuse it here.
      ; TODO: determine selection (or skip if none was selected)
      ; mouse coordinates are in mouse_variables::curr_data_1 and mouse_variables::curr_data_2 (been put there by the dummy GUI component)
      ; check if we're in correct x range
      lda mouse_variables::curr_data_1
      sec
      sbc box_x
      cmp box_width
      bcs @close_popup
      ; we're inside!
      ; check if we're in correct y range
      lda mouse_variables::curr_data_2
      sec
      sbc box_y
      cmp box_height
      bcs @close_popup
      ; we're inside!
      ; now the accumulator holds the new selection index. Put it back into the combobox.
      pha
      lda lb_addr
      sta clbp_pointer
      lda lb_addr+1
      sta clbp_pointer+1
      lda lb_ofs
      clc
      adc #components::combobox::data_members::selected_entry
      tay
      pla
      sta (clbp_pointer), y
   @close_popup:
      ; one thing that always happens, is that the popup is closed upon clicking.
      ; close popup
      dec panels_stack_pointer
      ; clear area where the popup has been before
      ; jsr guiutils::cls ; would be the cheap solution
      lda box_x
      sta guiutils::draw_x
      lda box_y
      sta guiutils::draw_y
      lda box_width
      sta guiutils::draw_width
      lda box_height
      sta guiutils::draw_height
      lda #(16*COLOR_BACKGROUND)
      sta guiutils::color
      jsr guiutils::clear_rectangle
      ; call writing function of panel
      lda lb_ofs
      sta mouse_variables::curr_component_ofs
      lda lb_id
      sta mouse_variables::curr_component_id
      lda lb_panel
      asl
      tax
      INDEXED_JSR jump_table_write, @ret_addr
   @ret_addr:
      ; redraw gui
      jsr gui_routines__draw_gui
      rts
   .endproc


   refresh = panel_common::dummy_subroutine

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_COMBOBOX_POPUP_ASM
