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


; This file contains code that has been removed from the main project,
; but is kept for reference.




   ; then load custom ones
   PRESET_ONE_OSC_PATCH 0
   PRESET_BRIGHT_PLUCK 1
   PRESET_KEY_1 2
   PRESET_KICK_DRUM_3 3
   PRESET_SNARE_DRUM_5 4
   PRESET_FAT_PLUCK 5
   PRESET_TAMBOURINE 6
   PRESET_KEY_2 7
   PRESET_GUITAR_1 8



; primitive write_timbre
   phx
   lda Timbre::n_oscs, x
   jsr CHROUT
   lda Timbre::n_envs, x
   jsr CHROUT
   lda Timbre::n_lfos, x
   jsr CHROUT
   lda Timbre::porta, x
   jsr CHROUT
   lda Timbre::porta_r, x
   jsr CHROUT
   lda Timbre::retrig, x
   jsr CHROUT
   lda Timbre::lfo::rateH, x
   jsr CHROUT
   lda Timbre::lfo::rateL, x
   jsr CHROUT
   lda Timbre::lfo::wave, x
   jsr CHROUT
   lda Timbre::lfo::retrig, x
   jsr CHROUT
   lda Timbre::lfo::offs, x
   jsr CHROUT
   ldy #MAX_ENVS_PER_VOICE
@loop_envs:
   lda Timbre::env::attackL, x
   jsr CHROUT
   lda Timbre::env::attackH, x
   jsr CHROUT
   lda Timbre::env::decayL, x
   jsr CHROUT
   lda Timbre::env::decayH, x
   jsr CHROUT
   lda Timbre::env::sustain, x
   jsr CHROUT
   lda Timbre::env::releaseL, x
   jsr CHROUT
   lda Timbre::env::releaseH, x
   jsr CHROUT
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_envs
   plx
   phx
   ldy #MAX_OSCS_PER_VOICE
@loop_oscs:
   lda Timbre::osc::pitch, x
   jsr CHROUT
   lda Timbre::osc::fine, x
   jsr CHROUT
   lda Timbre::osc::track, x
   jsr CHROUT
   lda Timbre::osc::pitch_mod_sel1, x
   jsr CHROUT
   lda Timbre::osc::pitch_mod_dep1, x
   jsr CHROUT
   lda Timbre::osc::pitch_mod_sel2, x
   jsr CHROUT
   lda Timbre::osc::pitch_mod_dep2, x
   jsr CHROUT
   lda Timbre::osc::lrmid, x
   jsr CHROUT
   lda Timbre::osc::volume, x
   jsr CHROUT
   lda Timbre::osc::amp_sel, x
   jsr CHROUT
   lda Timbre::osc::vol_mod_sel, x
   jsr CHROUT
   lda Timbre::osc::vol_mod_dep, x
   jsr CHROUT
   lda Timbre::osc::waveform, x
   jsr CHROUT
   lda Timbre::osc::pulse, x
   jsr CHROUT
   lda Timbre::osc::pwm_sel, x
   jsr CHROUT
   lda Timbre::osc::pwm_dep, x
   jsr CHROUT
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_oscs
   plx




; primitive listbox behaviour. just skip through the list
click_listbox:
   ; TODO: make popup happen
   lda ms_curr_component_ofs
   clc
   adc #7
   tay
   lda (ce_pointer), y
   inc
   dey
   dey
   dey
   cmp (ce_pointer), y
   bcc :+
   lda #0
:  iny
   iny
   iny
   sta (ce_pointer), y
@update:
   ldy ms_curr_component_ofs
   iny
   jsr draw_listbox

   rts




; this snippet is a draft from the SCALE5_16 macro
; it is supposed to rightshift a 16 bit register by N times (N: 0..15)
; the naive approach can be horribly slow if N is large
    ; do rightshifts
    .local @loopH
    .local @skipH
    lda moddepth, y
    and #%00001111
    beq @skipH
    phy
    tay
    lda mzpwb+1 ; 15 cycles
    ; we're here with a nonzero value in y which denotes the number of rightshifts to be done
@loopH:
    clc
    ror
    ror mzpwb   ; unfortunately, we cannot ROR both bytes entirely inside CPU ... or can we (efficiently) ?
    dey
    bne @loopH  ; 14 cycles * number of RSHIFTS

    sta mzpwb+1
    ply         ; plus 6 cycles
