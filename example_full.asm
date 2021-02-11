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


;*****************************************************************************;
; Program: CONCERTO                                                           ;
; Platform: Commander X16 (Emulator R38)                                      ;
; Compiler: CC65                                                              ;
; Compile with: cl65 -t cx16 -o CONCERTO.PRG example_full.asm -C cx16-asm.cfg ;
; Author: Carl Georg Biermann                                                 ;
; Dedication:                                                                 ;
;                                                                             ;
;                  Sing joyfully to the Lord, you righteous;                  ;
;                 it is fitting for the upright to praise him.                ;
;                       Praise the Lord with the harp;                        ;
;                 make music to him on the ten-stringed lyre.                 ;
;                          Sing to him a new song;                            ;
;                    play skillfully, and shout for joy.                      ;
;                 For the word of the Lord is right and true;                 ;
;                       he is faithful in all he does.                        ;
;                                                                             ;
;                            Psalm 33 Verses 1-4                              ;
;                                                                             ;
;*****************************************************************************;

.zeropage
; define zero page variables of the submodules
.include "concerto_synth/synth_zeropage.asm"
.include "concerto_gui/gui_zeropage.asm"


.segment "CODE"
; BASIC stub to start program
; "10 SYS2061"
.org $0801
.byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00

; And here is address 2061 = $080D, which is called by BASIC.
.org $080D

   jmp start

; include the synth engine
.include "concerto_synth/concerto_synth.asm"

; include the synth gui
.include "concerto_gui/concerto_gui.asm"


; keyboard variables
Octave:
   .byte 60
Note:
   .byte 0



start:
   ; set ROM bank to 0 (from 4, the BASIC ROM)
   ; this is for better performance (the BASIC ROM has shown to have a hit on performance over the 0 ROM)
   stz ROM_BANK

   jsr concerto_synth::initialize
   jsr concerto_gui::initialize

   jsr concerto_synth::activate_synth

.include "example_full_mainloop.asm"

   jsr concerto_synth::deactivate_synth
   jsr concerto_gui::hide_mouse

   ; restore BASIC ROM page
   lda #4
   sta ROM_BANK

   rts            ; return to BASIC
