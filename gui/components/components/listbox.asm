; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_LISTBOX_ASM

::GUI_COMPONENTS_COMPONENTS_LISTBOX_ASM = 1

.include "common.asm"

.scope listbox
   .struct data_members
      pos_x .byte
      pos_y .byte
      width .byte ; in characters, i.e. multiples of 8 pixels
      number_of_entries .byte
      address_of_first_entry .word
      selected_entry .byte
   .endstruct
   ; The names of the entries are given in a memory-contiguous block of zero-terminated
   ; screencode strings.

   .proc draw
      dlb_strp = guiutils::str_pointer
      lda (components_common::data_pointer), y
      sta guiutils::draw_x
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_y
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_width
      iny
      iny
      ; now determine the label of the selected option
      lda (components_common::data_pointer), y
      sta dlb_strp
      iny
      lda (components_common::data_pointer), y
      sta dlb_strp+1
      iny
      lda (components_common::data_pointer), y  ; put index of selected option in X
      tax
      iny
      phy
      ldy #0
      ; advance as long as X > 0
   @loop:
      dex
      bmi @end_loop
   @loop2:
      iny  ; having iny before reading the byte cannot cope with empty strings! It assumes the string has at least length 1
      lda (dlb_strp), y
      bne @loop2
      iny
      bra @loop
   @end_loop:
      ; now (dlb_strp+y) is the starting address of selected label
      ; compute starting address and store put it into the string pointer
      tya
      clc
      adc dlb_strp
      sta guiutils::str_pointer
      lda dlb_strp+1
      adc #0
      sta guiutils::str_pointer+1
      jsr guiutils::draw_listbox
      ply
      rts
   .endproc

   .proc check_mouse
      ; listbox check is identical to checkbox check.
      clb_width = gui_variables::mzpbf
      ; this is basically an "mouse is inside box" check
      ; with variable width
      ; get the width of the listbox
      iny
      iny
      lda (components_common::data_pointer), y
      sta clb_width
      dey
      dey
      ; check x direction
      lda mouse_variables::curr_x_downscaled
      lsr
      sec
      sbc (components_common::data_pointer), y ; now we have the distance of the mouse pointer to the left side of the checkbox
      ; now A must be smaller than the checkbox' width.
      cmp clb_width
      bcc @horizontal_in
   @out:   ; "from y" refers to the Y register being at the position of the y coordinate of the component's position data
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
      ; we don't activate gui_variables::request_component_write because the first click on the listbox
      ; doesn't change any actual data,
      ; bring up popup panel
      ; TODO: later we would need to calculate the popup position based on the listbox position
      ; and a possibly oversized popup (so that it would range beyond the screen)
      ; We'll deal with that as soon as this becomes an issue.
      ; For now, we'll just directly place it where we want it.
      ldy mouse_variables::curr_component_ofs
      lda (components_common::data_pointer), y
      sta panels__listbox_popup__box_x
      iny
      lda (components_common::data_pointer), y
      inc ; we'll see where exactly we want the popup (TODO)
      sta panels__listbox_popup__box_y
      ; load additional info into popup panel data
      iny 
      lda (components_common::data_pointer), y
      sta panels__listbox_popup__box_width
      iny 
      lda (components_common::data_pointer), y
      sta panels__listbox_popup__box_height
      iny
      lda (components_common::data_pointer), y
      sta panels__listbox_popup__strlist
      iny
      lda (components_common::data_pointer), y
      sta panels__listbox_popup__strlist+1
      lda mouse_variables::curr_component_ofs
      sta panels__listbox_popup__lb_ofs
      lda components_common::data_pointer
      sta panels__listbox_popup__lb_addr
      lda components_common::data_pointer+1
      sta panels__listbox_popup__lb_addr+1
      lda mouse_variables::curr_component_id
      sta panels__listbox_popup__lb_id
      lda mouse_variables::curr_panel
      sta panels__listbox_popup__lb_panel
      ; now do the GUI stack stuff
      ldx panels__panels_stack_pointer
      lda #panels__ids__listbox_popup
      sta panels__panels_stack, x
      inc panels__panels_stack_pointer
   @update_gui:
      jsr panels__listbox_popup__draw
      rts
   .endproc

   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_LISTBOX_ASM
