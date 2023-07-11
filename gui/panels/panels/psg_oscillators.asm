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
   modsecx = px + 4
   modsecy = py + 16
   pitsecx = px + 4
   pitsecy = py + 9
   pwsecx = px + 19
   pwsecy = py + 4
   wfsecx = px + 4
   wfsecy = py + 2
   ampsecx = px + 22
   ampsecy = pitsecy

   comps:
      .byte 2, px, py, MAX_OSCS_PER_VOICE, 0 ; tabselector
      .byte 6, wfsecx, wfsecy+2, 8, 4, (<waveforms_lb), (>waveforms_lb), 0 ; waveform listbox
      .byte 4, pwsecx, pwsecy+2, %00000000, 0, 63, 0, 0 ; pulse width drag edit
      .byte 6, ampsecx, ampsecy+1, 8, N_TOT_MODSOURCES, (<panel_common::modsources_lb), (>panel_common::modsources_lb), 0 ; amp listbox
      .byte 4, ampsecx, ampsecy+4, %00000000, 0, 64, 0, 0 ; volume drag edit
      .byte 6, ampsecx+4, ampsecy+4, 5, 4, (<panel_common::channel_select_lb), (>panel_common::channel_select_lb), 0 ; channel listbox
      .byte 4, pitsecx+3, pitsecy+2, %00000100, 128, 127, 0, 0 ; semitone edit ... signed range
      .byte 4, pitsecx+3, pitsecy+4, %00000100, 128, 127, 0, 0 ; fine tune edit ... signed range
      .byte 5, pitsecx+8, pitsecy+2, 7, 0 ; pitch tracking checkbox
      .byte 6, modsecx+7, modsecy+2, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pitch mod select 1
      .byte 6, modsecx+7, modsecy+3, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pitch mod select 2
      .byte 6, modsecx+7, modsecy+4, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pw mod select
      .byte 6, modsecx+7, modsecy+5, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; volume mod select
      .byte 4, modsecx+15, modsecy+2, %10000100, 256-76, 76, 0, 0 ; drag edit - pitch mod depth 1 range
      .byte 4, modsecx+15, modsecy+3, %10000100, 256-76, 76, 0, 0 ; drag edit - pitch mod depth 2 range
      .byte 4, modsecx+15, modsecy+4, %00000100, 256-127, 127, 0, 0 ; drag edit - pw mod depth range
      .byte 4, modsecx+15, modsecy+5, %00000100, 256-127, 127, 0, 0 ; drag edit - volume mod depth range
      .byte 0

   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, wfsecx, wfsecy
      .word panel_common::waveform_lb
      .byte CCOLOR_CAPTION, pwsecx, pwsecy
      .word pulsewidth_lb
      .byte CCOLOR_CAPTION, ampsecx, ampsecy
      .word amp_lb
      .byte CCOLOR_CAPTION, ampsecx, ampsecy+3
      .word panel_common::vol_lb
      .byte CCOLOR_CAPTION, ampsecx+5, ampsecy+3
      .word panel_common::channel_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy+2
      .word panel_common::semi_lb
      .byte CCOLOR_CAPTION, pitsecx, pitsecy+4
      .word panel_common::fine_lb
      .byte CCOLOR_CAPTION, pitsecx+10, pitsecy+2
      .word panel_common::track_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy
      .word modulation_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy+2
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy+4
      .word pw_lb
      .byte CCOLOR_CAPTION, modsecx, modsecy+5
      .word panel_common::vol_lb
      .byte 0

   ; data specific to the oscillator panel
   active_tab: .byte 0
   cp: STR_FORMAT "psg oscillators" ; caption of panel
   amp_lb: STR_FORMAT "amp env"
   pulsewidth_lb: STR_FORMAT "pulse width"
   pw_lb: STR_FORMAT "pw"
   modulation_lb: STR_FORMAT "modulation"
   ; stringlist for modsource listboxes
   waveforms_lb:
      STR_FORMAT "pulse"
      STR_FORMAT "saw"
      STR_FORMAT "tri"
      STR_FORMAT "noise"
   

   .proc draw
      lda #panels_luts::psg_oscillators::px
      sta guiutils::draw_x
      lda #panels_luts::psg_oscillators::py
      sta guiutils::draw_y
      lda #panels_luts::psg_oscillators::wd
      sta guiutils::draw_width
      lda #panels_luts::psg_oscillators::hg
      sta guiutils::draw_height
      lda #MAX_OSCS_PER_VOICE
      sta guiutils::draw_data1
      lda panels_luts::psg_oscillators::active_tab
      inc
      sta guiutils::draw_data2
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ; first, determine the offset of the oscillator in the Timbre data
      lda gui_definitions::current_synth_timbre
      ldx panels_luts::psg_oscillators::active_tab ; envelope number
   @loop:
      cpx #0
      beq @end_loop
      clc
      adc #N_TIMBRES
      dex
      bra @loop
   @end_loop:
      tax ; oscillator index is in x
      ; prepare component readout
      lda mouse_definitions::curr_component_ofs
      clc
      adc #4
      tay ; there's no component type where the data is before this index
      ; now determine which component has been changed
      phx
      lda mouse_definitions::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @tab_slector
      .word @waveform
      .word @pulsewidth ; pulse width
      .word @ampsel ; amp listbox
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
      lda mouse_definitions::curr_data_1
      sta panels_luts::psg_oscillators::active_tab
      jsr refresh
      rts
   @waveform:
      plx
      iny
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      clc
      ror
      ror
      ror
      sta concerto_synth::timbres::Timbre::osc::waveform, x
      rts
   @pulsewidth:
      plx
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      sta concerto_synth::timbres::Timbre::osc::pulse, x
      rts
   @ampsel:
      plx
      iny
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      sta concerto_synth::timbres::Timbre::osc::amp_sel, x
      rts
   @volume:
      plx
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      sta concerto_synth::timbres::Timbre::osc::volume, x
      rts
   @channelsel:
      plx
      iny
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      clc
      ror
      ror
      ror
      sta concerto_synth::timbres::Timbre::osc::lrmid, x
      rts
   @semitones:
      plx
      iny
      iny
      ; decide if we need to tune down to compensate for fine tuning (because fine tuning internally only goes up)
      lda concerto_synth::timbres::Timbre::osc::fine, x
      bmi :+
      lda panels_luts::psg_oscillators::comps, y
      sta concerto_synth::timbres::Timbre::osc::pitch, x
      rts
   :  lda panels_luts::psg_oscillators::comps, y
      dec
      sta concerto_synth::timbres::Timbre::osc::pitch, x
      rts
   @finetune:
      plx
      iny
      iny
      ; if fine tune is now negative, but was non-negative beforehand, we need to decrement semitones
      ; and the other way round: if fine tune was negative, but now is non-negative, we need to increment semitones
      lda concerto_synth::timbres::Timbre::osc::fine, x
      bmi @fine_negative
   @fine_positive:
      lda panels_luts::psg_oscillators::comps, y
      bpl @fine_normal
      dec concerto_synth::timbres::Timbre::osc::pitch, x
      bra @fine_normal
   @fine_negative:
      lda panels_luts::psg_oscillators::comps, y
      bmi @fine_normal
      inc concerto_synth::timbres::Timbre::osc::pitch, x
   @fine_normal:
      sta concerto_synth::timbres::Timbre::osc::fine, x
      rts
   @keytrack:
      plx
      lda panels_luts::psg_oscillators::comps, y
      sta concerto_synth::timbres::Timbre::osc::track, x
      rts
   @pmsel1:
      plx
      iny
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
      rts
   @pmsel2:
      plx
      iny
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
      rts
   @pwmsel:
      plx
      iny
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
      rts
   @volmsel:
      plx
      iny
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
      rts
   @pitchmoddep1:
      plx
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
      rts
   @pitchmoddep2:
      plx
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
      rts
   @pwmdep:
      plx
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr panel_common::map_twos_complement_to_signed_7bit
      sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
      rts
   @vmdep:
      plx
      iny
      iny
      lda panels_luts::psg_oscillators::comps, y
      jsr panel_common::map_twos_complement_to_signed_7bit
      sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
      rts
   .endproc


   .proc refresh
      ; first, determine the offset of the oscillator in the Timbre data
      lda gui_definitions::current_synth_timbre
      ldx panels_luts::psg_oscillators::active_tab ; envelope number
   @loop:
      cpx #0
      beq @end_loop
      clc
      adc #N_TIMBRES
      dex
      bra @loop
   @end_loop:
      tax ; oscillator index is in x
      ; read Timbre data and load it into GUI components
      ; waveform
      lda concerto_synth::timbres::Timbre::osc::waveform, x
      clc
      rol
      rol
      rol
      ldy #(tab_selector_data_size+listbox_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; pulse width
      lda concerto_synth::timbres::Timbre::osc::pulse, x
      ldy #(tab_selector_data_size+listbox_data_size+0*checkbox_data_size+drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; amplifier select
      lda concerto_synth::timbres::Timbre::osc::amp_sel, x
      ldy #(tab_selector_data_size+2*listbox_data_size+0*checkbox_data_size+drag_edit_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; volume
      lda concerto_synth::timbres::Timbre::osc::volume, x
      ldy #(tab_selector_data_size+2*listbox_data_size+0*checkbox_data_size+2*drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; L/R
      lda concerto_synth::timbres::Timbre::osc::lrmid, x
      clc
      rol
      rol
      rol
      ldy #(tab_selector_data_size+3*listbox_data_size+0*checkbox_data_size+2*drag_edit_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; semitones
      ; we need to check fine tune to get correct semi tones.
      ; if fine tune is negative, we need to increment one to the semitone value to be displayed on the GUI
      lda concerto_synth::timbres::Timbre::osc::fine, x
      bmi :+
      lda concerto_synth::timbres::Timbre::osc::pitch, x
      bra :++
   :  lda concerto_synth::timbres::Timbre::osc::pitch, x
      inc
   :  ldy #(tab_selector_data_size+3*listbox_data_size+0*checkbox_data_size+3*drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; fine tune
      lda concerto_synth::timbres::Timbre::osc::fine, x
      ldy #(tab_selector_data_size+3*listbox_data_size+0*checkbox_data_size+4*drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; key track
      lda concerto_synth::timbres::Timbre::osc::track, x
      ldy #(tab_selector_data_size+3*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; pitch mod select 1
      lda concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
      jsr panel_common::map_modsource_to_gui
      ldy #(tab_selector_data_size+4*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; pitch mod select 2
      lda concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
      jsr panel_common::map_modsource_to_gui
      ldy #(tab_selector_data_size+5*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; pwm select
      lda concerto_synth::timbres::Timbre::osc::pwm_sel, x
      jsr panel_common::map_modsource_to_gui
      ldy #(tab_selector_data_size+6*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; vol mod select
      lda concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
      jsr panel_common::map_modsource_to_gui
      ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
      sta panels_luts::psg_oscillators::comps, y
      ; pitch mod depth 1
      lda concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
      jsr concerto_synth::map_scale5_to_twos_complement
      ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+5*drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; pitch mod depth 2
      lda concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
      jsr concerto_synth::map_scale5_to_twos_complement
      ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+6*drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; pwm depth
      lda concerto_synth::timbres::Timbre::osc::pwm_dep, x
      jsr panel_common::map_signed_7bit_to_twos_complement
      ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+7*drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; volume mod depth
      lda concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
      jsr panel_common::map_signed_7bit_to_twos_complement
      ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+8*drag_edit_data_size-2)
      sta panels_luts::psg_oscillators::comps, y
      ; redraw components
      lda #1
      jsr draw_components
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_PSG_OSCILLATORS_ASM



