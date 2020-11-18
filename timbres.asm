; This file manages the synth patches.
; The patch data will be read by the synth engine as well as the GUI.
; For some parameters, there are conflicts about representations of
; parameters that are easy to use by the synth engine, and easy to
; use by the GUI/user.
; The synth engine friendly version will always be present. (e.g.
; envelope rates instead of times - Yamaha DX7 style ...
; or fine tuning only up instead of up and down).
; The schemes on which parameters are presented in which way to the user
; still have to be decided.

.scope timbres




.scope Timbre
   ;general
   n_oscs:  TIMBRE_BYTE_FIELD         ; how many oscillators are used
   n_envs:  TIMBRE_BYTE_FIELD         ; how many envelopes are used
   volume:  TIMBRE_BYTE_FIELD         ; overall volume
   mono:    TIMBRE_BYTE_FIELD         ; monophonic on/off
   porta_r: TIMBRE_BYTE_FIELD         ; portamento rate
   retrig:  TIMBRE_BYTE_FIELD         ; when monophonic, will envelopes be retriggered? (could be combined with mono variable)

   ; envelope rates (not times!)
   .scope env
      attackL: ENVELOPE_TIMBRE_BYTE_FIELD
      attackH: ENVELOPE_TIMBRE_BYTE_FIELD
      decayL:  ENVELOPE_TIMBRE_BYTE_FIELD
      decayH:  ENVELOPE_TIMBRE_BYTE_FIELD
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
      pitch_mod_sel:    OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects source for pitch modulation (bit 7 on means none)
      pitch_mod_dep:   OSCILLATOR_TIMBRE_BYTE_FIELD     ; pitch modulation depth (! weird format)

      ; volume stuff
      lrmid:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; 0, 64, 128 or 192 for mute, L, R or center
      volume:           OSCILLATOR_TIMBRE_BYTE_FIELD    ; oscillator volume (! weird format)
      amp_sel:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; amplifier select: gate, or one of the envelopes

      ; waveform stuff
      waveform:         OSCILLATOR_TIMBRE_BYTE_FIELD    ; including pulse width (PSG format) (? maybe not)
      pulse:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; pulse width
      pwm_lfo_sel:      OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects lfo to modulate pulse width
      pwm_lfo_depH:     OSCILLATOR_TIMBRE_BYTE_FIELD    ; high byte of pwm modulation by lfo depth
      pwm_lfo_depL:     OSCILLATOR_TIMBRE_BYTE_FIELD    ; low byte of pwm modulation by lfo depth
      ; etc.
   .endscope
.endscope


; Subroutines that will be implemented here are e.g.
;   * for updating the whole preinterpreted patch (e.g. when loading a preset)
;   * for updating parts of the preinterpreted patch, e.g. an oscillator
;   * or envelopes
;   * ...


.endscope