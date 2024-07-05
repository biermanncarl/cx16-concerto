; Copyright 2021-2022 Carl Georg Biermann


; This file manages the synth patches.
; The patch data will be read by the synth engine as well as the GUI.

; Disk save and load commands for individual synth patches are found in this file.

; The patch data is organized in arrays. Each successive byte belongs to a different patch.
; For example, the portamento rate is a field of N_TIMBRES bytes (32 the last time I checked).
;    rate of patch 0
;    rate of patch 1
;    rate of patch 2
;    ...
;    rate of patch 31
; Then, the next field:
;    retrigger setting patch 0
;    retrigger setting patch 1
;    ...
; This even holds true for arrays inside a patch, e.g. the attack rate for all envelopes:
;    attack rate Low byte env 1 patch 0
;    attack rate Low byte env 1 patch 1
;    attack rate Low byte env 1 patch 2
;    ...
;    attack rate Low byte env 2 patch 0
;    attack rate Low byte env 2 patch 1
;    attack rate Low byte env 2 patch 2
;    ...

; This is for more efficient accessing of the data.
; Timbre selection needs to be quick for arbitrary access.
; The individual envelopes and oscillators are only parsed from start to finish.
; To access all three envelope settings of a timbre, one starts by setting .X to the
; timbre index, giving the offset of envelope 1.
; Then, by adding N_TIMBRES to .X, we get the offset of envelope 2, and if we do it again,
; we get the offset of envelope 3 of that same patch.
; That way, we can avoid multiplications to find the correct indices.


.scope timbres

timbre_pointer = mzpwg


