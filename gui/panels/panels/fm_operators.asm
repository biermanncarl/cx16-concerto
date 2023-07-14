; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FM_OPERATORS_ASM

::GUI_PANELS_PANELS_FM_OPERATORS_ASM = 1

.include "common.asm"

; FM operators setup
.scope fm_operators
   px = fm_general::px+fm_general::wd
   py = fm_general::py
   wd = fm_general::wd
   hg = 17
   comps:
      .byte 2, px, py, N_OPERATORS, 0 ; tabselector
      .byte 4, px+4 , py+12, %0, 0, 31, 0, 0 ; drag edit - attack
      .byte 4, px+9, py+12, %0, 0, 31, 0, 0 ; drag edit - decay1
      .byte 4, px+14, py+12, %0, 0, 15, 0, 0 ; drag edit - decay level
      .byte 4, px+19, py+12, %0, 0, 31, 0, 0 ; drag edit - decay2
      .byte 4, px+24, py+12, %0, 0, 15, 0, 0 ; drag edit - release
      .byte 4, px+10, py+7, %0, 0, 15, 0, 0 ; drag edit - mul
      .byte 4, px+15, py+7, %00000100, 253, 3, 0, 0 ; drag edit - fine
      .byte 4, px+20, py+7, %0, 0, 3, 0, 0 ; drag edit - coarse
      .byte 4, px+4, py+3, %0, 0, 127, 0, 0 ; drag edit - level (vol)
      .byte 4, px+17, py+14, %00000000, 0, 3, 0, 0 ; drag edit - key scaling
      .byte 5, px+10, py+3, 2, 0 ; checkbox - volume sensitivity
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+4, py
      .word cp
      .byte CCOLOR_CAPTION, px+4, py+11
      .word panel_common::lb_attack
      .byte CCOLOR_CAPTION, px+9, py+11
      .word lb_decay_1
      .byte CCOLOR_CAPTION, px+14, py+11
      .word lb_decay_level
      .byte CCOLOR_CAPTION, px+19, py+11
      .word lb_decay_2
      .byte CCOLOR_CAPTION, px+24, py+11
      .word panel_common::lb_release
      .byte CCOLOR_CAPTION, px+4, py+6
      .word lb_tuning
      .byte CCOLOR_CAPTION, px+10, py+6
      .word lb_mul
      .byte CCOLOR_CAPTION, px+15, py+6
      .word lb_dt1
      .byte CCOLOR_CAPTION, px+20, py+6
      .word lb_dt2
      .byte CCOLOR_CAPTION, px+4, py+2
      .word panel_common::vol_lb
      .byte CCOLOR_CAPTION, px+4, py+14
      .word lb_ks
      .byte CCOLOR_CAPTION, px+12, py+3
      .word lb_vol_sens
      .byte 0
   active_tab: .byte 0
   cp: STR_FORMAT "fm operators"
   lb_decay_1: STR_FORMAT "dec1"
   lb_decay_2: STR_FORMAT "dec2"
   lb_decay_level: STR_FORMAT "lev"
   lb_tuning: STR_FORMAT "tune"
   lb_mul: STR_FORMAT "mul"
   lb_dt1: STR_FORMAT "fine"
   lb_dt2: STR_FORMAT "coarse"
   lb_ks: STR_FORMAT "key scaling"
   lb_vol_sens: STR_FORMAT "vol sens"

   .proc draw
      lda #px
      sta guiutils::draw_x
      lda #py
      sta guiutils::draw_y
      lda #wd
      sta guiutils::draw_width
      lda #hg
      sta guiutils::draw_height
      lda #N_OPERATORS
      sta guiutils::draw_data1
      lda active_tab
      inc
      sta guiutils::draw_data2
      jsr guiutils::draw_frame
      rts
   .endproc

   .proc write
      ; invalidate all FM timbres that have been loaded onto the YM2151 (i.e. enforce reload after timbre has been changed)
      jsr concerto_synth::voices::panic
      jsr concerto_synth::voices::invalidate_fm_timbres
      ; determine operator index
      ldx active_tab
      lda gui_definitions::current_synth_timbre
      clc
   @loop:
      dex
      bmi @loop_done
      adc #N_TIMBRES
      bra @loop
   @loop_done:
      tax
      ; component offset
      lda mouse_definitions::curr_component_ofs
      adc #6 ; carry should be clear from previous code
      tay ; there's no component type where the data is before this index
      ; now determine which component has been dragged
      phx
      lda mouse_definitions::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @tab_select
      .word @attack
      .word @decay1
      .word @decay_level
      .word @decay2
      .word @release
      .word @mul
      .word @fine
      .word @coarse
      .word @vol
      .word @key_scaling
      .word @vol_sens
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
      sta concerto_synth::timbres::Timbre::operators::ar, x
      rts
   @decay1:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::operators::d1r, x
      rts
   @decay_level:
      plx
      sec
      lda #15
      sbc comps, y
      sta concerto_synth::timbres::Timbre::operators::d1l, x
      rts
   @decay2:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::operators::d2r, x
      rts
   @release:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::operators::rr, x
      rts
   @mul:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::operators::mul, x
      rts
   @fine:
      plx
      lda comps, y
      bpl :+
      ; transform -3 ... -0 range to 5 .. 7 (4 is unused, since it does the same thing as 0)
      eor #%11111111
      clc
      adc #5
   :  sta concerto_synth::timbres::Timbre::operators::dt1, x
      rts
   @coarse:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::operators::dt2, x
      rts
   @vol:
      plx
      lda #127
      sec
      sbc comps, y
      sta concerto_synth::timbres::Timbre::operators::level, x
      rts
   @key_scaling:
      plx
      lda comps, y
      sta concerto_synth::timbres::Timbre::operators::ks, x
      rts
   @vol_sens:
      plx
      dey
      dey
      lda comps, y
      sta concerto_synth::timbres::Timbre::operators::vol_sens, x
      rts
   .endproc


   .proc refresh
      ; determine operator index
      ldx active_tab
      lda gui_definitions::current_synth_timbre
      clc
   @loop:
      dex
      bmi @loop_done
      clc
      adc #N_TIMBRES
      bra @loop
   @loop_done:
      tax
      ; attack
      lda concerto_synth::timbres::Timbre::operators::ar, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; decay 1
      lda concerto_synth::timbres::Timbre::operators::d1r, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+2*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; decay level
      sec
      lda #15
      sbc concerto_synth::timbres::Timbre::operators::d1l, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+3*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; decay 2
      lda concerto_synth::timbres::Timbre::operators::d2r, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+4*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; release
      lda concerto_synth::timbres::Timbre::operators::rr, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+5*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; mul
      lda concerto_synth::timbres::Timbre::operators::mul, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+6*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; fine
      lda concerto_synth::timbres::Timbre::operators::dt1, x
      and #%00000100
      beq :+
      lda concerto_synth::timbres::Timbre::operators::dt1, x
      eor #%11111111
      clc
      adc #5
      bra :++
   :  lda concerto_synth::timbres::Timbre::operators::dt1, x
   :  ldy #(tab_selector_data_size + 0*checkbox_data_size+7*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; coarse
      lda concerto_synth::timbres::Timbre::operators::dt2, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+8*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; vol
      sec
      lda #127
      sbc concerto_synth::timbres::Timbre::operators::level, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+9*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; key scaling
      lda concerto_synth::timbres::Timbre::operators::ks, x
      ldy #(tab_selector_data_size + 0*checkbox_data_size+10*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
      sta comps, y
      ; volume sensitivity
      lda concerto_synth::timbres::Timbre::operators::vol_sens, x
      ldy #(tab_selector_data_size + 1*checkbox_data_size+10*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-1)
      sta comps, y
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FM_OPERATORS_ASM