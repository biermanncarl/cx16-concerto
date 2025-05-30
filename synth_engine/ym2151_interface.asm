; Copyright 2021-2025, Carl Georg Biermann


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


; Lookup table that converts notes from 0..11 semitones to 0..15 semitones,
; because, for some reason, the YM2151 spreads 12 semitones over the range of 0..15
; Mathematically speaking, one would have to multiply by 4/3 and round down to get the YM2151 note value.
semitones_ym2151:
   .byte 0,1,2,3,5,6,7,9,10,11,13,14



; naive writing procedure to the YM2151
; potentially burns a lot of CPU cycles (up to ~150) in the waiting loop
; A: register
; Y: data
write_ym2151:
:  bit YM_data
   bmi :-  ; wait until ready flag is set
   sta YM_reg
   nop ; short pause to let the YM2151 react before writing to the data register
   nop
   nop
   nop
   nop
   nop
   sty YM_data
.ifdef ::concerto_enable_zsound_recording
   pha
   phx
   phy
   phy ; essentially copy .Y to .X via the stack
   plx
   jsr zsm_recording::fm_write
   ply
   plx
   pla
.endif
   rts


; prevent instruments already loaded onto the YM2151 from being reused, e.g. after a instrument has been modified.
invalidate_fm_instruments:
   ; override all instruments with invalid instrument
   ldx #(N_FM_VOICES-1)
@loop_fm_voices:
   lda #N_INSTRUMENTS ; invalid instrument number ... enforce loading onto the YM2151 (invalid instrument won't get reused)
   sta FMmap::instrumentmap, x
   dex
   bpl @loop_fm_voices
   ; invalidate FM LFO parameters
   lda #255
   sta last_fm_lfo_instrument
   rts


; Load an FM instrument onto the YM2151.
; Expects voice index in A
; Expects note_instrument and note_voice to be set accordingly.
.proc load_fm_instrument
   lfmt_operator_counter = mzpbd
   lfmt_op_en = mzpbc
   pha
   ldx note_instrument

   ; LFO gets updated independently on note-on

   ; General parameters
   ; set RL_FL_CON
   lda instruments::Instrument::fm_general::fl, x
   asl
   asl
   asl
   ora instruments::Instrument::fm_general::con, x ; set "Connection" bits
   ora instruments::Instrument::fm_general::lr, x ; set LR bits
   tay
   pla
   clc
   adc #YM_RL_FL_CON
   jsr write_ym2151
   ; PMS_AMS
   clc
   adc #(YM_PMS_AMS-YM_RL_FL_CON)
   pha
   lda instruments::Instrument::fm_general::lfo_pitch_sens, x
   asl
   asl
   asl
   asl
   ora instruments::Instrument::fm_general::lfo_vol_sens, x
   tay
   pla
   jsr write_ym2151


   ; Operator parameters
   ; We use a "running address register". To avoid adding the voice offset
   ; to an absolute address like with YM_RL_FL_CON above again and again,
   ; we simply add the differences between addresses.
   ; The running address is usually kept at the stack for easy access.
   clc
   adc #(YM_DT1_MUL-YM_PMS_AMS)
   pha ; push running address
   lda #4
   sta lfmt_operator_counter
   ; Load operator enabled register
   lda instruments::Instrument::fm_general::op_en, x
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
   lda instruments::Instrument::operators::dt1, x
   asl
   asl
   asl
   asl
   ora instruments::Instrument::operators::mul, x
   tay
   ; address
   pla
   pha
   jsr write_ym2151


   ; ** TL
   ; Total level can be skipped since it is set on note trigger.

   ; ** KS_AR
   ; value
   lda instruments::Instrument::operators::ks, x
   clc
   ror
   ror
   ror
   adc instruments::Instrument::operators::ar, x
   tay
   ; address
   pla
   clc
   adc #(YM_KS_AR-YM_DT1_MUL)
   pha
   jsr write_ym2151

   ; ** AMS-EN_D1R (5 bits D1R)
   ; value
   lda instruments::Instrument::operators::vol_sens_lfo, x
   lsr
   ror
   ora instruments::Instrument::operators::d1r, x
   tay
   ; address
   pla
   clc
   adc #(YM_AMS_EN_D1R-YM_KS_AR)
   pha
   jsr write_ym2151

   ; ** DT2_D2R
   ; value
   lda instruments::Instrument::operators::dt2, x
   clc
   ror
   ror
   ror
   ora instruments::Instrument::operators::d2r, x
   tay
   ; address
   pla
   clc
   adc #(YM_DT2_D2R-YM_AMS_EN_D1R)
   pha
   jsr write_ym2151

   ; ** D1L_RR
   ; value
   lda instruments::Instrument::operators::d1l, x
   asl
   asl
   asl
   asl
   ora instruments::Instrument::operators::rr, x
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
   ldy lfmt_operator_counter
   clc
   adc operator_stride-2, y ; -1 because lfmt_operator_counter goes from 1-4, another -1 since 4 operators = 3 steps in between --> one less stride needed
   pha
   ; advance read address offset
   txa
   clc
   adc #N_INSTRUMENTS
   tax
   lda lfmt_op_en
   dec lfmt_operator_counter
   bpl @loop

   ; pop running address
   pla
   rts
