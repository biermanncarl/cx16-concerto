; Copyright 2021, 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_COMMON_ASM

::GUI_COMPONENTS_COMPONENTS_COMMON_ASM = 1

.include "../../gui_zeropage.asm"

.scope components_common

   ; This pointer is valid for draw, check_mouse, event_click and event_drag subroutines.
   ; The relative index to this pointer is given either in .Y or in the mouse variables.
   data_pointer = mzpwa

   ; These variables are valid only for "check" routines.
   mouse_downscaled_x = mzpwd
   mouse_downscaled_y = mzpwd+1
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_COMMON_ASM
