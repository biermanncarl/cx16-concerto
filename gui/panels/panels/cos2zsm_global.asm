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
      COMPONENT_DEFINITION button, exit, 5, 57, 4, A exit_lb
      COMPONENT_DEFINITION text_field, converto_banner, 1, 1, 19, 6, A vram_assets::converto_banner
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, 22, 3
      .word caption_lb
      .byte 0
   ; data specific to this panel
   caption_lb: STR_FORMAT ".cos to .zsm file converter tool"
   exit_lb: STR_FORMAT "exit"

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
