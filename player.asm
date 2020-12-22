; plays notes
; currently just here to test the sound engine.

.scope player

.define event_length 5

; player variables
time: .word $0  ; countdown timer, counts the ticks until the next event.
event_pointer: .byte 0

; loop events. Each event 5 bytes. Some events may have a second one attached to it with more data
; first byte is event type
; the other bytes depend on the type
; event types:
; 0 - end of data stream
; 1 - wait -- 2 bytes wait length -- 2 bytes unused
; 2 - play note -- 1 byte channel -- 1 byte instrument -- 1 byte pitch -- 1 byte volume
; 3 - stop note -- 1 byte channel -- (1 byte soft or hard ending, i.e. with or without release phase)
; more to come
events:
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

player_tick:
   lda time
   bne :++
   ; low byte of timer is zero
   dec
   sta time
   lda time+1
   bne :+
   ; time is completely zero
   jmp do_events
:  ; update high byte
   dec
   sta time+1
   bra :++
:  ; update low byte
   dec
   sta time
:  rts

; timer has arrived at 0. This means, the next event is read
do_events:
   ; load event pointer
   ; put it into register Y before increasing it
   lda event_pointer
   tay
   clc
   adc #event_length
   sta event_pointer
   lda events, y
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word player_end_of_data
   .word player_wait
   .word player_play_note
   .word player_stop_note



; EVENT HANDLERS
; expect data pointer in register Y

; end of data event
; for now, just loop
player_end_of_data:
   stz event_pointer
   jmp do_events

; wait event
player_wait:
   ; load waiting length
   ; the subtraction is done, because the current tick is counted as 1. So if we wait 1 tick overall, in the next tick we will do the next event
   lda events+1, y
   sec
   sbc #1
   sta time
   lda events+2, y
   sbc #0
   sta time+1
   rts

; play note event
player_play_note:
   lda events+1, y
   sta voices::note_channel
   lda events+2, y
   sta voices::note_timbre
   lda events+3, y
   sta voices::note_pitch
   lda events+4, y
   sta voices::note_volume
   jsr voices::play_note
   jmp do_events

; stop note event. TODO: distinguish soft and hard note stops (soft aka. put notes into release phase)
player_stop_note:
   ; first check if note is active
   ldx events+1, y
   lda voices::Voice::active, x
   beq :+
   jsr voices::stop_note
:  jmp do_events

.endscope