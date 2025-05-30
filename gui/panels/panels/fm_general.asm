; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FM_GENERAL_ASM

::GUI_PANELS_PANELS_FM_GENERAL_ASM = 1

.include "common.asm"

; FM general setup (everything that isn't operators)
.scope fm_general
   px = 6
   py = envelopes::py+envelopes::hg+1
   wd = 41
   hg = 20
   lfo_x = px + 28
   lfo_y = py
   modsec_x = px + 13
   modsec_y = py + 16
   comps:
   .scope comps
      COMPONENT_DEFINITION arrowed_edit, connection, px+13, py+4, 0, 7, 0
      COMPONENT_DEFINITION drag_edit, feedback, px+14, py+6, %0, 0, 7, 0, 0
      COMPONENT_DEFINITION checkbox, op1_active, px+15, py+2, 2, 0
      COMPONENT_DEFINITION checkbox, op2_active, px+18, py+2, 2, 0
      COMPONENT_DEFINITION checkbox, op3_active, px+21, py+2, 2, 0
      COMPONENT_DEFINITION checkbox, op4_active, px+24, py+2, 2, 0
      COMPONENT_DEFINITION combobox, lr_select, px+13, py+9, 5, 4, A panel_common::channel_select_lb, 0
      COMPONENT_DEFINITION drag_edit, semitones, px+5, py+16, %00000100, 128, 127, 0, 0
      COMPONENT_DEFINITION drag_edit, fine_tune, px+5, py+17, %00000100, 128, 127, 0, 0
      COMPONENT_DEFINITION checkbox, key_track, px+13, py+14, 7, 0
      COMPONENT_DEFINITION combobox, pitchmod_sel, modsec_x, modsec_y, 8, N_TOT_MODSOURCES+1, A panel_common::modsources_none_option_lb, 0
      COMPONENT_DEFINITION drag_edit, pitchmod_dep, modsec_x+8, modsec_y, %10000100, 256-76, 76, 0, 0
      COMPONENT_DEFINITION checkbox, lfo_enable, lfo_x+2, lfo_y+2, 8, 0
      COMPONENT_DEFINITION combobox, lfo_wave, lfo_x+2, lfo_y+5, 7, 4, A lfo_waveform_lb, 0
      COMPONENT_DEFINITION drag_edit, lfo_freq, lfo_x+2, lfo_y+8, %0, 0, 255, 0, 0
      COMPONENT_DEFINITION drag_edit, lfo_vol_strength, lfo_x+2, lfo_y+15, %0, 0, 127, 127, 0
      COMPONENT_DEFINITION drag_edit, lfo_pitch_strength, lfo_x+8, lfo_y+15, %0, 0, 127, 127, 0
      COMPONENT_DEFINITION drag_edit, lfo_voice_vol_sens, px+13, py+11, %0, 0, 3, 0, 0
      COMPONENT_DEFINITION drag_edit, lfo_voice_pitch_sens, modsec_x+9, modsec_y+1, %0, 0, 7, 0, 0
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, px+2, py+4
      .word con_select_lb
      .byte CCOLOR_CAPTION, px+2, py+6
      .word lb_feedback
      .byte COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND, px+2, py+2
      .word lb_op_en
      .byte CCOLOR_CAPTION, px+16, py+2
      .word lb_op1
      .byte CCOLOR_CAPTION, px+19, py+2
      .word lb_op2
      .byte CCOLOR_CAPTION, px+22, py+2
      .word lb_op3
      .byte CCOLOR_CAPTION, px+25, py+2
      .word lb_op4
      .byte CCOLOR_CAPTION, px+2, py+9
      .word panel_common::channel_lb
      .byte CCOLOR_CAPTION, px+2, py+14
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, px+15, py+14
      .word panel_common::track_lb
      .byte CCOLOR_CAPTION, px+2, py+16
      .word panel_common::semi_lb
      .byte CCOLOR_CAPTION, px+2, py+17
      .word panel_common::fine_lb
      .byte CCOLOR_CAPTION, px+2, py+11
      .word lb_vol_mod
      .byte 0*16+12, modsec_x, modsec_y+1
      .word lb_fm_lfo_2
      ; global LFO
      .byte CCOLOR_CAPTION, lfo_x+2, lfo_y
      .word lb_fm_lfo
      .byte COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND, lfo_x+4, lfo_y+2
      .word lb_enable
      .byte CCOLOR_CAPTION, lfo_x+2, lfo_y+4
      .word panel_common::waveform_lb
      .byte CCOLOR_CAPTION, lfo_x+2, lfo_y+7
      .word panel_common::rate_lb
      .byte CCOLOR_CAPTION, lfo_x+2, lfo_y+11
      .word panel_common::lb_global
      .byte CCOLOR_CAPTION, lfo_x+3, lfo_y+12
      .word lb_strength
      .byte CCOLOR_CAPTION, lfo_x+2, lfo_y+14
      .word panel_common::vol_lb
      .byte CCOLOR_CAPTION, lfo_x+6, lfo_y+14
      .word panel_common::pitch_lb
      .byte 0
   cp: STR_FORMAT "fm general"
   con_select_lb: STR_FORMAT "connection"
   lb_feedback: STR_FORMAT "feedback"
   lb_op_en: STR_FORMAT "activate op."
   lb_op1: STR_FORMAT "1"
   lb_op2: STR_FORMAT "2"
   lb_op3: STR_FORMAT "3"
   lb_op4: STR_FORMAT "4"
   lb_fm_lfo: STR_FORMAT "fm lfo"
   lb_fm_lfo_2: STR_FORMAT " fm lfo  "
   lb_enable: STR_FORMAT "enable"
   lb_vol_mod: .byte 22, 15, 12, 31, 6, 13, 32, 12, 6, 15, 0 ; vol<-lfo
   ; lb_pitch_mod: .byte 6, 18, 5, 17, 31, 12, 6, 15, 0 ; freq<-lfo
   ; lb_pitch_mod: .byte 16, 9, 20, 3, 8, 31, 12, 6, 15, 0 ; pitch<-lfo
   lb_strength: STR_FORMAT "strength"
   lfo_waveform_lb:
      STR_FORMAT "saw"
      STR_FORMAT "squ"
      STR_FORMAT "tri"
      STR_FORMAT "noise"

   .proc draw
      lda #px
      sta guiutils::draw_x
      lda #py
      sta guiutils::draw_y
      lda #(lfo_x-px)
      sta guiutils::draw_width
      lda #hg
      sta guiutils::draw_height
      lda #0
      sta guiutils::draw_data1
      jsr guiutils::draw_frame
      lda #lfo_x
      sta guiutils::draw_x
      lda #py
      sta guiutils::draw_y
      lda #(wd+px-lfo_x)
      sta guiutils::draw_width
      lda #hg
      sta guiutils::draw_height
      lda #0
      sta guiutils::draw_data1
      jsr guiutils::draw_frame
      ; draw FM algorithm
      ldx gui_variables::current_synth_instrument
      lda concerto_synth::instruments::Instrument::fm_general::con, x
      sta guiutils::draw_data1
      jsr guiutils::draw_fm_alg
      rts
   .endproc

   .proc write
      wfm_bits = gui_variables::mzpbe
      ; invalidate all FM instruments that have been loaded onto the YM2151 (i.e. enforce reload after instrument has been changed)
      jsr concerto_synth::voices::panic
      jsr concerto_synth::voices::invalidate_fm_instruments
      ; do the usual stuff
      ldy gui_variables::current_synth_instrument
      ; now determine which component has been dragged
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @connection
      .word @feedback
      .word @op1_active
      .word @op2_active
      .word @op3_active
      .word @op4_active
      .word @lr_select
      .word @semitones
      .word @finetune
      .word @keytrack
      .word @pmsel ; pitch mod select
      .word @pitchmoddep ; pitch mod depth
      .word @lfo_enable
      .word @lfo_wave
      .word @lfo_freq
      .word @lfo_vol_strength
      .word @lfo_pitch_strength
      .word @lfo_voice_vol_sens
      .word @lfo_voice_pitch_sens
   @connection:
      LDA_COMPONENT_MEMBER_ADDRESS arrowed_edit, connection, value
      sta concerto_synth::instruments::Instrument::fm_general::con, y
      ; redraw FM algorithm
      sta guiutils::draw_data1
      jsr guiutils::draw_fm_alg
      rts
   @feedback:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, feedback, coarse_value
      sta concerto_synth::instruments::Instrument::fm_general::fl, y
      rts
   @op1_active:
      lda #%00000001
      sta wfm_bits
      bra @op_active_common
   @op2_active:
      lda #%00000010
      sta wfm_bits
      bra @op_active_common
   @op3_active:
      lda #%00000100
      sta wfm_bits
      bra @op_active_common
   @op4_active:
      lda #%00001000
      sta wfm_bits
   @op_active_common: ; DON'T put this label into jump table ...
      ldx mouse_variables::curr_component_ofs
      ; get checkbox value
      lda comps + components::checkbox::data_members::checked, x
      ; push into carry flag
      lsr
      lda wfm_bits
      bcc :+
      ; checkbox activated
      ora concerto_synth::instruments::Instrument::fm_general::op_en, y
      bra :++
   :  ; checkbox deactivated
      eor #%11111111
      and concerto_synth::instruments::Instrument::fm_general::op_en, y
   :  sta concerto_synth::instruments::Instrument::fm_general::op_en, y
      rts
   @lr_select:
      LDA_COMPONENT_MEMBER_ADDRESS combobox, lr_select, selected_entry
      clc
      ror
      ror
      ror
      sta concerto_synth::instruments::Instrument::fm_general::lr, y
      rts
   @semitones:
      ; decide if we need to tune down to compensate for fine tuning (because fine tuning internally only goes up)
      lda concerto_synth::instruments::Instrument::fm_general::fine, y
      bmi :+
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, semitones, coarse_value
      sta concerto_synth::instruments::Instrument::fm_general::pitch, y
      rts
   :  LDA_COMPONENT_MEMBER_ADDRESS drag_edit, semitones, coarse_value
      dec
      sta concerto_synth::instruments::Instrument::fm_general::pitch, y
      rts
   @finetune:
      tya
      tax
      ; if fine tune is now negative, but was non-negative beforehand, we need to decrement semitones
      ; and the other way round: if fine tune was negative, but now is non-negative, we need to increment semitones
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, fine_tune, coarse_value
      pha
      lda concerto_synth::instruments::Instrument::fm_general::fine, x
      bmi @fine_negative
   @fine_positive:
      pla
      bpl @fine_normal
      dec concerto_synth::instruments::Instrument::fm_general::pitch, x
      bra @fine_normal
   @fine_negative:
      pla
      bmi @fine_normal
      inc concerto_synth::instruments::Instrument::fm_general::pitch, x
   @fine_normal:
      sta concerto_synth::instruments::Instrument::fm_general::fine, x
      rts
   @keytrack:
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, key_track, checked
      sta concerto_synth::instruments::Instrument::fm_general::track, y
      rts
   @pmsel:
      LDA_COMPONENT_MEMBER_ADDRESS combobox, pitchmod_sel, selected_entry
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::instruments::Instrument::fm_general::pitch_mod_sel, y
      rts
   @pitchmoddep:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, pitchmod_dep, coarse_value
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::instruments::Instrument::fm_general::pitch_mod_dep, y
      rts
   @lfo_enable:
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, lfo_enable, checked
      sta concerto_synth::instruments::Instrument::fm_general::lfo_enable, y
      rts
   @lfo_wave:
      LDA_COMPONENT_MEMBER_ADDRESS combobox, lfo_wave, selected_entry
      sta concerto_synth::instruments::Instrument::fm_general::lfo_waveform, y
      rts
   @lfo_freq:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_freq, coarse_value
      sta concerto_synth::instruments::Instrument::fm_general::lfo_frequency, y
      rts
   @lfo_vol_strength:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_vol_strength, coarse_value
      sta concerto_synth::instruments::Instrument::fm_general::lfo_vol_mod, y
      rts
   @lfo_pitch_strength:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_pitch_strength, coarse_value
      sta concerto_synth::instruments::Instrument::fm_general::lfo_pitch_mod, y
      rts
   @lfo_voice_vol_sens:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_voice_vol_sens, coarse_value
      sta concerto_synth::instruments::Instrument::fm_general::lfo_vol_sens, y
      rts
   @lfo_voice_pitch_sens:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_voice_pitch_sens, coarse_value
      sta concerto_synth::instruments::Instrument::fm_general::lfo_pitch_sens, y
      rts
   .endproc


   .proc refresh
      ldx gui_variables::current_synth_instrument
      ; connection scheme
      lda concerto_synth::instruments::Instrument::fm_general::con, x
      STA_COMPONENT_MEMBER_ADDRESS arrowed_edit, connection, value
      ; feedback level
      lda concerto_synth::instruments::Instrument::fm_general::fl, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, feedback, coarse_value
      ; operators enable
      lda concerto_synth::instruments::Instrument::fm_general::op_en, x
      ; operator 1 enable
      ldy #0
      lsr
      bcc :+
      iny
   :  STY_COMPONENT_MEMBER_ADDRESS checkbox, op1_active, checked
      ; operator 2 enable
      ldy #0
      lsr
      bcc :+
      iny
   :  STY_COMPONENT_MEMBER_ADDRESS checkbox, op2_active, checked
      ; operator 3 enable
      ldy #0
      lsr
      bcc :+
      iny
   :  STY_COMPONENT_MEMBER_ADDRESS checkbox, op3_active, checked
      ; operator 4 enable
      ldy #0
      lsr
      bcc :+
      iny
   :  STY_COMPONENT_MEMBER_ADDRESS checkbox, op4_active, checked
      ; LR channel select
      lda concerto_synth::instruments::Instrument::fm_general::lr, x
      clc
      rol
      rol
      rol
      STA_COMPONENT_MEMBER_ADDRESS combobox, lr_select, selected_entry
      ; semitones
      ; we need to check fine tune to get correct semi tones.
      ; if fine tune is negative, we need to increment one to the semitone value to be displayed on the GUI
      lda concerto_synth::instruments::Instrument::fm_general::fine, x
      bmi :+
      lda concerto_synth::instruments::Instrument::fm_general::pitch, x
      bra :++
   :  lda concerto_synth::instruments::Instrument::fm_general::pitch, x
      inc
   :  STA_COMPONENT_MEMBER_ADDRESS drag_edit, semitones, coarse_value
      ; fine tune
      lda concerto_synth::instruments::Instrument::fm_general::fine, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, fine_tune, coarse_value
      ; key track
      lda concerto_synth::instruments::Instrument::fm_general::track, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, key_track, checked
      ; pitch mod select
      lda concerto_synth::instruments::Instrument::fm_general::pitch_mod_sel, x
      jsr panel_common::map_modsource_to_gui
      STA_COMPONENT_MEMBER_ADDRESS combobox, pitchmod_sel, selected_entry
      ; pitch mod depth
      lda concerto_synth::instruments::Instrument::fm_general::pitch_mod_dep, x
      jsr concerto_synth::map_scale5_to_twos_complement
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, pitchmod_dep, coarse_value
      ; LFO settings
      lda concerto_synth::instruments::Instrument::fm_general::lfo_enable, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, lfo_enable, checked
      lda concerto_synth::instruments::Instrument::fm_general::lfo_waveform, x
      STA_COMPONENT_MEMBER_ADDRESS combobox, lfo_wave, selected_entry
      lda concerto_synth::instruments::Instrument::fm_general::lfo_frequency, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_freq, coarse_value
      lda concerto_synth::instruments::Instrument::fm_general::lfo_vol_mod, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_vol_strength, coarse_value
      lda concerto_synth::instruments::Instrument::fm_general::lfo_pitch_mod, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_pitch_strength, coarse_value
      lda concerto_synth::instruments::Instrument::fm_general::lfo_vol_sens, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_voice_vol_sens, coarse_value
      lda concerto_synth::instruments::Instrument::fm_general::lfo_pitch_sens, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, lfo_voice_pitch_sens, coarse_value
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FM_GENERAL_ASM
