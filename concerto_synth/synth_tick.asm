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
; prefactor of 1. However, you can go up to 127 aka 1111111 (on your own risk!)

; Pitch modulation depth is defined by a different format that saves some CPU
; cycles (because it is a 16 bit modulation it's worth it).
; That format is termed Scale5, which is
; intended to be a cheap approximation of exponential
; scaling.
; An ordinary binary number N and a Scale5 number
; are multiplied the following way.
; The Scale5 number format is as follows. The 8 bits are assigned as
; SLLLHHHH
; S is the sign of the modulation depth
; HHHH is a binary number indicating how many
; times N gets right shifted.
; LLL is a binary number that must assume a value from 0 to 4.
; It is one of five sub-levels between powers of 2.
; Since the right shifts can only produce divisions with powers of 2,
; these sub-levels are intended to fill in the gaps between powers of 2
; as evenly as possible.
; Beware: HHHH denotes how much N is scaled DOWN
; LLL denotes how much N is scaled UP (but only just below the next power of 2)
; I know ... a bit complicated. Sorry pals.
; Believe me, it's faster than plain 8 bit multiplication.
; Basically, you can multiply with one of the five binary numbers
; %1.000
; %1.001
; %1.010
; %1.100
; %1.110
; and right shift the result up to 15 times. (only in practice, the right shift is done first)
; These values are chosen to be distributed relatively evenly on an exponential scale.


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

; give zero page variables more understandable names
voice_index = mzpbb
env_counter = mzpbc
n_envs      = mzpbd
lfo_counter = mzpbc
bittest     = mzpbd  ; for Sample and Hold RNG
osc_counter = mzpbc ; c and d are reused
n_oscs      = mzpbd
modsource_index = mzpbe ; keeps track of which modsource we're processing
osc_offset = mzpbe ; e reused for oscillators loop
; mzpbf and mzpbg are reserved for multiplications



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
   ; (At the moment, we just got AD envelopes)

   ; step = 0 means inactive (either not started or already finished) 
   ; When the envelope is inactive, phase has to be 0 for reference,
   ; since the envelope amplitude is in "phase".
   ; (If phase weren't 0 when the envelope is inactive, it would yield a nonzero modulation
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
   cmp #127 ; this is the threshold for when attack stage is done
   bcc advance_env ; if 64 is still larger than high byte, we're still in attack phase, and therefore done for now
   ; otherwise, advance to next stage:
   inc voices::Voice::env::step, x
   lda #127
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





   ; ---------------
   ; ---------------
   ; - VOICE PITCH -
   ; ---------------
   ; ---------------

   ; This section of code determines the *voice* pitch. Voice pitch depends
   ; only on the note played, on the (global) vibrato and on the porta settings.
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
   ldy voices::Voice::timbre, x
   lda timbres::Timbre::vibrato, y
   bpl :+
   jmp @skip_vibrato
:  ldx #3 ; select LFO as modsource
   ; actually, this routine could be sloightly optimized for this particular use case... (unsigned mod depth)
   SCALE5_16 voi_modsourcesL, voi_modsourcesH, timbres::Timbre::vibrato, voi_fine, voi_pitch

   
@skip_vibrato:
   ldx voice_index








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
   sta n_oscs
   stz osc_counter
   lda voice_index
   sta osc_offset
   lda voices::Voice::volume, x
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
   ; multiply with oscillator volume setting, input and output via register A
   SCALE_U7 timbres::Timbre::osc::volume, 2
   ; multiply with voice's volume
   SCALE_U7 voi_volume, 0
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
   lda timbres::Timbre::osc::pitch, y
   sta osc_pitch
@donetrack:
   ; pitch mod source 1
   ldx timbres::Timbre::osc::pitch_mod_sel1, y
   bpl :+
   jmp @skip_pitchmod1
:  SCALE5_16 voi_modsourcesL, voi_modsourcesH, timbres::Timbre::osc::pitch_mod_dep1, osc_fine, osc_pitch
@skip_pitchmod1:
   ; pitch mod source 2
   ldx timbres::Timbre::osc::pitch_mod_sel2, y
   bpl :+
   jmp @skip_pitchmod2
:  SCALE5_16 voi_modsourcesL, voi_modsourcesH, timbres::Timbre::osc::pitch_mod_dep2, osc_fine, osc_pitch
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

rts

.endscope