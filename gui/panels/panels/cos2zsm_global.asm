; Copyright 2025 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_COS2ZSM_GLOBAL_ASM

::GUI_PANELS_PANELS_COS2ZSM_GLOBAL_ASM = 1

.include "common.asm"

; global navigation panel
.scope cos2zsm_global
   px = 0
   py = 0
   wd = 80
   hg = 60
   comps:
   .scope comps
      COMPONENT_DEFINITION button, exit, 32, 40, 16, A exit_lb
      COMPONENT_DEFINITION button, load, 32, 27, 16, A load_lb
      COMPONENT_DEFINITION button, save, 32, 30, 16, A save_lb
      COMPONENT_DEFINITION text_field, converto_banner, 30, 17, 19, 4, A vram_assets::converto_banner
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, 24, 23
      .word caption_lb
      .byte 0
   ; data specific to this panel
   caption_lb: STR_FORMAT ".cos to .zsm file converter tool"
   exit_lb: STR_FORMAT "      exit"
   load_lb: STR_FORMAT " load .cos song"
   save_lb: STR_FORMAT "  save as .zsm"

   .proc draw
      rts
   .endproc

   .proc write
      ; prepare jump
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @exit
      .word @load
      .word @save
   @load:
      lda #file_browsing::file_type::song
      sta file_browsing::current_file_type
      lda #panels__ids__file_load_popup
      jmp gui_routines__openPopup
   @save:
      lda #file_browsing::file_type::zsm
      sta file_browsing::current_file_type
      lda #panels__ids__file_save_popup
      jmp gui_routines__openPopup
   @exit:
      inc gui_variables::request_program_exit
      rts
   .endproc

   .proc refresh
      rts
   .endproc

   .proc keypress
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_COS2ZSM_GLOBAL_ASM
