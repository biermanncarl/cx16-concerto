; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_ASM
::GUI_DRAG_AND_DROP_DRAGABLES_ASM = 1

.scope dragables

.include "../../common/utility_macros.asm"
.include "dragables/clips.asm"
.include "dragables/effects.asm"
.include "dragables/notes.asm"

; register all types of drag and drop objects we support
.define ALL_DRAG_AND_DROP_TYPE_SCOPES notes, effects, clips

.scope ids
   ID_GENERATOR 0, ALL_DRAG_AND_DROP_TYPE_SCOPES
.endscope

; This variable must be set to the desired type of objects before many function calls. (Move to zeropage?)
active_type:
   .res 1

; Dragable object heights in multiples of 4 pixel
hitbox_heights: SCOPE_MEMBER_BYTE_FIELD hitbox_height, ALL_DRAG_AND_DROP_TYPE_SCOPES

edit_positions_x: SCOPE_MEMBER_BYTE_FIELD px, ALL_DRAG_AND_DROP_TYPE_SCOPES
edit_positions_y: SCOPE_MEMBER_BYTE_FIELD py, ALL_DRAG_AND_DROP_TYPE_SCOPES
edit_width: SCOPE_MEMBER_BYTE_FIELD width, ALL_DRAG_AND_DROP_TYPE_SCOPES
edit_height: SCOPE_MEMBER_BYTE_FIELD height, ALL_DRAG_AND_DROP_TYPE_SCOPES

jump_table_draw: SCOPE_MEMBER_WORD_FIELD draw, ALL_DRAG_AND_DROP_TYPE_SCOPES
jump_table_drag: SCOPE_MEMBER_WORD_FIELD drag, ALL_DRAG_AND_DROP_TYPE_SCOPES

.endscope

.endif ; .ifndef ::GUI_DRAG_AND_DROP_DRAGABLES_ASM
