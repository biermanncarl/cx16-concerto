; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_SYNTH_NAV_ASM

::GUI_PANELS_PANELS_SYNTH_NAV_ASM = 1

.include "common.asm"

; synth navigation/tool panel ... it sits in the background of the synth.
.scope synth_navigation
   px = 10
   py = 0
   wd = 70
   hg = 60
   ; text input position
   ti_x = 66
   ti_y = 5
   ti_l = 8 ; maximum length
   comps:
      .byte 3, 41, 1, 0, N_TIMBRES-1, 0 ; arrowed edit (timbre selection)
      .byte 1, 66, 0, 13, (<load_preset_lb), (>load_preset_lb) ; load preset button
      .byte 1, 52, 0, 13, (<save_preset_lb), (>save_preset_lb) ; save preset button
      .byte 1, 34, 2, 6, (<copy_preset_lb), (>copy_preset_lb) ; copy preset button
      .byte 1, 41, 2, 7, (<paste_preset_lb), (>paste_preset_lb) ; paste preset button
      .byte 1, 52, 4, 13, (<file_lb), (>file_lb) ; set file name button
      .byte 4, 43, 5, %00000000, 0, 63, 63, 0 ; note volume
      .byte 1, 66, 2, 13, (<load_bank_lb), (>load_bank_lb) ; load bank button
      .byte 1, 52, 2, 13, (<save_bank_lb), (>save_bank_lb) ; save bank button
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, 34, 1
      .word timbre_lb
      .byte CCOLOR_CAPTION, ti_x, ti_y
      .word concerto_synth::timbres::file_name
      .byte CCOLOR_CAPTION, 34, 5
      .word velocity_lb
      .byte 0
   ; data specific to the synth-navigation panel
   timbre_lb: STR_FORMAT "timbre"
   load_preset_lb: STR_FORMAT " load preset"
   save_preset_lb: STR_FORMAT " save preset"
   load_bank_lb: STR_FORMAT "  load bank"
   save_bank_lb: STR_FORMAT "  save bank"
   copy_preset_lb: STR_FORMAT " copy"
   paste_preset_lb: STR_FORMAT " paste"
   file_lb: STR_FORMAT "  file name"
   velocity_lb: STR_FORMAT "velocity"

   ; No special action required (yet)
   draw = panel_common::dummy_subroutine

   .proc write
      ; prepare component string offset
      lda mouse_definitions::curr_component_ofs
      clc
      adc #5 ; currently, we're reading only arrowed edits and drag edits
      tay
      ; prepare jump
      lda mouse_definitions::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @timbre_selector
      .word @load_preset
      .word @save_preset
      .word @copy_preset
      .word @paste_preset
      .word @change_file_name
      .word @set_play_volume
      .word @load_bank
      .word @save_bank
   @timbre_selector:
      ; read data from component string and write it to the Timbre setting
      lda panels_luts::synth_navigation::comps, y
      sta gui_definitions::current_synth_timbre
      jsr refresh_gui
      rts
   @load_preset:
      sei
      jsr concerto_synth::voices::panic
      ldx gui_definitions::current_synth_timbre
      jsr concerto_synth::timbres::load_timbre
      jsr refresh_gui
      cli
      rts
   @save_preset:
      ldx gui_definitions::current_synth_timbre
      jsr concerto_synth::timbres::save_timbre
      rts
   @copy_preset:
      lda gui_definitions::current_synth_timbre
      sta concerto_synth::timbres::copying
      rts
   @paste_preset:
      sei
      jsr concerto_synth::voices::panic
      ldx gui_definitions::current_synth_timbre
      jsr concerto_synth::timbres::copy_paste
      jsr refresh_gui
      cli
      rts
   @change_file_name:
      ; clear string
      ;ldy #MAX_FILENAME_LENGTH
      ;lda #' '
   ; :  sta concerto_synth::timbres::file_name,y
      ;dey
      ;bpl :-
      ; do input string
      lda #panels_luts::synth_navigation::ti_x
      sta r2L
      lda #panels_luts::synth_navigation::ti_y
      sta r2H
      lda #<concerto_synth::timbres::file_name
      sta r0L
      lda #>concerto_synth::timbres::file_name
      sta r0H
      ldx #CCOLOR_CAPTION
      ldy #MAX_FILENAME_LENGTH
      jsr guiutils::vtui_input_str
      rts
   @set_play_volume:
      iny
      lda panels_luts::synth_navigation::comps, y
      sta play_volume
      rts
   @load_bank:
      sei
      jsr concerto_synth::voices::panic
      jsr concerto_synth::timbres::load_bank
      jsr refresh_gui
      cli
      rts
   @save_bank:
      jsr concerto_synth::timbres::save_bank
      rts
   .endproc


   refresh = panel_common::dummy_subroutine
   
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_SYNTH_NAV_ASM
