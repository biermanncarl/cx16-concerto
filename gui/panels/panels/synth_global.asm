; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_GLOBAL_ASM

::GUI_PANELS_PANELS_GLOBAL_ASM = 1

.include "common.asm"

; global synth settings panel
.scope synth_global
   px = 11
   py = 8
   wd = 12
   hg = 20
   comps:
   .scope comps
      COMPONENT_DEFINITION arrowed_edit, n_envs, px+3, py+6, 1, 3, 1
      COMPONENT_DEFINITION checkbox, retrigger, px+2, py+12, 8, 1
      COMPONENT_DEFINITION checkbox, porta_activate, px+2, py+14, 8, 0
      COMPONENT_DEFINITION drag_edit, porta_rate, px+2, py+16, %00000000, 0, 255, 0, 0
      COMPONENT_DEFINITION drag_edit, vibrato_amount, px+7, py+19, %00000000, 0, 76, 0, 0
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, px+3, py
      .word panel_common::lb_global
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+2, py+5 ; number of envelopes label
      .word nenv_lb
      .byte CCOLOR_CAPTION, px+4, py+12 ; porta checkbox label
      .word panel_common::retr_lb
      .byte CCOLOR_CAPTION, px+5, py+14 ; porta checkbox label
      .word porta_active_lb
      .byte CCOLOR_CAPTION, px+6, py+16 ; porta rate label
      .word panel_common::rate_lb
      .byte CCOLOR_CAPTION, px+2, py+19 ; vibrato amount label
      .word vibrato_lb
      .byte 0
   nenv_lb: STR_FORMAT "n. envs"
   porta_active_lb: STR_FORMAT "porta" ; portamento activate label
   vibrato_lb: STR_FORMAT "vib."

   .proc draw
      lda #px
      sta guiutils::draw_x
      lda #py
      sta guiutils::draw_y
      lda #wd
      sta guiutils::draw_width
      lda #hg
      sta guiutils::draw_height
      lda #0
      sta guiutils::draw_data1
      lda #0
      sta guiutils::draw_data2
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ldx gui_variables::current_synth_instrument
      ; now jump to component which has been clicked/dragged
      phx
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @n_envs
      .word @retr_activate
      .word @porta_activate
      .word @porta_rate
      .word @vibrato_amount
   @n_envs:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS arrowed_edit, n_envs, value
      sta concerto_synth::instruments::Instrument::n_envs, x
      rts
   @retr_activate:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, retrigger, checked
      sta concerto_synth::instruments::Instrument::retrig, x
      rts
   @porta_activate:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, porta_activate, checked
      sta concerto_synth::instruments::Instrument::porta, x
      rts
   @porta_rate:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, porta_rate, coarse_value
      sta concerto_synth::instruments::Instrument::porta_r, x
      rts
   @vibrato_amount:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, vibrato_amount, coarse_value ; if this value is 0, that means vibrato off, which is represented as a negative value internally
      beq :+
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::instruments::Instrument::vibrato, x
      rts
   :  lda #$FF
      sta concerto_synth::instruments::Instrument::vibrato, x
      rts
   .endproc


   .proc refresh
      ldx gui_variables::current_synth_instrument
      ; number of envelopes
      lda concerto_synth::instruments::Instrument::n_envs, x
      STA_COMPONENT_MEMBER_ADDRESS arrowed_edit, n_envs, value
      ; retrigger checkbox
      lda concerto_synth::instruments::Instrument::retrig, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, retrigger, checked
      ; porta activate checkbox
      lda concerto_synth::instruments::Instrument::porta, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, porta_activate, checked
      ; porta rate edit
      lda concerto_synth::instruments::Instrument::porta_r, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, porta_rate, coarse_value
      ; vibrato amount edit
      lda concerto_synth::instruments::Instrument::vibrato, x
      bmi :+
      jsr concerto_synth::map_scale5_to_twos_complement
      bra :++
   :  lda #0
   :  STA_COMPONENT_MEMBER_ADDRESS drag_edit, vibrato_amount, coarse_value
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_ASM