.struct TimbreDataStruct
   n_oscs  .res N_TIMBRES         ; how many oscillators are used
   n_envs  .res N_TIMBRES         ; how many envelopes are used
   n_lfos  .res N_TIMBRES
   porta   .res N_TIMBRES         ; portamento on/off
   porta_r .res N_TIMBRES         ; portamento rate
   retrig  .res N_TIMBRES         ; when monophonic, will envelopes be retriggered? (could be combined with mono variable)
   vibrato .res N_TIMBRES         ; vibrato amount (a scale5 value but only positive. negative value means inactive)

   ; envelope rates (not times!)
      env_attackL  .res N_TIMBRES * MAX_ENVS_PER_VOICE
      env_attackH  .res N_TIMBRES * MAX_ENVS_PER_VOICE
      env_decayL   .res N_TIMBRES * MAX_ENVS_PER_VOICE
      env_decayH   .res N_TIMBRES * MAX_ENVS_PER_VOICE
      env_sustain  .res N_TIMBRES * MAX_ENVS_PER_VOICE
      env_releaseL .res N_TIMBRES * MAX_ENVS_PER_VOICE
      env_releaseH .res N_TIMBRES * MAX_ENVS_PER_VOICE

   ; lfo stuff
      lfo_rateH   .res N_TIMBRES * MAX_LFOS_PER_VOICE
      lfo_rateL   .res N_TIMBRES * MAX_LFOS_PER_VOICE
      lfo_wave    .res N_TIMBRES * MAX_LFOS_PER_VOICE   ; waveform select: triangle, square, ramp up, ramp down, noise (S'n'H)
      lfo_retrig  .res N_TIMBRES * MAX_LFOS_PER_VOICE   ; retrigger
      lfo_offs    .res N_TIMBRES * MAX_LFOS_PER_VOICE   ; offset (high byte only, or seed for SnH)

   ; oscillators
   ; modulation sources are inactive if negative (bit 7 active)
   ; Except amp_sel: it is assumed to be always active.
   ; modulation depth is assumed to be negative if _depH is negative (bit 7 active)
      ; pitch stuff
      osc_pitch            .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; offset (or absolute if no tracking)
      osc_fine             .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; unsigned (only up)
      osc_track            .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; keyboard tracking on/off (also affects portamento on/off)
      osc_pitch_mod_sel1   .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; selects source for pitch modulation (bit 7 on means none)
      osc_pitch_mod_dep1   .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; pitch modulation depth (Scale5)
      osc_pitch_mod_sel2   .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; selects source for pitch modulation (bit 7 on means none)
      osc_pitch_mod_dep2   .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; pitch modulation depth (Scale5)

      ; volume stuff
      osc_lrmid            .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; 0, 64, 128 or 192 for mute, L, R or center
      osc_volume           .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; oscillator volume
      osc_amp_sel          .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; amplifier select: gate, or one of the envelopes
      osc_vol_mod_sel      .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; volume modulation source
      osc_vol_mod_dep      .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; volume modulation depth

      ; waveform stuff
      osc_waveform         .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; including pulse width (PSG format)
      osc_pulse            .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; pulse width
      osc_pwm_sel          .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; selects source to modulate pulse width
      osc_pwm_dep          .res N_TIMBRES * MAX_OSCS_PER_VOICE    ; pwm modulation depth


   ; FM general stuff
      fm_con              .res N_TIMBRES   ; the connection algorithm of the timbre (3 bits)
      fm_fl               .res N_TIMBRES   ; feedback level (3 bits)
      fm_op_en            .res N_TIMBRES   ; operator enable (4 bits) (also acts as FM enable)
      fm_lr               .res N_TIMBRES   ; Channels L/R (2 bits) (!!! stored in bits 6 and 7)
      ; pitch related
      fm_pitch            .res N_TIMBRES    ; offset (or absolute if no tracking)
      fm_fine             .res N_TIMBRES    ; unsigned (only up)
      fm_track            .res N_TIMBRES    ; keyboard tracking on/off (also affects portamento on/off)
      fm_pitch_mod_sel    .res N_TIMBRES    ; selects source for pitch modulation (bit 7 on means none)
      fm_pitch_mod_dep    .res N_TIMBRES    ; pitch modulation depth (Scale5)
   

   ; FM Operators
      op_level            .res N_TIMBRES * N_OPERATORS  ; volume (!!! attenuation: higher level means lower output volume) (7 bits)
      op_vol_sens         .res N_TIMBRES * N_OPERATORS  ; volume sensitivity on/off
      ; pitch related
      op_mul              .res N_TIMBRES * N_OPERATORS  ; multiplier for the frequency (4 bits)
      op_dt1              .res N_TIMBRES * N_OPERATORS  ; fine detune (3 bits)
      op_dt2              .res N_TIMBRES * N_OPERATORS  ; coarse detune (2 bits)
      ; envelope
      op_ar               .res N_TIMBRES * N_OPERATORS  ; attack rate (5 bits)
      op_d1r              .res N_TIMBRES * N_OPERATORS  ; decay rate 1 (classical decay)  (5 bits)
      op_d1l              .res N_TIMBRES * N_OPERATORS  ; decay level (or sustain level)  (4 bits)
      op_d2r              .res N_TIMBRES * N_OPERATORS  ; decay rate 2 (0 for sustain)    (5 bits)
      op_rr               .res N_TIMBRES * N_OPERATORS  ; release rate    (4 bits)
      op_ks               .res N_TIMBRES * N_OPERATORS  ; key scaling    (2 bits)
.endstruct

; allocate the actual memory
timbre_data_start:
.ifdef concerto_use_timbres_from_file
   ; discard magic sequence at the start of the file (first 4 bytes)
   .incbin CONCERTO_TIMBRES_PATH, 4, .sizeof(TimbreDataStruct)
.else
   .res .sizeof(TimbreDataStruct)
.endif

; communicate the size of the timbre data to other parts of the code
; the size of the whole timbre bank
timbre_data_size = .sizeof(TimbreDataStruct)
.export timbre_data_size  ; 5888 bytes currently
; the number of bytes per timbre
timbre_data_count = timbre_data_size / N_TIMBRES ; 184 currently
.export timbre_data_count

