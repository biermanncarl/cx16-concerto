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

   ; envelope rates (not times!)
   .scope env
      attackL: ENVELOPE_TIMBRE_BYTE_FIELD
      attackH: ENVELOPE_TIMBRE_BYTE_FIELD
      decayL:  ENVELOPE_TIMBRE_BYTE_FIELD
      decayH:  ENVELOPE_TIMBRE_BYTE_FIELD
   .endscope

   ; oscillators
   .scope osc
      waveform:         OSCILLATOR_TIMBRE_BYTE_FIELD    ; including pulse width (PSG format) (? maybe not)
      volume:           OSCILLATOR_TIMBRE_BYTE_FIELD    ; how many powers of 2 down
      lrmid:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; 0, 64, 128 or 192 for mute, L, R or center
      pitch:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; offset or absolute (if no tracking)
      fine:             OSCILLATOR_TIMBRE_BYTE_FIELD    ; unsigned (only up)
      track:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; keyboard tracking on/off (also affects portamento on/off)
      amp_sel:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; amplifier select: gate, or one of the envelopes
      pulse:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; pulse width
      pwm_lfo_sel:      OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects lfo to modulate pulse width
      pwm_lfo_depH:     OSCILLATOR_TIMBRE_BYTE_FIELD    ; high byte of pwm modulation by lfo depth
      pwm_lfo_depL:     OSCILLATOR_TIMBRE_BYTE_FIELD    ; low byte of pwm modulation by lfo depth
      pitch_env_sel:    OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects envelope for pitch modulation
      pitch_env_depH:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; high byte of pitch modulation by envelope depth
      pitch_env_depL:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; low byte of pitch modulation by envelope depth
      ; etc.
   .endscope
.endscope


; Subroutines that will be implemented here are e.g.
;   * for updating the whole preinterpreted patch (e.g. when loading a preset)
;   * for updating parts of the preinterpreted patch, e.g. an oscillator
;   * or envelopes
;   * ...


.endscope