.endproc


; Load the LFO parameters onto the YM2151.
; Expects instrument id in .X
.proc updateLfo
   ; LFO frequency
   ldy instruments::Instrument::fm_general::lfo_frequency, x
   lda #YM_LFRQ
   jsr write_ym2151
   ; LFO modulation strengths
   ldy instruments::Instrument::fm_general::lfo_vol_mod, x
   lda #YM_PMD_AMD
   jsr write_ym2151
   lda instruments::Instrument::fm_general::lfo_pitch_mod, x
   ora #%10000000
   tay
   lda #YM_PMD_AMD
   jsr write_ym2151
   ; waveform
   ldy instruments::Instrument::fm_general::lfo_waveform, x
   lda #YM_CT_W
   jmp write_ym2151
.endproc


; Sets the volume of an FM voice
; Only the operators that are marked as velocity-sensitive will be affected by
; a change of volume.
; Expects note_instrument and note_voice to be set accordingly.
; The volume is read from the respective voice.
; This function is called when a new note is being triggered, or upon volume updates
; during a note.
set_fm_voice_volume:
   sfmv_operator_counter = mzpbd
   sfmv_op_en = mzpbc
   ; (re)trigger FM voice (TBD later if it's done here)
   ldx note_voice

   ; set operator volumes
   ; *********************
   ; This is annoyingly complicated ... we basically need to replicate the load instrument loop just for this
   lda #YM_TL
   clc
   adc Voice::fm_voice_map, x
   pha ; push running address
   lda #4
   sta sfmv_operator_counter
   ; Load operator enabled register
   ldx note_instrument
   lda instruments::Instrument::fm_general::op_en, x
; expects the op_en register to be loaded in A (right shifted by how many operators we have already done)
@vol_loop:
   ; Check if operator is enabled, only then copy parameters
   lsr
   sta sfmv_op_en
   bcs @operator_enabled
@operator_disabled:
   pla
   bra @advance_in_loop
@operator_enabled:
   ; TOTAL LEVEL
   ; value
   lda instruments::Instrument::operators::level, x
   ldy instruments::Instrument::operators::vol_sens_vel, x
   beq @no_volume_sensitivity
   clc
   adc #64 ; when note volume is minimal, this is how much the level gets reduced
   ldy note_voice
   sec
   sbc voices::Voice::vol::volume, y ; note volume, range 1 to 64
   bpl @no_volume_sensitivity
   ; value is negative ... set it to minimum volume
   lda #127
@no_volume_sensitivity:
   tay
   ; address
   pla
   jsr write_ym2151
@advance_in_loop:
   ; expecting running write address in A
   ; advance running write address by multiple of 8 to get to the next operator
   ldy sfmv_operator_counter
   clc
   adc operator_stride-2, y ; -1 because operator_counter goes from 1 to 4, another -1 since 4 operators = 3 steps in between --> one less stride needed
   pha
   ; advance read address offset
   txa
   clc
   adc #N_INSTRUMENTS
   tax
   lda sfmv_op_en
   dec sfmv_operator_counter
   bpl @vol_loop
   ; pop running address
   pla

   rts
