; Copyright 2023 Carl Georg Biermann

.ifndef GUI_PANELS_PANELS_TEMPLATE_ASM

GUI_PANELS_PANELS_TEMPLATE_ASM = 1

.include "common.asm"

; editing area for clips
.scope clip_edit
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
.endscope

.endif ; .ifndef GUI_PANELS_PANELS_TEMPLATE_ASM
