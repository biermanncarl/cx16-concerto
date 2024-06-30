; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_GLOBAL_ASM

::GUI_PANELS_PANELS_GLOBAL_ASM = 1

.include "common.asm"

; global synth settings panel
.scope synth_global
   px = 11
   py = 8
   wd = 12
   hg = 24
   comps:
   .scope comps
      COMPONENT_DEFINITION arrowed_edit, n_oscs, px+3, py+3, 0, MAX_OSCS_PER_VOICE, 1
      COMPONENT_DEFINITION arrowed_edit, n_envs, px+3, py+6, 1, 3, 1
      COMPONENT_DEFINITION checkbox, lfo_activate, px+2, py+8, 8, 1
      COMPONENT_DEFINITION checkbox, retrigger, px+2, py+12, 8, 1
      COMPONENT_DEFINITION checkbox, porta_activate, px+2, py+14, 8, 0
      COMPONENT_DEFINITION drag_edit, porta_rate, px+2, py+16, %00000000, 0, 255, 0, 0
      COMPONENT_DEFINITION drag_edit, vibrato_amount, px+7, py+19, %00000000, 0, 76, 0, 0
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, px+3, py
      .word cp
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+2, py+2 ; number of oscillators label
      .word nosc_lb
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+2, py+5 ; number of envelopes label
      .word nenv_lb
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+4, py+8 ; number of envelopes label
      .word panel_common::lfo_lb
      .byte CCOLOR_CAPTION, px+4, py+12 ; porta checkbox label
      .word panel_common::retr_lb
      .byte CCOLOR_CAPTION, px+5, py+14 ; porta checkbox label
      .word porta_active_lb
      .byte CCOLOR_CAPTION, px+6, py+16 ; porta rate label
      .word panel_common::rate_lb
      .byte CCOLOR_CAPTION, px+2, py+19 ; vibrato amount label
      .word vibrato_lb
      .byte 0
   cp: STR_FORMAT "global" ; caption of panel
   nosc_lb: STR_FORMAT "n. oscs"
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
      ldx gui_variables::current_synth_timbre
      lda mouse_variables::curr_component_ofs
      clc
      adc #4
      tay ; there's no component type where the data is before this index
      ; now jump to component which has been clicked/dragged
      phx
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @n_oscs
      .word @n_envs
      .word @n_lfos
      .word @retr_activate
      .word @porta_activate
      .word @porta_rate
      .word @vibrato_amount
   @n_oscs:
      phy
      jsr concerto_synth::voices::panic ; If we don't do this, a different number of oscillators might be released than initially acquired by a voice. Safety first.
      ply
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::n_oscs, x
      rts
   @n_envs:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::n_envs, x
      rts
   @n_lfos:
      plx
      dey
      lda comps, y
      sta concerto_synth::timbres::Timbre::n_lfos, x
      rts
   @retr_activate:
      plx
      dey
      lda comps, y
      sta concerto_synth::timbres::Timbre::retrig, x
      rts
   @porta_activate:
      plx
      dey
      lda comps, y
      sta concerto_synth::timbres::Timbre::porta, x
      rts
   @porta_rate:
      plx
      iny
      lda comps, y
      sta concerto_synth::timbres::Timbre::porta_r, x
      rts
   @vibrato_amount:
      plx
      iny
      lda comps, y ; if this value is 0, that means vibrato off, which is represented as a negative value internally
      beq :+
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::timbres::Timbre::vibrato, x
      rts
   :  lda #$FF
      sta concerto_synth::timbres::Timbre::vibrato, x
      rts
   .endproc


   .proc refresh
      ldx gui_variables::current_synth_timbre
      ; number of oscillators
      lda concerto_synth::timbres::Timbre::n_oscs, x
      LDY_COMPONENT_MEMBER arrowed_edit, n_oscs, value
      sta comps, y
      ; number of envelopes
      lda concerto_synth::timbres::Timbre::n_envs, x
      LDY_COMPONENT_MEMBER arrowed_edit, n_envs, value
      sta comps, y
      ; LFO activate checkbox
      lda concerto_synth::timbres::Timbre::n_lfos, x
      LDY_COMPONENT_MEMBER checkbox, lfo_activate, checked
      sta comps, y
      ; retrigger checkbox
      lda concerto_synth::timbres::Timbre::retrig, x
      LDY_COMPONENT_MEMBER checkbox, retrigger, checked
      sta comps, y
      ; porta activate checkbox
      lda concerto_synth::timbres::Timbre::porta, x
      LDY_COMPONENT_MEMBER checkbox, porta_activate, checked
      sta comps, y
      ; porta rate edit
      lda concerto_synth::timbres::Timbre::porta_r, x
      LDY_COMPONENT_MEMBER drag_edit, porta_rate, coarse_value
      sta comps, y
      ; vibrato amount edit
      lda concerto_synth::timbres::Timbre::vibrato, x
      bmi :+
      jsr concerto_synth::map_scale5_to_twos_complement
      bra :++
   :  lda #0
   :  LDY_COMPONENT_MEMBER drag_edit, vibrato_amount, coarse_value
      sta comps, y
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_ASM



