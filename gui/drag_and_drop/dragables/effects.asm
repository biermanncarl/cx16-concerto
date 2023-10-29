; Copyright 2023 Carl Georg Biermann

; This contains implementation of drag and drop of effects within clips.

.ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_EFFECTS_ASM
::GUI_DRAG_AND_DROP_DRAGABLES_EFFECTS_ASM = 1

.include "common.asm"
.include "notes.asm"

.scope effects
    hitbox_height = 2
    px = notes::px
    py = notes::py + 2 * notes::height + 1
    width = notes::width
    height = 6 ; todo
    draw = dragables_common::dummy_subroutine ; this will stay dummy, as the note's draw routine will take care of drawing effects, too
    drag = dragables_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_EFFECTS_ASM
