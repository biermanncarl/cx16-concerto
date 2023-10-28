; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_DRAG_AND_DROP_LOOKUP_TABLES_ASM
::GUI_DRAG_AND_DROP_LOOKUP_TABLES_ASM = 1

; Object heights in multiples of 4 pixel
hitbox_heights:
; TODO: find clean solution for this, probably some "backward definitions"
;   .byte notes::height, effects::height, clips::height
   .byte 2, 2, 6

.endif ; .ifndef ::GUI_DRAG_AND_DROP_LOOKUP_TABLES_ASM
