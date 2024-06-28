; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FILE_BROWSER_POPUP_ASM

::GUI_PANELS_PANELS_FILE_BROWSER_POPUP_ASM = 1

.include "common.asm"

.scope file_browser_popup
   ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
   px = 0
   py = 0
   wd = 80
   hg = 60
   ; where the actual popup appears
   box_width = 20
   box_height = 20
   box_x = (80 - box_width) / 2
   box_y = (60 - box_height) / 2
   comps:
   .scope comps
      COMPONENT_DEFINITION button, ok, 37, box_y + box_height - 3, 6, A lb_ok
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 0
   ; data specific to the combobox-popup panel
   lb_ok: STR_FORMAT "  ok"

   .proc clearArea
      lda #box_x
      sta guiutils::draw_x
      lda #box_y
      sta guiutils::draw_y
      lda #box_width
      sta guiutils::draw_width
      lda #box_height
      sta guiutils::draw_height
      jsr guiutils::clear_rectangle
      rts
   .endproc

   .proc draw
      jsr clearArea
      ; TODO draw frame
      rts
   .endproc

   .proc write
      jsr clearArea
      ; close popup
      dec panels_stack_pointer
      jsr gui_routines__draw_gui
      rts
   .endproc

   refresh = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FILE_BROWSER_POPUP_ASM
