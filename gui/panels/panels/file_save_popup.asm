; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FILE_SAVE_POPUP_ASM

::GUI_PANELS_PANELS_FILE_SAVE_POPUP_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"
.include "file_popups_common.asm"

.scope file_save_popup
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
      COMPONENT_DEFINITION listbox, file_select, box_x+2, box_y + 2, box_width-4, box_height-7, A 0, 0, 255, 0
      COMPONENT_DEFINITION text_edit, file_name_edit, box_x+2, box_y + box_height-4, box_width-4, A 0, 0, 0
      COMPONENT_DEFINITION button, ok, 41, box_y + box_height - 3, 6, A lb_save
      COMPONENT_DEFINITION button, cancel, 33, box_y + box_height - 3, 6, A panel_common::lb_cancel
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 16*COLOR_BACKGROUND+1, 40-5, box_y
      .word lb_caption
      .byte 0
   ; data specific to the combobox-popup panel
   lb_save: STR_FORMAT " save"
   lb_caption: STR_FORMAT "save file"

   ; The file name the user wants
   save_file_name = comps::file_name_edit + components::text_edit::data_members::string_pointer

   .proc initialize
      lda file_browsing::files
      sta comps::file_select + components::listbox::data_members::string_pointer
      lda file_browsing::files+1
      sta comps::file_select + components::listbox::data_members::string_pointer+1
      ; initialize the text edit
      jsr v32b::new
      sta save_file_name
      stx save_file_name+1
      jsr v32b::accessFirstEntry
      lda #0
      tay
      sta (v32b::entrypointer), y
      rts
   .endproc

   .proc draw
      jsr file_popups_common::clearAndDrawFrame
      ; prepare file listing
      ldx #file_browsing::file_type::instrument
      jsr file_browsing::getFiles
      lda #255 ; none selected
      STA_COMPONENT_MEMBER_ADDRESS listbox, file_select, selected_entry
      STZ_COMPONENT_MEMBER_ADDRESS listbox, file_select, scroll_offset
      STZ_COMPONENT_MEMBER_ADDRESS text_edit, file_name_edit, cursor_position
      rts
   .endproc

   .proc write
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word file_select
      .word panel_common::dummy_subroutine ; file_name_edit
      .word button_ok
      .word button_cancel
   file_select:
      ; copy selected file string into text edit
      ldy comps::file_select + components::listbox::data_members::selected_entry
      cpy #255 ; skip if no valid file name was selected
      bne :+
      rts
   :  lda comps::file_select + components::listbox::data_members::string_pointer
      ldx comps::file_select + components::listbox::data_members::string_pointer+1
      jsr dll::getElementByIndex ; source entry in .A/.X
      ldy save_file_name
      sty dll::zp_pointer
      ldy save_file_name+1
      sty dll::zp_pointer+1
      jsr dll::copyElement
      inc gui_variables::request_components_redraw
      rts
   button_ok:
      lda save_file_name
      ldx save_file_name+1
      ldy #1 ; open for writing
      jsr file_browsing::openFile
      bcs file_exists
      lda gui_variables::current_synth_timbre
      jsr concerto_synth::timbres::saveInstrument
      jsr file_browsing::closeFile
      ; fall through to button_cancel, which closes the popup
   button_cancel:
      ; close popup
      jsr file_popups_common::clearArea
      dec panels_stack_pointer
      jsr gui_routines__draw_gui
      rts
   file_exists:
      ; TODO: factor out the GUI stack operation
      ; Here, we replace the current popup with the ok_cancel one
      jsr file_popups_common::clearArea
      ldx panels__panels_stack_pointer
      lda #panels__ids__ok_cancel_popup
      sta panels__panels_stack-1, x
      jsr gui_routines__draw_gui
      rts
   .endproc

   refresh = panel_common::dummy_subroutine

   .proc keypress
      lda kbd_variables::current_key
      cmp #13 ; enter
      beq write::button_ok
      cmp #$1B ; escape
      beq write::button_cancel
      LDY_COMPONENT_MEMBER text_edit, file_name_edit, pos_x ; start offset of text edit
      lda #<comps
      sta components::components_common::data_pointer
      lda #>comps
      sta components::components_common::data_pointer+1
      jsr components::text_edit::keyboard_edit
      stz kbd_variables::current_key
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FILE_SAVE_POPUP_ASM
