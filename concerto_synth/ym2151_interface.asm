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


; Operator order
; **************
; One of those annoying things of the YM2151: for the key-on command, the bits are in the order M1, C1, M2, C2,
; But in the address space, the operators are ordered M1, M2, C1, C2.
; WHY???
; Anyway, we store stuff in the order as the key-on flags: M1, C1, M2, C2,
; That is:
;   operator 1 = Modulator 1
;   operator 2 = Carrier 1
;   operator 3 = Modulator 2
;   operator 4 = Carrier 2
; This is nicer for editing, because then, modulation is more often routed into adjacent operators.
; Therefore, when writing stuff to the YM2151, we need to swap C1 and M2.
; For that purpose, we have a lookup table for writing address increments (backwards!!):
operator_stride:
   .byte (2*N_FM_VOICES), (256-N_FM_VOICES), (2*N_FM_VOICES)



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


; prevent timbres already loaded onto the YM2151 from being reused, e.g. after a timbre has been modified.
invalidate_fm_timbres:
   ; override all timbres with invalid timbre
   ldx #(N_FM_VOICES-1)
@loop_fm_voices:
   lda #N_TIMBRES ; invalid timbre number ... enforce loading onto the YM2151 (invalid timbre won't get reused)
   sta FMmap::timbremap, x
   dex
   bpl @loop_fm_voices
   rts


; Load an FM timbre onto the YM2151.
; Expects voice index in A
; Expects note_timbre and note_channel to be set accordingly.
load_fm_timbre:
   operator_counter = mzpbb
   lfmt_op_en = mzpbc
   pha
   ldx note_timbre

   ; General parameters
   ; set RL_FL_CON
   lda timbres::Timbre::fm_general::fl, x
   asl
   asl
   asl
   ora timbres::Timbre::fm_general::con, x ; set "Connection" bits
   ora timbres::Timbre::fm_general::lr, x ; set LR bits
   tay
   pla
   clc
   adc #YM_RL_FL_CON
   jsr write_ym2151
   ; PMS_AMS
   ; (TODO)

   ; Operator parameters
   ; We use a "running address register". To avoid adding the voice offset
   ; to an absolute address like YM_RL_FL_CON again and again,
   ; we simply add the differences between addresses.
   ; The running address is usually kept at the stack for easy access.
   adc #(YM_DT1_MUL-YM_RL_FL_CON)
   pha ; push running address
   lda #4
   sta operator_counter
   ; Load operator enabled register
   lda timbres::Timbre::fm_general::op_en, x
   ; Data offset
; expects the op_en register to be loaded in A (right shifted by how many operators we have already done)
@loop:
   ; Check if operator is enabled, only then copy parameters
   lsr
   sta lfmt_op_en
   bcs @operator_enabled
@operator_disabled:
   pla
   jmp @advance_loop
@operator_enabled:
   ; ** DT1_MUL
   ; value
   lda timbres::Timbre::operators::dt1, x
   asl
   asl
   asl
   asl
   ora timbres::Timbre::operators::mul, x
   tay
   ; address
   pla
   pha
   jsr write_ym2151


   ; ** TL
   ; Total level can be skipped since it is set on note trigger.

   ; ** KS_AR
   ; value
   lda timbres::Timbre::operators::ks, x
   clc
   ror
   ror
   ror
   adc timbres::Timbre::operators::ar, x
   tay
   ; address
   pla
   clc
   adc #(YM_KS_AR-YM_DT1_MUL)
   pha
   jsr write_ym2151

   ; ** AMS-EN_D1R (5 bits D1R)
   ; value
   ldy timbres::Timbre::operators::d1r, x
   ; address
   pla
   clc
   adc #(YM_AMS_EN_D1R-YM_KS_AR)
   pha
   jsr write_ym2151

   ; ** DT2_D2R
   ; value
   lda timbres::Timbre::operators::dt2, x
   clc
   ror
   ror
   ror
   ora timbres::Timbre::operators::d2r, x
   tay
   ; address
   pla
   clc
   adc #(YM_DT2_D2R-YM_AMS_EN_D1R)
   pha
   jsr write_ym2151

   ; ** D1L_RR
   ; value
   lda timbres::Timbre::operators::d1l, x
   asl
   asl
   asl
   asl
   ora timbres::Timbre::operators::rr, x
   tay
   ; address
   pla
   clc
   adc #(YM_D1L_RR-YM_DT2_D2R)
   pha
   jsr write_ym2151

@advance_running_address:
   ; revert running address back to "start"
   pla
   sec
   sbc #(YM_D1L_RR-YM_DT1_MUL)
@advance_loop:
   ; expecting running write address in A
   ; advance running write address by multiple of 8 to get to the next operator
   ldy operator_counter
   clc
   adc operator_stride-2, y ; -1 because operator_counter goes from 1-4, another -1 since 4 operators = 3 steps in between --> one less stride needed
   pha
   ; advance read address offset
   txa
   clc
   adc #N_TIMBRES
   tax
   lda lfmt_op_en
   dec operator_counter
   bpl @loop

   ; pop running address
   pla
   rts




; Triggers a note on the YM2151.
; Expects note_timbre, note_channel, note_pitch and note_volume to be set accordingly.
; This function is called from within retrigger_note
trigger_fm_note:
   tfm_operator_counter = mzpbb
   tfm_op_en = mzpbc
   ; (re)trigger FM voice (TBD later if it's done here)
   ldx note_channel

   ; key off
   lda #YM_KON
   ldy Voice::fm_voice_map, x
   jsr write_ym2151

   ; set operator volumes
   ; *********************
   ; This is annoyingly complicated ... we basically need to replicate the load timbre loop just for this
   ; TODO: velocity sensitivity!
   lda #YM_TL
   clc
   adc Voice::fm_voice_map, x
   pha ; push running address
   lda #4
   sta tfm_operator_counter
   ; Load operator enabled register
   ldx note_timbre
   lda timbres::Timbre::fm_general::op_en, x
; expects the op_en register to be loaded in A (right shifted by how many operators we have already done)
@vol_loop:
   ; Check if operator is enabled, only then copy parameters
   lsr
   sta tfm_op_en
   bcs @operator_enabled
@operator_disabled:
   pla
   bra @advance_loop
@operator_enabled:
   ; TOTAL LEVEL
   ; value
   lda timbres::Timbre::operators::level, x
   ldy timbres::Timbre::operators::vol_sens, x
   beq :+
   sec
   sbc note_volume
   adc #63 ; 63 - 1 for secretly added one and -1 for carry
:  tay
   ; address
   pla
   jsr write_ym2151
@advance_loop:
   ; expecting running write address in A
   ; advance running write address by multiple of 8 to get to the next operator
   ldy operator_counter
   clc
   adc operator_stride-2, y ; -1 because operator_counter goes from 1-4, another -1 since 4 operators = 3 steps in between --> one less stride needed
   pha
   ; advance read address offset
   txa
   clc
   adc #N_TIMBRES
   tax
   lda tfm_op_en
   dec tfm_operator_counter
   bpl @vol_loop
   ; pop running address
   pla

   ; Pitch is done inside synth tick.

   ; load trigger
   ; ************
   ldx note_channel
   lda #1
   sta Voice::fm::trigger_loaded, x

   rts
