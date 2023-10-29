; Copyright 2023 Carl Georg Biermann


.ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_COMMON_ASM
::GUI_DRAG_AND_DROP_DRAGABLES_COMMON_ASM = 1

.scope dragables_common
   ; subroutine which can be referenced where no action is required but still some address needs to be given.
   .proc dummy_subroutine
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_COMMON_ASM