; define the labels to access timbre data
.scope Timbre
   n_oscs  = timbre_data_start + TimbreDataStruct::n_oscs
   n_envs  = timbre_data_start + TimbreDataStruct::n_envs
   n_lfos  = timbre_data_start + TimbreDataStruct::n_lfos
   porta   = timbre_data_start + TimbreDataStruct::porta
   porta_r = timbre_data_start + TimbreDataStruct::porta_r
   retrig  = timbre_data_start + TimbreDataStruct::retrig
   vibrato = timbre_data_start + TimbreDataStruct::vibrato

   .scope env
      attackL = timbre_data_start + TimbreDataStruct::env_attackL
      attackH = timbre_data_start + TimbreDataStruct::env_attackH
      decayL = timbre_data_start + TimbreDataStruct::env_decayL
      decayH = timbre_data_start + TimbreDataStruct::env_decayH
      sustain = timbre_data_start + TimbreDataStruct::env_sustain
      releaseL = timbre_data_start + TimbreDataStruct::env_releaseL
      releaseH = timbre_data_start + TimbreDataStruct::env_releaseH
   .endscope

   .scope lfo
      rateH = timbre_data_start + TimbreDataStruct::lfo_rateH
      rateL = timbre_data_start + TimbreDataStruct::lfo_rateL
      wave = timbre_data_start + TimbreDataStruct::lfo_wave
      retrig = timbre_data_start + TimbreDataStruct::lfo_retrig
      offs = timbre_data_start + TimbreDataStruct::lfo_offs
   .endscope

   .scope osc
      pitch = timbre_data_start + TimbreDataStruct::osc_pitch
      fine = timbre_data_start + TimbreDataStruct::osc_fine
      track = timbre_data_start + TimbreDataStruct::osc_track
      pitch_mod_sel1 = timbre_data_start + TimbreDataStruct::osc_pitch_mod_sel1
      pitch_mod_dep1 = timbre_data_start + TimbreDataStruct::osc_pitch_mod_dep1
      pitch_mod_sel2 = timbre_data_start + TimbreDataStruct::osc_pitch_mod_sel2
      pitch_mod_dep2 = timbre_data_start + TimbreDataStruct::osc_pitch_mod_dep2

      lrmid = timbre_data_start + TimbreDataStruct::osc_lrmid
      volume = timbre_data_start + TimbreDataStruct::osc_volume
      amp_sel = timbre_data_start + TimbreDataStruct::osc_amp_sel
      vol_mod_sel = timbre_data_start + TimbreDataStruct::osc_vol_mod_sel
      vol_mod_dep = timbre_data_start + TimbreDataStruct::osc_vol_mod_dep

      waveform = timbre_data_start + TimbreDataStruct::osc_waveform
      pulse = timbre_data_start + TimbreDataStruct::osc_pulse
      pwm_sel = timbre_data_start + TimbreDataStruct::osc_pwm_sel
      pwm_dep = timbre_data_start + TimbreDataStruct::osc_pwm_dep
   .endscope

   .scope fm_general
      con = timbre_data_start + TimbreDataStruct::fm_con
      fl = timbre_data_start + TimbreDataStruct::fm_fl
      op_en = timbre_data_start + TimbreDataStruct::fm_op_en
      lr = timbre_data_start + TimbreDataStruct::fm_lr

      pitch = timbre_data_start + TimbreDataStruct::fm_pitch
      fine = timbre_data_start + TimbreDataStruct::fm_fine
      track = timbre_data_start + TimbreDataStruct::fm_track
      pitch_mod_sel = timbre_data_start + TimbreDataStruct::fm_pitch_mod_sel
      pitch_mod_dep = timbre_data_start + TimbreDataStruct::fm_pitch_mod_dep
   .endscope

   .scope operators
      level = timbre_data_start + TimbreDataStruct::op_level
      vol_sens = timbre_data_start + TimbreDataStruct::op_vol_sens

      mul = timbre_data_start + TimbreDataStruct::op_mul
      dt1 = timbre_data_start + TimbreDataStruct::op_dt1
      dt2 = timbre_data_start + TimbreDataStruct::op_dt2

      ar = timbre_data_start + TimbreDataStruct::op_ar
      d1r = timbre_data_start + TimbreDataStruct::op_d1r
      d1l = timbre_data_start + TimbreDataStruct::op_d1l
      d2r = timbre_data_start + TimbreDataStruct::op_d2r
      rr = timbre_data_start + TimbreDataStruct::op_rr
      ks = timbre_data_start + TimbreDataStruct::op_ks
   .endscope
