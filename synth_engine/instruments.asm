; Copyright 2021-2022 Carl Georg Biermann


; This file manages the synth instrumentes.
; The instrument data will be read by the synth engine as well as the GUI.

; Disk save and load commands for individual synth instruments are found in this file.

; The instrument data is organized in arrays. Each successive byte belongs to a different instrument.
; For example, the portamento rate is a field of N_INSTRUMENTS bytes (32 the last time I checked).
;    rate of instrument 0
;    rate of instrument 1
;    rate of instrument 2
;    ...
;    rate of instrument 31
; Then, the next field:
;    retrigger setting instrument 0
;    retrigger setting instrument 1
;    ...
; This even holds true for arrays inside a instrument, e.g. the attack rate for all envelopes:
;    attack rate Low byte env 1 instrument 0
;    attack rate Low byte env 1 instrument 1
;    attack rate Low byte env 1 instrument 2
;    ...
;    attack rate Low byte env 2 instrument 0
;    attack rate Low byte env 2 instrument 1
;    attack rate Low byte env 2 instrument 2
;    ...

; This is for more efficient accessing of the data.
; Instrument selection needs to be quick for arbitrary access.
; The individual envelopes and oscillators are only parsed from start to finish.
; To access all three envelope settings of a instrument, one starts by setting .X to the
; instrument index, giving the offset of envelope 1.
; Then, by adding N_INSTRUMENTS to .X, we get the offset of envelope 2, and if we do it again,
; we get the offset of envelope 3 of that same instrument.
; That way, we can avoid multiplications to find the correct indices.


.scope instruments

instrument_pointer = mzpwg


