; Copyright 2023-2025 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM

::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM = 1

.include "common.asm"

; global navigation panel
.scope global_navigation
   px = 0
   py = 12
   wd = 80
   hg = 60-py
   comps:
   .scope comps
      COMPONENT_DEFINITION drag_edit, keyboard_volume, 49, 58, %00000000, 0, 63, 63, 0
      COMPONENT_DEFINITION drag_edit, keyboard_instrument, 35, 58, %00000000, 0, N_INSTRUMENTS-1, N_INSTRUMENTS-1, 0
      COMPONENT_DEFINITION drag_edit, keyboard_basenote, 19, 58, %00000000, 0, 108, 60, 0
      COMPONENT_DEFINITION checkbox, keyboard_monophonic, 54, 58, 12, 0
      COMPONENT_DEFINITION checkbox, keyboard_drum_pad, 68, 58, 10, 0
      COMPONENT_DEFINITION dummy, click_catcher, 0, 0, 3, 60
      COMPONENT_DEFINITION text_field, concerto_banner, 1, 1, 19, 6, A vram_assets::concerto_banner
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte CCOLOR_CAPTION, 6, 58
      .word kbd_base_lb
      .byte CCOLOR_CAPTION, 24, 58
      .word panel_common::lb_instrument
      .byte CCOLOR_CAPTION, 40, 58
      .word velocity_lb
      .byte CCOLOR_CAPTION, 56, 58
      .word panel_common::lb_mono
      .byte CCOLOR_CAPTION, 70, 58
      .word panel_common::lb_drum
      .byte 0
   ; data specific to the synth-navigation panel
   active_tab: .byte 1
   velocity_lb: STR_FORMAT "velocity"
   kbd_base_lb: STR_FORMAT "kbd basenote"

   .proc draw
      lda active_tab
      sta guiutils::draw_data1
      jsr guiutils::draw_globalnav
      rts
   .endproc



   .proc write
      ; prepare jump
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @set_kbd_volume
      .word @set_kbd_instrument
      .word @set_kbd_basenote
      .word @set_kbd_mono
      .word @set_kbd_drum
      .word @select_tab
   @set_kbd_volume:
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, keyboard_volume, coarse_value
      sta gui_variables::musical_kbd_velocity
      rts
   @set_kbd_instrument:
      lda #kbd_variables::musical_keyboard_channel
      jsr song_engine::multitrack_player::stopVoicesOnChannel
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, keyboard_instrument, coarse_value
      sta gui_variables::current_synth_instrument
      jsr refresh
      jsr gui_routines__draw_gui
      rts
   @set_kbd_basenote:
   @set_kbd_mono:
   @set_kbd_drum:
      lda #kbd_variables::musical_keyboard_channel
      jsr song_engine::multitrack_player::stopVoicesOnChannel
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, keyboard_monophonic, checked
      sta gui_variables::musical_kbd_mono
      LDA_COMPONENT_MEMBER_ADDRESS checkbox, keyboard_drum_pad, checked
      sta gui_variables::musical_kbd_drum
      LDA_COMPONENT_MEMBER_ADDRESS drag_edit, keyboard_basenote, coarse_value
      sta gui_variables::musical_kbd_basenote
      rts
   @select_tab:
      lda mouse_variables::curr_data_2 ; y position in multiples of 8 pixels
      ; tabs start at row 28 and are 16 high each
      sec
      sbc #28
      lsr
      lsr
      lsr
      lsr
      ; fall through to loadTab
   .endproc
   ; Expects the tab number in .A
   .proc loadTab
      sta active_tab
      cmp #0
      beq @load_clip_view
      jmp gui_routines__load_synth_gui
   @load_clip_view:
      jmp gui_routines__load_clip_gui
   .endproc

   .proc refresh
      lda gui_variables::current_synth_instrument      
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, keyboard_instrument, coarse_value
      lda gui_variables::musical_kbd_mono
      STA_COMPONENT_MEMBER_ADDRESS checkbox, keyboard_monophonic, checked
      lda gui_variables::musical_kbd_drum
      STA_COMPONENT_MEMBER_ADDRESS checkbox, keyboard_drum_pad, checked
      lda gui_variables::musical_kbd_basenote
      STA_COMPONENT_MEMBER_ADDRESS drag_edit, keyboard_basenote, coarse_value
      ; There's nothing else messing with these
      ; lda gui_variables::musical_kbd_velocity
      ; STA_COMPONENT_MEMBER_ADDRESS drag_edit, keyboard_volume, coarse_value
      rts
   .endproc

   .proc keypress
      ; The keyboard handling was moved from the main loop to this place here.
      lda concerto_gui::kbd_variables::current_key
      stz concerto_gui::kbd_variables::current_key
      cmp #09 ; tab
      bne @skip_tab
      jmp @keyboard_tab
   @skip_tab:
      cmp #32
      bne @skip_space
      jmp @keyboard_space
   @skip_space:
      cmp #90        ; check if pressed "Z"
      bne @skip_z
      jmp @keyboard_z
   @skip_z:
      cmp #88        ; check if pressed "X"
      bne @skip_x
      jmp @keyboard_x
   @skip_x:
      cmp #81        ; exit if pressed "Q"
      bne @end_keychecks
      ;inc gui_variables::request_program_exit ; disable exit for now...
      rts
   @end_keychecks:
      rts

   @keyboard_tab:
      lda active_tab
      eor #1
      sta active_tab
      jmp loadTab

   @keyboard_space:
      lda song_engine::multitrack_player::detail::active
      beq @start_playback
      @stop_playback:
         jsr song_engine::multitrack_player::stopPlayback
         rts
      @start_playback:
         jsr song_engine::multitrack_player::startPlayback
         rts

   @keyboard_z:
      lda gui_variables::musical_kbd_basenote
      sec
      sbc #12
      bcc @end_keychecks
      sta gui_variables::musical_kbd_basenote
      bra @housekeeping
   @keyboard_x:
      lda gui_variables::musical_kbd_basenote
      clc
      adc #12
      cmp #110
      bcs @end_keychecks
      sta gui_variables::musical_kbd_basenote
   @housekeeping:
      lda #kbd_variables::musical_keyboard_channel
      jsr song_engine::multitrack_player::stopVoicesOnChannel
      ; fall through to refreshMusicalKeyboard
   .endproc
   .proc refreshMusicalKeyboard
      jsr refresh
      inc gui_variables::request_components_redraw
      ; this is a hack since normally, the mouse requests redrawings
      lda #panels__ids__global_navigation
      sta mouse_variables::curr_panel
      rts
   .endproc


.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM
