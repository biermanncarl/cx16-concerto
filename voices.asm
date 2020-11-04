; this file contains the facilities to play notes
; its back-end communicates with the synth engine
; NOTE: synth voices DO NOT correspond to PSG voices.
; Instead, the single oscillators of a synth voice correspond
; to the PSG voices.
.scope voices

; Interface. these variables have to be set before a play command
note_timbre:
   .byte 0
note_pitch:
   .byte 0
note_velocity:
   .byte 0

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
      phaseL:  VOICE_BYTE_FIELD
      phaseH:  VOICE_BYTE_FIELD
   .endscope

   ; PSG voices (oscillator to PSG voice mapping) (unused ATM)
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
   .scope porta
      active:  VOICE_BYTE_FIELD   ; is porta still going? 0 if inactive, 1 if going up, 2 if going down
      rateL:   VOICE_BYTE_FIELD   ; unsigned rate (fine, note)
      rateH:   VOICE_BYTE_FIELD
      posL:    VOICE_BYTE_FIELD   ; current position in protamento (fine, note). Overwrites note as long as active
      posH:    VOICE_BYTE_FIELD
   .endscope
.endscope


.scope Voicemap
   ; information about which voices are free,
   ; which ones are played monophonically etc.

   ; ringlist of available voices
   freevoicelist:    VOICE_BYTE_FIELD
   ffv:  .byte 0  ; index of entry in ringlist, which denotes the first free voice
   lfv:  .byte 0  ; index of entry in ringlist, which points one past the last free voice
   nfv:  .byte 0  ; number of free voices
   ; when a voice is used, the ffv is advanced
   ; when a voice is finished, its index is stored at index lfv. Then lfv is advanced.
   ; If ffv and lfv are equal, either all voices are free, or there are no more
   ; free voices.
   ; These two cases can be distinguished via the nfv (number of free voices) variables

   ; bidirectional list of voices currently used. The oldest voice is the first one in
   ; the list. The newest one is last. If a voice has finished playing, it is removed.
   ; This data structure enables voice stealing from the oldest voices, as well as
   ; searching all active voices (in case of a note-off event).
   usedvoicesup:     VOICE_BYTE_FIELD  ; pointer to the next younger voice, bit 7 set means none
   usedvoicesdn:     VOICE_BYTE_FIELD  ; pointer to the next older voice
   uvf:  .byte 0  ; oldest used voice. bit 7 is set if none used
   uvl:  .byte 0  ; youngest used voice. bit 7 is set if none used

   ; table which contains information which timbre is currently played by which voice,
   ; in case it is a monophonic timbre.
   ; if bit 7 is set, timbre is currently played
   ; bits 0 to 6 indicate voice number
   monovoicetable:   VOICE_BYTE_FIELD

   ; stack for voice release routine
   ; This stack is filled with a "job" every time a note has finished playing (from inside
   ; the ISR). This is convenient for one-shot notes that only have a note-on event and
   ; no note-off event, where the synth can determine if a voice has finished.
   ; The actual voice release is done by the main program, which also handles
   ; the voice acquisition. This is safer and prevents bad interference, for example
   ; a voice release from the ISR at the same time as a new note is being played in the
   ; main program. This could screw up the freevoicelist badly.
   ; In the ISR, a finished voice is only deactivated and a message pushed to this stack.
   releasevoicestack:   VOICE_BYTE_FIELD
   rvsp: .byte 0  ; stack pointer, points one past last message
.endscope


; other variables used by voices.asm
;distance:
;   .byte 0

.macro ADVANCE_FVL_POINTER adv_fvl_ptr
   lda adv_fvl_ptr
   ina
   cmp #(N_VOICES)
   bcc :+
   lda #0
:  sta adv_fvl_ptr
.endmacro

