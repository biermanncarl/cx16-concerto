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
      .byte 3, px+13, py+4, 0, 7, 0 ; connection scheme number (arrowed edit)
      .byte 4, px+14, py+6, %0, 0, 7, 0, 0 ; feedback level (drag edit)
      .byte 5, px+15, py+2, 2, 0 ; activate operator 1 checkbox
      .byte 5, px+18, py+2, 2, 0 ; activate operator 2 checkbox
      .byte 5, px+21, py+2, 2, 0 ; activate operator 3 checkbox
      .byte 5, px+24, py+2, 2, 0 ; activate operator 4 checkbox
      .byte 6, px+13, py+8, 5, 4, (<panel_common::channel_select_lb), (>panel_common::channel_select_lb), 0 ; L/R listbox
      .byte 4, px+5, py+13, %00000100, 128, 127, 0, 0 ; semitone edit ... signed range
      .byte 4, px+5, py+14, %00000100, 128, 127, 0, 0 ; fine tune edit ... signed range
      .byte 5, px+13, py+11, 7, 0 ; pitch tracking checkbox
      .byte 6, px+13, py+13, 8, N_TOT_MODSOURCES+1, (<panel_common::modsources_none_option_lb), (>panel_common::modsources_none_option_lb), 0 ; pitch mod select
      .byte 4, px+21, py+13, %10000100, 256-76, 76, 0, 0 ; drag edit - pitch mod depth
      .byte 0
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
      lda #panels_luts::fm_general::px
      sta guiutils::draw_x
      lda #panels_luts::fm_general::py
      sta guiutils::draw_y
      lda #panels_luts::fm_general::wd
      sta guiutils::draw_width
      lda #panels_luts::fm_general::hg
      sta guiutils::draw_height
      lda #0
      sta guiutils::draw_data1
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      wfm_bits = mzpbe
      ; invalidate all FM timbres that have been loaded onto the YM2151 (i.e. enforce reload after timbre has been changed)
      jsr concerto_synth::voices::panic
      jsr concerto_synth::voices::invalidate_fm_timbres
      ; do the usual stuff
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
      lda panels_luts::fm_general::comps, y
      sta concerto_synth::timbres::Timbre::fm_general::con, x
      ; draw FM algorithm
      sta guiutils::draw_data1
      jsr guiutils::draw_fm_alg
      rts
   @feedback:
      plx
      lda panels_luts::fm_general::comps, y
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
      lda panels_luts::fm_general::comps, y
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
      lda panels_luts::fm_general::comps, y
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
      lda panels_luts::fm_general::comps, y
      sta concerto_synth::timbres::Timbre::fm_general::pitch, x
      rts
   :  lda panels_luts::fm_general::comps, y
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
      lda panels_luts::fm_general::comps, y
      bpl @fine_normal
      dec concerto_synth::timbres::Timbre::fm_general::pitch, x
      bra @fine_normal
   @fine_negative:
      lda panels_luts::fm_general::comps, y
      bmi @fine_normal
      inc concerto_synth::timbres::Timbre::fm_general::pitch, x
   @fine_normal:
      sta concerto_synth::timbres::Timbre::fm_general::fine, x
      rts
   @keytrack:
      plx
      dey
      dey
      lda panels_luts::fm_general::comps, y
      sta concerto_synth::timbres::Timbre::fm_general::track, x
      rts
   @pmsel:
      plx
      iny
      lda panels_luts::fm_general::comps, y
      jsr panel_common::map_modsource_from_gui
      sta concerto_synth::timbres::Timbre::fm_general::pitch_mod_sel, x
      rts
   @pitchmoddep:
      plx
      lda panels_luts::fm_general::comps, y
      jsr concerto_synth::map_twos_complement_to_scale5
      sta concerto_synth::timbres::Timbre::fm_general::pitch_mod_dep, x
      rts
   .endproc


   .proc refresh
      @rfm_bits = mzpbd
      ldx gui_definitions::current_synth_timbre
      ; connection scheme
      lda concerto_synth::timbres::Timbre::fm_general::con, x
      ldy #(0*checkbox_data_size+0*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; feedback level
      lda concerto_synth::timbres::Timbre::fm_general::fl, x
      ldy #(0*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-2)
      sta panels_luts::fm_general::comps, y
      ; operators enable
      lda concerto_synth::timbres::Timbre::fm_general::op_en, x
      sta @rfm_bits
      ; operator 1 enable
      lda #0
      bbr0 @rfm_bits, :+
      lda #1
   :  ldy #(1*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; operator 2 enable
      lda #0
      bbr1 @rfm_bits, :+
      lda #1
   :  ldy #(2*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; operator 3 enable
      lda #0
      bbr2 @rfm_bits, :+
      lda #1
   :  ldy #(3*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; operator 4 enable
      lda #0
      bbr3 @rfm_bits, :+
      lda #1
   :  ldy #(4*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; LR channel select
      lda concerto_synth::timbres::Timbre::fm_general::lr, x
      clc
      rol
      rol
      rol
      ldy #(4*checkbox_data_size+1*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; semitones
      ; we need to check fine tune to get correct semi tones.
      ; if fine tune is negative, we need to increment one to the semitone value to be displayed on the GUI
      lda concerto_synth::timbres::Timbre::fm_general::fine, x
      bmi :+
      lda concerto_synth::timbres::Timbre::fm_general::pitch, x
      bra :++
   :  lda concerto_synth::timbres::Timbre::fm_general::pitch, x
      inc
   :  ldy #(4*checkbox_data_size+2*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-2)
      sta panels_luts::fm_general::comps, y
      ; fine tune
      lda concerto_synth::timbres::Timbre::fm_general::fine, x
      ldy #(4*checkbox_data_size+3*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-2)
      sta panels_luts::fm_general::comps, y
      ; key track
      lda concerto_synth::timbres::Timbre::fm_general::track, x
      ldy #(5*checkbox_data_size+3*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; pitch mod select
      lda concerto_synth::timbres::Timbre::fm_general::pitch_mod_sel, x
      jsr panel_common::map_modsource_to_gui
      ldy #(5*checkbox_data_size+3*drag_edit_data_size+2*listbox_data_size+1*arrowed_edit_data_size-1)
      sta panels_luts::fm_general::comps, y
      ; pitch mod depth
      lda concerto_synth::timbres::Timbre::fm_general::pitch_mod_dep, x
      jsr concerto_synth::map_scale5_to_twos_complement
      ldy #(5*checkbox_data_size+4*drag_edit_data_size+2*listbox_data_size+1*arrowed_edit_data_size-2)
      sta panels_luts::fm_general::comps, y

      ; redraw components
      lda #7
      jsr draw_components
      ; redraw FM algorithm
      ldx gui_definitions::current_synth_timbre
      lda concerto_synth::timbres::Timbre::fm_general::con, x
      sta guiutils::draw_data1
      jsr guiutils::draw_fm_alg
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FM_GENERAL_ASM
