; Copyright 2021 Carl Georg Biermann

; This file is part of Concerto.

; Concerto is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;*****************************************************************************


; This file contains the facilities to play notes.
; It can be thought of as an API to tell the synth engine to play and stop notes.

; The subroutines made for being called from outside are:
; init_voices
; play_note
; release_note
; stop_note       - release note puts a note into release phase, whereas stop_note stops it immediately
; panic

; NOTE: synth voices DO NOT correspond to PSG voices.
; Instead, the single oscillators of a synth voice correspond
; to the PSG voices. They are dynamically assigned.
.scope voices



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
   ; corresponding previous timbres that have been loaded onto them.
   ; This is to be able to reuse previously loaded timbres (which saves costly communication with the YM2151 chip)
   freevoicelist: FM_VOICE_BYTE_FIELD
   timbremap:     FM_VOICE_BYTE_FIELD
   ffv:  .byte 0
   lfv:  .byte 0
   nfv:  .byte 0
.endscope

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
   lda #N_TIMBRES ; invalid timbre number ... enforce loading onto the YM2151 (invalid timbre won't get reused)
   sta FMmap::timbremap, x
   dex
   bpl @loop_fm_voices

   stz FMmap::ffv
   stz FMmap::lfv
   lda #N_FM_VOICES
   sta FMmap::nfv

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
   inc ; compensate for max volume being 63, but the synth engine can handle 64. Consequently, volume 0 won't be silent.
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
; expects channel index in X, timbre index in Y (additionally to the note_ variables)
; doesn't preserve X and Y
continue_note:
   cn_slide_distance = mzpbb
   ; check if porta active
   lda timbres::Timbre::porta, y
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
   ldy note_timbre
   MUL8x8_PORTA
   ; set current porta starting point
   stz Voice::pitch_slide::posL, x
   lda Voice::pitch, x
   sta Voice::pitch_slide::posH, x
cn_check_retrigger:
   ; retrigger or continue?
   lda timbres::Timbre::retrig, y
   bne :+
   ; porta ... need to set FM pitch, which doesn't support porta (yet)
   lda note_pitch
   jsr set_fm_note
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
   stz Voice::fm::trigger_loaded, x
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

   ; Check if FM voice is needed
   ldy note_timbre
   lda timbres::Timbre::fm_general::op_en, y
   beq @skip_fm  ; no voice is needed.
   jsr trigger_fm_note
@skip_fm:
   lda #1 ; return successfully
   rts


; checks if there are enough VERA oscillators and FM voices available
; and, in that case, reserves them for the new voice.
; Also resets portamento.
; expects channel index in X, timbre index in Y
; returns A=1 if successful, A=0 otherwise (zero flag set accordingly)
; doesn't preserve X and Y
; This function is used within play_note.
start_note:
   stn_loop_counter = mzpbb
   lda Oscmap::nfo
   cmp timbres::Timbre::n_oscs, y ; carry is set if nfo>=non (number of free oscillators >= number of oscillators needed)
   bcs :+
   jmp @unsuccessful    ; if there's not enough oscillators left, don't play
:  ; check if we need an FM voice
   lda timbres::Timbre::fm_general::op_en, y
   beq :+ ; no FM voice needed -> go ahead initializing the voice
   lda FMmap::nfv ; check if there's an FM voice available
   bne :+
   jmp @unsuccessful ; no FM voice available -> can't play note
:  ; reset portamento
   stz Voice::pitch_slide::active, x
   ; get oscillators from and update free oscillators ringlist
   ; x: offset in voice data
   ; y: offset in freeosclist (but first, it is timbre index)
   lda timbres::Timbre::n_oscs, y
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


   ; FM stuff
   ; Check again if FM voice is needed
   ldy note_timbre
   lda timbres::Timbre::fm_general::op_en, y
   bne :+
   lda #1 ; if no voice is needed, return successfully
   rts
:  ; look for an unused voice that has the same timbre loaded
   lda note_timbre
   ldx FMmap::ffv
@search_timbre:
   cmp FMmap::timbremap, x ; patches that have last been loaded are stored in timbremap
   beq @timbre_found
   inx
   cpx #N_FM_VOICES
   bne :+
   ldx #0
:  cpx FMmap::lfv
   bne @search_timbre
@timbre_not_found:
   ; this is simple. get the next available voice, and load data onto YM2151
   ldx FMmap::ffv
   lda FMmap::freevoicelist, x
   pha
   jsr load_fm_timbre
   pla
   bra @claim_fm_voice
