; This file manages the synth patches.
; The patch data will be read by the synth engine as well as the GUI.

; Disk save and load commands for individual synth patches are planned to be in this file.

; The patch data is organized in arrays. Each successive byte belongs to a different patch.
; For example, the portamento rate is a field of N_TIMBRES bytes (32 the last time I checked).
;    rate of patch 0
;    rate of patch 1
;    rate of patch 2
;    ...
; rate of patch 31
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
; To access all three envelope settings of a timbre, one starts by setting X to the
; timbre index, giving the offset of envelope 1.
; Then, by adding N_TIMBRES to X, we get the offset of envelope 2, and if we do it again,
; we get the offset of envelope 3 of that same patch.
; That way, we can avoid multiplications to find the correct indices.


.scope timbres




.scope Timbre
data_start:

   ;general
   n_oscs:  TIMBRE_BYTE_FIELD         ; how many oscillators are used
   n_envs:  TIMBRE_BYTE_FIELD         ; how many envelopes are used
   n_lfos:  TIMBRE_BYTE_FIELD
   porta:   TIMBRE_BYTE_FIELD         ; portamento on/off
   porta_r: TIMBRE_BYTE_FIELD         ; portamento rate
   retrig:  TIMBRE_BYTE_FIELD         ; when monophonic, will envelopes be retriggered? (could be combined with mono variable)

   ; envelope rates (not times!)
   .scope env
      attackL:  ENVELOPE_TIMBRE_BYTE_FIELD
      attackH:  ENVELOPE_TIMBRE_BYTE_FIELD
      decayL:   ENVELOPE_TIMBRE_BYTE_FIELD
      decayH:   ENVELOPE_TIMBRE_BYTE_FIELD
      sustain:  ENVELOPE_TIMBRE_BYTE_FIELD
      releaseL: ENVELOPE_TIMBRE_BYTE_FIELD
      releaseH: ENVELOPE_TIMBRE_BYTE_FIELD
   .endscope

   ; lfo stuff
   .scope lfo
      rateH:   LFO_TIMBRE_BYTE_FIELD
      rateL:   LFO_TIMBRE_BYTE_FIELD
      wave:    LFO_TIMBRE_BYTE_FIELD   ; waveform select: triangle, square, ramp up, ramp down, noise (S'n'H)
      retrig:  LFO_TIMBRE_BYTE_FIELD   ; retrigger
      offs:    LFO_TIMBRE_BYTE_FIELD   ; offset (high byte only, or seed for SnH)
   .endscope

   ; oscillators
   ; modulation sources are inactive if negative (bit 7 active)
   ; Except amp_sel: it is assumed to be always active.
   ; modulation depth is assumed to be negative if _depH is negative (bit 7 active)
   .scope osc
      ; pitch stuff
      pitch:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; offset (or absolute if no tracking)
      fine:             OSCILLATOR_TIMBRE_BYTE_FIELD    ; unsigned (only up)
      track:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; keyboard tracking on/off (also affects portamento on/off)
      pitch_mod_sel1:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects source for pitch modulation (bit 7 on means none)
      pitch_mod_dep1:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; pitch modulation depth (Scale5)
      pitch_mod_sel2:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects source for pitch modulation (bit 7 on means none)
      pitch_mod_dep2:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; pitch modulation depth (Scale5)

      ; volume stuff
      lrmid:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; 0, 64, 128 or 192 for mute, L, R or center
      volume:           OSCILLATOR_TIMBRE_BYTE_FIELD    ; oscillator volume
      amp_sel:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; amplifier select: gate, or one of the envelopes
      vol_mod_sel:      OSCILLATOR_TIMBRE_BYTE_FIELD    ; volume modulation source
      vol_mod_dep:      OSCILLATOR_TIMBRE_BYTE_FIELD    ; volume modulation depth

      ; waveform stuff
      waveform:         OSCILLATOR_TIMBRE_BYTE_FIELD    ; including pulse width (PSG format)
      pulse:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; pulse width
      pwm_sel:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects source to modulate pulse width
      pwm_dep:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; pwm modulation depth
      ; etc.
   .endscope
data_end:
data_size = data_end - data_start
data_count = data_size / N_TIMBRES
.endscope

command_len:
   .byte 15
command_string:
   ; needs to be MAX_FILENAME_LEN bytes in total
   .byte 64,"0:test.cot,s,w"
   .res 12,0

; this is the sequence that must be found at the beginning of each valid timbre file
; 4 bytes
magic_sequence:
   .byte "cot", 0   ; stands for CONCERTO timbre, version number 0




; more info about the Commander DOS
; https://en.wikipedia.org/wiki/Commodore_DOS

; opens the file with filename specified in "filename" and saves a timbre in it
; X:            timbre number
; filename:     name of the file to store the timbre in
; filename_len: length of the file name
; This routine can be dramatically optimized in size if the data format in memory is known
; Don't need to call each label on its own, just visit a set number of locations,
; evenly spaced by N_TIMBRES bytes.
; TODO!!
save_timbre:
   st_pointer = mzpwd
   phx
   ; set file name
   lda command_len
   ldx #(<command_string)
   ldy #(>command_string)
   jsr SETNAM
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #2 ; secondary command address, apparently must not be zero
   jsr SETLFS
   ; open - open the logical file
   lda #1
   jsr OPEN
   ; chkin - open a logical file for output
   ldx #1 ; logical file to be used
   jsr CHKOUT
   ; magic sequence
   lda magic_sequence
   jsr CHROUT
   lda magic_sequence+1
   jsr CHROUT
   lda magic_sequence+2
   jsr CHROUT
   lda magic_sequence+3
   jsr CHROUT
   ; write patch data
   plx
   txa
   clc
   adc #(<Timbre::data_start)
   sta st_pointer
   lda #(>Timbre::data_start)
   adc #0
   sta st_pointer+1
   ldy #Timbre::data_count
@loop:
   lda (st_pointer)
   jsr CHROUT
   lda st_pointer
   clc
   adc #N_TIMBRES
   sta st_pointer
   lda st_pointer+1
   adc #0
   sta st_pointer+1
   dey
   bne @loop
   ; close file
   lda #1
   jsr CLOSE
   jsr CLRCHN
   rts





; loads the default sound
; at the same time, this function IS the definition of the default patch.
; X: timbre number, is preserved.
; does not preserve A, Y
load_default_timbre:
   ; do all "direct" values first
   lda #1
   sta Timbre::n_oscs, x
   sta Timbre::n_envs, x
   sta Timbre::retrig, x
   sta Timbre::n_lfos, x
   stz Timbre::porta, x
   lda #20
   sta Timbre::porta_r, x
   ; LFO
   lda #10
   sta Timbre::lfo::rateH, x
   stz Timbre::lfo::rateL, x
   stz Timbre::lfo::wave, x
   stz Timbre::lfo::offs, x
   lda #1
   sta Timbre::lfo::retrig
   ; envelopes
   phx
   ldy #MAX_ENVS_PER_VOICE
@loop_envs:
   stz Timbre::env::attackL, x
   stz Timbre::env::decayL, x
   stz Timbre::env::releaseL, x
   lda #127
   sta Timbre::env::attackH, x
   lda #63
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
   plx
   ; oscillators
   phx
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
   lda #64
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
   plx
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

.endscope