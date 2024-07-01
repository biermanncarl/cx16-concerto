; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_TEXT_FIELD_ASM

::GUI_COMPONENTS_COMPONENTS_TEXT_FIELD_ASM = 1

; This component fills a rectangular area on the text screen with
; data from the VRAM. It is non-interactive.
.include "common.asm"

.scope text_field
   .struct data_members
      pos_x  .byte
      pos_y  .byte
      width  .byte
      height .byte
      vram_address .word
   .endstruct

   .proc draw
      lda (components_common::data_pointer), y
      sta guiutils::draw_x
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_y
      iny
      lda (components_common::data_pointer), y
      asl
      sta guiutils::draw_width
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_height
      iny
      lda (components_common::data_pointer), y
      tax
      iny
      lda (components_common::data_pointer), y
      iny
      phy
      jsr guiutils::draw_buffer_box
      ply
      rts
   .endproc

   .proc check_mouse
      ; never in
      clc
      rts
   .endproc

   event_click = components_common::dummy_subroutine
   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_TEXT_FIELD_ASM
