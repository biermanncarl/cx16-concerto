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

; Include this file to be able to use the Concerto synth engine.

; Usage:
;  - include this file
;  - call ... to install the interrupt service routine that updates the VERA PSG voices.
;  - call ... to play notes (for more details, see voices.asm)
;  - call ... to stop the interrupt service routine

; You can emply your own playback routine within each call of the interrupt service routine
; via setting this following (compile time) vector to point to the starting address of
; your own routine before including concerto_synth.asm.
; Example:
;
;    concerto_playback_routine = my_playback_routine
;    .include "concerto_synth/concerto_synth.asm"
;
;    my_playback_routine:
;       ...
;       rts

; this is used by the GUI, as well. Therefore cannot put it into a scope.
.include "x16.asm"



.scope concerto_synth

.include "pitch_data.asm"
.include "synth_macros.asm"
.include "timbres.asm"
.include "voices.asm"
.include "synth_tick.asm"
.include "my_isr.asm"



; subroutine to initialize the synth engine
initialize:
   jsr timbres::init_timbres
   jsr voices::init_voices
   rts

; subroutine to activate the synth engine
activate_synth = my_isr::launch_isr

; subroutine to deactivate the synth engine
deactivate_synth:
   ; turn off all voices
   jsr voices::panic
   jsr my_isr::shutdown_isr
   rts

; default dummy playback routine being called in the isr
; can be replaced by setting the macro "concerto_playback_routine" to the starting address of a custom playback routine
default_playback:
   rts

.ifndef playback_routine
   concerto_playback_routine = default_playback
.endif

.endscope