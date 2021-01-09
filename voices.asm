; this file contains the facilities to play notes
; its back-end communicates with the synth engine
; NOTE: synth voices DO NOT correspond to PSG voices.
; Instead, the single oscillators of a synth voice correspond
; to the PSG voices.
.scope voices

; Interface. these variables have to be set before a play command
note_channel:
   .byte 0
note_timbre:
   .byte 0
note_pitch:
   .byte 0
note_volume:
   .byte 0

; These data fields correspond to the monophonic voices of all the 16 channels.
; Each voice can be active or inactive.
; Active voices can be overridden by new play events.
.scope Voice
   active:    VOICE_BYTE_FIELD   ; on/off

   ; general
   pitch:     VOICE_BYTE_FIELD
   volume:    VOICE_BYTE_FIELD   ; voice's volume can be modified in real time. 128 is full volume, everything below is more quiet.
   timbre:    VOICE_BYTE_FIELD   ; which synth patch to use

   ; envelopes
   .scope env
      step:    ENVELOPE_VOICE_BYTE_FIELD
      phaseL:  ENVELOPE_VOICE_BYTE_FIELD
      phaseH:  ENVELOPE_VOICE_BYTE_FIELD
   .endscope

   ; lfos
   .scope lfo
      phaseL:  LFO_VOICE_BYTE_FIELD
      phaseH:  LFO_VOICE_BYTE_FIELD
   .endscope

   ; PSG voices (synth oscillator to PSG oscillator mapping)
   osc_psg_map:   OSCILLATOR_VOICE_BYTE_FIELD

   ; portamento
   .scope porta
      active:  VOICE_BYTE_FIELD   ; is porta still going? 0 if inactive, 1 if going up, 2 if going down
      rateL:   VOICE_BYTE_FIELD   ; unsigned rate (fine, note)
      rateH:   VOICE_BYTE_FIELD
      posL:    VOICE_BYTE_FIELD   ; current position in protamento (fine, note). Overwrites note as long as active
      posH:    VOICE_BYTE_FIELD
   .endscope
.endscope


.scope Oscmap
   ; information about which oscillators are free

   ; ringlist of available PSG oscillators
   ; freeosclist contains the VERA numbers of all the PSG oscillators.
   ; In the beginning, they will be in there like 0, 1, 2, ... , 14, 15
   ; but get scrambled during runtime, because oscillators will be used and
   ; released in "random" order.
   ; Think of freeosclist as an array of indices
   ; freeosclist[ffo] contains the VERA index of the first currently available oscillator
   ; freeosclist[lfo-1] contains the VERA index of the last currently available oscillator
   ; that means, if lfo=ffo, there are either no oscillators free to use,
   ; or all oscillators are free (because of cyclic indexing).
   freeosclist:   OSCILLATOR_BYTE_FIELD
   ffo:  .byte 0  ; index of entry in ringlist, which denotes the first free oscillator
   lfo:  .byte 0  ; index of entry in ringlist, which points one past the last free oscillator
   nfo:  .byte 0  ; number of free oscillators
   ; when an oscillator is used, the ffo is advanced
   ; when an oscillator is finished, its index is stored at index lfo. Then lfo is advanced.
   ; If ffo and lfo are equal, either all voices are free, or there are no more
   ; free voices.
   ; These two cases can be distinguished via the nfo (number of free oscillators) variable
.endscope


.macro ADVANCE_FOL_POINTER adv_fol_ptr
   lda adv_fol_ptr
   ina
   cmp #(N_OSCILLATORS)
   bcc :+
   lda #0
:  sta adv_fol_ptr
.endmacro

; In this macro, the slide distance is multiplied by the portamento (base-)rate.
; The result is the effective portamento rate.
; It guarantees that the portamento time is constant regardless of how far
; two notes are apart.
; Expects voice index in X, timbre index in Y, slide distance in mzpbb
.macro MUL8x8_PORTA ; uses ZP variables in the process
   mp_slide_distance = mzpbb ; must be the same as in "continue_note"!
   mp_return_value = mzpwb
   ; the idea is that portamento is finished in a constant time
   ; that means, rate must be higher, the larger the porta distance is
   ; This is achieved by multiplying the "base rate" by the porta distance
   
   ; initialization
   ; mzpwa stores the porta rate. It needs a 16 bit variable because it is left shifted
   ; throughout the multiplication
   lda timbres::Timbre::porta_r, y
   sta mp_return_value+1
   stz mp_return_value
   stz Voice::porta::rateL, x
   stz Voice::porta::rateH, x

   ; multiplication
   bbr0 mp_slide_distance, :+
   lda mp_return_value+1
   sta Voice::porta::rateL, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr1 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mp_return_value
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr2 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mp_return_value
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr3 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mp_return_value
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr4 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mp_return_value
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr5 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mp_return_value
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr6 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mp_return_value
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr7 mp_slide_distance, @end_macro
   clc
   lda mp_return_value+1
   adc Voice::porta::rateL, x
   sta Voice::porta::rateL, x
   lda mp_return_value
   adc Voice::porta::rateH, x
   sta Voice::porta::rateH, x
