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

   zoom_level_indicator_x = components::dnd::dragables::notes::detail::event_edit_pos_x + components::dnd::dragables::notes::detail::event_edit_width - 6
   zoom_level_indicator_y = components::dnd::dragables::notes::detail::event_edit_pos_y - 1
   help_box_x = 62
   help_box_y = 24
   help_box_width = (80 - help_box_x - 2)
   help_box_height = 28

   comps:
   .scope comps
      COMPONENT_DEFINITION drag_and_drop_area, notes_edit, components::dnd::dragables::ids::notes
      COMPONENT_DEFINITION combobox, zoom_level_indicator, zoom_level_indicator_x, zoom_level_indicator_y, 6, 5, A zoom_select_lb, 0
      COMPONENT_DEFINITION button, play_start, 34, 57, 6, A play_caption
      COMPONENT_DEFINITION button, play_stop, 41, 57, 6, A stop_caption
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
   play_caption: STR_FORMAT " play"
   stop_caption: STR_FORMAT " stop"

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
      sta song_engine::unselected_events_vector
      iny
      lda (v32b::entrypointer),y
      sta song_engine::unselected_events_vector+1
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
      .word song_engine::simple_player::startPlayback
      .word song_engine::simple_player::stopPlayback
   @zoom_level:
      lda comps, y
      sta components::dnd::dragables::notes::temporal_zoom
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
