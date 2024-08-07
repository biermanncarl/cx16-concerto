; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM

::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM = 1

.include "common.asm"

; global navigation panel
.scope global_navigation
   px = 0
   py = 12
   wd = 3
   hg = 60-py
   comps:
   .scope comps
      COMPONENT_DEFINITION dummy, click_catcher, 0, 0, 3, 60
      COMPONENT_DEFINITION text_field, concerto_banner, 1, 1, 19, 6, A vram_assets::concerto_banner
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 0
   ; data specific to the synth-navigation panel
   active_tab: .byte 1

   .proc draw
      lda active_tab
      sta guiutils::draw_data1
      jsr guiutils::draw_globalnav
      rts
   .endproc



   .proc write
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

   refresh = panel_common::dummy_subroutine

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
      lda kbd_variables::musical_keyboard_base_pitch
      beq :+
      sec
      sbc #12
      sta kbd_variables::musical_keyboard_base_pitch
      lda #kbd_variables::musical_keyboard_channel
      jsr song_engine::multitrack_player::stopVoicesOnChannel
   :  rts
   @keyboard_x:
      lda kbd_variables::musical_keyboard_base_pitch
      cmp #108
      beq :+
      clc
      adc #12
      sta kbd_variables::musical_keyboard_base_pitch
      lda #kbd_variables::musical_keyboard_channel
      jsr song_engine::multitrack_player::stopVoicesOnChannel
   :  rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_GLOBAL_NAVIGATION_ASM
