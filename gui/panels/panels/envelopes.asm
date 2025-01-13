; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_ENVELOPE_ASM

::GUI_PANELS_PANELS_ENVELOPE_ASM = 1

.include "common.asm"

; envelope settings panel
.scope envelopes
   px = synth_global::px
   py = psg_oscillators::py+psg_oscillators::hg+1
   wd = 24
   hg = 8
   comps:
   .scope comps
      COMPONENT_DEFINITION tab_selector, tab_select, px, py, 3, 0
      COMPONENT_DEFINITION arrowed_edit, n_envs, px+12, py+2, 1, 3, 1
      COMPONENT_DEFINITION drag_edit, attack, px+4 , py+5, %00000001, 0, 127, 0, 0
      COMPONENT_DEFINITION drag_edit, decay, px+9 , py+5, %00000001, 0, 127, 0, 0
      COMPONENT_DEFINITION drag_edit, sustain, px+14, py+5, %00000000, 0, ENV_PEAK, 0, 0
      COMPONENT_DEFINITION drag_edit, release, px+18, py+5, %00000001, 0, 127, 0, 0
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+4, py+2 ; number of envelopes label
      .word nenv_lb
      .byte CCOLOR_CAPTION, px+4, py+4
      .word panel_common::lb_attack
      .byte CCOLOR_CAPTION, px+9, py+4
      .word lb_decay
      .byte CCOLOR_CAPTION, px+14, py+4
      .word lb_sustain
      .byte CCOLOR_CAPTION, px+18, py+4
      .word panel_common::lb_release
      .byte 0
   ; data specific to the envelope panel
   active_tab: .byte 0
   nenv_lb: STR_FORMAT "n. envs"
   cp: STR_FORMAT "software envelopes" ; caption of panel
   lb_decay: STR_FORMAT "dec"
   lb_sustain: STR_FORMAT "sus"

   .proc draw
      lda #px
      sta guiutils::draw_x
      lda #py
      sta guiutils::draw_y
      lda #wd
      sta guiutils::draw_width
      lda #hg
      sta guiutils::draw_height
      lda #MAX_ENVS_PER_VOICE
      sta guiutils::draw_data1
      lda active_tab
      inc
      sta guiutils::draw_data2
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ; first, determine the offset of the envelope in the instrument data
      lda gui_variables::current_synth_instrument
      ldx active_tab ; envelope number
   @loop:
      cpx #0
      beq @end_loop
      clc
      adc #N_INSTRUMENTS
      dex
      bra @loop
   @end_loop:
      tax ; envelope index is in x
      ; prepare drag edit readout
      lda mouse_variables::curr_component_ofs
      clc
      adc #5 ; 6 because most of the control elements are drag edits anyway
      tay ; drag edit's coarse value offset is in Y
      ; now determine which component has been dragged
      phx
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @tab_select
      .word @n_envs
      .word @attack
      .word @decay
      .word @sustain
      .word @release
   @tab_select:
      plx
      lda mouse_variables::curr_data_1
      sta active_tab
      jsr refresh
      inc gui_variables::request_components_redraw
      rts
   @n_envs:
      plx
      ldx gui_variables::current_synth_instrument
      LDA_COMPONENT_MEMBER_ADDRESS arrowed_edit, n_envs, value
      sta concerto_synth::instruments::Instrument::n_envs, x
      rts
   @attack:
      plx
      lda comps, y
      sta concerto_synth::instruments::Instrument::env::attackH, x
      iny
      lda comps, y
      sta concerto_synth::instruments::Instrument::env::attackL, x
      rts
   @decay:
      plx
      lda comps, y
      sta concerto_synth::instruments::Instrument::env::decayH, x
      iny
      lda comps, y
      sta concerto_synth::instruments::Instrument::env::decayL, x
      rts
   @sustain:
      plx
      lda comps, y
      sta concerto_synth::instruments::Instrument::env::sustain, x
      rts
   @release:
      plx
      lda comps, y
      sta concerto_synth::instruments::Instrument::env::releaseH, x
      iny
      lda comps, y
      sta concerto_synth::instruments::Instrument::env::releaseL, x
      rts
   @skip:
      plx
      rts
   .endproc


   .proc refresh
      ; first, determine the offset of the envelope in the instrument data
      lda gui_variables::current_synth_instrument
      ldx active_tab ; envelope number
   @loop:
      cpx #0
      beq @end_loop
      clc
      adc #N_INSTRUMENTS
      dex
      bra @loop
   @end_loop:
      tax ; envelope index is in x
      ; read ADSR data from Instrument and load it into edits
      ; attack edit
      lda concerto_synth::instruments::Instrument::env::attackH, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, attack, coarse_value
      lda concerto_synth::instruments::Instrument::env::attackL, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, attack, fine_value
      ; decay edit
      lda concerto_synth::instruments::Instrument::env::decayH, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, decay, coarse_value
      lda concerto_synth::instruments::Instrument::env::decayL, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, decay, fine_value
      ; sustain edit
      lda concerto_synth::instruments::Instrument::env::sustain, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, sustain, coarse_value
      ; release edit
      lda concerto_synth::instruments::Instrument::env::releaseH, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, release, coarse_value
      lda concerto_synth::instruments::Instrument::env::releaseL, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, release, fine_value
      ; number of envelopes
      ldx gui_variables::current_synth_instrument
      lda concerto_synth::instruments::Instrument::n_envs, x
      STA_COMPONENT_MEMBER_ADDRESS arrowed_edit, n_envs, value
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_ENVELOPE_ASM
