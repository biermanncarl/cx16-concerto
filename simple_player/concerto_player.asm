; Copyright 2021-2022 Carl Georg Biermann


; This file contains the API to a music player. It plays back linear
; data in RAM using the Concerto synth engine.
; The music data format is detailed in "specifications.md".

; If you include this file, you do NOT need to include "concerto_synth.asm" separately.

concerto_playback_routine = concerto_player_temp
.include "../synth_engine/concerto_synth.asm"

.pushseg
.code

.scope concerto_player

; PLAYER INTERFACE
; ****************

; concerto_player::repeat
; This variable states whether or not to repeat the song being played.
; 0 = no repeat. Everything else is repeat.
repeat:
   .byte 0

; This variable holds the vector to a customizable callback function.
; Player command 13 calls this with one data byte in .A as a parameter.
callback_vector:
   .word dummy_subroutine


; concerto_player::play_track
; Enables the player and starts playing from the specified address in RAM.
; PARAMETERS: .X low byte address
;             .Y high byte address
play_track:
   stz wait_timer
   stz wait_timer+1
   php
   sei
   stx data_pointer
   sty data_pointer+1
   plp
   stx start_address
   sty start_address+1
   jsr concerto_synth::activate_synth
dummy_subroutine: ; I just need a label pointing to an RTS instruction for this, so I take the one from play_track.
   rts


stop_track:
   stz start_address+1 ; turn player off
   jsr concerto_synth::panic ; turn off all voices
   rts

; ***********************
; END OF PLAYER INTERFACE


; this counter counts down the ticks until the next event.
wait_timer:
   .word 0

; the music data pointer
; The high byte being 0 is interpreted as player inactive, i.e., the song data
; cannot be on the zero page.
data_pointer:
   .word 0
; the zeropage pointer. This is "stolen" from the concerto_synth zeropage.
; However, as the player tick is guaranteed to run BEFORE the synth_tick,
; we can do this, as long as the variable is not needed for any voice
; management routines, which might get called from within the player tick.
; optimally, one would use a dedicated ZP variable, as this would allow for
; both faster operation and would eliminate the need to copy the pointer
; to the ZP in every tick.
zp_pointer = concerto_synth::mzpwf ; safe to use, since this comes IN the ISR, before the synth_tick subroutine, so it is impossible to get interrupted by the ISR.

; remembers the address where the song was started, in case it is repeated
start_address:
   .word 0





concerto_player_tick:
   ; check if active
   lda start_address+1
   bne :+
   rts ; HI address byte being zero indicates player inactive
:  ; do wait timer
   lda wait_timer
   beq @check_zero
   dec
   sta wait_timer
   rts
@check_zero:
   lda wait_timer+1
   beq @read_event
   dec
   sta wait_timer+1
   dec wait_timer
   rts
@read_event:
   lda data_pointer
   sta zp_pointer
   lda data_pointer+1
   sta zp_pointer+1
   ldy #0
   lda (zp_pointer), y
   and #%11110000 ; extract upper nibble to get command number
   lsr
   lsr
   lsr
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @wait
   .word @play_note
   .word @release_note
   .word @stop_note
   .word @pitchbend_position
   .word @pitchbend_rate
   .word @volume
   .word @volume_ramp
   .word @vibrato_amount
   .word @vibrato_ramp
   .word 0 ; unused
   .word 0 ; unused
   .word 0 ; unused
   .word @user_callback
   .word @panic
   .word @end_track
@wait:
   iny
   lda (zp_pointer), y
   sta wait_timer
   iny
   lda (zp_pointer), y
   sta wait_timer+1
   lda #3
   ; We have set the timer to the number of ticks we shall wait until the next event.
   ; After the event address increment, we will end up at the top of this routine,
   ; where one tick is decremented from the timer,
   ; which accounts for this very tick we are in right here.
   jmp @increment_address
@play_note:
   ; get voice number
   jsr read_voice
   sta concerto_synth::note_voice
   iny
   lda (zp_pointer), y
   sta concerto_synth::note_instrument
   iny
   lda (zp_pointer), y
   sta concerto_synth::note_pitch
   iny
   lda (zp_pointer), y ; load note volume
   jsr concerto_synth::play_note
   lda #4
   jmp @increment_address
@release_note:
   jsr read_voice
   sta concerto_synth::note_voice
   jsr concerto_synth::release_note
   lda #1
   jmp @increment_address
@stop_note:
   jsr read_voice
   sta concerto_synth::note_voice
   jsr concerto_synth::stop_note
   lda #1
   jmp @increment_address
@pitchbend_position:
   jsr read_voice
   tax
   iny
   lda (zp_pointer), y ; fine position
   pha
   iny
   lda (zp_pointer), y ; coarse position
   ply
   jsr concerto_synth::set_pitchslide_position
   lda #3
   jmp @increment_address
@pitchbend_rate:
   jsr read_voice
   tax
   iny
   lda (zp_pointer), y
   pha ; fine rate
   iny
   lda (zp_pointer), y
   pha ; coarse rate
   iny
   lda (zp_pointer), y
   sta concerto_synth::pitchslide_mode
   ply ; coarse rate
   pla ; fine rate
   jsr concerto_synth::set_pitchslide_rate
   lda #4
   jmp @increment_address
@volume:
   jsr read_voice
   tax
   iny
   lda (zp_pointer), y ; volume
   jsr concerto_synth::set_volume
   lda #2
   jmp @increment_address
@volume_ramp:
   jsr read_voice
   tax
   iny
   lda (zp_pointer), y
   pha ; slope
   iny
   lda (zp_pointer), y
   tay ; threshold
   pla ; slope
   jsr concerto_synth::set_volume_ramp
   lda #3
   jmp @increment_address
@vibrato_amount:
   jsr read_voice
   tax
   iny
   lda (zp_pointer), y
   jsr concerto_synth::set_vibrato_amount
   lda #2
   jmp @increment_address
@vibrato_ramp:
   jsr read_voice
   tax
   iny
   lda (zp_pointer), y
   pha ; slope
   iny
   lda (zp_pointer), y
   tay ; threshold level
   pla ; slope
   jsr concerto_synth::set_vibrato_ramp
   lda #3
   jmp @increment_address
@user_callback:
   iny
   lda (zp_pointer), y ; load callback parameter into .A
   ; indirect JSR
   ldx #>(@return_addr-1)
   phx
   ldx #<(@return_addr-1)
   phx
   jmp (callback_vector)
@return_addr:
   lda #2
   jmp @increment_address
@panic:
   jsr concerto_synth::panic
   lda #1
   jmp @increment_address
@end_track:
   jsr concerto_synth::panic
   lda repeat
   bne :+
   stz start_address+1 ; turn player off
   rts ; return if there is no repeat
:  lda start_address
   sta data_pointer
   lda start_address+1
   sta data_pointer+1
   jmp concerto_player_tick ; continue reading commands if repeat is on

@increment_address:
   ; expect address increment in .A
   clc
   adc data_pointer
   sta data_pointer
   bcc :+
   inc data_pointer+1
:  ; process next command, until wait command or song's end
   jmp concerto_player_tick


; reads the number of the voice being addressed from the current song position
read_voice:
   lda (zp_pointer), y
   and #%00001111
   rts

.endscope

.popseg

concerto_player_temp = concerto_player::concerto_player_tick

