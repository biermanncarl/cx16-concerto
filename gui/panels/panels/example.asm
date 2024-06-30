; Copyright 2023 Carl Georg Biermann

; THIS IS EXAMPLE/DOCUMENTATION CODE!
; DO NOT INCLUDE IN THE ACTUAL PROJECT!

.ifndef ::GUI_PANELS_PANELS_EXAMPLE_ASM

::GUI_PANELS_PANELS_EXAMPLE_ASM = 1

.include "common.asm"

; template panel, serves as a minimal working example
.scope panel_template
   px = 20 ; top left corner of the panel, x coordinate
   py = 10 ; top left corner of the panel, y coordinate
   wd = 70 ; width of the panel
   hg = 60 ; height of the panel

   ; GUI component "string" of the panel. Contains things like component type, position, current value etc. of each component.
   ; Zero marks the end of the component string.
   ; Note that the total length of the component string must not exceed 256 bytes (including the ending 0).
   comps:
   .scope comps
      COMPONENT_LIST_END
   .endscope

   ; caption list of the panel. Consists of the color, the x and y position,
   ; and a pointer to a zero-terminated screencode string (the "@" symbol is unusable as screencode 0 is "@").
   ; Repeat this as often as needed. Zero marks the end of the list.
   ; Note that the total length of the captions string must not exceed 256 bytes (including the ending 0).
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

   ; This method must read a value from a GUI component and store that value or otherwise process it.
   ; This method is called when the user interacts with GUI components and changes their values.
   ; (Data transfer direction: GUI components -> underlying data)
   ; Input: The write method may rely on the current ("curr_...") mouse variables being populated correctly,
   ;        most importantly, curr_component_id and curr_component_ofs, which give the id of the clicked
   ;        component and its memory offset within the panel's component string.
   ;        It is usually unnecessary to check curr_panel, as the fact that this panel's write routine
   ;        is being called indicates that curr_panel is equal to this panel's id.
   ; No return values are expected.
   .proc write
      rts
   .endproc

   ; This method must put currently valid values into the GUI components, so when they are drawn they show
   ; currently valid values. This is for cases such as a different synth timbre is selected and the new
   ; values have to be loaded into the GUI, or a different oscillator tab has been selected etc.
   ; (Data transfer direction: underlying data -> GUI components)
   ; Note: Redrawing the panel after refresh is handled by the calling code, so refresh routines don't need to do it.
   .proc refresh
      rts
   .endproc

   ; This method handles key presses. The return value of the most recently called GETIN value
   ; is in kbd_variables::current_key.
   ; Each panel gets the chance to react to a key press, in the order they appear in the GUI stack.
   ; If this panel does not react to (i.e., "use") the key press, no action is required.
   ; If the key press is used, the above mentioned variable should be set to zero so that other panels
   ; do not react to the same key press.
   .proc keypress
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_EXAMPLE_ASM
