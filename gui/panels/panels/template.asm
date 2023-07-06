; Copyright 2023 Carl Georg Biermann

.ifndef GUI_PANELS_PANELS_TEMPLATE_ASM

GUI_PANELS_PANELS_TEMPLATE_ASM = 1

.include "common.asm"

; template panel, serves as a minimal working example
.scope panel_template
   px = 20 ; top left corner of the panel, x coordinate
   py = 10 ; top left corner of the panel, y coordinate
   wd = 70 ; width of the panel
   hg = 60 ; height of the panel

   ; GUI component "string" of the panel. Contains things like component type, position, current value etc. of each component.
   ; Zero marks the end of the component string.
   comps:
      .byte 0 ; end of components

   ; caption list of the panel. Consists of the color, the x and y position,
   ; and a pointer to a zero-terminated screencode string (the "@" symbol is unusable as screencode 0 is "@").
   ; Repeat this as often as needed. Zero marks the end of the list.
   capts:
      .byte CCOLOR_CAPTION, px+5, py
      .word template_label
      .byte 0 ; end of captions

   ; data specific to this panel
   template_label: STR_FORMAT "template"
.endscope

.endif ; .ifndef GUI_PANELS_PANELS_TEMPLATE_ASM