.macro MUL8x8_PORTA ; uses ZP variables in the process
   ; the idea is that portamento is finished in a constant time
   ; that means, rate must be higher, the larger the porta distance is
   ; This is achieved by multiplying the "base rate" by the porta distance
   
   ; initialization
   ; mzpwa stores the porta rate. It needs a 16 bit variable because it is left shifted
   ; throughout the multiplication
   lda timbres_pre::Timbre::porta_r, y
   sta mzpwa+1
   stz mzpwa
   stz Voice::porta::rateL, x
   stz Voice::porta::rateH, x

   ; multiplication
   bbr0 mzpba, :+
   lda mzpwa+1
   sta Voice::porta::rateL, x
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr1 mzpba, :+
   clc
   lda mzpwa+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mzpwa
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr2 mzpba, :+
   clc
   lda mzpwa+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mzpwa
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr3 mzpba, :+
   clc
   lda mzpwa+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mzpwa
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr4 mzpba, :+
   clc
   lda mzpwa+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mzpwa
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr5 mzpba, :+
   clc
   lda mzpwa+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mzpwa
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr6 mzpba, :+
   clc
   lda mzpwa+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mzpwa
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mzpwa+1
   rol mzpwa
   bbr7 mzpba, @end_macro
   clc
   lda mzpwa+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mzpwa
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
@end_macro:
.endmacro




; Puts all the Voicemap variables into a state ready to receive
; play_note commands.
init_voicelist:
   ; init freevoicelist, used-voices-list, and monovoicetable at the same time
   ; and while we're in this loop, deactivate all voices
   ldx #(N_VOICES-1)
@loop:
   txa
   sta Voicemap::freevoicelist, x
   lda #255
   sta Voicemap::usedvoicesup, x ; none
   sta Voicemap::usedvoicesdn, x ; none
   sta Voicemap::monovoicetable, x ; none
   stz Voice::active, x
   dex
   bpl @loop

   stz Voicemap::ffv
   stz Voicemap::lfv ; first and last free voice are set to 0
   lda #N_VOICES
   sta Voicemap::nfv ; all voices are free
   lda #255
   sta Voicemap::uvf ; first used voice is none
   sta Voicemap::uvl ; last used voice is none

   ; release-voices stack
   stz Voicemap::rvsp    ; the actual stack doesn't need to be initialized.
rts



; plays a note. needs info for pitch, velocity and timbre
; in this subroutine, register X usually contains the index of the voice
play_note:
   ; do resource investigation/acquisition

   ; check if mono patch
   ldy note_timbre
   lda timbres_pre::Timbre::mono, y
   bne :+
   jmp @poly_voice_acquisition

:  ; check if mono voice still playing. if yes, replace it
   ldx Voicemap::monovoicetable, y
   bpl @reuse_mono_voice

@get_new_mono_voice:
   phy
   jsr get_voice
   ply
   cpx #0
   bpl :+
   jmp @skip_play
:  ; update monovoicetable
   txa
   sta Voicemap::monovoicetable, y

   ; deactivate porta (? maybe add other bend-modes later)
   lda #0
   sta Voice::porta::active, x
   jmp @non_mono_dependent_setup