.endscope



.scope detail
   copying:
      .byte 128 ; which timbre to copy. negative is none
   pasting:
      .byte 0   ; where to paste

   ; advances the timbre_pointer by N_TIMBRES, i.e. from one parameter to the next
   .proc advance_timbre_pointer
      lda timbre_pointer
      clc
      adc #N_TIMBRES
      sta timbre_pointer
      bcc :+
      inc timbre_pointer+1
   :  rts
   .endproc

   ; Sets up the loop over single instrument data
   .proc prepareSingleInstrumentTransfer
      clc
      adc #(<timbre_data_start)
      sta timbre_pointer
      lda #(>timbre_data_start)
      adc #0
      sta timbre_pointer+1
      ldy #timbre_data_count
      rts
   .endproc
.endscope


; Emits instrument data for a single instrument via CHROUT to the currently active file/stream.
; .A: instrument number
.proc saveInstrument
   jsr detail::prepareSingleInstrumentTransfer
@loop:
   lda (timbre_pointer)
   jsr CHROUT
   jsr detail::advance_timbre_pointer
   dey
   bne @loop
   rts
.endproc


; Consumes instrument data for a single instrument via CHRIN from the currently active file/stream.
; .A: instrument number
.proc loadInstrument
   jsr detail::prepareSingleInstrumentTransfer
@loop:
   jsr CHRIN
   sta (timbre_pointer)
   jsr detail::advance_timbre_pointer
   dey
   bne @loop
   rts
.endproc



; loads the default sound
; at the same time, this function IS the definition of the default patch.
; X: timbre number, is preserved.
; does not preserve A, Y
load_default_timbre:
   stx detail::pasting
   ; do all "direct" values first
   lda #1
   sta Timbre::n_oscs, x
   sta Timbre::n_envs, x
   sta Timbre::retrig, x
   sta Timbre::n_lfos, x
   stz Timbre::porta, x
   lda #20
   sta Timbre::porta_r, x
   lda #$FF
   sta Timbre::vibrato, x
   ; LFO
   lda #13
   sta Timbre::lfo::rateH, x
   stz Timbre::lfo::rateL, x
   stz Timbre::lfo::wave, x
   stz Timbre::lfo::offs, x
   lda #1
   sta Timbre::lfo::retrig, x
   ; FM general
   sta Timbre::fm_general::track, x
   lda #7
   sta Timbre::fm_general::con, x
   lda #15
   sta Timbre::fm_general::op_en, x
   stz Timbre::fm_general::fl, x
   lda #%11000000
   sta Timbre::fm_general::lr, x
   ; select no modulation source
   lda #128
   sta Timbre::fm_general::pitch_mod_sel, x
   ; select minimal modulation depth
   lda #15
   sta Timbre::fm_general::pitch_mod_dep, x
   ; envelopes
   ldy #MAX_ENVS_PER_VOICE
@loop_envs:
   stz Timbre::env::attackL, x
   stz Timbre::env::decayL, x
   stz Timbre::env::releaseL, x
   lda #127
   sta Timbre::env::attackH, x
   lda #90
   sta Timbre::env::sustain, x
   lda #2
   sta Timbre::env::decayH, x
   sta Timbre::env::releaseH, x
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_envs
   ; oscillators
   ldx detail::pasting
   ldy #MAX_OSCS_PER_VOICE