@skipH:

    ; naive scheme: 20 cycles + 14 * number of rightshifts





   ; 1 bar DnB beat
   .byte    2,    0,    3,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    20,   0,    0,    0
   .byte    2,    0,    4,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    40,   0,    0,    0
   .byte    2,    0,    3,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    2,    0,    4,    40,   64
   .byte    1,    20,   0,    0,    0
   .byte    3,    0,    0,    0,    0
   .byte    1,    20,   0,    0,    0






; initial startup message
; string constants
message:
   .byte $0D, "controls", $0D
   .byte "--------", $0D, $0D
   .byte "a,w,s,...   play notes", $0D
   .byte "z,x         toggle octaves", $0D
   .byte "q           quit", $0D
end_message:

   ; print message
   lda #<message
   sta mzpwa
   lda #>message
   sta mzpwa+1
   ldy #0
@loop_msg:
   cpy #(end_message-message)
   beq @done_msg
   lda (mzpwa),y
   jsr CHROUT
   iny
   bra @loop_msg
@done_msg:








; Voicing system debug GUI
; message strings
msg_freevoicelist:
   STR_FORMAT "freevoicelist"
msg_nfv:
   STR_FORMAT "number of free voices"
msg_ffv:
   STR_FORMAT "first free voice"
msg_lfv:
   STR_FORMAT "last free voice"

msg_usedvoicelist:
   STR_FORMAT "usedvoicelist"
msg_uvl_up:
   STR_FORMAT "up"
msg_uvl_dn:
   STR_FORMAT "dn"
msg_uvl_oldest:
   STR_FORMAT "oldest"
msg_uvl_youngest:
   STR_FORMAT "youngest"

   ; displaying for debugging
   ; freevoicelist
   DISPLAY_LABEL msg_freevoicelist, 2, 10
   DISPLAY_LABEL msg_nfv, 2, 12
   DISPLAY_BYTE voices::Voicemap::nfv, 2,13
   DISPLAY_LABEL msg_ffv, 27, 12
   DISPLAY_BYTE voices::Voicemap::ffv, 27, 13
   DISPLAY_LABEL msg_lfv, 52, 12
   DISPLAY_BYTE voices::Voicemap::lfv, 52, 13

   DISPLAY_BYTE voices::Oscmap::freeosclist+00,  2, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+01,  6, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+02, 10, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+03, 14, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+04, 18, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+05, 22, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+06, 26, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+07, 30, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+08, 34, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+09, 38, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+10, 42, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+11, 46, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+12, 50, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+13, 54, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+14, 58, 15
   DISPLAY_BYTE voices::Oscmap::freeosclist+15, 62, 15

   DISPLAY_BYTE voices::Oscmap::ffo,  2, 17
   DISPLAY_BYTE voices::Oscmap::lfo,  6, 17
   DISPLAY_BYTE voices::Oscmap::nfo, 10, 17

   DISPLAY_LABEL msg_usedvoicelist, 2, 18
   DISPLAY_LABEL msg_uvl_oldest, 2, 20
   DISPLAY_BYTE voices::Voicemap::uvf, 2,21
   DISPLAY_LABEL msg_uvl_youngest, 27, 20
   DISPLAY_BYTE voices::Voicemap::uvl, 27,21
   DISPLAY_LABEL msg_uvl_up, 2, 23
   DISPLAY_LABEL msg_uvl_dn, 2, 25

   DISPLAY_BYTE voices::Voicemap::usedvoicesup+00,  6, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+01, 10, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+02, 14, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+03, 18, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+04, 22, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+05, 26, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+06, 30, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+07, 34, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+08, 38, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+09, 42, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+10, 46, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+11, 50, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+12, 54, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+13, 58, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+14, 62, 23
   DISPLAY_BYTE voices::Voicemap::usedvoicesup+15, 66, 23

   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+00,  6, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+01, 10, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+02, 14, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+03, 18, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+04, 22, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+05, 26, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+06, 30, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+07, 34, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+08, 38, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+09, 42, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+10, 46, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+11, 50, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+12, 54, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+13, 58, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+14, 62, 25
   DISPLAY_BYTE voices::Voicemap::usedvoicesdn+15, 66, 25




   ; draw something
   lda cx
   sta guiutils::cur_x
   lda cy
   sta guiutils::cur_y
   jsr guiutils::set_cursor
   lda #65
   sta VERA_data0