@reuse_mono_voice:   ; reuse voice, setup portamento etc.
   ; portamento stuff (must come before voice's pitch is replaced!)
   ldy #2
   lda note_pitch
   sec
   sbc Voice::pitch, x ; if aimed pitch is higher than current pitch, no overflow, thus carry set
   bcs :+
   ; aimed lower
   ; must invert accumulator for correct portamento rate determination
   sta mzpba   ; here: contains slide distance
   lda #0
   sec
   sbc mzpba
   sta mzpba
   bra :++
:  ; aimed higher
   sta mzpba
   ldy #1
:  tya
   sta Voice::porta::active, x ; up or down
   ; determine porta rate
   ldy note_timbre
   MUL8x8_PORTA
   ; set current porta starting point
   stz Voice::porta::posL
   lda Voice::pitch
   sta Voice::porta::posH
   jmp @non_mono_dependent_setup

@poly_voice_acquisition:
   phy
   jsr get_voice
   ply
   ; check if we got a valid voice
   cpx #0
   bpl :+
   jmp @skip_play
:  ; deactivate voice first, so the ISR won't play an "unfinished" voice
   stz Voice::active,x
   

@non_mono_dependent_setup:
   ; launch ENV generator (this might be migrated to mono/poly specific stuff for legato modes)
   stz Voice::ad1::phaseL, x
   stz Voice::ad1::phaseH, x
   stz Voice::ad1::step, x

   ; other stuff
   lda note_pitch
   sta Voice::pitch, x
   lda note_velocity
   sta Voice::velocity, x
   lda note_timbre
   sta Voice::timbre, x
   lda #0
   sta Voice::osc1_psg, x

   ; activate note (should be the last thing done!)
   lda #1
   sta Voice::active,x
@skip_play:
rts

; looks for a voice of given timbre and pitch and stops it
; this is practically a note-off
; note-offs are not strictly necessary, if an instrument is
; auto-finishing
stop_note:
   nop ; TODO
rts

; looks for all voices of a given instrument and stops them
stop_instrument:
   nop ; TODO
rts

; acquires a new voice and returns voice index in register X
; oscillators needed are assumed to be according to note_timbre
; this is NOT a note-on.
; note-on events need further setting up of the voice
; if unsuccessful, bit 7 of X is set (indicating NONE)
get_voice:
   ; check how many voices are free
   lda Voicemap::nfv
   beq @unsuccessful    ; if there's no voice left, don't play ... or steal a voice (TODO)
   ; get voice from and update free voices ringlist
   ldy Voicemap::ffv
   ldx Voicemap::freevoicelist, y  ; index of acquired voice in X
   ADVANCE_FVL_POINTER Voicemap::ffv
   dec Voicemap::nfv

   ; append to used voices list
   lda #255
   sta Voicemap::usedvoicesup, x ; set next voice to none
   ldy Voicemap::uvl ; look for last voice
   stx Voicemap::uvl ; and replace last voice before evaluating last voice
   bmi @we_are_first ; branch if last voice is none
   txa ; if last voice existed, just do the links in both directions
   sta Voicemap::usedvoicesup, y
   tya
   sta Voicemap::usedvoicesdn, x
rts
@we_are_first: ; if last voice didn't exist, setup start and end pointers, and set down link to none
   stx Voicemap::uvf
   stx Voicemap::uvl
   sta Voicemap::usedvoicesdn, x
rts
@unsuccessful:
   ldx #255
rts

; takes index of voice to be released in register A and does all the buereaucracy
; to check out the voice
; this is NOT a note-off, because note-offs still need to be translated from
; Pitch/Timbre to Voice index
release_voice:
   tax
   ; update freevoicelist
   ldy Voicemap::lfv
   sta Voicemap::freevoicelist, y
   ADVANCE_FVL_POINTER Voicemap::lfv
   inc Voicemap::nfv

   ; update monovoicelist
   lda #255
   sta Voicemap::monovoicetable, x   ; set to "not playing" (bit 7 set)

   ; update bidirectional used voice list
   ; link previous one to next one
   ldy Voicemap::usedvoicesdn, x
   bmi @prev_is_none
   lda Voicemap::usedvoicesup, x
   sta Voicemap::usedvoicesup, y
   bra @continue1
@prev_is_none:
   lda Voicemap::usedvoicesup, x
   sta Voicemap::uvf    ; replace index of oldest voice
@continue1:
   ; link next one to previous one
   ldy Voicemap::usedvoicesup, x
   bmi @next_is_none
   lda Voicemap::usedvoicesdn, x
   sta Voicemap::usedvoicesdn, y
   bra @continue2
@next_is_none:
   lda Voicemap::usedvoicesdn, x
   sta Voicemap::uvl    ; replace index of youngest voice
@continue2:

   ; TODO update freeosclist
rts

; does all the release commands put on the release stack by the ISR
do_stack_releases:
   ; read and update release-voice-stack
   sei   ; don't allow interference as long as there must not be interference
   ldx Voicemap::rvsp
   beq @end_do_stack_releases
   dex
   lda Voicemap::releasevoicestack, x
   stx Voicemap::rvsp
   cli   ; that's all we need. Our ISR won't mess up the freevoicelist & freeosclist

   phx
   jsr release_voice
   plx ; x holds the "stack pointer" and indicates whether we have reached the bottom

   bne do_stack_releases

@end_do_stack_releases:
   cli
rts




; stop all voices, should contain a PSG MUTE ALL, as well (TODO)
panic:
   ldx #(N_VOICES-1)
@loop:
   stz Voice::active, x
   dex
   bpl @loop
   jsr init_voicelist
rts




.endscope