@timbre_found:
   ; More complicated. need to swap things around.
   ; The situation is as follows:
   ;                               v   unused voice with the same timbre loaded as the new note
   ; | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |     (0=unused, 1=used)

   ; We want to move the slots as follows
   ;                   ,-----------,
   ;                   V -> ->  -> |
   ; | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |
   ; so that the unused voice with the correct timbre is right in front of the other used voices,
   ; and the order of the other unused voices has been preserved.

   ; We will do this backwards
   ; We know which timbre the found voice has, so we don't need to save that.
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
   lda FMmap::timbremap, x
   sta FMmap::timbremap, y
   ; loop condition
   cpx FMmap::ffv
   bne @shift_loop
   ; Loop is done, now we can put the appropriate data into the FMmap::ffv'th slot.
   pla ; pull YM2151 voice index

@claim_fm_voice:
   ; the number of the free FM voice is expected in A
   ldx note_channel
   sta Voice::fm_voice_map, x
   dec FMmap::nfv
   ADVANCE_FVL_POINTER FMmap::ffv

   lda #1
   rts
@unsuccessful:
   lda #0
   rts



useless_subroutine:
   ; minimal set of setup to get a tone (except key on)
   SET_YM YM_RL_FL_CON, %01000111 ; all parallel setup
   SET_YM YM_TL, 0 ; max volume
   SET_YM YM_KC, $50
   SET_YM YM_KS_AR, 63
   ; additional stuff
   SET_YM YM_AMS_EN_D1R, 15
   SET_YM YM_D1L_RR, %11111011
   SET_YM YM_DT2_D2R, %00000011
   SET_YM YM_KON, %0000000 ; key off to safely retrigger the note
   SET_YM YM_KON, %1111000




; This subroutine deactivates the voice on a given channel and
; releases the oscillators occupied by it, so that they can be used by other notes.
; (and also mutes the PSG and FM voices)
; This subroutine can be called from within the ISR, or from the main program.
; To ensure that the variables used by this function aren't messed up by the ISR,
; SEI has to be done before this function is called in the main program.
; r0L: channel of note
; doesn't preserve X and Y
stop_note:
   ldx note_channel
   ; check if note is active. If not, return.
   lda Voice::active, x
   bne :+
   rts
:
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
   ; no sei/cli before/after this because: if stop_note is called from within the ISR it's unnecessary. if it's called from the main program, the whole rutine call needs to be braced by sei-cli
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
   
   ; do FM stuff
   ; check if FM was used
   ldx note_channel
   ldy Voice::timbre, x
   lda timbres::Timbre::fm_general::op_en, y
   bne :+
   rts
:  ; FM was used
   ; FM key off
   lda #YM_KON
   ldy Voice::fm_voice_map, x
   jsr write_ym2151
   ; immediately mute voice by setting to minimal volume
   ldx note_channel
   lda Voice::fm_voice_map, x
   clc
   adc #YM_TL
   ldy #%01111111
   jsr write_ym2151
   adc #8
   jsr write_ym2151
   adc #8
   jsr write_ym2151
   adc #8
   jsr write_ym2151

   ; release FM resources
   ADVANCE_FVL_POINTER FMmap::lfv
   tay
   lda Voice::fm_voice_map, x
   sta FMmap::freevoicelist, y
   lda Voice::timbre, x
   sta FMmap::timbremap, y
   inc FMmap::nfv

   rts


; Puts a note into its release phase.
; Basically just puts every envelope into the release phase.
; expects channel of note in r0L
; doesn't preserve X and Y
release_note:
   rln_env_counter = mzpbb
   ldx note_channel
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

   ; FM key off
   lda timbres::Timbre::fm_general::op_en, y
   bne :+
   rts
:  ldx note_channel
   lda #YM_KON
   ldy Voice::fm_voice_map, x
   jsr write_ym2151
   rts




; stop all voices (aka panic off)
panic:
   ldx #(N_VOICES-1)
@loop:
   lda Voice::active, x
   beq :+
   phx
   stx note_channel
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


; set slide position
; parameters according to labels in concerto_synth.asm
; if slide was inactive beforehand, it is activated and its rate set to 0
; if position is set to 255, it will automatically set the slide position to
; the note that was originally played.
set_pitchslide_position:
   ldx note_channel
   lda pitchslide_position_note
   cmp #255
   bne :+
@reset:
   lda Voice::pitch, x
   sta Voice::pitch_slide::posH, x
   stz Voice::pitch_slide::posL, x
   beq :++
@normal:
:  sta Voice::pitch_slide::posH, x
   lda pitchslide_position_fine
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
set_pitchslide_rate:
   ldx note_channel
   lda pitchslide_rate_fine
   sta Voice::pitch_slide::rateL, x
   lda pitchslide_rate_note
   sta Voice::pitch_slide::rateH, x
   lda Voice::pitch_slide::active, x
   bne :+
   lda Voice::pitch, x
   sta Voice::pitch_slide::posH, x
   stz Voice::pitch_slide::posL, x
:  lda #3
   sta Voice::pitch_slide::active, x
   rts



.endscope