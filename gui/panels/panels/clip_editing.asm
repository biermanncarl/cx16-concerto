; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_TEMPLATE_ASM

::GUI_PANELS_PANELS_TEMPLATE_ASM = 1

.include "common.asm"

; editing area for clips
.scope clip_editing
   px = notes::detail::event_edit_pos_x
   py = notes::detail::event_edit_pos_y-3 ; for navigation buttons at the top (temporary solution, until we implement a more convenient navigation solution)
   wd = notes::detail::event_edit_width
   hg = notes::detail::event_edit_height+3
   comps:
      .byte 3, px+5, py+1, 1, 5, 3 ; arrowed edit (zoom level)
      .byte 1, px+14, py+0, 5, (<lb_left), (>lb_left) ; button go left
      .byte 1, px+20, py+0, 5, (<lb_up), (>lb_up) ; button go up
      .byte 1, px+26, py+0, 5, (<lb_down), (>lb_down) ; button go down
      .byte 1, px+32, py+0, 5, (<lb_right), (>lb_right) ; button go right
      .byte 7 ; dummy component, to catch click events
      .byte 0
   capts:
      .byte CCOLOR_CAPTION, px+0, py+1
      .word lb_zoom
      .byte 0 ; empty
   ; data specific to the clip editing panel
   zoom_level:
      .byte 4
   time_stamp: ; lowest time stamp in view
      .word 0
   low_note: ; lowest note in view
      .byte 48
   lb_zoom: STR_FORMAT "zoom"
   lb_left: STR_FORMAT "left"
   lb_right: STR_FORMAT "right"
   lb_up: STR_FORMAT " up"
   lb_down: STR_FORMAT "down"

   .proc draw
      lda panels_luts::clip_editing::time_stamp
      sta notes::argument_x
      lda panels_luts::clip_editing::time_stamp+1
      sta notes::argument_x+1
      lda panels_luts::clip_editing::low_note
      sta notes::argument_y
      lda panels_luts::clip_editing::zoom_level
      sta notes::argument_z
      ; event vectors are set by setup_test_clip (and we never touch them elsewhere yet)
      jsr notes::draw_events
      rts
   .endproc

   .proc write
      ; prepare component string offset
      lda mouse_definitions::curr_component_ofs
      clc
      adc #5 ; we're reading only arrowed edits
      tay
      ; prepare jump
      lda mouse_definitions::curr_component_id
      asl
      tax
      jmp (@jmp_tbl, x)
   @jmp_tbl:
      .word @zoom_level
      .word @go_left
      .word @go_up
      .word @go_down
      .word @go_right
      .word @edit_notes
   @zoom_level:
      ; read data from component string and write it to the zoom setting
      lda panels_luts::clip_editing::comps, y
      dec
      sta panels_luts::clip_editing::zoom_level
      ; make sure the time stamp is aligned with the current grid ... very crude method. TODO: "round to nearest"
      stz panels_luts::clip_editing::time_stamp
      stz panels_luts::clip_editing::time_stamp+1
      jsr draw
      rts
   @go_left:
      ; TODO: provide different strides at different zoom levels
      lda panels_luts::clip_editing::time_stamp
      sec
      sbc timing::detail::quarter_ticks
      sta panels_luts::clip_editing::time_stamp
      lda panels_luts::clip_editing::time_stamp+1
      sbc #0
      sta panels_luts::clip_editing::time_stamp+1
      jsr draw
      rts
   @go_up:
      lda panels_luts::clip_editing::low_note
      clc
      adc #6
      sta panels_luts::clip_editing::low_note
      jsr draw
      rts
   @go_down:
      lda panels_luts::clip_editing::low_note
      sec
      sbc #6
      sta panels_luts::clip_editing::low_note
      jsr draw
      rts
   @go_right:
      ; TODO: provide different strides at different zoom levels
      lda panels_luts::clip_editing::time_stamp
      clc
      adc timing::detail::quarter_ticks
      sta panels_luts::clip_editing::time_stamp
      lda panels_luts::clip_editing::time_stamp+1
      adc #0
      sta panels_luts::clip_editing::time_stamp+1
      jsr draw
      rts
   @edit_notes:
      rts
   .endproc


   .proc refresh
      ; TODO: read in zoom level
      jsr draw
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_TEMPLATE_ASM
