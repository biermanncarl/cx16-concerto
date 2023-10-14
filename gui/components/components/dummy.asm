; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_DUMMY_ASM

::GUI_COMPONENTS_COMPONENTS_DUMMY_ASM = 1

.include "common.asm"

.scope dummy
   ; The dummy component always registers a click event, so that its parent panel
   ; never misses a click (useful e.g. for popups which close when one clicks anywhere on screen).

   .struct data_members
      ; no data
   .endstruct

   draw = components_common::dummy_subroutine

   ; dummy always registers a click event, regardless of where the mouse is. Useful for popups.
   .proc check_mouse
      ; get mouse coordinates (in 8 pixel multiples) and put them into data
      lda components_common::mouse_downscaled_x
      lsr
      sta mouse_variables::curr_data_1
      lda components_common::mouse_downscaled_y
      lsr
      sta mouse_variables::curr_data_2
      sec
      rts
   .endproc

   .proc event_click
      ; Similar to a button. Just tell the panel that it needs to do *something* (it will know what to do when it is told *which* dummy was clicked)
      inc gui_variables::request_component_write
      rts
   .endproc

   event_drag = components_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DUMMY_ASM
