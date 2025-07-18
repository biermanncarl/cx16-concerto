; Copyright 2021-2022 Carl Georg Biermann


; This file contains the facilities to play notes.
; It can be thought of as an API to tell the synth engine to play and stop notes.

; The subroutines made for being called from outside are:
; init_voices
; play_note
; release_note
; stop_note       - release note puts a note into release phase, whereas stop_note stops it immediately
; panic
; TODO: add pitch slide, vibrato and volume routines here

; NOTE: synth voices DO NOT correspond to PSG voices.
; Instead, the single oscillators of a synth voice correspond
; to the PSG voices. They are dynamically assigned.
.scope voices



; These data fields correspond to the 16 monophonic voices.
; Each voice can be active or inactive.
; Active voices can be overridden by new play events.
.scope Voice
   active:    VOICE_BYTE_FIELD   ; on/off

   ; general
   pitch:     VOICE_BYTE_FIELD
   instrument:    VOICE_BYTE_FIELD   ; which synth instrument to use

   ; volume
   .scope vol
      volume:     VOICE_BYTE_FIELD   ; voice's volume can be modified in real time. 128 is full volume, everything below is more quiet.
      volume_low: VOICE_BYTE_FIELD   ; sublevels of volume, only relevant when working with slopes
      slope:      VOICE_BYTE_FIELD   ; 0 is inactive, positive numbers go up, negative numbers go down
      threshold:  VOICE_BYTE_FIELD   ; the threshold up to which the slope will last
   .endscope

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
      phaseS:  LFO_VOICE_BYTE_FIELD ; sample index, only used for Sample and Hold
   .endscope

   ; PSG voices (synth oscillator to PSG oscillator mapping) and FM voices (synth voice to YM2151 voice mapping)
   osc_psg_map:   OSCILLATOR_VOICE_BYTE_FIELD
   fm_voice_map:  VOICE_BYTE_FIELD

   .scope fm
      trigger_loaded:   VOICE_BYTE_FIELD  ; true if FM voice shall be triggered in the next synth tick. (usually the first tick of a voice)
   .endscope

   ; pitch slide (either for pitchbend or portamento)
   .scope pitch_slide
      active:  VOICE_BYTE_FIELD   ; is porta still going? 0 if inactive, 1 if going up, 2 if going down, 3 if free slide (no aimed for note)
      rateL:   VOICE_BYTE_FIELD   ; unsigned rate (fine, note)
      rateH:   VOICE_BYTE_FIELD
      posL:    VOICE_BYTE_FIELD   ; current position in slide (fine, note). Overwrites note as long as active
      posH:    VOICE_BYTE_FIELD
   .endscope

   ; vibrato settings, overrides the vibrato setting of the instrument
   .scope vibrato
      current_level: VOICE_BYTE_FIELD ; refers to vibrato lookup-table, 128 or higher means inactive
      ticks:         VOICE_BYTE_FIELD ; current "vibrato tick" countdown until the next vibrato level
      slope:         VOICE_BYTE_FIELD ; how many "vibrato ticks" per "synth tick" are counted?
      threshold_level:     VOICE_BYTE_FIELD ; this is where the slope stops
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

.scope FMmap
   ; information about which FM voices are free

   ; ringlist of available FM voices and another list with their
   ; corresponding previous instruments that have been loaded onto them.
   ; This is to be able to reuse previously loaded instruments (which saves costly communication with the YM2151 chip)
   freevoicelist: FM_VOICE_BYTE_FIELD
   instrumentmap:     FM_VOICE_BYTE_FIELD
   ffv:  .byte 0 ; this is the next (first) free voice (as long as there is at least one) in the ring list
   lfv:  .byte 0 ; this points one past the last free voice, or to the first used voice as long as there is at least one being used
   nfv:  .byte 0
.endscope

last_fm_lfo_instrument: .byte 255 ; which instrument's LFO parameters were uploaded most recently

; advance free-oscillators-list pointer
.macro ADVANCE_FOL_POINTER adv_fol_ptr
   lda adv_fol_ptr
   ina
   cmp #(N_OSCILLATORS)
   bcc :+
   lda #0
:  sta adv_fol_ptr
.endmacro

