; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_TEMPLATE_ASM

::GUI_PANELS_PANELS_TEMPLATE_ASM = 1

.include "../../gui_macros.asm"
.include "common.asm"
.include "../../drag_and_drop/drag_and_drop.asm"

; editing area for clips
.scope clip_editing
   px = 5 ; todo
   py = 0
   wd = 70
   hg = 60

   zoom_level_indicator_x = components::dnd::dragables::notes::detail::event_edit_pos_x + components::dnd::dragables::notes::detail::event_edit_width - 6
   zoom_level_indicator_y = components::dnd::dragables::notes::detail::event_edit_pos_y - 1

   comps:
   .scope comps
      COMPONENT_DEFINITION drag_and_drop_area, notes_edit, components::dnd::dragables::ids::notes
      COMPONENT_DEFINITION listbox, zoom_level_indicator, zoom_level_indicator_x, zoom_level_indicator_y, 6, 5, A zoom_select_lb, 0
      COMPONENT_DEFINITION button, play_start, 34, 57, 6, A play_caption
      COMPONENT_DEFINITION button, play_stop, 41, 57, 6, A stop_caption
      COMPONENT_LIST_END
   .endscope

   capts:
      .byte CCOLOR_CAPTION, zoom_level_indicator_x - 5, zoom_level_indicator_y
      .word zoom_caption
      .byte 0
   
   zoom_select_lb:
      STR_FORMAT "1/32"
      STR_FORMAT "1/8"
      STR_FORMAT "1/4"
      STR_FORMAT "1/2"
      STR_FORMAT "1/1"

   zoom_caption: STR_FORMAT "grid"
   play_caption: STR_FORMAT " play"
   stop_caption: STR_FORMAT " stop"

   .proc draw
      rts
   .endproc

   .proc write
      LDY_COMPONENT_MEMBER listbox, zoom_level_indicator, selected_entry
      lda mouse_variables::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word panel_common::dummy_subroutine ; drag and drop
      .word @zoom_level
      .word @play
      .word song_engine::simple_player::stop_playback ; @stop
   @zoom_level:
      lda comps, y
      sta components::dnd::dragables::notes::temporal_zoom
      rts
   @play:
      ; start play routine
      php
      sei
      lda #1
      sta song_engine::simple_player::detail::active
      stz song_engine::simple_player::detail::time_stamp
      stz song_engine::simple_player::detail::time_stamp+1
      jsr song_engine::event_selection::swapBackFrontStreams
      SET_SELECTED_VECTOR components::dnd::dragables::notes::selected_events_vector
      SET_UNSELECTED_VECTOR  components::dnd::dragables::notes::unselected_events_vector
      jsr song_engine::event_selection::resetStream
      jsr song_engine::simple_player::detail::getNextEventAndTimeStamp
      jsr song_engine::event_selection::swapBackFrontStreams
      plp
      rts
   ; @stop:
   ;    rts
   .endproc


   .proc refresh
      lda components::dnd::dragables::notes::temporal_zoom
      LDY_COMPONENT_MEMBER listbox, zoom_level_indicator, selected_entry
      sta comps, y
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_TEMPLATE_ASM
