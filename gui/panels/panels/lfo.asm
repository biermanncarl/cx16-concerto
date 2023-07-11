; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_LFO_ASM

::GUI_PANELS_PANELS_LFO_ASM = 1

.include "common.asm"

; LFO settings panel
.scope lfo
   px = envelopes::px+envelopes::wd
   py = psg_oscillators::py+psg_oscillators::hg
   wd = (synth_global::wd+psg_oscillators::wd-envelopes::wd)
   hg = envelopes::hg
   comps:
      .byte 6, px+2, py+3, 8, 5, (<lfo_waveform_lb), (>lfo_waveform_lb), 0 ; waveform listbox
      .byte 5, px+12, py+2, 8, 0 ; LFO retrigger checkbox
      .byte 4, px+7 , py+5, %00000001, 0, 128, 10, 0 ; drag edit - LFO rate
      .byte 4, px+14 , py+5, %00000000, 0, 255, 0, 0 ; drag edit - LFO phase offset
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word panel_common::lfo_lb
      .byte CCOLOR_CAPTION, px+2, py+2
      .word panel_common::waveform_lb
      .byte CCOLOR_CAPTION, px+14, py+2
      .word panel_common::retr_lb
      .byte CCOLOR_CAPTION, px+2, py+5
      .word panel_common::rate_lb
      .byte CCOLOR_CAPTION, px+14, py+4
      .word phase_lb
      .byte 0
   ; data specific to the LFO panel
   phase_lb: STR_FORMAT "phase"
   lfo_waveform_lb:
      STR_FORMAT "tri"
      STR_FORMAT "squ"
      STR_FORMAT "saw up"
      STR_FORMAT "saw dn"
      STR_FORMAT "s'n'h"

   .proc draw
      lda #panels_luts::lfo::px
      sta guiutils::draw_x
      lda #panels_luts::lfo::py
      sta guiutils::draw_y
      lda #panels_luts::lfo::wd
      sta guiutils::draw_width
      lda #panels_luts::lfo::hg
      sta guiutils::draw_height
      lda #0
      sta guiutils::draw_data1
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ldx gui_definitions::current_synth_timbre
      lda mouse_definitions::curr_component_ofs
      clc
      adc #6
      tay ; there's no component type where the data is before this index
      ; now determine which component has been dragged
      phx
      lda mouse_definitions::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @wave
      .word @retr
      .word @rate
      .word @offs
   @wave:
      plx
      iny
      lda panels_luts::lfo::comps, y
      sta concerto_synth::timbres::Timbre::lfo::wave, x
      rts
   @retr:
      plx
      dey
      dey
      lda panels_luts::lfo::comps, y
      sta concerto_synth::timbres::Timbre::lfo::retrig, x
      rts
   @rate:
      plx
      lda panels_luts::lfo::comps, y
      sta concerto_synth::timbres::Timbre::lfo::rateH, x
      iny
      lda panels_luts::lfo::comps, y
      sta concerto_synth::timbres::Timbre::lfo::rateL, x
      rts
   @offs:
      plx
      lda panels_luts::lfo::comps, y
      sta concerto_synth::timbres::Timbre::lfo::offs, x
      rts
   .endproc


   .proc refresh
      ldx gui_definitions::current_synth_timbre
      ; LFO waveform
      lda concerto_synth::timbres::Timbre::lfo::wave, x
      ldy #(0*checkbox_data_size+0*drag_edit_data_size+1*listbox_data_size-1)
      sta panels_luts::lfo::comps, y
      ; LFO retrigger
      lda concerto_synth::timbres::Timbre::lfo::retrig, x
      ldy #(1*checkbox_data_size+0*drag_edit_data_size+1*listbox_data_size-1)
      sta panels_luts::lfo::comps, y
      ; LFO rate
      lda concerto_synth::timbres::Timbre::lfo::rateH, x
      ldy #(1*checkbox_data_size+1*drag_edit_data_size+1*listbox_data_size-2)
      sta panels_luts::lfo::comps, y
      iny
      lda concerto_synth::timbres::Timbre::lfo::rateL, x
      sta panels_luts::lfo::comps, y
      ; phase offset
      lda concerto_synth::timbres::Timbre::lfo::offs, x
      ldy #(1*checkbox_data_size+2*drag_edit_data_size+1*listbox_data_size-2)
      sta panels_luts::lfo::comps, y
      ; redraw components
      lda #5
      jsr draw_components
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_LFO_ASM
