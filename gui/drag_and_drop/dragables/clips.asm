; Copyright 2023 Carl Georg Biermann

; This contains implementation of drag and drop of clips within the arrangement view.

.ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_CLIPS_ASM
::GUI_DRAG_AND_DROP_DRAGABLES_CLIPS_ASM = 1

.scope clips
    hitbox_height = 6
    px = 0
    py = 0
    width = 0
    height = 0
    draw = dragables_common::dummy_subroutine
    drag = dragables_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_CLIPS_ASM