; just parking this here



   lda my_switch  ; load the variable which tells us what to do
   asl            ; multiply with 2, so we can index 16 bit addresses
   tax            ; put it into indexing register
   jmp (jmp_table, x)
jmp_table:
   .word subroutine_1
   .word subroutine_2
   .word subroutine_3
return_here:
   ; continue your program
   ; ...

subroutine_1:
   ; do something 1
   jmp return_here

subroutine_2:
   ; do something 2
   jmp return_here

subroutine_3:
   ; do something 3
   jmp return_here









; this is used for volume scaling
; modulation depth is assumed to be indexed by register Y
; value to be scaled is assumed to be in register A
; result is returned in register A
; volume is moddepth
; moddepth has the format  %0LLL0HHH
; where %HHHH is the number of rightshifts to be applied to the volume signal
; and %LLL is the number of the sub-level
.macro VOLUME_SCALE5_8 moddepth
    ; initialize zero page 8 bit value
    sta mzpwb   ; only low byte is used  (3 cycles) (except for the very end)

    ; do %0HHH rightshifts (highest bit is discarded, because 7 rightshifts is maximum)
    ; TODO: check highest bit first ... (if that gives us any advantage)
    .local @endH
    .local @loopH
    .local @skipH2
    lda moddepth, y
    and #%00000100
    beq @skipH2 ; or skip this part if it's clear
    lda mzpwb
    lsr
    lsr
    lsr
    lsr
    sta mzpwb
@skipH2:
    lda moddepth, y
    and #%00000011
    bne :+          ; if no bit is set, we are done
    jmp @endH
:   phx ; if we got here, we've got a nonzero number of rightshifts to be done in register A
    tax
    lda mzpwb
@loopH:
    lsr
    dex
    bne @loopH
    plx
    sta mzpwb
    ; worst case: 7 rightshifts, 66 cycles  (naive approach without bit 2 checking would be 72 ... almost not worth it to check it separately)
    ; complex approach
    ; cycle counts for all 8 cases: 7->66, 6->59, 5->52, 4->34, 3->51, 2->44, 1->37, 0->23  Average: 46
    ; naive approach
    ; cycle counts for all 8 cases: 7->72, 6->55, 5->48, 4->40, 3->34, 2->27, 1->20, 0->14  Average: 39
    ; and since bigger modulations are more often used, the naive approach is better.
@endH:

    ; do sublevel scaling
    .local @endL
    .local @tableL
    .local @sublevel_1
    .local @sublevel_2
    .local @sublevel_3
    .local @sublevel_4
    ; select subroutine
    lda moddepth, y
    and #%01110000
    beq :+
    lsr
    lsr
    lsr
    tax
    jmp (@tableL-2, x)  ; if x=0, nothing has to be done. if x=2,4,6 or 8, jump to respective subroutine --- 22 cycles
:   lda mzpwb
    jmp @endL
    ; 24 cycles
@tableL:
    .word @sublevel_1
    .word @sublevel_2
    .word @sublevel_3
    .word @sublevel_4
@sublevel_1:
    ; 2^(1/5) ~= %1.001
    lda mzpwb
    lsr
    lsr
    lsr
    clc
    adc mzpwb
    jmp @endL  ; 17 cycles
@sublevel_2:
    ; 2^(2/5) ~= %1.01
    ; refer to @sublevel_1 for code commentary
    lda mzpwb
    lsr
    lsr
    clc
    adc mzpwb
    jmp @endL  ; 15 cycles
@sublevel_3:
    ; 2^(3/5) ~= %1.1
    lda mzpwb
    lsr
    clc
    adc mzpwb
    jmp @endL  ; 13 cycles
@sublevel_4:
    ; 2^(4/5) ~= %1.11
    lda mzpwb
    lsr
    sta mzpwb+1 ; save intermediate
    lsr
    clc
    adc mzpwb+1 ; no clc after this ... if we get a carry, result is broken anyway
    adc mzpwb   ; 18 cycles
