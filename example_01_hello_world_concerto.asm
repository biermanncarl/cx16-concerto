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

; Compile with: cl65 -t cx16 -o EXAMPLE01.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_01_hello_world_concerto.asm"


.zeropage
.include "concerto_synth/synth_zeropage.asm"


.code
; BASIC stub to start program
; "10 SYS2061"
;.org $0801
;.byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
;.org $080D

   jmp start

.include "concerto_synth/concerto_synth.asm"

start:
   jsr concerto_synth::initialize
   jsr concerto_synth::activate_synth


   ; play a note
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

   ; and wait until key is pressed
mainloop:
   jsr $FFE4 ; GETIN
   beq mainloop

   jsr concerto_synth::deactivate_synth
   rts