@end_macro:
.endmacro




; Puts all the Voicemap & Oscmap variables into a state ready to receive
; play_note commands.
init_voices:
   ; init free-oscillator-list
   ldx #(N_OSCILLATORS-1)
@loop_osc:
   txa
   sta Oscmap::freeosclist, x
   dex
   bpl @loop_osc

   stz Oscmap::ffo
   stz Oscmap::lfo
   lda #N_OSCILLATORS
   sta Oscmap::nfo
rts



; Plays a note. needs info for channel, timbre, pitch and volume.
; Can be called from within the ISR and the main program.
; Zero-Page variables used in this routine are the ones belonging to the ISR.
; However, by calling SEI-CLI, it is prevented that they get messed up by the ISR, if the main program
; calls this function. (If calling this from the main program, you MUST do SEI before! And CLI after)
; In this subroutine, register X usually contains the index of the voice.
; What exactly does this routine do?
; If no note is currently active on the channel, it plays a new note with retriggering envelopes,
; and retriggering LFOs as specified in the timbre settings, provided there are enough oscillators
; available.
; If a note is currently active on the channel, the action depends on whether it is the same timbre or not.
; If it's the same timbre, retrigger and portamento are applied as specified in the timbre settings.
; If it's a different timbre, the old note is replaced entirely (just as if there was no note).
play_note:
   ldx note_channel
   ldy note_timbre
   ; check if there is an active note on the channel
   lda Voice::active, x
   beq @new_note
@existing_note:
   ; check if it's the same timbre
   lda Voice::timbre, x
   cmp note_timbre
   beq @same_timbre
@different_timbre:
   jsr stop_note
   ldx note_channel
   ldy note_timbre
   bra @new_note
@same_timbre:
   jsr continue_note
   bra @common_stuff