@endL:
    ; worst case L: 40 cycles.
    ; average: 4->40, 3->35, 2->37, 1->39, 0->15  Average: 33
    ; worst case overall: 112 cycles (with naive approach)
    ; average overall: 72 (with naive approach)

    ; result is in register A
.endmacro






; This is used for modulation of the parameters that are only 6 bits wide,
; namely volume and pulse width.
; modulation depth is assumed to be indexed by register Y
; modulation source is assumed to be in register A (and all flags from loading of A)
; result is returned in register A
; moddepth has the format  %0LLL0HHH
; where %HHH is the number of rightshifts to be applied to the volume signal
; and %LLL is the number of the sub-level
.macro SCALE5_6 moddepth
    ; with this sequence, we do several tasks at once:
    ; We extract the sign from the modulation source and store it in mzpbf
    ; We truncate the sign from the modulation source
    ; and right shift it effectively once, because the amplitude of any modulation source is too high anyway
    stz mzpbf
    asl         ; push sign out
    rol mzpbf   ; push sign into variable
    lsr
    lsr
    ; initialize zero page 8 bit value
    sta mzpwb   ; only low byte is used

    ; do %0HHH rightshifts (highest bit is discarded, because 7 rightshifts is maximum)
    ; TODO: check highest bit first ... (if that gives us any advantage)
    .local @endH
    .local @loopH
    .local @skipH2
    ; check bit 2, and do 4 RORs if it's set
    lda moddepth, y
    and #%00000100
    beq @skipH2 ; or skip this part if it's clear
    lda mzpwb
    lsr
    lsr
    lsr
    lsr
    sta mzpwb
@skipH2:
    lda moddepth, y
    and #%00000011
    bne :+          ; if no bit is set, we are done
    jmp @endH
:   phx ; if we got here, we've got a nonzero number of rightshifts to be done in register A
    tax
    lda mzpwb
@loopH:
    lsr
    dex
    bne @loopH
    plx
    sta mzpwb   ; worst case: 7 rightshifts, makes 43 + 3*7 = 64 cycles (72 if we just loop naively ... almost not worth it)
@endH:

    ; do sublevel scaling
    .local @endL
    .local @tableL
    .local @sublevel_1
    .local @sublevel_2
    .local @sublevel_3
    .local @sublevel_4
    ; select subroutine
    lda moddepth, y
    and #%01110000
    beq :+
    lsr
    lsr
    lsr
    tax
    jmp (@tableL-2, x)  ; if x=0, nothing has to be done. if x=2,4,6 or 8, jump to respective subroutine
:   lda mzpwb
    jmp @endL
    ; 22 cycles
@tableL:
    .word @sublevel_1
    .word @sublevel_2
    .word @sublevel_3
    .word @sublevel_4
@sublevel_1:
    ; 2^(1/5) ~= %1.001
    lda mzpwb
    lsr
    lsr
    lsr
    adc mzpwb
    jmp @endL  ; 15 cycles
@sublevel_2:
    ; 2^(2/5) ~= %1.01
    ; refer to @sublevel_1 for code commentary
    lda mzpwb
    lsr
    lsr
    adc mzpwb
    jmp @endL  ; 13 cycles
@sublevel_3:
    ; 2^(3/5) ~= %1.1
    lda mzpwb
    lsr
    clc
    adc mzpwb
    jmp @endL  ; 13 cycles
@sublevel_4:
    ; 2^(4/5) ~= %1.11
    lda mzpwb
    lsr
    sta mzpwb+1 ; save intermediate
    lsr
    clc
    adc mzpwb+1 ; no clc after this ... if we get a carry, result is broken anyway
    adc mzpwb   ; 22 cycles
@endL:
    ; result is in register A
    sta mzpwb   ; save it

    ; determine overall sign (mod source * mod depth)
    lda moddepth, y
    and #%10000000
    beq :+
    inc mzpbf
:   ; now if lowest bit of mzpbf is even, sign is positive and if it's odd, sign is negative

    ; now add/subtract scaling result to modulation destiny, according to sign
    .local @minusS
    .local @endS
    lda mzpbf
    ror
    bcs @minusS
    ; if we're here, sign is positive
    lda mzpwb
    bra @endS
@minusS:
    ; if we're here, sign is negative
    lda mzpwb
    eor #%11111111
    inc
@endS:


.endmacro