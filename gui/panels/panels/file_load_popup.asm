; Copyright 2024-2025 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_FILE_LOAD_POPUP_ASM

::GUI_PANELS_PANELS_FILE_LOAD_POPUP_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"
.include "file_popups_common.asm"

.scope file_load_popup
   ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
   px = 0
   py = 0
   wd = 80
   hg = 60
   ; where the actual popup appears
   box_width = file_popups_common::box_width
   box_height = file_popups_common::box_height
   box_x = file_popups_common::box_x
   box_y = file_popups_common::box_y
   comps:
   .scope comps
      COMPONENT_DEFINITION listbox, file_select, box_x+2, box_y + 2, box_width-4, box_height-7, A 0, 0, 255, 0
      COMPONENT_DEFINITION button, ok, 41, box_y + box_height - 3, 6, A lb_load
      COMPONENT_DEFINITION button, cancel, 33, box_y + box_height - 3, 6, A panel_common::lb_cancel
      COMPONENT_LIST_END
   .endscope
   capts:
      .byte 16*COLOR_BACKGROUND+1, 40-5, box_y
      .word lb_caption
      .byte 16*COLOR_BACKGROUND+12, 40-9, box_y + box_height - 4
      .word file_popups_common::lb_scroll_hint
      .byte 0
   ; data specific to the combobox-popup panel
   lb_load: STR_FORMAT " load"
   lb_caption: STR_FORMAT "load file"

   .proc initialize
      lda file_browsing::files
      sta comps::file_select + components::listbox::data_members::string_pointer
      lda file_browsing::files+1
      sta comps::file_select + components::listbox::data_members::string_pointer+1
      rts
   .endproc

   .proc draw
      inc kbd_variables::musical_keyboard_bypass
      jsr file_popups_common::clearAndDrawFrame
      ; fall through to refresh
   .endproc
   .proc refresh
      ; prepare file listing
      jsr file_browsing::getFiles
      lda #255 ; none selected
      ; #optimize-for-size by putting stuff above in common function (load and save popup)
      STA_COMPONENT_MEMBER_ADDRESS listbox, file_select, selected_entry
      rts
   .endproc

   .proc write
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word panel_common::dummy_subroutine ; file_select
      .word button_ok
      .word button_cancel
   button_ok:
      ; get reference to file name
      lda file_browsing::files
      ldx file_browsing::files+1
      LDY_COMPONENT_MEMBER_ADDRESS listbox, file_select, selected_entry
      cpy #255
      beq button_cancel ; don't open invalid file
      jsr dll::getElementByIndex
      pha
      phx
      jsr file_browsing::checkIfFolderAndRemovePadding
      plx
      pla
      ldy file_browsing::current_selection_is_directory
      beq :+
         jmp file_browsing::changeFolder
      :
      ; open file
      ldy #0 ; open for reading
      php
      sei
      jsr file_browsing::openFile
      bcs :+
      jsr song_engine::multitrack_player::stopPlayback
      lda file_browsing::current_file_type
      bne @load_song
      @load_instrument:
         .ifdef ::concerto_full_daw
            lda gui_variables::current_synth_instrument
            jsr concerto_synth::instruments::loadInstrument
         .endif
         bra @close_file
      @load_song:
         jsr song_engine::song_data::loadSong
         .ifdef ::concerto_full_daw
            jsr panels__clip_properties__copyClipSettingsToMusicalKeyboard
            lda #$ff
            sta concerto_synth::instruments::detail::copying
            stz song_engine::multitrack_player::player_start_timestamp
            stz song_engine::multitrack_player::player_start_timestamp+1
            stz components::dnd::dragables::notes::window_time_stamp
            stz components::dnd::dragables::notes::window_time_stamp+1
         .endif
      @close_file:
      jsr file_browsing::closeFile
   :  plp
      jsr gui_routines__refresh_gui
      ; fall through to button_cancel, which closes the popup
   button_cancel:
      ; close popup
      jsr file_popups_common::clearArea
      dec panels_stack_pointer
      jmp gui_routines__draw_gui
   .endproc

   .proc keypress
      lda kbd_variables::current_key
      stz kbd_variables::current_key
      cmp #13 ; enter
      beq write::button_ok
      cmp #$1B ; escape
      beq write::button_cancel
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_FILE_LOAD_POPUP_ASM
