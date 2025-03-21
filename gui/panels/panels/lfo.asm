; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_LFO_ASM

::GUI_PANELS_PANELS_LFO_ASM = 1

.include "common.asm"

; LFO settings panel
.scope lfo
   px = envelopes::px+envelopes::wd
   py = psg_oscillators::py+psg_oscillators::hg+1
   wd = (synth_global::wd+psg_oscillators::wd-envelopes::wd)
   hg = envelopes::hg
   comps:
   .scope comps
      COMPONENT_DEFINITION checkbox, lfo_activate, px+2, py, 8, 1
      COMPONENT_DEFINITION combobox, waveform, px+2, py+3, 8, 5, A lfo_waveform_lb, 0
      COMPONENT_DEFINITION checkbox, retrigger, px+12, py+2, 8, 0
      COMPONENT_DEFINITION drag_edit, rate, px+7 , py+5, %00000001, 0, 128, 10, 0
      COMPONENT_DEFINITION drag_edit, phase, px+14 , py+5, %00000000, 0, 255, 0, 0
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte (COLOR_IMPORTANT_CAPTION+16*COLOR_BACKGROUND), px+4, py
      .word lfo_lb
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
   lfo_lb: STR_FORMAT "software lfo"
   lfo_waveform_lb:
      STR_FORMAT "tri"
      STR_FORMAT "squ"
      STR_FORMAT "saw up"
      STR_FORMAT "saw dn"
      STR_FORMAT "s'n'h"

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
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ldy gui_variables::current_synth_instrument
      ; now determine which component has been dragged
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @n_lfos
      .word @wave
      .word @retr
      .word @rate
      .word @offs
   @n_lfos:
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, lfo_activate, checked
      sta concerto_synth::instruments::Instrument::n_lfos, y
      rts
   @wave:
      LDA_COMPONENT_MEMBER_ADDRESS combobox, waveform, selected_entry
      sta concerto_synth::instruments::Instrument::lfo::wave, y
      rts
   @retr:
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, retrigger, checked
      sta concerto_synth::instruments::Instrument::lfo::retrig, y
      rts
   @rate:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, rate, coarse_value
      sta concerto_synth::instruments::Instrument::lfo::rateH, y
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, rate, fine_value
      sta concerto_synth::instruments::Instrument::lfo::rateL, y
      rts
   @offs:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, phase, coarse_value
      sta concerto_synth::instruments::Instrument::lfo::offs, y
      rts
   .endproc


   .proc refresh
      ldx gui_variables::current_synth_instrument
      ; LFO activate checkbox
      lda concerto_synth::instruments::Instrument::n_lfos, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, lfo_activate, checked
      ; LFO waveform
      lda concerto_synth::instruments::Instrument::lfo::wave, x
      STA_COMPONENT_MEMBER_ADDRESS combobox, waveform, selected_entry
      ; LFO retrigger
      lda concerto_synth::instruments::Instrument::lfo::retrig, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, retrigger, checked
      ; LFO rate
      lda concerto_synth::instruments::Instrument::lfo::rateH, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, rate, coarse_value
      lda concerto_synth::instruments::Instrument::lfo::rateL, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, rate, fine_value
      ; phase offset
      lda concerto_synth::instruments::Instrument::lfo::offs, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, phase, coarse_value
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_LFO_ASM
