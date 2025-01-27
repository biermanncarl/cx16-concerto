; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_CLIP_EDITING_ASM

::GUI_PANELS_PANELS_CLIP_EDITING_ASM = 1

.include "../../gui_macros.asm"
.include "common.asm"
.include "../../drag_and_drop/drag_and_drop.asm"

; editing area for clips
.scope clip_editing
   px = 5 ; todo
   py = 0
   wd = 70
   hg = 60

   event_edit_pos_x = components::dnd::dragables::notes::detail::event_edit_pos_x
   event_edit_pos_y = components::dnd::dragables::notes::detail::event_edit_pos_y
   event_edit_width = components::dnd::dragables::notes::detail::event_edit_width
   event_edit_height = components::dnd::dragables::notes::detail::event_edit_height
   zoom_level_indicator_x = event_edit_pos_x + event_edit_width - 6
   zoom_level_indicator_y = event_edit_pos_y + event_edit_height + 3
   help_box_x = 62
   help_box_y = 24
   help_box_width = (80 - help_box_x - 2)
   help_box_height = 33

   comps:
   .scope comps
      COMPONENT_DEFINITION drag_and_drop_area, notes_edit, components::dnd::dragables::ids::notes
      COMPONENT_DEFINITION combobox, zoom_level_indicator, zoom_level_indicator_x, zoom_level_indicator_y, 6, 5, A zoom_select_lb, 0
      COMPONENT_DEFINITION button, play_start, 34, 54, 3, A play_caption
      COMPONENT_DEFINITION button, play_stop, 38, 54, 3, A stop_caption
      COMPONENT_DEFINITION button, song_tempo, 31, 57, 10, A tempo_caption
      COMPONENT_DEFINITION button, load_song, 11, 57, 9, A load_song_lb
      COMPONENT_DEFINITION button, save_song, 21, 57, 9, A save_song_lb
      COMPONENT_DEFINITION dummy, start_of_playback_ruler, event_edit_pos_x, event_edit_pos_y-1, event_edit_width, 1
      COMPONENT_DEFINITION text_field, clip_help, help_box_x+2, help_box_y+2, help_box_width-4, help_box_height-4, A vram_assets::help_text_note_edit
      COMPONENT_LIST_END
   .endscope

   capts:
      .byte CCOLOR_CAPTION, zoom_level_indicator_x - 5, zoom_level_indicator_y
      .word zoom_caption
      .byte CCOLOR_CAPTION, help_box_x+5, help_box_y
      .word panel_common::lb_help
      .byte 0

   zoom_select_lb:
      STR_FORMAT "1/32"
      STR_FORMAT "1/8"
      STR_FORMAT "1/4"
      STR_FORMAT "1/4"
      STR_FORMAT "1/1"

   zoom_caption: STR_FORMAT "grid"
   play_caption: .byte 32, '>', 0
   stop_caption: .byte 32, 228, 0
   tempo_caption: STR_FORMAT "song tempo"
   load_song_lb: STR_FORMAT "load song"
   save_song_lb: STR_FORMAT "save song"

   .proc draw
      ; help frame
      lda #help_box_x
      sta guiutils::draw_x
      lda #help_box_y
      sta guiutils::draw_y
      lda #help_box_width
      sta guiutils::draw_width
      lda #help_box_height
      sta guiutils::draw_height
      stz guiutils::draw_data1
      jsr guiutils::draw_frame
      ; put current clip as clip data
      ldy song_engine::clips::active_clip_id
      jsr song_engine::clips::accessClip
      ldy #song_engine::clips::clip_data::event_ptr
      lda (v32b::entrypointer),y
      sta song_engine::event_selection::unselected_events_vector
      iny
      lda (v32b::entrypointer),y
      sta song_engine::event_selection::unselected_events_vector+1
      rts
   .endproc

   .proc write
      LDY_COMPONENT_MEMBER combobox, zoom_level_indicator, selected_entry
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word panel_common::dummy_subroutine ; drag and drop
      .word @zoom_level
      .word song_engine::multitrack_player::startPlayback
      .word song_engine::multitrack_player::stopPlayback
      .word @song_tempo
      .word @load_song
      .word @save_song
      .word @set_start_of_playback
   @zoom_level:
      lda comps, y
      sta components::dnd::dragables::notes::temporal_zoom
      rts
   @song_tempo:
      ; TODO: factor out the GUI stack operation
      ldx panels__panels_stack_pointer
      lda #panels__ids__song_tempo_popup
      sta panels__panels_stack, x
      inc panels__panels_stack_pointer
      jsr gui_routines__draw_gui
      rts
   @load_song:
      jsr song_engine::multitrack_player::stopPlayback
      jsr song_engine::event_selection::unselectAllEvents
      ; open the file browser popup on the GUI stack
      lda #file_browsing::file_type::song
      sta file_browsing::current_file_type
      ; TODO: factor out the GUI stack operation
      ldx panels__panels_stack_pointer
      lda #panels__ids__file_load_popup
      sta panels__panels_stack, x
      inc panels__panels_stack_pointer
      jsr gui_routines__draw_gui
      rts
   @save_song:
      ; open the file browser popup on the GUI stack
      lda #file_browsing::file_type::song
      sta file_browsing::current_file_type
      ; TODO: factor out the GUI stack operation
      ldx panels__panels_stack_pointer
      lda #panels__ids__file_save_popup
      sta panels__panels_stack, x
      inc panels__panels_stack_pointer
      jsr gui_routines__draw_gui
      rts
   @set_start_of_playback:
      lda mouse_variables::curr_data_1
      sec
      sbc #components::dnd::dragables::notes::detail::event_edit_pos_x
      eor #$ff
      inc
      jsr components::dnd::dragables::notes::getTimeStampAtScreen
      lda song_engine::timing::time_stamp_parameter
      sta song_engine::multitrack_player::player_start_timestamp
      lda song_engine::timing::time_stamp_parameter+1
      sta song_engine::multitrack_player::player_start_timestamp+1
      jsr gui_routines__draw_gui
      rts
   .endproc


   .proc refresh
      lda components::dnd::dragables::notes::temporal_zoom
      LDY_COMPONENT_MEMBER combobox, zoom_level_indicator, selected_entry
      sta comps, y
      rts
   .endproc

   keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_CLIP_EDITING_ASM
