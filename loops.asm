; This file contains macros for loops used for testing purposes.

; copied from player.asm
; loop events. Each event 5 bytes. Some events may have a second one attached to it with more data
; first byte is event type
; the other bytes depend on the type
; event types:
; 0 - end of data stream
; 1 - wait -- 2 bytes wait length -- 2 bytes unused
; 2 - play note -- 1 byte channel -- 1 byte instrument -- 1 byte pitch -- 1 byte volume
; 3 - stop note -- 1 byte channel -- (1 byte soft or hard ending, i.e. with or without release phase)
; more to come

.macro DNB1
   ; 1 bar
   .byte    2,    0,    3,    40,   64
   .byte    2,    1,    1,    36,   60
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    4,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    2,    1,    1,    36,   60
   .byte    3,    0,    0,    0,    0
   .byte    1,    40,   0,    0,    0
   .byte    2,    0,    3,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    2,    0,    4,    40,   64
   .byte    2,    1,    1,    44,   60
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    20,   0,    0,    0
   ; 1 bar
   .byte    2,    0,    3,    40,   64
   .byte    2,    1,    1,    43,   60
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    4,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    2,    1,    1,    43,   60
   .byte    3,    0,    0,    0,    0
   .byte    1,    40,   0,    0,    0
   .byte    2,    0,    3,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    2,    0,    4,    40,   64
   .byte    2,    1,    1,    37,   60
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    20,   0,    0,    0
   ; end of loop
   .byte    0
.endmacro

.macro POLY_SUS_RELEASE
   .byte    2,    0,    0,    48,   64
   .byte    1,    60,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    60,   0,    0,    0
   ; end of loop
   .byte    0
.endmacro