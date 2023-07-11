; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_COMMON_ASM

::GUI_PANELS_PANELS_COMMON_ASM = 1

.include "../../gui_macros.asm"

.scope panel_common
   ; Recurring Labels
   ; ----------------
   vol_lb: STR_FORMAT "vol"
   pitch_lb: STR_FORMAT "pitch"
   semi_lb: STR_FORMAT "st"
   fine_lb: STR_FORMAT "fn"
   track_lb: STR_FORMAT "track"
   waveform_lb: STR_FORMAT "waveform"
   lfo_lb: STR_FORMAT "lfo"
   retr_lb: STR_FORMAT "retrig"
   rate_lb: STR_FORMAT "rate"
   lb_attack: STR_FORMAT "att"
   lb_release: STR_FORMAT "rel"
   channel_lb: .byte 12, 47, 18, 0 ; L/R

   modsources_none_option_lb:
      .byte 32, 45, 45, 0
   modsources_lb: 
      STR_FORMAT "env1"
      STR_FORMAT "env2"
      STR_FORMAT "env3"
      STR_FORMAT "lfo"
   channel_select_lb:
      .byte 32, 45, 0
      STR_FORMAT " l"
      STR_FORMAT " r"
      .byte 12, 43, 18, 0


   ; Utility Subroutines
   ; -------------------

   ; subroutine which can be referenced where no action is required but still some address needs to be given.
   .proc dummy_subroutine
      rts
   .endproc

   ; If a subroutine is expected to pull .X from the stack, this is the minimalist choice.
   .proc dummy_plx
      plx
      rts
   .endproc

   ; on the GUI, "no modulation source" is 0, but in the synth engine, it is 128 (bit 7 set)
   ; The following two routines map between those two formats.
   .proc map_modsource_from_gui
      cmp #0
      beq :+
      dec
      rts
   :  lda #128
      rts
   .endproc

   .proc map_modsource_to_gui
      cmp #0
      bmi :+
      inc
      rts
   :  lda #0
      rts
   .endproc

   ; this is for the modulation depths
   .proc map_twos_complement_to_signed_7bit
      cmp #0
      bpl @done
      eor #%01111111
      inc
   @done:
      rts
   .endproc

   .proc map_signed_7bit_to_twos_complement
      cmp #0
      bpl @done
      dec
      eor #%01111111
   @done:
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_COMMON_ASM
