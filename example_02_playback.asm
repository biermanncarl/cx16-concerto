; Copyright 2021 Carl Georg Biermann

; This file is part of Concerto.

; Concerto is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;*****************************************************************************

; Compile with: cl65 -t cx16 -o EXAMPLE01.PRG example_01_hello_world_concerto.asm -C cx16-asm.cfg


.zeropage
.include "concerto_synth/synth_zeropage.asm"


.segment "CODE"
; BASIC stub to start program
; "10 SYS2061"
.org $0801
.byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
.org $080D

   jmp start



; define a macro with the player address BEFORE including "concerto_synth/concerto_synth.asm"
concerto_playback_routine = my_custom_playback_routine

.include "concerto_synth/concerto_synth.asm"

; You can do anything you want in this routine.
; Here we have set up an example that plays a chromatic scale
; with two notes which are 3 semi tones apart.
my_custom_playback_routine:
   ; every time playback_ticks is 0 we play a note
   lda playback_ticks
   beq @trigger_note
   dec playback_ticks
   rts
@trigger_note:
   ; reset timer. The higher this number, the slower the chromatic scale is played.
   lda #30
   sta playback_ticks
   ; now play the note
   lda playback_note
   sta concerto_synth::note_pitch
   lda #63
   sta concerto_synth::note_volume
   lda #0
   sta concerto_synth::note_channel
   lda #0
   sta concerto_synth::note_timbre
   sei
   jsr concerto_synth::play_note
   cli
   ; and play another note at another channel
   lda playback_note
   clc
   adc #3
   sta concerto_synth::note_pitch
   lda #1
   sta concerto_synth::note_channel
   sei
   jsr concerto_synth::play_note
   cli
   ; increase pitch
   inc playback_note
   rts

playback_ticks:
   .byte 0
playback_note:
   .byte 0

start:
   ; initialize player variables
   lda #0
   sta playback_ticks
   lda #48
   sta playback_note

   jsr concerto_synth::initialize
   jsr concerto_synth::activate_synth

   ; and wait until key is pressed
mainloop:
   jsr $FFE4 ; GETIN
   beq mainloop

   jsr concerto_synth::deactivate_synth

   rts
