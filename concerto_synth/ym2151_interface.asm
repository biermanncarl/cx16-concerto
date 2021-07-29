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

; This file contains various routines that help interfacing with the
; YM2151 FM sound chip.
; Much of this file is concerned with loading data efficiently over the
; limited bandwidth onto this chip.


; naive writing procedure to the YM2151
; potentially burns a lot of cycles in the waiting loop
; A: register
; Y: data
write_ym2151:
:  bit YM_data
   bmi :-  ; wait until ready flag is set
   sta YM_reg
   sty YM_data
   rts


; Load an FM timbre onto the YM2151.
; Expects note_timbre and note_channel to be set accordingly.
load_fm_timbre:
   rts


; expects note pitch in A
set_fm_note:
   keycode = mzpbb
   ; set key code (convert it from note pitch)
   ; Do this naively by a subtract loop.
   ldy #0
   ; adjust pitch to make up for YM2151 running at a different frequency than recommended
   dea
   dea
   dea
   sec
@sub_loop:
   iny
   sbc #12
   bcs @sub_loop
   adc #12
   ; semitone is in A. Now translate it to stupid YM2151 format
   tax
   lda semitones_ym2151, x
   sta keycode
   ldx note_channel
   dey
   ; octave is in Y
   tya
   clc
   asl
   asl
   asl
   asl
   clc
   adc keycode ; carry should be clear from previous operation, where bits were pushed out that are supposed to be zero anyway.
   tay
   lda #YM_KC
   clc
   adc Voice::fm_voice_map, x
   jsr write_ym2151
   rts



; Triggers a note on the YM2151.
; Expects note_timbre, note_channel, note_pitch and note_volume to be set accordingly.
; This function is called from within retrigger_note
trigger_fm_note:
   ; (re)trigger FM voice (TBD later if it's done here)
   ldx note_channel
   ; set connection
   lda #YM_RL_FL_CON
   clc
   adc Voice::fm_voice_map, x
   ldy #%11000111 ; L+R enabled, all parallel connection
   jsr write_ym2151
   ; set max volume
   lda #YM_TL
   clc
   adc Voice::fm_voice_map, x
   ldy #0
   jsr write_ym2151
   ; key off
   lda #YM_KON
   ldy Voice::fm_voice_map, x
   jsr write_ym2151
   ; note pitch
   lda note_pitch
   jsr set_fm_note
   ; attack rate (and key scaling)
   lda #YM_KS_AR
   clc
   adc Voice::fm_voice_map, x
   ldy #63
   jsr write_ym2151
   ; decay rate 1 (+ amplitude modulation sensitivity)
   lda #YM_AMS_EN_D1R
   clc
   adc Voice::fm_voice_map, x
   ldy #6
   jsr write_ym2151
   ; decay level 1 & release rate
   lda #YM_D1L_RR
   clc
   adc Voice::fm_voice_map, x
   ldy #%11110011
   jsr write_ym2151
   ; key on
   ldy note_timbre
   lda timbres::Timbre::fm_general::op_en, y
   clc
   rol
   rol
   rol
   adc Voice::fm_voice_map, x
   tay
   lda #YM_KON
   jsr write_ym2151

   rts