@new_note:
   jsr start_note
   ; check if starting note was successful (unsuccessful if there weren't enough oscillators available)
   beq @skip_play
   ldx note_channel
   ldy note_timbre
   jsr retrigger_note
@common_stuff:
   ; the stuff that is always done.
   ldx note_channel
   lda note_pitch
   sta Voice::pitch, x
   lda note_volume
   sta Voice::volume, x
   lda note_timbre
   sta Voice::timbre, x

   ; activate note (should be the last thing done!)
   lda #1
   sta Voice::active,x
@skip_play:
rts

; This subroutine is used in play_note in the case that a note with the same timbre as played is
; still active on the channel. It does all the stuff specific to that case.
; expects channel index in X, timbre index in Y
; doesn't preserve X and Y
continue_note:
   cn_slide_distance = mzpbb
   ; check if porta active
   lda timbres::Timbre::porta, y
   bne @setup_porta
@no_porta:
   stz Voice::porta::active, x
   jmp cn_check_retrigger
@setup_porta:
   ; portamento stuff (must come before voice's pitch is replaced!)
   ldy #2
   lda note_pitch
   sec
   sbc Voice::pitch, x ; if aimed pitch is higher than current pitch, no overflow, thus carry set
   bcs :+
   ; aimed lower
   ; must invert accumulator for correct portamento rate determination
   eor #%11111111
   inc
   sta cn_slide_distance
   bra :++
:  ; aimed higher
   sta cn_slide_distance
   ldy #1
:  tya
   sta Voice::porta::active, x ; up or down
   ; determine porta rate
   ldy note_timbre
   MUL8x8_PORTA
   ; set current porta starting point
   stz Voice::porta::posL, x
   lda Voice::pitch, x
   sta Voice::porta::posH, x
cn_check_retrigger:
   ; retrigger or continue?
   lda timbres::Timbre::retrig, y
   bne :+
   rts
:  jsr retrigger_note
rts

; retriggers note (envelopes and LFOs). This subroutine is called in play_note.
; expects channel index in X and timbre index in Y
; doesn't preserve X and Y
retrigger_note:
   ; initialize envelopes
   ; x: starts as voice index, becomes env1, env2, env3 sublattice offset by addition of N_VOICES
   ; ZP variable: is set to n_envs
   ; y: counter (and timbre index before that)
   rn_number = mzpbb
   phx
   phy
   lda timbres::Timbre::n_envs, y
   sta rn_number
   ldy #0
@loop_envs:
   ; set envelope levels/phases to 0 (phase is both)
   stz Voice::env::phaseL, x
   stz Voice::env::phaseH, x
   ; figure out if envelope is active. If yes, set step to 1, if not set it to 0
   cpy rn_number ;   if index<n_envs, env is active, i.e. if carry clear (that means, y<mzpba)
   bcc :+
   stz Voice::env::step, x
   bra :++
:  lda #1
   sta Voice::env::step, x
:  ; advance x offset and y counter
   txa
   clc
   adc #N_VOICES
   tax
   iny
   cpy #MAX_ENVS_PER_VOICE
   bne @loop_envs

   ; restore x and y
   ply
   plx

   ; initialize LFOs
   ; x: starts as voice index, becomes lfo1, lfo2, lfo3 sublattice offset by addition of N_VOICES
   ; y: starts as timbre index, becomes lfo1, lfo2, lfo3 sublattice offset by addition of N_TIMBRES
@reset_lfos:
   lda timbres::Timbre::n_lfos, y
   beq @skip_lfos   ; for now we skip only if there are NO LFOs active. should be fine tho, because initializing unused stuff doesn't hurt
@loop_lfos:
   ; figure out if lfo is retriggered. If yes, reset phase
   ; TODO: if it's an SnH LFO, get a random initial phase from entropy_get (KERNAL routine) if not retriggered
   lda timbres::Timbre::lfo::retrig, y
   beq @advance_lfo
   ; set lfo phase
   lda timbres::Timbre::lfo::offs, y
   sta Voice::lfo::phaseH, x
   stz Voice::lfo::phaseL, x

@advance_lfo:  ; advance x and y offset
   txa
   clc
   adc #N_VOICES
   tax
   tya
   clc
   adc #N_TIMBRES
   tay
   cpx #(MAX_LFOS_PER_VOICE*N_VOICES) ; a bit wonky ... but should do.
   bcc @loop_envs

@skip_lfos:
rts

; checks if there are enough oscillators available
; and, in that case, reserves them for the neq voice.
; expects channel index in X, timbre index in Y
; returns A=1 if successful, A=0 otherwise (zero flag set accordingly)
; doesn't preserve X and Y
start_note:
   stn_loop_counter = mzpbb
   lda Oscmap::nfo
   cmp timbres::Timbre::n_oscs, y ; carry is set if nfo>=non (number of oscillators needed)
   bcs :+
   jmp @unsuccessful    ; if there's no oscillator left, don't play
   ; get oscillators from and update free oscillators ringlist
   ; x: offset in voice data
   ; y: offset in freeosclist (but first, it is timbre index)
:  lda timbres::Timbre::n_oscs, y
   sta stn_loop_counter
@loop_osc:
   ; get oscillator from list and put it into voice data
   ldy Oscmap::ffo
   lda Oscmap::freeosclist, y
   sta Voice::osc_psg_map, x
   ; advance indices
   txa
   clc
   adc #N_VOICES
   tax
   ADVANCE_FOL_POINTER Oscmap::ffo
   dec Oscmap::nfo
   dec stn_loop_counter
   bne @loop_osc

   lda #1
   rts
@unsuccessful:
   lda #0
rts

; This subroutine deactivates the voice on a given channel and
; releases the oscillators occupied by it, so that they can be used by other notes.
; (and also mutes the PSG voices)
; This subroutine can be called from within the ISR, or from the main program.
; To ensure that the variables used by this function aren't messed up by the ISR,
; SEI has to be done before this function is called in the main program.
; This subroutine does not check if the note is actually playing!
; It needs to be guaranteed by the context where it is called.
; X: channel of note
; doesn't preserve X and Y
stop_note:
   ; update freeosclist
   ; get oscillators from voice and put them back into free oscillators ringlist
   ; x: offset in voice data
   ; y: offset in freeosclist (but first, it is timbre index)
   spn_loop_counter = mzpbe ; e and not b because it is also called from within synth_tick
   ldy Voice::timbre, x
   stz Voice::active, x
   lda timbres::Timbre::n_oscs, y
   sta spn_loop_counter
@loop_osc:
   ; get oscillator from voice and put it into ringlist
   ldy Oscmap::lfo
   lda Voice::osc_psg_map, x
   sta Oscmap::freeosclist, y
   sei
   VERA_MUTE_VOICE_A
   cli
   ; advance indices
   txa
   clc
   adc #N_VOICES
   tax
   ADVANCE_FOL_POINTER Oscmap::lfo
   inc Oscmap::nfo
   dec spn_loop_counter
   bne @loop_osc
rts


; Puts a note into its release phase.
; Basically just puts every envelope into the release phase.
; expects channel of note in X
; doesn't preserve X and Y
release_note:
   rln_env_counter = mzpbb
   ; load timbre number
   ldy Voice::timbre, x
   ; number of active envelopes
   lda timbres::Timbre::n_envs, y
   sta rln_env_counter
@loop_env:
   lda #4
   sta Voice::env::step, x
   ; advance indices
   txa
   clc
   adc #N_VOICES
   tax
   dec rln_env_counter
   bne @loop_env
rts



; stop all voices, should contain a PSG MUTE ALL, as well (TODO)
panic:
   ldx #(N_VOICES-1)
@loop:
   lda Voice::active, x
   beq :+
   phx
   jsr stop_note
   plx
:  dex
   bpl @loop
   jsr init_voices
   ; PSG Mute all
   sei
   ldx #(N_VOICES-1)
@loop2:
   VERA_MUTE_VOICE_X
   dex
   bpl @loop2
   cli
rts




.endscope