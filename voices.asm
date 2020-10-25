; this file contains the facilities to play notes
; its back-end communicates with the synth engine
; NOTE: synth voices DO NOT correspond to PSG voices.
; Instead, the single oscillators of a synth voice correspond
; to the PSG voices.
.scope voices

; internal data for synth
.scope Voice
   active:    VOICE_BYTE_FIELD   ; on/off

   ; general
   pitch:     VOICE_BYTE_FIELD
   velocity:  VOICE_BYTE_FIELD
   timbre:    VOICE_BYTE_FIELD   ; which synth patch to use

   ; envelopes
   .scope ad1
      step:   VOICE_BYTE_FIELD
      phase:  VOICE_WORD_FIELD
   .endscope

   ; PSG voices (oscillator to PSG voice mapping)
   osc_psg_map:
   osc1_psg:  VOICE_BYTE_FIELD
   osc2_psg:  VOICE_BYTE_FIELD
   osc3_psg:  VOICE_BYTE_FIELD
   osc4_psg:  VOICE_BYTE_FIELD
   osc5_psg:  VOICE_BYTE_FIELD
   osc6_psg:  VOICE_BYTE_FIELD
   osc7_psg:  VOICE_BYTE_FIELD
   osc8_psg:  VOICE_BYTE_FIELD

   ; portamento
   porta_active: VOICE_BYTE_FIELD   ; active at beginning of note
   porta_pos:    VOICE_WORD_FIELD   ; current position in protamento (note, fine). Overwrites note as long as active
   porta_rate:   VOICE_WORD_FIELD   ; unsigned rate (note, fine) negative slopes just by overflowing
.endscope


.scope Voicemap
   ; information about which voices are free,
   ; which ones are played monophonically etc.
.endscope




; Interface. these variables have to be set before a play command
note_timbre:
   .byte 0
note_pitch:
   .byte 0
note_velocity:
   .byte 0


; plays a monophonic note, i.e. another voice is replaced by
; the new voice.
; Later, it should be specified somehow, which voice is going
; to be replaced (maybe by timbre - in multitimbral mode)
; Monophonic playing also facilitates portamento
play_monophonic:
   ; launch ENV generator
   stz Voice::ad1::phase
   stz Voice::ad1::phase+1
   stz Voice::ad1::step

   ; activate voice
   lda #1
   sta Voice::active

   ; monophonic specific stuff
   sta Voice::porta_active

   ; other stuff
   lda note_pitch
   sta Voice::pitch
   lda note_velocity
   sta Voice::velocity
   lda note_timbre
   sta Voice::timbre
   lda #0
   sta Voice::osc1_psg



   ; activate note (should be the last thing done!)
   lda #1
   sta Voice::active
rts





.endscope