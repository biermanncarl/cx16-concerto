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
      .byte 3, px+3, py+3, 0, MAX_OSCS_PER_VOICE, 1 ; number of oscillators
      .byte 3, px+3, py+6, 1, 3, 1 ; number of envelopes
      .byte 5, px+2, py+8, 8, 1 ; LFO activate checkbox
      .byte 5, px+2, py+12, 8, 1 ; retrigger checkbox
      .byte 5, px+2, py+14, 8, 0 ; porta checkbox
      .byte 4, px+2, py+16, %00000000, 0, 255, 0, 0 ; porta rate edit
      .byte 4, px+7, py+19, %00000000, 0, 76, 0, 0 ; vibrato amount edit
      .byte 0
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
      lda #panels_luts::synth_global::px
      sta guiutils::draw_x
      lda #panels_luts::synth_global::py
      sta guiutils::draw_y
      lda #panels_luts::synth_global::wd
      sta guiutils::draw_width
      lda #panels_luts::synth_global::hg
      sta guiutils::draw_height
      lda #0
      sta guiutils::draw_data1
      lda #0
      sta guiutils::draw_data2
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ldx gui_definitions::current_synth_timbre
      lda mouse_definitions::curr_component_ofs
      clc
      adc #5
      tay ; there's no component type where the data is before this index
      ; now jump to component which has been clicked/dragged
      phx
      lda mouse_definitions::curr_component_id
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
      lda panels_luts::synth_global::comps, y
      sta concerto_synth::timbres::Timbre::n_oscs, x
      rts
   @n_envs:
      plx
      lda panels_luts::synth_global::comps, y
      sta concerto_synth::timbres::Timbre::n_envs, x
      rts
   @n_lfos:
      plx
      dey
      lda panels_luts::synth_global::comps, y
      sta concerto_synth::timbres::Timbre::n_lfos, x
      rts
   @retr_activate:
      plx
      dey
      lda panels_luts::synth_global::comps, y
      sta concerto_synth::timbres::Timbre::retrig, x
      rts
   @porta_activate:
      plx
      dey
      lda panels_luts::synth_global::comps, y
      sta concerto_synth::timbres::Timbre::porta, x
      rts
   @porta_rate:
      plx
      iny
      lda panels_luts::synth_global::comps, y
      sta concerto_synth::timbres::Timbre::porta_r, x
      rts
   @vibrato_amount:
      plx
      iny
      lda panels_luts::synth_global::comps, y ; if this value is 0, that means vibrato off, which is represented as a negative value internally
      beq :+
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::timbres::Timbre::vibrato, x
      rts
   :  lda #$FF
      sta concerto_synth::timbres::Timbre::vibrato, x
      rts
   .endproc


   .proc refresh
      ldx gui_definitions::current_synth_timbre
      ; number of oscillators
      lda concerto_synth::timbres::Timbre::n_oscs, x
      ldy #(0*checkbox_data_size+0*drag_edit_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::synth_global::comps, y
      ; number of envelopes
      lda concerto_synth::timbres::Timbre::n_envs, x
      ldy #(0*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
      sta panels_luts::synth_global::comps, y
      ; LFO activate checkbox
      lda concerto_synth::timbres::Timbre::n_lfos, x
      ldy #(1*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
      sta panels_luts::synth_global::comps, y
      ; retrigger checkbox
      lda concerto_synth::timbres::Timbre::retrig, x
      ldy #(2*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
      sta panels_luts::synth_global::comps, y
      ; porta activate checkbox
      lda concerto_synth::timbres::Timbre::porta, x
      ldy #(3*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
      sta panels_luts::synth_global::comps, y
      ; porta rate edit
      lda concerto_synth::timbres::Timbre::porta_r, x
      ldy #(3*checkbox_data_size+1*drag_edit_data_size+2*arrowed_edit_data_size-2)
      sta panels_luts::synth_global::comps, y
      ; vibrato amount edit
      lda concerto_synth::timbres::Timbre::vibrato, x
      bmi :+
      jsr concerto_synth::map_scale5_to_twos_complement
      bra :++
   :  lda #0
   :  ldy #(3*checkbox_data_size+2*drag_edit_data_size+2*arrowed_edit_data_size-2)
      sta panels_luts::synth_global::comps, y
      ; redraw components
      lda #0
      jsr draw_components
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_ASM



