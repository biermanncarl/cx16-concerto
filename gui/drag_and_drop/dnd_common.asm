; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_DRAG_AND_DROP_VARIABLES_ASM
::GUI_DRAG_AND_DROP_VARIABLES_ASM = 1

; by putting these variables in here (globally), we assume there can only be one scrolling operation going on at any one time
accumulated_x:
    .byte 0
accumulated_y:
    .byte 0
; Keyboard modifiers
ctrl_key_pressed:
    .byte 0
shift_key_pressed:
    .byte 0
alt_key_pressed:
    .byte 0

; Vectors for processing events
temp_events:
    .res 2
clipboard_events:
    .res 2

; Which kind of drag & drop operation is going on. Values mean different things
drag_action_state:
    .byte 0


; Returns the mouse's relative motion in terms of whole characters (i.e. multiples of 8 pixels).
; Accumulation of sub-character motion is done internally.
; Returns delta x in .A
; Returns delta y in .X
.proc getMouseChargridMotion
    ; y coordinate
    lda mouse_variables::delta_y
    clc
    adc dnd::accumulated_y
    jsr signedDivMod8
    sty dnd::accumulated_y
    tax
    ; x coordinate
    lda mouse_variables::delta_x
    clc
    adc dnd::accumulated_x
    jsr signedDivMod8
    sty dnd::accumulated_x
    rts

    ; Do a signed division by 8 and modulo 8 operation on the argument in .A.
    ; Returns the quotient in .A and the remainder in .Y.
    ; Preserves .X
    .proc signedDivMod8
        pha
        and #7
        tay
        pla
        clc
        adc #128
        lsr
        lsr
        lsr
        sec
        sbc #128/8
        rts
    .endproc
.endproc

.endif ; .ifndef ::GUI_DRAG_AND_DROP_VARIABLES_ASM
