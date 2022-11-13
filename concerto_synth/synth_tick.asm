; Copyright 2021-2022 Carl Georg Biermann


; This file contains the code that is executed in each tick
; All the updating of the PSG voices is done here.

.scope synth_engine

; Synth Tick variables
voi_pitch:     .byte 0
voi_fine:      .byte 0
voi_volume:    .byte 0
osc_pitch:     .byte 0
osc_fine:      .byte 0
osc_freq:      .word 0
osc_volume:    .byte 0
osc_wave:      .byte 0
osc_pw:        .byte 0
osc_panmute:   .byte 0



; MODULATION DEPTH NUMBER FORMAT
; ------------------------------
; Modulation depths have different formats.
; PWM and volume modulation are adjusted by a number of the following format:
; SMMMMMMM
; where S is the sign of the modulation, and MMMMMMM is a 7 bit value defining
; the magnitude of the modulation depth. 64 aka 1000000 is full modulation
; depth, i.e. the modulation source is added to the destination with a 
; prefactor of 1. However, you can go up to 127 aka 1111111 (at your own risk!)

; The scale5 format is used for pitch modulation (see scale5.asm)

; MODULATION SOURCE NUMBER FORMAT
; -------------------------------
; Modulation sources are always binary and consist of two bytes:
; A high byte and a low byte
; There are unipolar and bipolar sources.
; The low byte can have any desired value
; The high byte can range from 0 to 127 on unipolar sources.
; On bipolar sources, it is allowed to range from 0 to 64 (or 63?) (doesn't matter)
; and bit 7 is the sign of the modulation.

; modulation sources, indexed
; available: env1, env2, env3, lfo1
; maybe later: gate, wavetable, MSEG, modwheel
.define N_MODSOURCES MAX_ENVS_PER_VOICE+MAX_LFOS_PER_VOICE
voi_modsourcesL:
   .repeat N_MODSOURCES
      .byte 0
   .endrepeat
voi_modsourcesH:
   .repeat N_MODSOURCES
      .byte 0
   .endrepeat



; ZERO PAGE USAGE
; ***************
; give zero page variables more understandable names
; mzpbb stays constant throughout the whole voice being processed (voice index)
; mzpbc and mzpbd are reused per code section
; mzpbf is reserved for multiplications
; mzpbe is used for all modulation sources, but is reused afterwards, and is also used in all voice-handling subroutines
voice_index = mzpbb
; envelopes
env_counter = mzpbc
n_envs      = mzpbd
; mzpbe is used in the envelopes section indirectly, through the stop_note subroutine
; LFOs
lfo_counter = mzpbc
bittest     = mzpbd  ; for Sample and Hold RNG
; all modulation sources
modsource_index = mzpbe ; keeps track of which modsource we're processing
; volume slope
;     mzpbc and mzpbd are used during setting the volume of the FM voice
; vibrato
threshold_level = mzpbc
slope = mzpbd
; FM
keycode     = mzpbc
; PSG Oscillators
osc_counter = mzpbc
n_oscs      = mzpbd
osc_offset = mzpbe




synth_tick:
   ; loop over synth voices, counting down from 15 to 0
   ; x: voice index
   ldx #N_VOICES
next_voice:
   dex
   bpl :+
   jmp end_synth_tick
:  ; check if voice active
   lda voices::Voice::active, x
   beq next_voice

   ; setup zero page variables
   ; voice index is in register X
   stx voice_index ; needed? yes, if X is used for something else, this is the backup
   stz modsource_index


   ; -----------------------
   ; -----------------------
   ; - ENVELOPE GENERATORS -
   ; -----------------------
   ; -----------------------

   ; This section of code updates all active ADSR envelopes.

   ; step = 0 means inactive (either not started or already finished) 
   ; When the envelope is inactive, phase has to be 0 for reference,
   ; since the envelope amplitude is in "phase".
   ; (If phase wasn't 0 when the envelope is inactive, it would yield a nonzero modulation
   ; to everything the envelope is assigned to)
   
   ; step legend:
   ; 0 - inactive
   ; 1 - attack phase
   ; 2 - decay phase
   ; 3 - sustain phase
   ; 4 - release phase

   ; load timbre index into register Y ... this will function as the indexing 
   ; offset to access the correct envelope data.
   ; it will be advanced by N_TIMBRES steps in order to access envelope fields
   ; in the Timbre data.
   ldy voices::Voice::timbre, x
   ; A similar thing will be done with the X register. It will be advanced by
   ; N_VOICES in order to access envelope fields in the Voice data.
   ; setup loop counter
   lda timbres::Timbre::n_envs, y
   sta n_envs
   dec
next_env:
   bpl :+
   jmp end_env
:  sta env_counter

   ; actual envelope logic
   ; ---------------------
   lda voices::Voice::env::step, x ; get current envelope stage
   bne :+   ; step = 0 means inactive
   jmp advance_env
:  ; choose envelope stage
   asl ; could save two cycles per envelope if we set the steps to only even numbers.
   phx
   tax
   jmp (@jmp_tbl-2, x)
@jmp_tbl:
   .word env_do_attack
   .word env_do_decay
   .word env_do_sustain
   .word env_do_release
env_do_attack:
   plx
   ; add attack rate to phase
   clc
   lda timbres::Timbre::env::attackL, y
   adc voices::Voice::env::phaseL, x
   sta voices::Voice::env::phaseL, x
   lda timbres::Timbre::env::attackH, y
   adc voices::Voice::env::phaseH, x
   sta voices::Voice::env::phaseH, x
   ; high byte still in accumulator after addition
   cmp #ENV_PEAK ; this is the threshold for when attack stage is done
   bcc advance_env ; if 64 is still larger than high byte, we're still in attack phase, and therefore done for now
   ; otherwise, advance to next stage:
   inc voices::Voice::env::step, x
   lda #ENV_PEAK
   sta voices::Voice::env::phaseH, x
   stz voices::Voice::env::phaseL, x
   jmp advance_env
env_do_decay:
   plx
   ; subtract decay rate from phase
   sec
   lda voices::Voice::env::phaseL, x
   sbc timbres::Timbre::env::decayL, y
   sta voices::Voice::env::phaseL, x
   lda voices::Voice::env::phaseH, x
   sbc timbres::Timbre::env::decayH, y
   sta voices::Voice::env::phaseH, x
   ; high byte still in accumulator after subtraction, and flags set according to subtraction
   ; first thing that needs to be checked, is for overflow during subtraction (especially for low sustain levels and/or high decay rates)
   bcc @transition_into_sustain
   ; compare to sustain level and check if we've arrived.
   cmp timbres::Timbre::env::sustain, y
   bcs advance_env
   ; advance to sustain stage. Set sustain level.
@transition_into_sustain:
   inc voices::Voice::env::step, x
   lda timbres::Timbre::env::sustain, y
   sta voices::Voice::env::phaseH, x
   stz voices::Voice::env::phaseL, x
   jmp advance_env
env_do_sustain:
   plx
   ; We don't need to do anything. Correct phase should be set by end of decay (see above).
   ; Release phase will not be triggered from within the synth engine, but from outside,
   ; i.e. by note-off events.
   ; HOWEVER, since we want real-time feedback if the parameter changes,
   ; we do set the phase to the sustain level in every tick.
   lda timbres::Timbre::env::sustain, y
   sta voices::Voice::env::phaseH, x
   stz voices::Voice::env::phaseL, x
   jmp advance_env
env_do_release:
   plx
   ; subtract release rate from phase
   sec
   lda voices::Voice::env::phaseL, x
   sbc timbres::Timbre::env::releaseL, y
   sta voices::Voice::env::phaseL, x
   lda voices::Voice::env::phaseH, x
   sbc timbres::Timbre::env::releaseH, y
   sta voices::Voice::env::phaseH, x
   ; high byte still in accumulator after subtraction, and flags set according to subtraction
   ; finish up envelope if overflow during subtraction (which indicates we've crossed zero)
   bcc env_finish
   jmp advance_env
env_finish:
   ; set step and phase to 0
   ; check if we're in envelope 0 (the master envelope), which upon finishing deactivates the voice
   ; reset envelope
   stz voices::Voice::env::phaseL, x
   stz voices::Voice::env::phaseH, x
   stz voices::Voice::env::step, x

   ; check if this is the master envelope (the first one). If yes, finish up the voice:
   lda n_envs
   sec
   sbc env_counter
   cmp #1
   bne advance_env
   ; if we got to this point, this voice will be deactivated
   ; therefore, the voice data offset in X can be safely discarded, as it is no longer needed
   ; deactivate voice
   ldx voice_index
   stx note_channel
   jsr voices::stop_note
   ldx voice_index
   jmp next_voice

advance_env: ; load phase into modsource and go to next envelope
   ; store phase in mod source array
   phy
   ldy modsource_index
   lda voices::Voice::env::phaseL, x
   sta voi_modsourcesL, y
   lda voices::Voice::env::phaseH, x
   sta voi_modsourcesH, y
   ply
   ; advance modulation source
   inc modsource_index
   ; advance index for Timbre data
   tya
   clc
   adc #N_TIMBRES
   tay
   ; advance index for Voice data
   txa
   clc ; actually redundant, could be left away
   adc #N_VOICES
   tax
   ; advance counter
   lda env_counter
   dec
   jmp next_env

end_env: ; jump here when done with all envelopes
   ldx voice_index ; restore X register
   ; advance modsource index up to position for next modsource in case we didn't get there
   lda #MAX_ENVS_PER_VOICE
   sta modsource_index






   ; -----------
   ; -----------
   ; - L F O s -
   ; -----------
   ; -----------

   ; This section updates the LFOs (it is only one LFO planned ... but I kept the engine general
   ; just incase I change my mind)

   ; X register: starts as voice index, increased by N_VOICES to get to the other LFO voice fields
   ; Y register: starts as timbre index, increased by N_TIMBRES to get to the other LFO timbre fields
   ; once the LFO phase has been incremented, Y is changed to indexing the modsources
   ldy voices::Voice::timbre, x
   lda timbres::Timbre::n_lfos, y
   sta lfo_counter
@loop_lfos:
   ; assumes that the zero flag is set according to a counter counting down from n_lfos
   bne :+
   jmp @end_lfos
:  
   ; select waveform / algorithm
   phx
   lda timbres::Timbre::lfo::wave, y
   asl
   tax
   jmp (@jmp_table, x)
@jmp_table:
   .word @alg_triangle
   .word @alg_square
   .word @ramp_up
   .word @ramp_down
   .word @alg_snh


   ; triangle waveform
   ; modulation rising, if most significant phase bit is 0
   ; modulation falling, if most significant phase bit is 1
@alg_triangle:
   plx
   ; advance phase
   lda voices::Voice::lfo::phaseL, x
   clc
   adc timbres::Timbre::lfo::rateL, y
   sta voices::Voice::lfo::phaseL, x
   lda voices::Voice::lfo::phaseH, x
   adc timbres::Timbre::lfo::rateH, y
   sta voices::Voice::lfo::phaseH, x
   ; check high bit
   bmi @tri_falling
@tri_rising:
   ; accumulator is in the range 0 ... 127
   phy
   ldy modsource_index
   ; adapt the numbering format: shift to range -64 ... 63
   ; and then flip sign if negative
   sec
   sbc #64
   bpl @tri_rising_positive
@tri_rising_negative:
   ; we are in the range %11000000 to %11111111
   ; transform to  range %10111111 to %10000000
   eor #%01111111
   sta voi_modsourcesH, y
   ; invert fine tuning
   lda voices::Voice::lfo::phaseL, x
   eor #%11111111
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos
@tri_rising_positive:
   ; we are in the range %00000000 to %00111111
   ; simply store result in modsource list
   sta voi_modsourcesH, y
   lda voices::Voice::lfo::phaseL, x
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos
@tri_falling:
   ; accumulator is in range 128 ... 255
   phy
   ldy modsource_index
   ; adapt numbering format: shift to range -64 ... 63
   clc
   adc #64
   bmi @tri_falling_positive
@tri_falling_negative:
   ; we are in the range %00000000 to %00111111
   ; put negative sign onto everything
   ora #%10000000
   sta voi_modsourcesH, y
   lda voices::Voice::lfo::phaseL, x
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos
@tri_falling_positive:
   ; we are in the range %11000000 to %11111111
   ; transform to  range %00111111 to %00000000
   eor #%11111111
   sta voi_modsourcesH, y
   ; invert fine tuning
   lda voices::Voice::lfo::phaseL, x
   eor #%11111111
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos



   ; square waveform
   ; modulation is maximal, if most significant phase bit is 0
   ; modulation is minimal, if most significant phase bit is 1
@alg_square:
   plx
   ; advance phase
   lda voices::Voice::lfo::phaseL, x
   clc
   adc timbres::Timbre::lfo::rateL, y
   sta voices::Voice::lfo::phaseL, x
   lda voices::Voice::lfo::phaseH, x
   adc timbres::Timbre::lfo::rateH, y
   sta voices::Voice::lfo::phaseH, x
   ; check high bit
   bmi @squ_high
@squ_low:
   phy
   ldy modsource_index
   lda #(128+63)
   sta voi_modsourcesH, y
   lda #255
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos
@squ_high:
   phy
   ldy modsource_index
   lda #63
   sta voi_modsourcesH, y
   lda #255
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos


   ; ramp up
   ; signal needs to be rightshifted, since otherwise we would get too much amplitude
@ramp_up:
   plx
   ; advance phase
   lda voices::Voice::lfo::phaseL, x
   clc
   adc timbres::Timbre::lfo::rateL, y
   sta voices::Voice::lfo::phaseL, x
   lda voices::Voice::lfo::phaseH, x
   adc timbres::Timbre::lfo::rateH, y
   sta voices::Voice::lfo::phaseH, x
   ; check high bit
   bmi @ramp_up_negative
@ramp_up_positive:
   ; we are in range %00000000 to %01111111
   ; need to rightshift once to get into the correct range 0 ... 63
   phy
   ldy modsource_index
   clc
   ror
   sta voi_modsourcesH, y
   lda voices::Voice::lfo::phaseL, x
   ror
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos
@ramp_up_negative:
   ; need to rightshift and invert and put sign
   phy
   ldy modsource_index
   sec
   ror
   ; we are in range %11000000 to %11111111
   ; transform to    %10111111 to %10000000
   eor #%01111111
   ;lda #0
   sta voi_modsourcesH, y
   lda voices::Voice::lfo::phaseL, x
   ror
   eor #%11111111
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos

   ; ramp down ... we basically need to invert the sign
@ramp_down:
   plx
   ; advance phase
   lda voices::Voice::lfo::phaseL, x
   clc
   adc timbres::Timbre::lfo::rateL, y
   sta voices::Voice::lfo::phaseL, x
   lda voices::Voice::lfo::phaseH, x
   adc timbres::Timbre::lfo::rateH, y
   sta voices::Voice::lfo::phaseH, x
   ; check high bit
   bmi @ramp_dn_negative
@ramp_dn_positive:
   ; we are in range %00000000 to %01111111
   ; need to rightshift once to get into the correct range 0 ... 63
   phy
   ldy modsource_index
   clc
   ror
   eor #%10000000
   sta voi_modsourcesH, y
   lda voices::Voice::lfo::phaseL, x
   ror
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos
@ramp_dn_negative:
   ; need to rightshift and invert and put sign
   phy
   ldy modsource_index
   sec
   ror
   eor #%11111111
   ;lda #0
   sta voi_modsourcesH, y
   lda voices::Voice::lfo::phaseL, x
   ror
   eor #%11111111
   sta voi_modsourcesL, y
   ply
   jmp @advance_lfos


   ; Sample and Hold
   ; phaseL is a counter, which upon hitting 0 initiates the generation of a new random value
   ; phaseH is the seed as well as the random value itself (LFSR algorithm)
@alg_snh:
   plx
   ; countdown
   lda voices::Voice::lfo::phaseL, x
   bne @snh_constant
@snh_random:
   ; reset counter
   lda timbres::Timbre::lfo::rateL, y
   dec
   sta voices::Voice::lfo::phaseL, x
   ; very rudimentary RNG: 8 bit LFSR
   lda voices::Voice::lfo::phaseH, x
   sta bittest
   phy
   ldy #1
   bbr0 bittest, :+
   iny
:  bbr2 bittest, :+
   iny
:  bbr3 bittest, :+
   iny
:  bbr4 bittest, :+
   iny
:  tya
   ror   ; put least significant bit (i.e. parity) into carry flag
   lda bittest
   ror
   sta voices::Voice::lfo::phaseH, x
   jmp @snh_write
   ; if just held constant
@snh_constant:
   dec
   sta voices::Voice::lfo::phaseL, x
   lda voices::Voice::lfo::phaseH, x
   phy
@snh_write:
   ldy modsource_index
   sta voi_modsourcesH, y
   lda #0
   sta voi_modsourcesL, y
   ply

@advance_lfos:
   ; advance counters
   txa
   clc
   adc #N_VOICES
   tax
   tya
   clc   ; unnecessary
   adc #N_TIMBRES
   tay
   inc modsource_index
   lda lfo_counter
   dec
   jmp @loop_lfos

@end_lfos:

   ldx voice_index
   lda #(MAX_ENVS_PER_VOICE+MAX_LFOS_PER_VOICE)
   sta modsource_index




   ; ----------------
   ; ----------------
   ; - VOICE VOLUME -
   ; ----------------
   ; ----------------

   ; This section determines the voice's overall volume.
   ; Typically, it stays constant once set at the beginning of a note,
   ; but a volume slope can be set, which will be updated here.
   ; ! Spaghetti Code Alert !

   ; x: voice index
   lda voices::Voice::vol::slope, x
   beq @end_volume_slope
   ; the higher 4 bits will be added to the low byte
   and #%11110000
   clc
   adc voices::Voice::vol::volume_low, x
   sta voices::Voice::vol::volume_low, x
   ; the lower 3 bits will be added to the high byte
   lda voices::Voice::vol::slope, x
   and #%00000111
   adc voices::Voice::vol::volume, x
   sta voices::Voice::vol::volume, x
   ; and the (former) most significant bit will decide upon the sign of the slope
   lda voices::Voice::vol::slope, x
   and #%00001000
   bne @downward_slope
   ; bra @upward_slope
@upward_slope:
   lda voices::Voice::vol::volume, x
   cmp voices::Voice::vol::threshold, x
   bcs @hit_threshold
   bra @store_new_volume
@downward_slope:
   lda voices::Voice::vol::volume, x
   sec
   sbc #%00001000
   bmi @hit_threshold
   cmp voices::Voice::vol::threshold, x
   bcs @store_new_volume
   ; bra @hit_threshold
@hit_threshold:
   stz voices::Voice::vol::slope, x
   lda voices::Voice::vol::threshold, x
   ; bra @store_new_volume
@store_new_volume:
   sta voices::Voice::vol::volume, x
   stx note_channel
   ldy voices::Voice::timbre, x
   lda timbres::Timbre::fm_general::op_en, y
   jsr voices::set_fm_voice_volume
@end_volume_slope:
   ldx voice_index




   ; ---------------
   ; ---------------
   ; - VOICE PITCH -
   ; ---------------
   ; ---------------

   ; This section of code determines the *voice* pitch. Voice pitch depends
   ; only on the note played, on the (global) vibrato and on the porta settings.
   ; I.e. it does not depend on the individual oscillators' pitch settings.
   ; The resulting pitch will be added to all oscillators with enabled
   ; keyboard tracking.

   ; x: voice index
   ; y: timbre index (in vibrato section)

   ; check pitch slide
   lda voices::Voice::pitch_slide::active, x
   beq @skip_porta   ; porta inactive?
   ; do slide
   lda voices::Voice::pitch_slide::posL, x
   clc
   adc voices::Voice::pitch_slide::rateL, x
   sta voices::Voice::pitch_slide::posL, x
   sta voi_fine
   lda voices::Voice::pitch_slide::posH, x
   adc voices::Voice::pitch_slide::rateH, x
   sta voices::Voice::pitch_slide::posH, x
   sta voi_pitch
   ; check for finish
   lda voices::Voice::pitch_slide::active, x
   cmp #3            ; free porta?
   beq @do_vibrato
   cmp #2            ; porta down?
   beq @porta_down_check
@porta_up_check:
   lda voices::Voice::pitch_slide::posH, x
   cmp voices::Voice::pitch, x
   ; slide still going? if not, end it
   bcs @stop_porta
   bra @do_vibrato
@porta_down_check:
   lda voices::Voice::pitch_slide::posH, x
   cmp voices::Voice::pitch, x
   bcs @do_vibrato
@stop_porta:
   stz voices::Voice::pitch_slide::active, x
   stz voi_fine
   lda voices::Voice::pitch, x
   sta voi_pitch
   bra @do_vibrato
@skip_porta:
   ; normal keyboard note
   lda voices::Voice::pitch, x
   sta voi_pitch
   stz voi_fine

@do_vibrato:
   ; check if channel vibrato is active
   lda voices::Voice::vibrato::current_level, x
   bmi @timbre_vibrato
@channel_vibrato: ; sorry for the spaghetti code in this section (lasts until @timbre_vibrato)
   ; channel vibrato, with possible vibrato ramp being active.
   ; The idea here is that we want to get a linear increase / decrease of modulation depth over time.
   ; This is challenging, since Scale5 is an exponential format, and it is non-trivial to figure out how long
   ; to wait in between individual Scale5 modulation depth levels.
   ; This is what the table at the label "vibrato_delays_lut" is for.
   ; The following code takes care of advancing as many ticks as specified by the "slope" set by the user
   ; and advancing modulation depth levels in the case of overflow.
   ; Multiple levels are advanced if necessary.
   lda voices::Voice::vibrato::threshold_level, x ; read the threshold up to which the slope shall go.
   sta threshold_level
   lda voices::Voice::vibrato::slope, x ; read slope and check if we're going up or down
   sta slope
   bpl @vibrato_slope_going_up
@vibrato_slope_going_down:
   ; TODO: special case for crossing zero -> inactivate vibrato?
   lda voices::Voice::vibrato::ticks, x ; this is the internal countdown to the next modulation level.
   clc
   adc slope
   bcs @update_vibrato_slope_ticks ; when that did wrap around, we do not need to advance to the next level
   ; no wrap around: go to next level(s)
   ; determine next level and new vibrato tick count
   ldy voices::Voice::vibrato::current_level, x
   beq @threshold_level_reached ; catch the case where we're at level zero and the next step will be inactivating vibrato. We will not inactivat vibrato in this tick, but stay at the lowest nonzero amount for one tick longer and avoid an annoying glitch that way.
:  dey
   adc vibrato_delays_lut, y
   bcs @ticks_positive_again_sldown
   cpy threshold_level ; check if minimum level is reached 
   bne :- ; add delay times for successive vibrato levels until we're back in the positive range
   bra @threshold_level_reached
@ticks_positive_again_sldown:
   sta voices::Voice::vibrato::ticks, x
   tya
   sta voices::Voice::vibrato::current_level, x
   bra @update_vibrato_slope_ticks
@vibrato_slope_going_up:
   lda voices::Voice::vibrato::ticks, x ; this is the internal countdown to the next modulation level.
   sec
   sbc slope
   bcs @update_vibrato_slope_ticks ; when the result is >= 0, we do not need to advance to the next level
   ; overflow: go to next level(s)
   ; determine next level and new vibrato tick count
   ldy voices::Voice::vibrato::current_level, x
:  adc vibrato_delays_lut, y ; carry is clear, because subtraction overflow occurred
   bcs @ticks_positive_again_slup ; check if we're back to positive.
   iny
   cpy threshold_level ; check if maximum level is reached
   bcc :- ; add delay times for successive vibrato levels until we're back in the positive range
@threshold_level_reached:
   lda threshold_level
   sta voices::Voice::vibrato::current_level, x
   stz voices::Voice::vibrato::slope, x
   bra @load_channel_vibrato_amount
@ticks_positive_again_slup:
   sta voices::Voice::vibrato::ticks, x
   iny ; do the final level increase
   cpy threshold_level
   beq @threshold_level_reached
   tya
   sta voices::Voice::vibrato::current_level, x
@update_vibrato_slope_ticks:
   sta voices::Voice::vibrato::ticks, x
   ldy voices::Voice::vibrato::current_level, x
@load_channel_vibrato_amount:
   ; load vibrato amount
   lda vibrato_scale5_lut, y
   bra @vibrato_multiplication ; scale5 vibrato amount is in A
@timbre_vibrato:
   ldy voices::Voice::timbre, x
   lda timbres::Timbre::vibrato, y
@vibrato_multiplication:
   bpl :+
   jmp @skip_vibrato
:  sta scale5_moddepth
   ldx #3 ; select LFO as modsource
   ; actually, this routine could be slightly optimized for this particular use case... (unsigned mod depth)
   SCALE5_16 voi_modsourcesL, voi_modsourcesH, voi_fine, voi_pitch

   
@skip_vibrato:
   ldx voice_index
   ldy voices::Voice::timbre, x




   ; --------------
   ; --------------
   ; -- FM VOICE --
   ; --------------
   ; --------------

   ; check if FM is active
   lda timbres::Timbre::fm_general::op_en, y
   bne :+
   jmp @skip_fm_pitch
:

   ; keyboard + portamento
   lda timbres::Timbre::fm_general::track, y
   beq @notrack_fm
   lda voi_fine
   clc
   adc timbres::Timbre::fm_general::fine, y
   sta osc_fine
   lda voi_pitch
   adc timbres::Timbre::fm_general::pitch, y
   sta osc_pitch
   bra @donetrack_fm
@notrack_fm:
   lda timbres::Timbre::fm_general::fine, y
   sta osc_fine
   lda #NOTRACK_CENTER
   clc
   adc timbres::Timbre::fm_general::pitch, y
   sta osc_pitch
@donetrack_fm:
   ; modulation
   ; source indexed by X
   ; depth stored in scale5_moddepth
   ; pitch mod source
   ldx timbres::Timbre::fm_general::pitch_mod_sel, y
   bpl :+
   jmp @skip_pitchmod_fm
:  lda timbres::Timbre::fm_general::pitch_mod_dep, y
   sta scale5_moddepth
   SCALE5_16 voi_modsourcesL, voi_modsourcesH, osc_fine, osc_pitch
@skip_pitchmod_fm:


   ; Set note's pitch
   ; We have to convert from continuous internal format to
   ; annoying YM2151 format.
   ; Maybe one or two lookup tables can do the trick in the future
   ; (There is already one being used in the NOTE determination)
   ldy #0
   lda osc_pitch
   dec ; this is just to correct for YM octaves starting at C# and not C
   sec
@sub_loop:
   iny
   sbc #12
   bcs @sub_loop
   adc #12
   ; semitone is in A. Now translate it to stupid YM2151 format
   tax
   lda voices::semitones_ym2151, x
   sta keycode
   ldx voice_index
   dey
   ; octave is in Y
   tya
   clc
   asl
   asl
   asl
   asl
   clc
   adc keycode ; carry should be clear from previous operation, where bits were pushed out that are supposed to be zero anyway.
   tay ; done computing the value
   lda #YM_KC
   clc
   adc voices::Voice::fm_voice_map, x
   jsr voices::write_ym2151
   ; key fraction
   ; this is trivial
   ldy osc_fine
   lda #YM_KF
   adc voices::Voice::fm_voice_map, x
   jsr voices::write_ym2151


   ; trigger key-on if it has been loaded
   ldx voice_index
   lda voices::Voice::fm::trigger_loaded, x
   beq @skip_fm_trigger
@do_fm_trigger:
   ; key off
   lda #YM_KON
   ldy voices::Voice::fm_voice_map, x
   jsr voices::write_ym2151
   ; key on
   stz voices::Voice::fm::trigger_loaded, x
   ldy voices::Voice::timbre, x
   lda timbres::Timbre::fm_general::op_en, y
   asl
   asl
   asl
   adc voices::Voice::fm_voice_map, x
   tay
   lda #YM_KON
   jsr voices::write_ym2151
@skip_fm_trigger:
@skip_fm_pitch:



   ; ---------------
   ; ---------------
   ; - OSCILLATORS -
   ; ---------------
   ; ---------------

   ; x: offset for envelope/lfo data access, and multi purpose indexing register
   ; y: offset for oscillator timbre data access ... starting at timbre index, increased by N_TIMBRES for each oscillator
   ; osc_counter: keeps track of which oscillator we're processing
   ; n_oscs: number of oscillators to be processed
   ; during the PSG voice stuff, x and y are doing different stuff
   ; osc_offset: starting at voice_index, increased by N_VOICES, to access voice dependent oscillator data (PSG index)
   ldy voices::Voice::timbre, x
   lda timbres::Timbre::n_oscs, y
   bne :+
   ldx voice_index
   jmp next_voice
:  sta n_oscs
   stz osc_counter
   lda voice_index
   sta osc_offset
   lda voices::Voice::vol::volume, x
   sta voi_volume

next_osc:


   ; do oscillator volume control
   ; read amplifier
   ldx timbres::Timbre::osc::amp_sel, y
   lda voi_modsourcesH, x
   lsr   ; put into range 0 ... 63
   sta osc_volume
   ; modulate volume
   ldx timbres::Timbre::osc::vol_mod_sel, y
   bpl :+
   jmp @do_volume_knobs
:  lda voi_modsourcesH, x
   SCALE_S6 timbres::Timbre::osc::vol_mod_dep, 2
   clc
   adc osc_volume   ; add modulation to amp envelope
   ; clamp to valid range
   cmp #63
   bcs :+   ; if carry clear, we are in valid range
   bra @do_volume_knobs
:  ; if carry set, we have to clamp range
   ; if we're below 159, set to 63. if we're above 159, set to 0
   cmp #159
   bcc :+ ; if carry set, we set 0
   lda #0
   bra @do_volume_knobs
:  lda #63  ; if carry clear, we set 63
@do_volume_knobs:
   ; There are two possibilities of doing the volume knobs
   ; * multiplying the amp envelope with the volume knobs
   ; * subtracting the difference to full volume from the amp envelope
   ; The output value is fed into the VERA, which uses a logarithmic volume scale.
   ; Hence, the subtraction (or addition) route is mathematically correct, 
   ; as addition on a logarithmic scale is equivalent to multiplication
   ; on a linear scale.
   ; The two routes sound differently:
   ; * multiplication: quiet sounds sound squashed, not as "plucky" as louder sounds
   ; * addition: quiet sounds may be truncated (due to the finite length of the logarithmic scale)
   ; It is a tradeoff.
   ; Truncated attack phase (the sound becoming audible with a delay when using long attack phase)
   ; is certainly the most annoying caveat of the additive route. It can, fortunately, be worked around
   ; by adding a zero-attack envelope to the volume via modulation. This bumps up the volume
   ; during the attack phase, so that it is audible immediately, even at low volumes.
   ; 

   ; multiplying route:
   ; multiply with oscillator volume setting, input and output via register A
   ;SCALE_U7 timbres::Timbre::osc::volume, 2
   ; multiply with voice's volume
   ;SCALE_U7 voi_volume, 0

   ; addition route:
   clc
   ; A is in [0, ... 63]
   adc timbres::Timbre::osc::volume, y ; maximally 64, result can't be above 127
   adc voi_volume ; maximally 64 (increased by 1 frome the user input), result can't be above 191
   sec
   sbc #128
   bcs :+ ; clamp to 0
   lda #0
:

   ; do channel selection
@do_channel_selection:
   clc
   adc timbres::Timbre::osc::lrmid, y
   sta osc_volume


   ; do oscillator pitch control
   ; keyboard + portamento
   lda timbres::Timbre::osc::track, y
   beq @notrack
   lda voi_fine
   clc
   adc timbres::Timbre::osc::fine, y
   sta osc_fine
   lda voi_pitch
   adc timbres::Timbre::osc::pitch, y
   sta osc_pitch
   bra @donetrack
@notrack:
   ; modulation
   ; source indexed by X
   ; depth indexed by Y
   lda timbres::Timbre::osc::fine, y
   sta osc_fine
   lda #NOTRACK_CENTER
   clc
   adc timbres::Timbre::osc::pitch, y
   sta osc_pitch
@donetrack:
   ; pitch mod source 1
   ldx timbres::Timbre::osc::pitch_mod_sel1, y
   bpl :+
   jmp @skip_pitchmod1
:  lda timbres::Timbre::osc::pitch_mod_dep1, y
   sta scale5_moddepth
   SCALE5_16 voi_modsourcesL, voi_modsourcesH, osc_fine, osc_pitch
@skip_pitchmod1:
   ; pitch mod source 2
   ldx timbres::Timbre::osc::pitch_mod_sel2, y
   bpl :+
   jmp @skip_pitchmod2
:  lda timbres::Timbre::osc::pitch_mod_dep2, y
   sta scale5_moddepth
   SCALE5_16 voi_modsourcesL, voi_modsourcesH, osc_fine, osc_pitch
@skip_pitchmod2:

   ; compute frequency
   phy
   COMPUTE_FREQUENCY osc_pitch,osc_fine,osc_freq
   ply


   ; do oscillator waveform control
   lda timbres::Timbre::osc::waveform, y
   sta osc_wave
   beq :+
   jmp @end_pwm
:  ; pulse width modulation
   ; load pulse width
   lda timbres::Timbre::osc::pulse, y
   sta osc_wave
   ; modulate pulse width
   ldx timbres::Timbre::osc::pwm_sel, y
   bpl :+
   jmp @end_pwm
:  lda voi_modsourcesH, x
   SCALE_S6 timbres::Timbre::osc::pwm_dep, 2
   clc
   adc osc_wave   ; add static pulse width to mpdulation signal
   ; clamp to valid range
   cmp #63
   bcs :+   ; if carry clear, we are in valid range
   sta osc_wave
   bra @end_pwm
:  ; if carry set, we have to clamp range
   ; if we're below 159, set to 63. if we're above 159, set to 0
   cmp #159
   bcc :+ ; if carry set, we set 0
   stz osc_wave
   bra @end_pwm
:  lda #63  ; if carry clear, we set 63
   sta osc_wave
@end_pwm:

   ; do oscillator's PSG voice control
   ldx osc_offset
   lda voices::Voice::osc_psg_map, x
   VERA_SET_VOICE_PARAMS_MEM_A osc_freq,osc_volume,osc_wave

   ; advance counters for oscillator loop
   ; timbre data offset
   tya
   clc
   adc #N_TIMBRES
   tay
   ; oscillator voice offset
   lda osc_offset
   clc ; redundant
   adc #N_VOICES
   sta osc_offset
   ; oscillator counter
   lda osc_counter
   inc
   cmp n_oscs
   sta osc_counter
   beq :+
   jmp next_osc
:  ; end of oscillator loop

   ; - VOICE DONE -
   ldx voice_index
   jmp next_voice

end_synth_tick:
.ifdef concerto_enable_zsound_recording
   jsr zsm_recording::tick
.endif

   rts

.endscope