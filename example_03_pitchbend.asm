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

; Compile with: cl65 -t cx16 -o EXAMPLE02.PRG example_02_playback.asm -C cx16-asm.cfg


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

playback_ticks:
   .byte 0
playback_note:
   .byte 0

; You can do anything you want in this routine.
my_custom_playback_routine:
   lda playback_ticks
   beq @reset_loop
   cmp #255
   bne :+
   jsr play_note_1     ; play note if timer is 255
:  lda playback_ticks
   cmp #(255-32)
   bne :+
   jsr set_pitchslide_upwards   ; set pitchbend up if timer is 255-32
:  cmp #(255-96)
   bne :+
   jsr set_pitchslide_downwards  ; set pitchbend down if timer is 255-96
:  cmp #(255-192)
   bne :+
   jsr set_slide_position  ; set pitchbend position if timer is 255-192
:  dec playback_ticks
   rts
@reset_loop:
   ; reset timer. The higher this number, the slower the chromatic scale is played.
   lda #255
   sta playback_ticks
   rts

play_note_1:
   lda #60
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
   rts

set_pitchslide_upwards:
   lda #0
   sta concerto_synth::pitchslide_rate_note
   lda #20
   sta concerto_synth::pitchslide_rate_fine
   lda #0
   sta concerto_synth::note_channel
   jsr concerto_synth::set_pitchslide_rate
   rts

set_pitchslide_downwards:
   ; because fine values are always positive, we have to add a negative "coarse" value to achieve a slow downwards slope
   ; E.g. we want the negative slope -0.1
   ; We achieve this by -0.1 = -1 + 0.9
   lda #255 ; -1
   sta concerto_synth::pitchslide_rate_note
   lda #(255-25) ; +0.9.  
   sta concerto_synth::pitchslide_rate_fine
   lda #0
   sta concerto_synth::note_channel
   jsr concerto_synth::set_pitchslide_rate
   rts

set_slide_position:
   lda #80
   sta concerto_synth::pitchslide_position_note
   lda #0
   sta concerto_synth::pitchslide_position_fine
   lda #0
   sta concerto_synth::note_channel
   jsr concerto_synth::set_pitchslide_position
   rts

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
