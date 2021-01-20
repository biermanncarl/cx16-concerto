; This file contains macros for loops used for testing purposes.

; copied from player.asm
; loop events. Each event 5 bytes. Some events may have a second one attached to it with more data
; first byte is event type
; the other bytes depend on the type
; event types:
; 0 - end of data stream
; 1 - wait -- 2 bytes wait length -- 2 bytes unused
; 2 - play note -- 1 byte channel -- 1 byte instrument -- 1 byte pitch -- 1 byte volume
; 3 - stop note -- 1 byte channel -- 1 byte soft or hard ending -- 2 bytes unused (ending: 0 with release, 1 hard ending)
; more to come

.macro DNB ; we don't need note-offs xD
   ; 1 bar
   .byte    2,    0,    3,   40,   64
   .byte    2,    1,    5,   48,   60
   .byte    2,    2,    6,    0,   40
   .byte    1,   20,    0,    0,    0
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    4,   40,   64
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    1,    5,   48,   60
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    3,   40,   64
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    4,   40,   64
   .byte    2,    1,    5,   56,   60
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    2,    6,    0,   40
   ; 1 bar
   .byte    2,    0,    3,   40,   64
   .byte    2,    1,    5,   55,   60
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    4,   40,   64
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    1,    5,   55,   60
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    3,    1,    0,    0,    0
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    3,   40,   64
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    4,   40,   64
   .byte    2,    1,    5,   49,   60
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   .byte    2,    2,    6,    0,   40
   .byte    1,    20,   0,    0,    0
   ; end of loop
   .byte    0
.endmacro

.macro MELLOW_LOOP
   ; 1 bar
   .byte    2,    0,    8,   43,   64
   .byte    1,    3,    0,    0,    0
   .byte    2,    3,    8,   62,   64
   .byte    1,   47,    0,    0,    0
   .byte    2,    1,    8,   50,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    4,    8,   67,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    3,    8,   62,   64
   .byte    1,   25,    0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    3,    4,    0,    0,    0
   .byte    1,   28,    0,    0,    0
   ; 1 bar
   .byte    2,    0,    8,   50,   64
   .byte    2,    3,    8,   62,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    1,    8,   57,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    4,    8,   66,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    3,    8,   62,   64
   .byte    1,   25,    0,    0,    0
   .byte    3,    3,    0,    0,    0
   .byte    3,    4,    0,    0,    0
   .byte    1,   28,    0,    0,    0
   ; 1 bar
   .byte    2,    3,    8,   59,   64
   .byte    1,    3,    0,    0,    0
   .byte    2,    0,    8,   40,   64
   .byte    1,   47,    0,    0,    0
   .byte    2,    1,    8,   47,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    4,    8,   64,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    3,    8,   59,   64
   .byte    1,   25,    0,    0,    0
   .byte    3,    3,    0,    0,    0
   .byte    3,    4,    0,    0,    0
   .byte    1,   28,    0,    0,    0
   ; 1 bar
   .byte    2,    0,    8,   48,   64
   .byte    1,    3,    0,    0,    0
   .byte    2,    3,    8,   62,   64
   .byte    1,   47,    0,    0,    0
   .byte    2,    1,    8,   52,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    4,    8,   67,   64
   .byte    1,   50,    0,    0,    0
   .byte    2,    3,    8,   62,   64
   .byte    1,   25,    0,    0,    0
   ;.byte    3,    3,    0,    0,    0
   ;.byte    3,    4,    0,    0,    0
   .byte    1,   28,    0,    0,    0
   .byte    0
.endmacro