@loop_oscs:
   stz Timbre::osc::pitch, x
   stz Timbre::osc::fine, x
   stz Timbre::osc::amp_sel
   stz Timbre::osc::waveform
   lda #1
   sta Timbre::osc::track, x
   lda #192
   sta Timbre::osc::lrmid, x
   lda #50
   sta Timbre::osc::volume, x
   lda #40
   sta Timbre::osc::pulse, x
   ; select no modulation source
   lda #128
   sta Timbre::osc::pitch_mod_sel1, x
   sta Timbre::osc::pitch_mod_sel2, x
   sta Timbre::osc::vol_mod_sel, x
   sta Timbre::osc::pwm_sel, x
   ; select minimal modulation depths
   lda #15
   sta Timbre::osc::pitch_mod_dep1, x
   sta Timbre::osc::pitch_mod_dep2, x
   stz Timbre::osc::vol_mod_dep, x
   stz Timbre::osc::pwm_dep, x
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_oscs
   ; FM operators
   ldx detail::pasting
   ldy #N_OPERATORS
@loop_operators:
   stz Timbre::operators::mul, x
   stz Timbre::operators::dt1, x
   stz Timbre::operators::dt2, x
   stz Timbre::operators::ks, x
   lda #31
   sta Timbre::operators::ar, x
   lda #12
   sta Timbre::operators::d1r, x
   lda #4
   sta Timbre::operators::d2r, x
   lda #15
   sta Timbre::operators::d1l, x
   sta Timbre::operators::rr, x
   lda #22
   sta Timbre::operators::level, x
   lda #1
   sta Timbre::operators::vol_sens, x
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_operators
   ldx detail::pasting
   rts


; initializes all timbres to the default timbre
init_timbres:
   ldx #N_TIMBRES
@loop_timbres:
   dex
   jsr load_default_timbre
   cpx #0
   bne @loop_timbres
   rts

; sets the timbre pointer to the start of the timbre data
initialize_timbre_pointer:
   lda #<timbre_data_start
   sta timbre_pointer
   lda #>timbre_data_start
   sta timbre_pointer+1
   rts

; copy_paste. copies the timbre stored in variable "copying" to the one given in Y
; if the value of "copying" is negative, nothing is done.
; copy timbre "copying" to timbre "Y"
copy_paste:
   lda detail::copying
   bpl :+
   rts    ; exit if no preset is being copied
:  stx detail::pasting
   ldx #timbre_data_count
   jsr initialize_timbre_pointer
@loop:
   ldy detail::copying
   lda (timbre_pointer), y
   ldy detail::pasting
   sta (timbre_pointer), y
   jsr detail::advance_timbre_pointer
   dex
   bne @loop
   rts

; dumps all timbre data to CHROUT. can be used to write to an already opened file
dump_to_chrout:
   ; write timbre data
   jsr initialize_timbre_pointer
   ldx #timbre_data_count
@loop_parameters:
   ldy #0
@loop_timbres:
   lda (timbre_pointer), y
   jsr CHROUT ; leaves X and Y untouched
   iny
   cpy #N_TIMBRES
   beq @goto_next_parameter
   bra @loop_timbres
@goto_next_parameter:
   jsr detail::advance_timbre_pointer
   dex
   bne @loop_parameters
   rts

; restores all timbres from a data stream from CHRIN (which was previously dumped via dump_to_chrout)
; can be used to read from an already opened file
restore_from_chrin:
   ; read timbre data
   jsr initialize_timbre_pointer
   ldx #timbre_data_count
@loop_parameters:
   ldy #0
@loop_timbres:
   phy
   jsr CHRIN ; leaves X untouched, uses Y (as far as I know)
   ply
   sta (timbre_pointer), y
   iny
   cpy #N_TIMBRES
   beq @goto_next_parameter
   bra @loop_timbres
@goto_next_parameter:
   jsr detail::advance_timbre_pointer
   dex
   bne @loop_parameters
   lda #1 ; success
   rts
@abort:
   lda #0 ; error
   rts


.endscope