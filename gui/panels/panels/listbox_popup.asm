; Copyright 2021, 2023 Carl Georg Biermann

.ifndef GUI_PANELS_PANELS_LISTBOX_POPUP_ASM

GUI_PANELS_PANELS_LISTBOX_POPUP_ASM = 1

.include "common.asm"

; listbox popup. shows up when a listbox was clicked.
.scope listbox_popup
   ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
   px = 0
   py = 0
   wd = 80
   hg = 60
   comps:
      .byte 7 ; dummy component, to catch click events (without it, the panel wouldn't receive any click events!)
      .byte 0
   capts:
      .byte 0
   ; data specific to the listbox-popup panel
   strlist: .word 0
   ; this is the position where the popup is actually drawn
   box_x: .byte 0
   box_y: .byte 0
   box_width: .byte 0
   box_height: .byte 0
   lb_panel: .byte 0 ; panel index of the listbox, so the popup knows which writing-function to call when done.
   lb_addr: .word 0 ; address and offset of the listbox that was causing the popup
   lb_ofs: .byte 0
   lb_id: .byte 0
.endscope

.endif ; .ifndef GUI_PANELS_PANELS_LISTBOX_POPUP_ASM
