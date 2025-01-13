; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_PSG_OSCILLATORS_ASM

::GUI_PANELS_PANELS_PSG_OSCILLATORS_ASM = 1

.include "common.asm"

; oscillator settings panel
.scope psg_oscillators
   px = synth_global::px+synth_global::wd
   py = synth_global::py
   wd = 34
   hg = synth_global::hg
   ; positions of sub-sections inside the panel
   wfsecx = px + 4
   wfsecy = py + 5
   pwsecx = px + 4
   pwsecy = py + 8
   ampsecx = px + 20
   ampsecy = py + 5
   modsecx = px + 14
   modsecy = py + 12
   pitsecx = px + 4
   pitsecy = py + 12

   comps:
   .scope comps
      COMPONENT_DEFINITION tab_selector, tab_select, px, py, MAX_OSCS_PER_VOICE, 0
      COMPONENT_DEFINITION arrowed_edit, n_oscs, px+12, py+2, 0, MAX_OSCS_PER_VOICE, 1
      COMPONENT_DEFINITION combobox, waveform, wfsecx, wfsecy+1, 8, 4, A waveforms_lb, 0
      COMPONENT_DEFINITION drag_edit, pulse_width, pwsecx, pwsecy+1, %00000000, 0, 63, 0, 0
      COMPONENT_DEFINITION combobox, amp_env, ampsecx, ampsecy+4, 8, N_TOT_MODSOURCES, A panel_common::modsources_lb, 0
      COMPONENT_DEFINITION drag_edit, volume, ampsecx, ampsecy+1, %00000000, 0, 64, 0, 0
      COMPONENT_DEFINITION combobox, lr_select, ampsecx+4, ampsecy+1, 5, 4, A panel_common::channel_select_lb, 0
      COMPONENT_DEFINITION drag_edit, semitones, pitsecx+3, pitsecy+2, %00000100, 128, 127, 0, 0
      COMPONENT_DEFINITION drag_edit, fine_tune, pitsecx+3, pitsecy+3, %00000100, 128, 127, 0, 0
      COMPONENT_DEFINITION checkbox, key_track, pitsecx, pitsecy+5, 7, 0
      COMPONENT_DEFINITION combobox, pitch1_modsource, modsecx+6, modsecy+2, 8, N_TOT_MODSOURCES+1, A panel_common::modsources_none_option_lb, 0
      COMPONENT_DEFINITION combobox, pitch2_modsource, modsecx+6, modsecy+3, 8, N_TOT_MODSOURCES+1, A panel_common::modsources_none_option_lb, 0
      COMPONENT_DEFINITION combobox, pw_modsource, modsecx+6, modsecy+4, 8, N_TOT_MODSOURCES+1, A panel_common::modsources_none_option_lb, 0
      COMPONENT_DEFINITION combobox, volume_modsource, modsecx+6, modsecy+5, 8, N_TOT_MODSOURCES+1, A panel_common::modsources_none_option_lb, 0
      COMPONENT_DEFINITION drag_edit, pitch1_moddepth, modsecx+14, modsecy+4, %10000100, 256-76, 76, 0, 0
      COMPONENT_DEFINITION drag_edit, pitch2_moddepth, modsecx+14, modsecy+5, %10000100, 256-76, 76, 0, 0
      COMPONENT_DEFINITION drag_edit, pw_moddepth, modsecx+14, modsecy+2, %00000100, 256-127, 127, 0, 0
      COMPONENT_DEFINITION drag_edit, volume_moddepth, modsecx+14, modsecy+3, %00000100, 256-127, 127, 0, 0
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+4, py+2 ; number of oscillators label
      .word nosc_lb
      .byte CCOLOR_CAPTION, wfsecx, wfsecy
      .word panel_common::waveform_lb
      .byte CCOLOR_CAPTION, pwsecx, pwsecy
      .word pulsewidth_lb
      .byte CCOLOR_CAPTION, ampsecx, ampsecy+3
      .word amp_lb
      .byte CCOLOR_CAPTION, ampsecx, ampsecy
      .word panel_common::vol_lb
      .byte CCOLOR_CAPTION, ampsecx+5, ampsecy
      .word panel_common::channel_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy+2
      .word panel_common::semi_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy+3
      .word panel_common::fine_lb
      .byte CCOLOR_CAPTION, pitsecx+2, pitsecy+5
      .word panel_common::track_lb
      .byte CCOLOR_CAPTION, modsecx+4, modsecy
      .word modulation_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy+4
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, modsecx+3, modsecy+2
      .word pw_lb
      .byte CCOLOR_CAPTION, modsecx+2, modsecy+3
      .word panel_common::vol_lb
      .byte 0

   ; data specific to the oscillator panel
   active_tab: .byte 0
   cp: STR_FORMAT "psg oscillators" ; caption of panel
   nosc_lb: STR_FORMAT "n. oscs"
   amp_lb: STR_FORMAT "amp env"
   pulsewidth_lb: STR_FORMAT "pulse width"
   pw_lb: STR_FORMAT "pw"
   modulation_lb: STR_FORMAT "modulation"
   ; stringlist for modsource comboboxes
   waveforms_lb:
      STR_FORMAT "pulse"
      STR_FORMAT "saw"
      STR_FORMAT "tri"
      STR_FORMAT "noise"
   

   .proc draw
      lda #px
      sta guiutils::draw_x
      lda #py
      sta guiutils::draw_y
      lda #wd
      sta guiutils::draw_width
      lda #hg
      sta guiutils::draw_height
      lda #MAX_OSCS_PER_VOICE
      sta guiutils::draw_data1
      lda active_tab
      inc
      sta guiutils::draw_data2
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ; first, determine the offset of the oscillator in the instrument data
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
      tax ; oscillator index is in x
      ; now determine which component has been changed
      phx
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @tab_slector
      .word @n_oscs
      .word @waveform
      .word @pulsewidth ; pulse width
      .word @ampsel ; amp combobox
      .word @volume ; oscillator volume
      .word @channelsel ; L/R select
      .word @semitones
      .word @finetune
      .word @keytrack
      .word @pmsel1 ; pitch mod select 1
      .word @pmsel2 ; pitch mod select 2
      .word @pwmsel ; pw mod select
      .word @volmsel ; vol mod select
      .word @pitchmoddep1 ; pitch mod depth 1
      .word @pitchmoddep2 ; pitch mod depth 2
      .word @pwmdep ; pw mod depth
      .word @vmdep ; vol mod depth
   @tab_slector:
      plx
      lda mouse_variables::curr_data_1
      sta active_tab
      jsr refresh
      inc gui_variables::request_components_redraw
      rts
   @n_oscs:
      jsr concerto_synth::voices::panic ; If we don't do this, a different number of oscillators might be released than initially acquired by a voice. Safety first.
      plx
      ldx gui_variables::current_synth_instrument
      LDA_COMPONENT_MEMBER_ADDRESS arrowed_edit, n_oscs, value
      sta concerto_synth::instruments::Instrument::n_oscs, x
      rts
   @waveform:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS combobox, waveform, selected_entry
      clc
      ror
      ror
      ror
      sta concerto_synth::instruments::Instrument::osc::waveform, x
      rts
   @pulsewidth:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, pulse_width, coarse_value
      sta concerto_synth::instruments::Instrument::osc::pulse, x
      rts
   @ampsel:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS combobox, amp_env, selected_entry
      sta concerto_synth::instruments::Instrument::osc::amp_sel, x
      rts
   @volume:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, volume, coarse_value
      sta concerto_synth::instruments::Instrument::osc::volume, x
      rts
   @channelsel:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS combobox, lr_select, selected_entry
      clc
      ror
      ror
      ror
      sta concerto_synth::instruments::Instrument::osc::lrmid, x
      rts
   @semitones:
      plx
      ; decide if we need to tune down to compensate for fine tuning (because fine tuning internally only goes up)
      lda concerto_synth::instruments::Instrument::osc::fine, x
      php
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, semitones, coarse_value
      plp
      bmi :+
      sta concerto_synth::instruments::Instrument::osc::pitch, x
      rts
   :  dec
      sta concerto_synth::instruments::Instrument::osc::pitch, x
      rts
   @finetune:
      plx
      ; if fine tune is now negative, but was non-negative beforehand, we need to decrement semitones
      ; and the other way round: if fine tune was negative, but now is non-negative, we need to increment semitones
      lda concerto_synth::instruments::Instrument::osc::fine, x
      bmi @fine_negative
   @fine_positive:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, fine_tune, coarse_value
      bpl @fine_normal
      dec concerto_synth::instruments::Instrument::osc::pitch, x
      bra @fine_normal
   @fine_negative:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, fine_tune, coarse_value
      bmi @fine_normal
      inc concerto_synth::instruments::Instrument::osc::pitch, x
   @fine_normal:
      sta concerto_synth::instruments::Instrument::osc::fine, x
      rts
   @keytrack:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, key_track, checked
      sta concerto_synth::instruments::Instrument::osc::track, x
      rts
   @pmsel1:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS combobox, pitch1_modsource, selected_entry
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::instruments::Instrument::osc::pitch_mod_sel1, x
      rts
   @pmsel2:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS combobox, pitch2_modsource, selected_entry
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::instruments::Instrument::osc::pitch_mod_sel2, x
      rts
   @pwmsel:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS combobox, pw_modsource, selected_entry
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::instruments::Instrument::osc::pwm_sel, x
      rts
   @volmsel:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS combobox, volume_modsource, selected_entry
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::instruments::Instrument::osc::vol_mod_sel, x
      rts
   @pitchmoddep1:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, pitch1_moddepth, coarse_value
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::instruments::Instrument::osc::pitch_mod_dep1, x
      rts
   @pitchmoddep2:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, pitch2_moddepth, coarse_value
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::instruments::Instrument::osc::pitch_mod_dep2, x
      rts
   @pwmdep:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, pw_moddepth, coarse_value
      jsr panel_common::map_twos_complement_to_signed_7bit
      sta concerto_synth::instruments::Instrument::osc::pwm_dep, x
      rts
   @vmdep:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, volume_moddepth, coarse_value
      jsr panel_common::map_twos_complement_to_signed_7bit
      sta concerto_synth::instruments::Instrument::osc::vol_mod_dep, x
      rts
   .endproc


   .proc refresh
      ; first, determine the offset of the oscillator in the Instrument data
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
      tax ; oscillator index is in x
      ; read Instrument data and load it into GUI components
      ; waveform
      lda concerto_synth::instruments::Instrument::osc::waveform, x
      clc
      rol
      rol
      rol
      STA_COMPONENT_MEMBER_ADDRESS combobox, waveform, selected_entry
      ; pulse width
      lda concerto_synth::instruments::Instrument::osc::pulse, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, pulse_width, coarse_value
      ; amplifier select
      lda concerto_synth::instruments::Instrument::osc::amp_sel, x
      STA_COMPONENT_MEMBER_ADDRESS combobox, amp_env, selected_entry
      ; volume
      lda concerto_synth::instruments::Instrument::osc::volume, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, volume, coarse_value
      ; L/R
      lda concerto_synth::instruments::Instrument::osc::lrmid, x
      clc
      rol
      rol
      rol
      STA_COMPONENT_MEMBER_ADDRESS combobox, lr_select, selected_entry
      ; semitones
      ; we need to check fine tune to get correct semi tones.
      ; if fine tune is negative, we need to increment one to the semitone value to be displayed on the GUI
      lda concerto_synth::instruments::Instrument::osc::fine, x
      bmi :+
      lda concerto_synth::instruments::Instrument::osc::pitch, x
      bra :++
   :  lda concerto_synth::instruments::Instrument::osc::pitch, x
      inc
   :  STA_COMPONENT_MEMBER_ADDRESS drag_edit, semitones, coarse_value
      ; fine tune
      lda concerto_synth::instruments::Instrument::osc::fine, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, fine_tune, coarse_value
      ; key track
      lda concerto_synth::instruments::Instrument::osc::track, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, key_track, checked
      ; pitch mod select 1
      lda concerto_synth::instruments::Instrument::osc::pitch_mod_sel1, x
      jsr panel_common::map_modsource_to_gui
      STA_COMPONENT_MEMBER_ADDRESS combobox, pitch1_modsource, selected_entry
      ; pitch mod select 2
      lda concerto_synth::instruments::Instrument::osc::pitch_mod_sel2, x
      jsr panel_common::map_modsource_to_gui
      STA_COMPONENT_MEMBER_ADDRESS combobox, pitch2_modsource, selected_entry
      ; pwm select
      lda concerto_synth::instruments::Instrument::osc::pwm_sel, x
      jsr panel_common::map_modsource_to_gui
      STA_COMPONENT_MEMBER_ADDRESS combobox, pw_modsource, selected_entry
      ; vol mod select
      lda concerto_synth::instruments::Instrument::osc::vol_mod_sel, x
      jsr panel_common::map_modsource_to_gui
      STA_COMPONENT_MEMBER_ADDRESS combobox, volume_modsource, selected_entry
      ; pitch mod depth 1
      lda concerto_synth::instruments::Instrument::osc::pitch_mod_dep1, x
      jsr concerto_synth::map_scale5_to_twos_complement
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, pitch1_moddepth, coarse_value
      ; pitch mod depth 2
      lda concerto_synth::instruments::Instrument::osc::pitch_mod_dep2, x
      jsr concerto_synth::map_scale5_to_twos_complement
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, pitch2_moddepth, coarse_value
      ; pwm depth
      lda concerto_synth::instruments::Instrument::osc::pwm_dep, x
      jsr panel_common::map_signed_7bit_to_twos_complement
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, pw_moddepth, coarse_value
      ; volume mod depth
      lda concerto_synth::instruments::Instrument::osc::vol_mod_dep, x
      jsr panel_common::map_signed_7bit_to_twos_complement
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, volume_moddepth, coarse_value
      ; number of oscillators
      ldx gui_variables::current_synth_instrument
      lda concerto_synth::instruments::Instrument::n_oscs, x
      STA_COMPONENT_MEMBER_ADDRESS arrowed_edit, n_oscs, value
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_PSG_OSCILLATORS_ASM



