; This file manages the pre-interpreted synth patches in a format,
; that is designed to be efficiently interpreted by the synth engine.
; E.g. all times have been converted to rates or ticks
; And the interpreter won't have to check all on/off switches, because
; there are lists of things that the interpreter has to do.
.scope timbres_pre




.scope Timbre
   ;general
   n_oscs:  TIMBRE_BYTE_FIELD         ; how many oscillators are used
   volume:  TIMBRE_BYTE_FIELD         ; overall volume
   mono:    TIMBRE_BYTE_FIELD         ; monophonic on/off
   porta_r: TIMBRE_BYTE_FIELD         ; portamento rate

   ; envelope rates (not times!)
   .scope ad1
      attackL: TIMBRE_BYTE_FIELD
      attackH: TIMBRE_BYTE_FIELD
      decayL:  TIMBRE_BYTE_FIELD
      decayH:  TIMBRE_BYTE_FIELD
   .endscope

   ; oscillators
   .scope osc1
      waveform: TIMBRE_BYTE_FIELD    ; including pulse width (PSG format) (? maybe not)
      volume:   TIMBRE_BYTE_FIELD    ; how many powers of 2 down
      pitch:    TIMBRE_BYTE_FIELD    ; offset or absolute (if no tracking)
      fine:     TIMBRE_BYTE_FIELD    ; unsigned (only up)
      track:    TIMBRE_BYTE_FIELD    ; keyboard tracking on/off (also affects portamento on/off)
      amp_sel:  TIMBRE_BYTE_FIELD    ; amplifier select: gate, or one of the envelopes
   .endscope
.endscope


; Subroutines that will be implemented here are e.g.
;   * for updating the whole preinterpreted patch (e.g. when loading a preset)
;   * for updating parts of the preinterpreted patch, e.g. an oscillator
;   * or envelopes
;   * ...


.endscope