.struct InstrumentDataStruct
   n_oscs  .res N_INSTRUMENTS         ; how many oscillators are used
   n_envs  .res N_INSTRUMENTS         ; how many envelopes are used
   n_lfos  .res N_INSTRUMENTS
   porta   .res N_INSTRUMENTS         ; portamento on/off
   porta_r .res N_INSTRUMENTS         ; portamento rate
   retrig  .res N_INSTRUMENTS         ; when monophonic, will envelopes be retriggered? (could be combined with mono variable)
   vibrato .res N_INSTRUMENTS         ; vibrato amount (a scale5 value but only positive. negative value means inactive)

   ; envelope rates (not times!)
      env_attackL  .res N_INSTRUMENTS * MAX_ENVS_PER_VOICE
      env_attackH  .res N_INSTRUMENTS * MAX_ENVS_PER_VOICE
      env_decayL   .res N_INSTRUMENTS * MAX_ENVS_PER_VOICE
      env_decayH   .res N_INSTRUMENTS * MAX_ENVS_PER_VOICE
      env_sustain  .res N_INSTRUMENTS * MAX_ENVS_PER_VOICE
      env_releaseL .res N_INSTRUMENTS * MAX_ENVS_PER_VOICE
      env_releaseH .res N_INSTRUMENTS * MAX_ENVS_PER_VOICE

   ; lfo stuff
      lfo_rateH   .res N_INSTRUMENTS * MAX_LFOS_PER_VOICE
      lfo_rateL   .res N_INSTRUMENTS * MAX_LFOS_PER_VOICE
      lfo_wave    .res N_INSTRUMENTS * MAX_LFOS_PER_VOICE   ; waveform select: triangle, square, ramp up, ramp down, noise (S'n'H)
      lfo_retrig  .res N_INSTRUMENTS * MAX_LFOS_PER_VOICE   ; retrigger
      lfo_offs    .res N_INSTRUMENTS * MAX_LFOS_PER_VOICE   ; offset (high byte only, or seed for SnH)

   ; oscillators
   ; modulation sources are inactive if negative (bit 7 active)
   ; Except amp_sel: it is assumed to be always active.
   ; modulation depth is assumed to be negative if _depH is negative (bit 7 active)
      ; pitch stuff
      osc_pitch            .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; offset (or absolute if no tracking)
      osc_fine             .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; unsigned (only up)
      osc_track            .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; keyboard tracking on/off (also affects portamento on/off)
      osc_pitch_mod_sel1   .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; selects source for pitch modulation (bit 7 on means none)
      osc_pitch_mod_dep1   .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; pitch modulation depth (Scale5)
      osc_pitch_mod_sel2   .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; selects source for pitch modulation (bit 7 on means none)
      osc_pitch_mod_dep2   .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; pitch modulation depth (Scale5)

      ; volume stuff
      osc_lrmid            .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; 0, 64, 128 or 192 for mute, L, R or center
      osc_volume           .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; oscillator volume
      osc_amp_sel          .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; amplifier select: gate, or one of the envelopes
      osc_vol_mod_sel      .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; volume modulation source
      osc_vol_mod_dep      .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; volume modulation depth

      ; waveform stuff
      osc_waveform         .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; including pulse width (PSG format)
      osc_pulse            .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; pulse width
      osc_pwm_sel          .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; selects source to modulate pulse width
      osc_pwm_dep          .res N_INSTRUMENTS * MAX_OSCS_PER_VOICE    ; pwm modulation depth


   ; FM general stuff
      fm_con              .res N_INSTRUMENTS   ; the connection algorithm of the instrument (3 bits)
      fm_fl               .res N_INSTRUMENTS   ; feedback level (3 bits)
      fm_op_en            .res N_INSTRUMENTS   ; operator enable (4 bits) (also acts as FM enable)
      fm_lr               .res N_INSTRUMENTS   ; Channels L/R (2 bits) (!!! stored in bits 6 and 7)
      ; pitch related
      fm_pitch            .res N_INSTRUMENTS    ; offset (or absolute if no tracking)
      fm_fine             .res N_INSTRUMENTS    ; unsigned (only up)
      fm_track            .res N_INSTRUMENTS    ; keyboard tracking on/off (also affects portamento on/off)
      fm_pitch_mod_sel    .res N_INSTRUMENTS    ; selects source for pitch modulation (bit 7 on means none)
      fm_pitch_mod_dep    .res N_INSTRUMENTS    ; pitch modulation depth (Scale5)
      ; LFO
      fm_lfo_enable       .res N_INSTRUMENTS    ; zero if this instrument should not overwrite the global LFO, one if it should
      fm_lfo_vol_mod      .res N_INSTRUMENTS    ; how much the YM2151's LFO affects volume  -  global setting, which can clash with other instruments!
      fm_lfo_pitch_mod    .res N_INSTRUMENTS    ; how much the YM2151's LFO affects pitch   -  global setting, which can clash with other instruments!
      fm_lfo_waveform     .res N_INSTRUMENTS    ; YM2151's LFO waveform                     -  global setting, which can clash with other instruments!
      fm_lfo_frequency    .res N_INSTRUMENTS    ; YM2151's LFO frequency                    -  global setting, which can clash with other instruments!
      fm_lfo_vol_sens     .res N_INSTRUMENTS    ; voice's sensitivity for volume modulation
      fm_lfo_pitch_sens   .res N_INSTRUMENTS    ; voice's sensitivity for pitch modulation



   ; FM Operators
      op_level            .res N_INSTRUMENTS * N_OPERATORS  ; volume (!!! attenuation: higher level means lower output volume) (7 bits)
      op_vol_sens_vel     .res N_INSTRUMENTS * N_OPERATORS  ; volume sensitivity on/off (velocity)
      op_vol_sens_lfo     .res N_INSTRUMENTS * N_OPERATORS  ; volume sensitivity on/off (YM2151's LFO)
      ; pitch related
      op_mul              .res N_INSTRUMENTS * N_OPERATORS  ; multiplier for the frequency (4 bits)
      op_dt1              .res N_INSTRUMENTS * N_OPERATORS  ; fine detune (3 bits)
      op_dt2              .res N_INSTRUMENTS * N_OPERATORS  ; coarse detune (2 bits)
      ; envelope
      op_ar               .res N_INSTRUMENTS * N_OPERATORS  ; attack rate (5 bits)
      op_d1r              .res N_INSTRUMENTS * N_OPERATORS  ; decay rate 1 (classical decay)  (5 bits)
      op_d1l              .res N_INSTRUMENTS * N_OPERATORS  ; decay level (or sustain level)  (4 bits)
      op_d2r              .res N_INSTRUMENTS * N_OPERATORS  ; decay rate 2 (0 for sustain)    (5 bits)
      op_rr               .res N_INSTRUMENTS * N_OPERATORS  ; release rate    (4 bits)
      op_ks               .res N_INSTRUMENTS * N_OPERATORS  ; key scaling    (2 bits)
.endstruct

; allocate the actual memory
instrument_data_start:
.ifdef concerto_use_instruments_from_file
   ; discard magic sequence at the start of the file (first 4 bytes)
   .incbin CONCERTO_INSTRUMENTS_PATH, 4, .sizeof(InstrumentDataStruct)
.else
   .res .sizeof(InstrumentDataStruct)
.endif

; communicate the size of the instrument data to other parts of the code
; the size of the whole instrument bank
instrument_data_size = .sizeof(InstrumentDataStruct)
.export instrument_data_size  ; 5152 bytes currently
; the number of bytes per instrument
instrument_data_count = instrument_data_size / N_INSTRUMENTS ; 161 currently
.export instrument_data_count

; define the labels to access instrument data
.scope Instrument
   n_oscs  = instrument_data_start + InstrumentDataStruct::n_oscs
   n_envs  = instrument_data_start + InstrumentDataStruct::n_envs
   n_lfos  = instrument_data_start + InstrumentDataStruct::n_lfos
   porta   = instrument_data_start + InstrumentDataStruct::porta
   porta_r = instrument_data_start + InstrumentDataStruct::porta_r
   retrig  = instrument_data_start + InstrumentDataStruct::retrig
   vibrato = instrument_data_start + InstrumentDataStruct::vibrato

   .scope env
      attackL = instrument_data_start + InstrumentDataStruct::env_attackL
      attackH = instrument_data_start + InstrumentDataStruct::env_attackH
      decayL = instrument_data_start + InstrumentDataStruct::env_decayL
      decayH = instrument_data_start + InstrumentDataStruct::env_decayH
      sustain = instrument_data_start + InstrumentDataStruct::env_sustain
      releaseL = instrument_data_start + InstrumentDataStruct::env_releaseL
      releaseH = instrument_data_start + InstrumentDataStruct::env_releaseH
   .endscope

   .scope lfo
      rateH = instrument_data_start + InstrumentDataStruct::lfo_rateH
      rateL = instrument_data_start + InstrumentDataStruct::lfo_rateL
      wave = instrument_data_start + InstrumentDataStruct::lfo_wave
      retrig = instrument_data_start + InstrumentDataStruct::lfo_retrig
      offs = instrument_data_start + InstrumentDataStruct::lfo_offs
   .endscope

   .scope osc
      pitch = instrument_data_start + InstrumentDataStruct::osc_pitch
      fine = instrument_data_start + InstrumentDataStruct::osc_fine
      track = instrument_data_start + InstrumentDataStruct::osc_track
      pitch_mod_sel1 = instrument_data_start + InstrumentDataStruct::osc_pitch_mod_sel1
      pitch_mod_dep1 = instrument_data_start + InstrumentDataStruct::osc_pitch_mod_dep1
      pitch_mod_sel2 = instrument_data_start + InstrumentDataStruct::osc_pitch_mod_sel2
      pitch_mod_dep2 = instrument_data_start + InstrumentDataStruct::osc_pitch_mod_dep2

      lrmid = instrument_data_start + InstrumentDataStruct::osc_lrmid
      volume = instrument_data_start + InstrumentDataStruct::osc_volume
      amp_sel = instrument_data_start + InstrumentDataStruct::osc_amp_sel
      vol_mod_sel = instrument_data_start + InstrumentDataStruct::osc_vol_mod_sel
      vol_mod_dep = instrument_data_start + InstrumentDataStruct::osc_vol_mod_dep

      waveform = instrument_data_start + InstrumentDataStruct::osc_waveform
      pulse = instrument_data_start + InstrumentDataStruct::osc_pulse
      pwm_sel = instrument_data_start + InstrumentDataStruct::osc_pwm_sel
      pwm_dep = instrument_data_start + InstrumentDataStruct::osc_pwm_dep
   .endscope

   .scope fm_general
      con = instrument_data_start + InstrumentDataStruct::fm_con
      fl = instrument_data_start + InstrumentDataStruct::fm_fl
      op_en = instrument_data_start + InstrumentDataStruct::fm_op_en
      lr = instrument_data_start + InstrumentDataStruct::fm_lr

      pitch = instrument_data_start + InstrumentDataStruct::fm_pitch
      fine = instrument_data_start + InstrumentDataStruct::fm_fine
      track = instrument_data_start + InstrumentDataStruct::fm_track
      pitch_mod_sel = instrument_data_start + InstrumentDataStruct::fm_pitch_mod_sel
      pitch_mod_dep = instrument_data_start + InstrumentDataStruct::fm_pitch_mod_dep

      lfo_enable = instrument_data_start + InstrumentDataStruct::fm_lfo_enable
      lfo_vol_mod = instrument_data_start + InstrumentDataStruct::fm_lfo_vol_mod
      lfo_pitch_mod = instrument_data_start + InstrumentDataStruct::fm_lfo_pitch_mod
      lfo_waveform = instrument_data_start + InstrumentDataStruct::fm_lfo_waveform
      lfo_frequency = instrument_data_start + InstrumentDataStruct::fm_lfo_frequency
      lfo_vol_sens = instrument_data_start + InstrumentDataStruct::fm_lfo_vol_sens
      lfo_pitch_sens = instrument_data_start + InstrumentDataStruct::fm_lfo_pitch_sens
   .endscope

   .scope operators
      level = instrument_data_start + InstrumentDataStruct::op_level
      vol_sens_vel = instrument_data_start + InstrumentDataStruct::op_vol_sens_vel
      vol_sens_lfo = instrument_data_start + InstrumentDataStruct::op_vol_sens_lfo

      mul = instrument_data_start + InstrumentDataStruct::op_mul
      dt1 = instrument_data_start + InstrumentDataStruct::op_dt1
      dt2 = instrument_data_start + InstrumentDataStruct::op_dt2

      ar = instrument_data_start + InstrumentDataStruct::op_ar
      d1r = instrument_data_start + InstrumentDataStruct::op_d1r
      d1l = instrument_data_start + InstrumentDataStruct::op_d1l
      d2r = instrument_data_start + InstrumentDataStruct::op_d2r
      rr = instrument_data_start + InstrumentDataStruct::op_rr
      ks = instrument_data_start + InstrumentDataStruct::op_ks
   .endscope
.endscope



.scope detail
   copying:
      .byte 128 ; which instrument to copy. negative is none
   pasting:
      .byte 0   ; where to paste

   ; advances the instrument_pointer by N_INSTRUMENTS, i.e. from one parameter to the next
   .proc advance_instrument_pointer
      lda instrument_pointer
      clc
      adc #N_INSTRUMENTS
      sta instrument_pointer
      bcc :+
      inc instrument_pointer+1
   :  rts
   .endproc

   ; Sets up the loop over single instrument data
   .proc prepareSingleInstrumentTransfer
      clc
      adc #(<instrument_data_start)
      sta instrument_pointer
      lda #(>instrument_data_start)
      adc #0
      sta instrument_pointer+1
      ldy #instrument_data_count
      rts
   .endproc
.endscope


; Emits instrument data for a single instrument via CHROUT to the currently active file/stream.
; .A: instrument number
.proc saveInstrument
   jsr detail::prepareSingleInstrumentTransfer
@loop:
   lda (instrument_pointer)
   jsr CHROUT
   jsr detail::advance_instrument_pointer
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
   sta (instrument_pointer)
   jsr detail::advance_instrument_pointer
   dey
   bne @loop
   rts
.endproc



; loads the default sound
; at the same time, this function IS the definition of the default instrument.
; X: instrument number, is preserved.
; does not preserve A, Y
load_default_instrument:
   stx detail::pasting
   ; do all "direct" values first
   lda #1
   sta Instrument::n_oscs, x
   sta Instrument::n_envs, x
   sta Instrument::retrig, x
   sta Instrument::n_lfos, x
   stz Instrument::porta, x
   lda #20
   sta Instrument::porta_r, x
   lda #$FF
   sta Instrument::vibrato, x
   ; LFO
   lda #13
   sta Instrument::lfo::rateH, x
   stz Instrument::lfo::rateL, x
   stz Instrument::lfo::wave, x
   stz Instrument::lfo::offs, x
   lda #1
   sta Instrument::lfo::retrig, x
   ; FM general
   sta Instrument::fm_general::track, x
   lda #7
   sta Instrument::fm_general::con, x
   lda #15
   sta Instrument::fm_general::op_en, x
   stz Instrument::fm_general::fl, x
   lda #%11000000
   sta Instrument::fm_general::lr, x
   ; select no modulation source
   lda #128
   sta Instrument::fm_general::pitch_mod_sel, x
   ; select minimal modulation depth
   lda #15
   sta Instrument::fm_general::pitch_mod_dep, x
   ; FM LFO -- todo: select reasonable defaults
   stz Instrument::fm_general::lfo_enable, x
   stz Instrument::fm_general::lfo_vol_sens, x
   stz Instrument::fm_general::lfo_pitch_sens, x
   lda #2
   sta Instrument::fm_general::lfo_waveform, x
   lda #210
   sta Instrument::fm_general::lfo_frequency, x
   lda #127
   sta Instrument::fm_general::lfo_vol_mod, x
   sta Instrument::fm_general::lfo_pitch_mod, x

   ; envelopes
   ldy #MAX_ENVS_PER_VOICE
@loop_envs:
   stz Instrument::env::attackL, x
   stz Instrument::env::decayL, x
   stz Instrument::env::releaseL, x
   lda #127
   sta Instrument::env::attackH, x
   lda #90
   sta Instrument::env::sustain, x
   lda #2
   sta Instrument::env::decayH, x
   lda #64
   sta Instrument::env::releaseH, x
   txa
   clc
   adc #N_INSTRUMENTS
   tax
   dey
   bne @loop_envs
   ; oscillators
   ldx detail::pasting
   ldy #MAX_OSCS_PER_VOICE
@loop_oscs:
   stz Instrument::osc::pitch, x
   stz Instrument::osc::fine, x
   stz Instrument::osc::amp_sel
   stz Instrument::osc::waveform
   lda #1
   sta Instrument::osc::track, x
   lda #192
   sta Instrument::osc::lrmid, x
   lda #50
   sta Instrument::osc::volume, x
   lda #63
   sta Instrument::osc::pulse, x
   ; select no modulation source
   lda #128
   sta Instrument::osc::pitch_mod_sel1, x
   sta Instrument::osc::pitch_mod_sel2, x
   sta Instrument::osc::vol_mod_sel, x
   sta Instrument::osc::pwm_sel, x
   ; select minimal modulation depths
   lda #15
   sta Instrument::osc::pitch_mod_dep1, x
   sta Instrument::osc::pitch_mod_dep2, x
   stz Instrument::osc::vol_mod_dep, x
   stz Instrument::osc::pwm_dep, x
   txa
   clc
   adc #N_INSTRUMENTS
   tax
   dey
   bne @loop_oscs
   ; FM operators
   ldx detail::pasting
   ldy #N_OPERATORS
@loop_operators:
   lda #1
   sta Instrument::operators::mul, x
   stz Instrument::operators::dt1, x
   stz Instrument::operators::dt2, x
   stz Instrument::operators::ks, x
   stz Instrument::operators::vol_sens_lfo, x
   lda #31
   sta Instrument::operators::ar, x
   lda #12
   sta Instrument::operators::d1r, x
   lda #4
   sta Instrument::operators::d2r, x
   lda #15
   sta Instrument::operators::d1l, x
   sta Instrument::operators::rr, x
   lda #22
   sta Instrument::operators::level, x
   lda #1
   sta Instrument::operators::vol_sens_vel, x
   sta Instrument::operators::vol_sens_lfo, x
   txa
   clc
   adc #N_INSTRUMENTS
   tax
   dey
   bne @loop_operators
   ldx detail::pasting
   rts


; initializes all instruments to the default instrument
init_instruments:
   ldx #N_INSTRUMENTS
@loop_instruments:
   dex
   jsr load_default_instrument
   cpx #0
   bne @loop_instruments
   rts

; sets the instrument pointer to the start of the instrument data
initialize_instrument_pointer:
   lda #<instrument_data_start
   sta instrument_pointer
   lda #>instrument_data_start
   sta instrument_pointer+1
   rts

; copy_paste. copies the instrument stored in variable "copying" to the one given in Y
; if the value of "copying" is negative, nothing is done.
; copy instrument "copying" to instrument "Y"
copy_paste:
   lda detail::copying
   bpl :+
   rts    ; exit if no instrument is being copied
:  stx detail::pasting
   ldx #instrument_data_count
   jsr initialize_instrument_pointer
@loop:
   ldy detail::copying
   lda (instrument_pointer), y
   ldy detail::pasting
   sta (instrument_pointer), y
   jsr detail::advance_instrument_pointer
   dex
   bne @loop
   rts

; dumps all instrument data to CHROUT. can be used to write to an already opened file
dump_to_chrout:
   ; write instrument data
   jsr initialize_instrument_pointer
   ldx #instrument_data_count
@loop_parameters:
   ldy #0
@loop_instruments:
   lda (instrument_pointer), y
   jsr CHROUT ; leaves X and Y untouched
   iny
   cpy #N_INSTRUMENTS
   beq @goto_next_parameter
   bra @loop_instruments
@goto_next_parameter:
   jsr detail::advance_instrument_pointer
   dex
   bne @loop_parameters
   rts

; restores all instruments from a data stream from CHRIN (which was previously dumped via dump_to_chrout)
; can be used to read from an already opened file
restore_from_chrin:
   ; read instrument data
   jsr initialize_instrument_pointer
   ldx #instrument_data_count
@loop_parameters:
   ldy #0
@loop_instruments:
   phy
   jsr CHRIN ; leaves X untouched, uses Y (as far as I know)
   ply
   sta (instrument_pointer), y
   iny
   cpy #N_INSTRUMENTS
   beq @goto_next_parameter
   bra @loop_instruments
@goto_next_parameter:
   jsr detail::advance_instrument_pointer
   dex
   bne @loop_parameters
   lda #1 ; success
   rts
@abort:
   lda #0 ; error
   rts


.endscope