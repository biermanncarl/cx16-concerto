; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FILE_LOAD_POPUP_ASM

::GUI_PANELS_PANELS_FILE_LOAD_POPUP_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"
.include "file_popups_common.asm"

.scope file_load_popup
   ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
   px = 0
   py = 0
   wd = 80
   hg = 60
   ; where the actual popup appears
   box_width = file_popups_common::box_width
   box_height = file_popups_common::box_height
   box_x = file_popups_common::box_x
   box_y = file_popups_common::box_y
   comps:
   .scope comps
      COMPONENT_DEFINITION listbox, file_select, box_x+2, box_y + 2, box_width-4, box_height-5, A 0, 0, 255, 0
      COMPONENT_DEFINITION button, ok, 41, box_y + box_height - 3, 6, A lb_load
      COMPONENT_DEFINITION button, cancel, 33, box_y + box_height - 3, 6, A panel_common::lb_cancel
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 16*COLOR_BACKGROUND+1, 40-5, box_y
      .word lb_caption
      .byte 0
   ; data specific to the combobox-popup panel
   lb_load: STR_FORMAT " load"
   lb_caption: STR_FORMAT "load file"

   .proc initialize
      lda file_browsing::files
      sta comps::file_select + components::listbox::data_members::string_pointer
      lda file_browsing::files+1
      sta comps::file_select + components::listbox::data_members::string_pointer+1
      rts
   .endproc

   .proc draw
      jsr file_popups_common::clearAndDrawFrame
      ; prepare file listing
      ldx #file_browsing::file_type::instrument
      jsr file_browsing::getFiles
      lda #255 ; none selected
      ; #optimize-for-size by putting stuff above in common function (load and save popup)
      STA_COMPONENT_MEMBER_ADDRESS listbox, file_select, selected_entry
      STZ_COMPONENT_MEMBER_ADDRESS listbox, file_select, scroll_offset
      rts
   .endproc

   .proc write
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word panel_common::dummy_subroutine ; file_select
      .word button_ok
      .word button_cancel
   button_ok:
      ; get reference to file name
      lda file_browsing::files
      ldx file_browsing::files+1
      LDY_COMPONENT_MEMBER_ADDRESS listbox, file_select, selected_entry
      cpy #255
      beq :+ ; don't open invalid file
      jsr dll::getElementByIndex
      ; open file
      ldy #0 ; open for writing
      jsr file_browsing::openFile
      bcs :+
      php
      sei
      jsr concerto_synth::voices::panic
      lda gui_variables::current_synth_timbre
      jsr concerto_synth::timbres::loadInstrument
      plp
      jsr file_browsing::closeFile
   :  ; fall through to button_cancel, which closes the popup
   button_cancel:
      ; close popup
      jsr file_popups_common::clearArea
      dec panels_stack_pointer
      jsr gui_routines__draw_gui
      rts
   .endproc

   refresh = panel_common::dummy_subroutine

   .proc keypress
      lda kbd_variables::current_key
      stz kbd_variables::current_key
      cmp #13 ; enter
      beq write::button_ok
      cmp #$1B ; escape
      beq write::button_cancel
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FILE_LOAD_POPUP_ASM
