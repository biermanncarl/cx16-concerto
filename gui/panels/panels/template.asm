; Copyright 2023 Carl Georg Biermann

; THIS IS EXAMPLE/DOCUMENTATION CODE!
; DO NOT INCLUDE IN THE ACTUAL PROJECT!

.ifndef ::GUI_PANELS_PANELS_TEMPLATE_ASM

::GUI_PANELS_PANELS_TEMPLATE_ASM = 1

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

   ; This method takes care of any panel-specific drawing tasks APART FROM drawing GUI components and labels.
   ; (Drawing GUI components and labels is taken care of by the generic GUI code.)
   .proc draw
      rts
   .endproc

   ; This method must put currently valid values into the GUI components, so when they are drawn they show
   ; currently valid values. This is for cases such as a different synth timbre is selected and the new
   ; values have to be loaded into the GUI, or a different oscillator has been selected etc.
   ; (Data transfer direction: underlying data -> GUI components)
   ; TODO: Which arguments can it expect?
   ;       Which return values are expected?
   .proc refresh
      rts
   .endproc

   ; This method must read a value from a GUI component and store that value or otherwise process it.
   ; This method is called when the user interacts with GUI components and changes their values.
   ; (Data transfer direction: underlying data -> GUI components)
   ; TODO: Which arguments can it expect?
   ;       Which return values are expected?
   .proc write
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_TEMPLATE_ASM
