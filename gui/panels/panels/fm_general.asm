; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FM_GENERAL_ASM

::GUI_PANELS_PANELS_FM_GENERAL_ASM = 1

.include "common.asm"

; FM general setup (everything that isn't operators)
.scope fm_general
   px = synth_global::px
   py = envelopes::py+envelopes::hg+1
   wd = 29
   hg = 17
   comps:
   .scope comps
      COMPONENT_DEFINITION arrowed_edit, connection, px+13, py+4, 0, 7, 0
      COMPONENT_DEFINITION drag_edit, feedback, px+14, py+6, %0, 0, 7, 0, 0
      COMPONENT_DEFINITION checkbox, op1_active, px+15, py+2, 2, 0
      COMPONENT_DEFINITION checkbox, op2_active, px+18, py+2, 2, 0
      COMPONENT_DEFINITION checkbox, op3_active, px+21, py+2, 2, 0
      COMPONENT_DEFINITION checkbox, op4_active, px+24, py+2, 2, 0
      COMPONENT_DEFINITION listbox, lr_select, px+13, py+8, 5, 4, A panel_common::channel_select_lb, 0
      COMPONENT_DEFINITION drag_edit, semitones, px+5, py+13, %00000100, 128, 127, 0, 0
      COMPONENT_DEFINITION drag_edit, fine_tune, px+5, py+14, %00000100, 128, 127, 0, 0
      COMPONENT_DEFINITION checkbox, key_track, px+13, py+11, 7, 0
      COMPONENT_DEFINITION listbox, pitchmod_sel, px+13, py+13, 8, N_TOT_MODSOURCES+1, A panel_common::modsources_none_option_lb, 0
      COMPONENT_DEFINITION drag_edit, pitchmod_dep, px+21, py+13, %10000100, 256-76, 76, 0, 0
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
      .byte CCOLOR_CAPTION, px+2, py+8
      .word panel_common::channel_lb
      .byte CCOLOR_CAPTION, px+2, py+11
      .word panel_common::pitch_lb
      .byte CCOLOR_CAPTION, px+15, py+11
      .word panel_common::track_lb
      .byte CCOLOR_CAPTION, px+2, py+13
      .word panel_common::semi_lb
      .byte CCOLOR_CAPTION, px+2, py+14
      .word panel_common::fine_lb
      .byte 0
   cp: STR_FORMAT "fm general"
   con_select_lb: STR_FORMAT "connection"
   lb_feedback: STR_FORMAT "feedback"
   lb_op_en: STR_FORMAT "activate op."
   lb_op1: STR_FORMAT "1"
   lb_op2: STR_FORMAT "2"
   lb_op3: STR_FORMAT "3"
   lb_op4: STR_FORMAT "4"

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
      ; draw FM algorithm
      ldx gui_variables::current_synth_timbre
      lda concerto_synth::timbres::Timbre::fm_general::con, x
      sta guiutils::draw_data1
      jsr guiutils::draw_fm_alg
      rts
   .endproc

   .proc write
      wfm_bits = gui_variables::mzpbe
      ; invalidate all FM timbres that have been loaded onto the YM2151 (i.e. enforce reload after timbre has been changed)
      jsr concerto_synth::voices::panic
      jsr concerto_synth::voices::invalidate_fm_timbres
      ; do the usual stuff
      ldx gui_variables::current_synth_timbre
      lda mouse_variables::curr_component_ofs
      clc
      adc #5
      tay ; there's no component type where the data is before this index
      ; now determine which component has been dragged
      phx
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
   @connection:
      plx
      dey
      lda comps, y
      sta concerto_synth::timbres::Timbre::fm_general::con, x
      ; redraw FM algorithm
      sta guiutils::draw_data1
      jsr guiutils::draw_fm_alg
      rts
   @feedback:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::fm_general::fl, x
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
      bra @op_active_common
   @op_active_common: ; DON'T put this label into jump table ...
      plx
      ; get checkbox value
      dey
      dey
      lda comps, y
      ; push into carry flag
      lsr
      lda wfm_bits
      bcc :+
      ; checkbox activated
      ora concerto_synth::timbres::Timbre::fm_general::op_en, x
      bra :++
   :  ; checkbox deactivated
      eor #%11111111
      and concerto_synth::timbres::Timbre::fm_general::op_en, x
   :  sta concerto_synth::timbres::Timbre::fm_general::op_en, x
      rts
   @lr_select:
      plx
      iny
      lda comps, y
      clc
      ror
      ror
      ror
      sta concerto_synth::timbres::Timbre::fm_general::lr, x
      rts
   @semitones:
      plx
      ; decide if we need to tune down to compensate for fine tuning (because fine tuning internally only goes up)
      lda concerto_synth::timbres::Timbre::fm_general::fine, x
      bmi :+
      lda comps, y
      sta concerto_synth::timbres::Timbre::fm_general::pitch, x
      rts
   :  lda comps, y
      dec
      sta concerto_synth::timbres::Timbre::fm_general::pitch, x
      rts
   @finetune:
      plx
      ; if fine tune is now negative, but was non-negative beforehand, we need to decrement semitones
      ; and the other way round: if fine tune was negative, but now is non-negative, we need to increment semitones
      lda concerto_synth::timbres::Timbre::fm_general::fine, x
      bmi @fine_negative
   @fine_positive:
      lda comps, y
      bpl @fine_normal
      dec concerto_synth::timbres::Timbre::fm_general::pitch, x
      bra @fine_normal
   @fine_negative:
      lda comps, y
      bmi @fine_normal
      inc concerto_synth::timbres::Timbre::fm_general::pitch, x
   @fine_normal:
      sta concerto_synth::timbres::Timbre::fm_general::fine, x
      rts
   @keytrack:
      plx
      dey
      dey
      lda comps, y
      sta concerto_synth::timbres::Timbre::fm_general::track, x
      rts
   @pmsel:
      plx
      iny
      lda comps, y
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::timbres::Timbre::fm_general::pitch_mod_sel, x
      rts
   @pitchmoddep:
      plx
      lda comps, y
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::timbres::Timbre::fm_general::pitch_mod_dep, x
      rts
   .endproc


   .proc refresh
      @rfm_bits = gui_variables::mzpbd
      ldx gui_variables::current_synth_timbre
      ; connection scheme
      lda concerto_synth::timbres::Timbre::fm_general::con, x
      LDY_COMPONENT_MEMBER arrowed_edit, connection, value
      sta comps, y
      ; feedback level
      lda concerto_synth::timbres::Timbre::fm_general::fl, x
      LDY_COMPONENT_MEMBER drag_edit, feedback, coarse_value
      sta comps, y
      ; operators enable
      lda concerto_synth::timbres::Timbre::fm_general::op_en, x
      sta @rfm_bits
      ; operator 1 enable
      lda #0
      bbr0 @rfm_bits, :+
      lda #1
   :  LDY_COMPONENT_MEMBER checkbox, op1_active, checked
      sta comps, y
      ; operator 2 enable
      lda #0
      bbr1 @rfm_bits, :+
      lda #1
   :  LDY_COMPONENT_MEMBER checkbox, op2_active, checked
      sta comps, y
      ; operator 3 enable
      lda #0
      bbr2 @rfm_bits, :+
      lda #1
   :  LDY_COMPONENT_MEMBER checkbox, op3_active, checked
      sta comps, y
      ; operator 4 enable
      lda #0
      bbr3 @rfm_bits, :+
      lda #1
   :  LDY_COMPONENT_MEMBER checkbox, op4_active, checked
      sta comps, y
      ; LR channel select
      lda concerto_synth::timbres::Timbre::fm_general::lr, x
      clc
      rol
      rol
      rol
      LDY_COMPONENT_MEMBER listbox, lr_select, selected_entry
      sta comps, y
      ; semitones
      ; we need to check fine tune to get correct semi tones.
      ; if fine tune is negative, we need to increment one to the semitone value to be displayed on the GUI
      lda concerto_synth::timbres::Timbre::fm_general::fine, x
      bmi :+
      lda concerto_synth::timbres::Timbre::fm_general::pitch, x
      bra :++
   :  lda concerto_synth::timbres::Timbre::fm_general::pitch, x
      inc
   :  LDY_COMPONENT_MEMBER drag_edit, semitones, coarse_value
      sta comps, y
      ; fine tune
      lda concerto_synth::timbres::Timbre::fm_general::fine, x
      LDY_COMPONENT_MEMBER drag_edit, fine_tune, coarse_value
      sta comps, y
      ; key track
      lda concerto_synth::timbres::Timbre::fm_general::track, x
      LDY_COMPONENT_MEMBER checkbox, key_track, checked
      sta comps, y
      ; pitch mod select
      lda concerto_synth::timbres::Timbre::fm_general::pitch_mod_sel, x
      jsr panel_common::map_modsource_to_gui
      LDY_COMPONENT_MEMBER listbox, pitchmod_sel, selected_entry
      sta comps, y
      ; pitch mod depth
      lda concerto_synth::timbres::Timbre::fm_general::pitch_mod_dep, x
      jsr concerto_synth::map_scale5_to_twos_complement
      LDY_COMPONENT_MEMBER drag_edit, pitchmod_dep, coarse_value
      sta comps, y
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FM_GENERAL_ASM
