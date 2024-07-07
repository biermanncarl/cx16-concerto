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
   .scope comps
      COMPONENT_DEFINITION tab_selector, tab_select, px, py, N_OPERATORS, 0
      COMPONENT_DEFINITION drag_edit, attack, px+4 , py+12, %0, 0, 31, 0, 0
      COMPONENT_DEFINITION drag_edit, decay_1, px+9, py+12, %0, 0, 31, 0, 0 
      COMPONENT_DEFINITION drag_edit, decay_level, px+14, py+12, %0, 0, 15, 0, 0 
      COMPONENT_DEFINITION drag_edit, decay_2, px+19, py+12, %0, 0, 31, 0, 0 
      COMPONENT_DEFINITION drag_edit, release, px+24, py+12, %0, 0, 15, 0, 0 
      COMPONENT_DEFINITION drag_edit, mul, px+10, py+7, %0, 0, 15, 0, 0 
      COMPONENT_DEFINITION drag_edit, fine, px+15, py+7, %00000100, 253, 3, 0, 0 
      COMPONENT_DEFINITION drag_edit, coarse, px+20, py+7, %0, 0, 3, 0, 0 
      COMPONENT_DEFINITION drag_edit, level, px+4, py+3, %0, 0, 127, 0, 0 
      COMPONENT_DEFINITION drag_edit, key_scaling, px+17, py+14, %00000000, 0, 3, 0, 0 
      COMPONENT_DEFINITION checkbox, vol_sensitivity, px+10, py+3, 2, 0
      COMPONENT_LIST_END
   .endscope
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
      ; invalidate all FM instruments that have been loaded onto the YM2151 (i.e. enforce reload after instrument has been changed)
      jsr concerto_synth::voices::panic
      jsr concerto_synth::voices::invalidate_fm_instruments
      ; determine operator index
      ldx active_tab
      lda gui_variables::current_synth_instrument
      clc
   @loop:
      dex
      bmi @loop_done
      adc #N_INSTRUMENTS
      bra @loop
   @loop_done:
      tax
      ; now determine which component has been dragged
      phx
      lda mouse_variables::curr_component_id
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
      lda mouse_variables::curr_data_1
      sta active_tab
      jsr refresh
      inc gui_variables::request_components_redraw
      rts
   @attack:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, attack, coarse_value
      sta concerto_synth::instruments::Instrument::operators::ar, x
      rts
   @decay1:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, decay_1, coarse_value
      sta concerto_synth::instruments::Instrument::operators::d1r, x
      rts
   @decay_level:
      plx
      sec
      lda #15
      SBC_COMPONENT_MEMBER_ADDRESS drag_edit, decay_level, coarse_value
      sta concerto_synth::instruments::Instrument::operators::d1l, x
      rts
   @decay2:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, decay_2, coarse_value
      sta concerto_synth::instruments::Instrument::operators::d2r, x
      rts
   @release:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, release, coarse_value
      sta concerto_synth::instruments::Instrument::operators::rr, x
      rts
   @mul:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, mul, coarse_value
      sta concerto_synth::instruments::Instrument::operators::mul, x
      rts
   @fine:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, fine, coarse_value
      bpl :+
      ; transform -3 ... -0 range to 5 .. 7 (4 is unused, since it does the same thing as 0)
      eor #%11111111
      clc
      adc #5
   :  sta concerto_synth::instruments::Instrument::operators::dt1, x
      rts
   @coarse:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, coarse, coarse_value
      sta concerto_synth::instruments::Instrument::operators::dt2, x
      rts
   @vol:
      plx
      lda #127
      sec
      SBC_COMPONENT_MEMBER_ADDRESS drag_edit, level, coarse_value
      sta concerto_synth::instruments::Instrument::operators::level, x
      rts
   @key_scaling:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, key_scaling, coarse_value
      sta concerto_synth::instruments::Instrument::operators::ks, x
      rts
   @vol_sens:
      plx
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, vol_sensitivity, checked
      sta concerto_synth::instruments::Instrument::operators::vol_sens, x
      rts
   .endproc


   .proc refresh
      ; determine operator index
      ldx active_tab
      lda gui_variables::current_synth_instrument
      clc
   @loop:
      dex
      bmi @loop_done
      clc
      adc #N_INSTRUMENTS
      bra @loop
   @loop_done:
      tax
      ; attack
      lda concerto_synth::instruments::Instrument::operators::ar, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, attack, coarse_value
      ; decay 1
      lda concerto_synth::instruments::Instrument::operators::d1r, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, decay_1, coarse_value
      ; decay level
      sec
      lda #15
      sbc concerto_synth::instruments::Instrument::operators::d1l, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, decay_level, coarse_value
      ; decay 2
      lda concerto_synth::instruments::Instrument::operators::d2r, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, decay_2, coarse_value
      ; release
      lda concerto_synth::instruments::Instrument::operators::rr, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, release, coarse_value
      ; mul
      lda concerto_synth::instruments::Instrument::operators::mul, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, mul, coarse_value
      ; fine
      lda concerto_synth::instruments::Instrument::operators::dt1, x
      and #%00000100
      beq :+
      lda concerto_synth::instruments::Instrument::operators::dt1, x
      eor #%11111111
      clc
      adc #5
      bra :++
   :  lda concerto_synth::instruments::Instrument::operators::dt1, x
   :  STA_COMPONENT_MEMBER_ADDRESS drag_edit, fine, coarse_value
      ; coarse
      lda concerto_synth::instruments::Instrument::operators::dt2, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, coarse, coarse_value
      ; vol
      sec
      lda #127
      sbc concerto_synth::instruments::Instrument::operators::level, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, level, coarse_value
      ; key scaling
      lda concerto_synth::instruments::Instrument::operators::ks, x
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, key_scaling, coarse_value
      ; volume sensitivity
      lda concerto_synth::instruments::Instrument::operators::vol_sens, x
      STA_COMPONENT_MEMBER_ADDRESS checkbox, vol_sensitivity, checked
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FM_OPERATORS_ASM