; advance free-FM-voices-list pointer
.macro ADVANCE_FVL_POINTER adv_fvl_ptr
   lda adv_fvl_ptr
   ina
   cmp #(N_FM_VOICES)
   bcc :+
   lda #0
:  sta adv_fvl_ptr
.endmacro


.include "ym2151_interface.asm"


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

   ; init free-fm-voice-list
   ldx #(N_FM_VOICES-1)
@loop_fm_voices:
   txa
   sta FMmap::freevoicelist, x
   lda #N_INSTRUMENTS ; invalid instrument number ... enforce loading onto the YM2151 (invalid instrument won't get reused)
   sta FMmap::instrumentmap, x
   dex
   bpl @loop_fm_voices

   stz FMmap::ffv
   stz FMmap::lfv
   lda #N_FM_VOICES
   sta FMmap::nfv

   rts



; Plays a note. needs info for voice number, instrument, pitch and volume.
; Can be called from within the ISR and the main program.
; In this subroutine, register X usually contains the index of the voice.
; What exactly does this routine do?
; If no note is currently active on the voice, it plays a new note with retriggering envelopes,
; and retriggering LFOs as specified in the instrument settings, provided there are enough oscillators
; available.
; If a note is currently active on the voice, the action depends on whether it is the same instrument or not.
; If it's the same instrument, retrigger and portamento are applied as specified in the instrument settings.
; If it's a different instrument, the old note is replaced entirely (just as if there was no note played previously).
play_note:
   php
   sei
   ldx note_voice
   ldy note_instrument
   inc ; compensate for max volume being 63, but the synth engine can handle 64. Consequently, volume 0 won't be silent.
   sta Voice::vol::volume, x
   ; check if there is an active note on the voice
   lda Voice::active, x
   beq @new_note
@existing_note:
   ; check if it's the same instrument
   lda Voice::instrument, x
   cmp note_instrument
   beq @same_instrument
@different_instrument:
   jsr stop_note
   ldx note_voice
   ldy note_instrument
   bra @new_note
@same_instrument:
   jsr continue_note
   bra @common_stuff
