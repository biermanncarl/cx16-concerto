; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_ENVELOPE_ASM

::GUI_PANELS_PANELS_ENVELOPE_ASM = 1

.include "common.asm"

; envelope settings panel
.scope envelopes
   px = synth_global::px
   py = psg_oscillators::py+psg_oscillators::hg
   wd = 24
   hg = 8
   comps:
      .byte 2, px, py, 3, 0 ; tab selector
      .byte 4, px+4 , py+4, %00000001, 0, 127, 0, 0 ; drag edit - attack
      .byte 4, px+9 , py+4, %00000001, 0, 127, 0, 0 ; drag edit - decay
      .byte 4, px+14, py+4, %00000000, 0, ENV_PEAK, 0, 0 ; drag edit - sustain
      .byte 4, px+18, py+4, %00000001, 0, 127, 0, 0 ; drag edit - release
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, px+4, py+3
      .word panel_common::lb_attack
      .byte CCOLOR_CAPTION, px+9, py+3
      .word lb_decay
      .byte CCOLOR_CAPTION, px+14, py+3
      .word lb_sustain
      .byte CCOLOR_CAPTION, px+18, py+3
      .word panel_common::lb_release
      .byte 0
   ; data specific to the envelope panel
   active_tab: .byte 0
   cp: STR_FORMAT "envelopes" ; caption of panel
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
      ; first, determine the offset of the envelope in the Timbre data
      lda gui_definitions::current_synth_timbre
      ldx active_tab ; envelope number
   @loop:
      cpx #0
      beq @end_loop
      clc
      adc #N_TIMBRES
      dex
      bra @loop
   @end_loop:
      tax ; envelope index is in x
      ; prepare drag edit readout
      lda mouse_definitions::curr_component_ofs
      clc
      adc #6 ; 6 because most of the control elements are drag edits anyway
      tay ; drag edit's coarse value offset is in Y
      ; now determine which component has been dragged
      phx
      lda mouse_definitions::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @tab_select
      .word @attack
      .word @decay
      .word @sustain
      .word @release
   @tab_select:
      plx
      lda mouse_definitions::curr_data_1
      sta active_tab
      jsr refresh
      inc gui_definitions::request_components_redraw
      rts
   @attack:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::env::attackH, x
      iny
      lda comps, y
      sta concerto_synth::timbres::Timbre::env::attackL, x
      rts
   @decay:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::env::decayH, x
      iny
      lda comps, y
      sta concerto_synth::timbres::Timbre::env::decayL, x
      rts
   @sustain:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::env::sustain, x
      rts
   @release:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::env::releaseH, x
      iny
      lda comps, y
      sta concerto_synth::timbres::Timbre::env::releaseL, x
      rts
   @skip:
      plx
      rts
   .endproc


   .proc refresh
      ; first, determine the offset of the envelope in the Timbre data
      lda gui_definitions::current_synth_timbre
      ldx active_tab ; envelope number
   @loop:
      cpx #0
      beq @end_loop
      clc
      adc #N_TIMBRES
      dex
      bra @loop
   @end_loop:
      tax ; envelope index is in x
      ; read ADSR data from Timbre and load it into edits
      ; attack edit
      ldy #(tab_selector_data_size + 6)
      lda concerto_synth::timbres::Timbre::env::attackH, x
      sta comps, y
      iny
      lda concerto_synth::timbres::Timbre::env::attackL, x
      sta comps, y
      ; decay edit
      tya
      clc
      adc #(drag_edit_data_size-1)
      tay
      lda concerto_synth::timbres::Timbre::env::decayH, x
      sta comps, y
      iny
      lda concerto_synth::timbres::Timbre::env::decayL, x
      sta comps, y
      ; sustain edit
      tya
      clc
      adc #(drag_edit_data_size-1)
      tay
      lda concerto_synth::timbres::Timbre::env::sustain, x
      sta comps, y
      ; release edit
      tya
      clc
      adc #(drag_edit_data_size)
      tay
      lda concerto_synth::timbres::Timbre::env::releaseH, x
      sta comps, y
      iny
      lda concerto_synth::timbres::Timbre::env::releaseL, x
      sta comps, y
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_ENVELOPE_ASM
