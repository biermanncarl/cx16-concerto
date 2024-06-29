; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FILE_BROWSER_POPUP_ASM

::GUI_PANELS_PANELS_FILE_BROWSER_POPUP_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"

.scope file_browser_popup
   ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
   px = 0
   py = 0
   wd = 80
   hg = 60
   ; where the actual popup appears
   box_width = 20
   box_height = 30
   box_x = (80 - box_width) / 2
   box_y = (60 - box_height) / 2
   comps:
   .scope comps
      COMPONENT_DEFINITION listbox, file_select, box_x+2, box_y + 2, 16, box_height-6, A 0, 0, 255
      COMPONENT_DEFINITION button, ok, 41, box_y + box_height - 3, 6, A lb_ok
      COMPONENT_DEFINITION button, cancel, 33, box_y + box_height - 3, 6, A lb_cancel
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 16*COLOR_BACKGROUND+1, 40-5, box_y
      .word lb_file_name
      .byte 0
   ; data specific to the combobox-popup panel
   lb_ok: STR_FORMAT "  ok"
   lb_cancel: STR_FORMAT "cancel"
   lb_file_name: STR_FORMAT "file name"

   .proc initialize
      lda file_browsing::files
      sta comps::file_select + components::listbox::data_members::string_pointer
      lda file_browsing::files+1
      sta comps::file_select + components::listbox::data_members::string_pointer+1
      rts
   .endproc

   .proc clearArea
      lda #box_x-1
      sta guiutils::draw_x
      lda #box_y-1
      sta guiutils::draw_y
      lda #box_width+2
      sta guiutils::draw_width
      lda #box_height+2
      sta guiutils::draw_height
      jsr guiutils::clear_rectangle
      rts
   .endproc

   .proc draw
      jsr clearArea
      ; clearArea already populates draw_x, draw_y, draw_width, draw_height, but we want different values unfortunately
      lda #box_x
      sta guiutils::draw_x
      lda #box_y
      sta guiutils::draw_y
      lda #box_width
      sta guiutils::draw_width
      lda #box_height
      sta guiutils::draw_height
      stz guiutils::draw_data1
      jsr guiutils::draw_frame
      ; prepare file listing
      ldx #file_browsing::file_type::instrument
      jsr file_browsing::getFiles
      stz comps::file_select + components::listbox::data_members::selected_entry
      rts
   .endproc

   .proc write
      jsr clearArea
      ; close popup
      ; TODO
      dec panels_stack_pointer
      jsr gui_routines__draw_gui
      rts
   .endproc

   refresh = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FILE_BROWSER_POPUP_ASM