@new_note:
   jsr start_note
   ; check if starting note was successful (unsuccessful if there weren't enough oscillators available)
   beq @skip_play
   ldx note_voice
   ldy note_instrument
   jsr retrigger_note
@common_stuff:
   ; the stuff that is always done.
   ldx note_voice
   lda note_pitch
   sta Voice::pitch, x
   lda note_instrument
   sta Voice::instrument, x
   ; activate note
   lda #1
   sta Voice::active,x
   ; re-upload global FM LFO parameters if needed
   ldx note_instrument
   lda instruments::Instrument::fm_general::lfo_enable, x
   beq @skip_play ; FM LFO disabled
   cpx last_fm_lfo_instrument
   beq @skip_play ; same instrument
   stx last_fm_lfo_instrument
   jsr updateLfo
@skip_play:
   plp
   rts

; This subroutine is used in play_note in the case that a note with the same instrument as played is
; still active on the voice. It does all the stuff specific to that case.
; expects voice index in X, instrument index in Y (additionally to the note_ variables)
; doesn't preserve X and Y
continue_note:
   cn_slide_distance = mzpbe
   ; check if porta active
   lda instruments::Instrument::porta, y
   bne @setup_porta
@no_porta:
   stz Voice::pitch_slide::active, x
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
   sta Voice::pitch_slide::active, x ; up or down
   ; determine porta rate
   ldy note_instrument
   MUL8x8_PORTA
   ; set current porta starting point
   stz Voice::pitch_slide::posL, x
   lda Voice::pitch, x
   sta Voice::pitch_slide::posH, x
cn_check_retrigger:
   ; retrigger or continue?
   lda instruments::Instrument::retrig, y
   beq :+
   ; do retrigger
   jsr retrigger_note
   rts
:  ; if not retriggered, we still need to update the FM volume
   lda instruments::Instrument::fm_general::op_en, y
   beq :+
   jsr set_fm_voice_volume
:  rts


; retriggers note (envelopes and LFOs). This subroutine is called in play_note.
; expects voice index in X and instrument index in Y
; doesn't preserve X and Y
retrigger_note:
   ; initialize envelopes
   ; x: starts as voice index, becomes env1, env2, env3 sublattice offset by addition of N_VOICES
   ; ZP variable: is set to n_envs
   ; y: counter (and instrument index before that)
   rn_number = mzpbe
   stz Voice::fm::trigger_loaded, x
   stz Voice::vol::slope, x
   phx
   phy
   lda instruments::Instrument::n_envs, y
   sta rn_number
   ldy #0
@loop_envs:
   ; set envelope levels/phases to 0 (phase is both)
   stz Voice::env::phaseL, x
   stz Voice::env::phaseH, x
   ; figure out if envelope is active. If yes, set step to 1, if not set it to 0
   cpy rn_number ;   if index<n_envs, env is active, i.e. if carry clear (that means, y<rn_number)
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
   ; y: starts as instrument index, becomes lfo1, lfo2, lfo3 sublattice offset by addition of N_INSTRUMENTS
@reset_lfos:
   lda instruments::Instrument::n_lfos, y
   beq @skip_lfos   ; for now we skip only if there are NO LFOs active. should be fine tho, because initializing unused stuff doesn't hurt
@loop_lfos:
   ; figure out if lfo is retriggered. If yes, reset phase
   lda instruments::Instrument::lfo::retrig, y
   beq @advance_lfo
   ; set lfo phase
   lda instruments::Instrument::lfo::wave, y
   cmp #4 ; SnH?
   bne @periodic_lfo
   @snh:
      lda instruments::Instrument::lfo::offs, y
      sta Voice::lfo::phaseS, x
      stz Voice::lfo::phaseH, x
      bra @endif
   @periodic_lfo:
      lda instruments::Instrument::lfo::offs, y
      sta Voice::lfo::phaseH, x
@endif:
   stz Voice::lfo::phaseL, x

@advance_lfo:  ; advance x and y offset
   txa
   clc
   adc #N_VOICES
   tax
   tya
   clc
   adc #N_INSTRUMENTS
   tay
   cpx #(MAX_LFOS_PER_VOICE*N_VOICES) ; a bit wonky ... but should do.
   bcc @loop_envs
@skip_lfos:

   ; Check if FM voice is needed
   ldy note_instrument
   lda instruments::Instrument::fm_general::op_en, y
   beq @skip_fm  ; no voice is needed.
   jsr set_fm_voice_volume
   ldx note_voice
   lda #1
   sta Voice::fm::trigger_loaded, x
@skip_fm:
   lda #1 ; return successfully
   rts


; Checks if there are currently enough oscillators available for a voice of specified instrument.
; Expects instrument index in Y
; If resources are available, carry will be set. Clear otherwise.
; Preserves .Y and .X
.proc checkOscillatorResources
   lda Oscmap::nfo
   cmp instruments::Instrument::n_oscs, y ; carry is set if nfo>=non (number of free oscillators >= number of oscillators needed)
   bcs :+
   rts ; if there's not enough oscillators left, don't play
:  ; check if we need an FM voice
   lda instruments::Instrument::fm_general::op_en, y
   beq :+ ; no FM voice needed -> enough resources are available
   lda FMmap::nfv ; check if there's an FM voice available
   bne :+ ; FM voice is available -> enough resources are available
   clc
   rts
:  sec
   rts
.endproc


; Reserves VERA oscillators and FM voices for a new note.
; Also resets portamento and vibrato.
; expects voice index in X, instrument index in Y
; returns A=1 if successful, A=0 otherwise (zero flag set accordingly)
; doesn't preserve X and Y
; This function is used within play_note.
start_note:
   stn_loop_counter = mzpbe
   jsr checkOscillatorResources
   bcs :+
   jmp @unsuccessful
:  ; reset portamento and vibrato
   stz Voice::pitch_slide::active, x
   lda #128
   sta Voice::vibrato::current_level, x
   ; get oscillators from and update free oscillators ringlist
   ; x: offset in voice data
   ; y: offset in freeosclist (but first, it is instrument index)
   lda instruments::Instrument::n_oscs, y
   beq @end_loop_osc
   sta stn_loop_counter
@loop_osc:
   ; get oscillator from list and put it into voice data
   .ifdef ::concerto_enable_zsound_recording
      ; For ZSM recording, we want the lowest voice index possible.
      ; This causes songs that don't use all VERA voices to not "spill" all over VERA.
      ; Moreover, the resulting ZSMs tend to be a little smaller, and the Melodius visualizations
      ; a little easier on the eye.
      ;
      ; Get index of next voice in the ring list.
      ldy Oscmap::ffo
      lda Oscmap::freeosclist, y
      ; Find lowest free VERA voice.
      ; .A contains the lowest free voice index found so far.
      ; .Y contains the current ring list index
      @find_lowest_vera_loop:
         ; Advance .Y to the next entry in the ring list
         iny
         cpy #N_OSCILLATORS
         bne :+
         ldy #0
      :  ; Check if we have already checked all free oscillators
         cpy Oscmap::lfo
         beq @find_lowest_vera_loop_end
         ; Check if the current oscillator has lower index than the previously selected one
         cmp Oscmap::freeosclist, y
         bcc @find_lowest_vera_loop ; nope, previous VERA voice was lower
         ; yes, current VERA voice is lower --> swap
         phx
         ldx Oscmap::ffo
         pha ; save higher voice
         ; copy lower voice to first ringlist slot
         lda Oscmap::freeosclist, y
         sta Oscmap::freeosclist, x
         ; copy higher voice to current ringlist slot
         pla
         sta Oscmap::freeosclist, y
         ; Load lower voice into .A
         lda Oscmap::freeosclist, x
         plx
         bra @find_lowest_vera_loop
      @find_lowest_vera_loop_end:
   .endif
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
@end_loop_osc:

   ; FM stuff
   ; Check again if FM voice is needed
   ldy note_instrument
   lda instruments::Instrument::fm_general::op_en, y
   bne :+
   lda #1 ; if no voice is needed, return successfully
   rts
:  ; look for an unused voice that has the same instrument loaded
   lda note_instrument
   ldx FMmap::ffv
@search_instrument:
   cmp FMmap::instrumentmap, x ; instruments that have been loaded are stored in instrumentmap
   beq @instrument_found
   inx
   cpx #N_FM_VOICES
   bne :+
   ldx #0
:  cpx FMmap::lfv
   bne @search_instrument
@instrument_not_found:
   ; this is simple. get the next available voice, and load data onto YM2151
   ldx FMmap::ffv
   lda FMmap::freevoicelist, x
   pha
   jsr load_fm_instrument
   pla
   bra @claim_fm_voice
@instrument_found:
   ; First check if the instrument found is actually in the next avialable voice.
   ; in this case, we doe the same as in the case the instrument was not found,
   ; only we do not load the instrument onto the YM2151.
   cpx FMmap::ffv
   bne @rotate_voices
   lda FMmap::freevoicelist, x
   bra @claim_fm_voice
@rotate_voices:
   ; More complicated. need to swap things around.
   ; The situation is as follows:
   ;                               v   unused voice with the same instrument loaded as the new note
   ; | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |     (0=unused, 1=used)

   ; We want to move the slots as follows
   ;                   ,-----------,
   ;                   V -> ->  -> |
   ; | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |
   ; so that the unused voice with the correct instrument is right in front of the other used voices,
   ; and the order of the other unused voices has been preserved.

   ; We will do this backwards
   ; We know which instrument the found voice has, so we don't need to save that.
   ; But we do need to save the voide index.
   lda FMmap::freevoicelist, x
   pha
   ; Now loop backwards
@shift_loop:
   ; copy X to Y
   txa
   tay
   ; advance X backwards
   dex
   bpl :+
   ldx #(N_FM_VOICES-1)
:  ; move data
   lda FMmap::freevoicelist, x
   sta FMmap::freevoicelist, y
   lda FMmap::instrumentmap, x
   sta FMmap::instrumentmap, y
   ; loop condition
   cpx FMmap::ffv
   bne @shift_loop
   ; Loop is done, now we can put the appropriate data into the FMmap::ffv'th slot.
   pla ; pull YM2151 voice index

@claim_fm_voice:
   ; the number of the free FM voice is expected in A
   ldx note_voice
   sta Voice::fm_voice_map, x
   dec FMmap::nfv
   ADVANCE_FVL_POINTER FMmap::ffv

   lda #1
   rts
@unsuccessful:
   lda #0
   rts




; This subroutine deactivates the voice on a given voice and
; releases the oscillators occupied by it, so that they can be used by other notes.
; (and also mutes the PSG and FM voices)
; This subroutine can be called from within the ISR, or from the main program.
; Expects note voice in note_voice
; doesn't preserve X and Y
stop_note:
   ldx note_voice
   ; check if note is active. If not, return.
   lda Voice::active, x
   bne :+
   rts
:
   php
   sei
   ; update freeosclist
   ; get oscillators from voice and put them back into free oscillators ringlist
   ; x: offset in voice data
   ; y: offset in freeosclist (but first, it is instrument index)
   spn_loop_counter = mzpbe ; e and not b because stop_note is also called from within synth_tick
   ldy Voice::instrument, x
   stz Voice::active, x
   lda instruments::Instrument::n_oscs, y
   beq @end_loop_osc
   sta spn_loop_counter
@loop_osc:
   ; get oscillator from voice and put it into ringlist
   ldy Oscmap::lfo
   lda Voice::osc_psg_map, x
   sta Oscmap::freeosclist, y
   VERA_MUTE_VOICE_A
   ; advance indices
   txa
   clc
   adc #N_VOICES
   tax
   ADVANCE_FOL_POINTER Oscmap::lfo
   inc Oscmap::nfo
   dec spn_loop_counter
   bne @loop_osc
@end_loop_osc:
   
   ; do FM stuff
   ; check if FM was used
   ldx note_voice
   ldy Voice::instrument, x
   lda instruments::Instrument::fm_general::op_en, y
   bne :+
   plp
   rts
:  ; FM was used
   ; FM key off
   lda #YM_KON
   ldy Voice::fm_voice_map, x
   jsr write_ym2151
   ; immediately mute voice by setting to minimal volume
   ldx note_voice
   lda Voice::fm_voice_map, x
   clc
   adc #YM_TL
   ldy #%01111111
   jsr write_ym2151
   clc
   adc #8
   jsr write_ym2151
   clc
   adc #8
   jsr write_ym2151
   clc
   adc #8
   jsr write_ym2151

   ; release FM resources
   ldy FMmap::lfv
   ; put the YM2151 voice back into the ringlist
   lda Voice::fm_voice_map, x
   sta FMmap::freevoicelist, y
   ; remember which instrument was played so that we may not need to reload it
   lda Voice::instrument, x
   sta FMmap::instrumentmap, y
   ; advance the pointer of the first used voice
   ADVANCE_FVL_POINTER FMmap::lfv
   ; increment available voices
   inc FMmap::nfv
   plp
   rts


; Puts a note into its release phase.
; Basically just puts every envelope into the release phase.
; expects voice of note in note_voice
; doesn't preserve X and Y
release_note:
   rln_env_counter = mzpbe
   php
   sei
   ldx note_voice
   ; load instrument number
   ldy Voice::instrument, x
   ; number of active envelopes
   lda instruments::Instrument::n_envs, y
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

   ; FM key off
   lda instruments::Instrument::fm_general::op_en, y
   bne :+
   plp
   rts
:  ldx note_voice
   lda #YM_KON
   ldy Voice::fm_voice_map, x
   jsr write_ym2151
   plp
   rts




; stop all voices (aka panic off)
panic:
   php
   sei
   ldx #(N_VOICES-1)
@loop:
   lda Voice::active, x
   beq :+
   phx
   stx note_voice
   jsr stop_note
   plx
:  dex
   bpl @loop
   jsr init_voices
   ; PSG Mute all
   ldx #(N_VOICES-1)
@loop2:
   VERA_MUTE_VOICE_X
   dex
   bpl @loop2
   plp
   rts


; set slide position
; parameters according to labels in concerto_synth.asm
; if slide was inactive beforehand, it is activated and its rate set to 0
; if position is set to 255, it will automatically set the slide position to
; the note that was originally played.
; Expects voice in .X, coarse position in .A, fine position in .Y
set_pitchslide_position:
   cmp #255
   bne :+
@reset:
   lda Voice::pitch, x
   sta Voice::pitch_slide::posH, x
   stz Voice::pitch_slide::posL, x
   beq :++
@normal:
:  sta Voice::pitch_slide::posH, x
   tya
   sta Voice::pitch_slide::posL, x
:  ; check if slide was active beforehand
   ; if yes, keep it going with the previously set slide rate (i.e. do nothing)
   ; if not, activate it and set slide rate to 0   
   lda Voice::pitch_slide::active, x
   bne :+
   lda #3
   sta Voice::pitch_slide::active, x
   stz Voice::pitch_slide::rateL, x
   stz Voice::pitch_slide::rateH, x
:  rts

; set slide rate
; parameters according to labels in concerto_synth.asm
; if slide has been inactive, activate and set slide position to the original note
; The slide stops when it reaches the originally played note.
; Expects voice in .X, coarse position in .Y, fine position in .A, mode in pitchslide_mode
set_pitchslide_rate:
   sta Voice::pitch_slide::rateL, x
   tya
   sta Voice::pitch_slide::rateH, x
   lda Voice::pitch_slide::active, x
   bne :+
   lda Voice::pitch, x
   sta Voice::pitch_slide::posH, x
   stz Voice::pitch_slide::posL, x
:  ; activate slide and set the mode
   lda pitchslide_mode
   beq @free_slide
@bounded_slide:
   ; check whether we're going up or down
   lda Voice::pitch_slide::rateL, x
   bmi :+
   ; going up
   lda #1
   bra :++
:  ; going down
   lda #2
:  sta Voice::pitch_slide::active, x
   rts
@free_slide:
   lda #3
   sta Voice::pitch_slide::active, x
   rts


; set vibrato amount
; If vibrato was inactive before, it gets activated by this subroutine.
; Expects voice in .X, amount in .A
set_vibrato_amount:
   cmp #0
   bne @activate
@inactivate:
   lda #128
   sta Voice::vibrato::current_level, x
   rts
@activate:
   dec ; amount 1 actually means 0+MINIMAL_VIBRATO_DEPTH
   sta Voice::vibrato::current_level, x
   stz Voice::vibrato::slope, x
   lda #1
   sta Voice::vibrato::ticks, x
   rts

; set vibrato slope
; If vibrato was inactive before, it gets activated by this subroutine
; note voice: .X
; slope: .A
; max level: .Y
set_vibrato_ramp:
   sta Voice::vibrato::slope, x
   tya
   dec ; shift maximum amount to zero-based (instead of 1-based, i.e. range 0-26 internal instead of 1-27 user)
   ; the edge-case where the user might want to set 0 as the lower threshold for a downward slope must be considered. Then we get 255 as threshold.
   sta Voice::vibrato::threshold_level, x
   stz Voice::vibrato::ticks, x
   lda Voice::vibrato::current_level, x
   bpl :+
   stz Voice::vibrato::current_level, x ; reset to zero when inactive previously
:  rts


; set note volume
; voice: .X
; volume: .A
; affects: .A, .X, .Y
set_volume:
   php
   sei
   inc ; put volume into range 1 to 64
   sta Voice::vol::volume, x
   stz Voice::vol::volume_low, x
   lda Voice::active, x
   beq :+ ; skip FM part if voice is inactive
   ldy Voice::instrument, x
   lda instruments::Instrument::fm_general::op_en, y
   beq :+ ; skip FM part if FM part is inactive
   stx note_voice
   jsr voices::set_fm_voice_volume
:  plp
   rts


; set volume ramp (lasts until the threshold is hit, or until the next retrigger event)
; voice: .X
; slope: .A
; threshold: .Y
set_volume_ramp:
   ; First, we need to left rotate .A four times before we store it,
   ; because that is the format that the slope calculation expects.
   clc
   rol
   adc #0
   rol
   adc #0
   rol
   adc #0
   rol
   adc #0
   sta Voice::vol::slope, x
   tya
   inc
   sta Voice::vol::threshold, x
   stz Voice::vol::volume_low, x
   rts



.endscope