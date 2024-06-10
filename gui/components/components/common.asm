; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_COMMON_ASM

::GUI_COMPONENTS_COMPONENTS_COMMON_ASM = 1

.include "../../gui_variables.asm"

.scope components_common
   ; This pointer is valid for draw, check_mouse, event_click and event_drag subroutines.
   ; The relative offset to this pointer is given either in .Y or in the mouse variables.
   data_pointer = gui_variables::mzpwa

   ; subroutine which can be referenced where no action is required but still some address needs to be given.
   .proc dummy_subroutine
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_COMMON_ASM
