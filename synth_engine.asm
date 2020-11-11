; This file contains the code that is executed in each tick
; All the updating of the PSG voices is done here.

.scope synth_engine


voi_pitch:     .byte 0
voi_fine:      .byte 0
osc_pitch:     .byte 0
osc_fine:      .byte 0
osc_freq:      .word 0
osc_volume:    .byte 0
osc_wave:      .byte 0
osc_pw:        .byte 0
osc_panmute:   .byte 0

; modulation sources, indexed
; available: env1, env2, env3
; maybe later: lfo, gate, wavetable
.define N_MODSOURCES MAX_ENVS_PER_VOICE
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
osc_counter = mzpbc ; c and d are reused
n_oscs      = mzpbd
modsource_index = mzpbe ; keeps track of which modsource we're processing
osc_offset = mzpbe ; e reused for oscillators loop
; mzpbf is reserved for compute_frequency



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
   ; when envelope is inactive, phase has to be 0 for reference
   ; since the envelope amplitude is in "phase"

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
:  cmp #1
   beq env_do_attack ; step = 1 means attack stage
   bra env_do_decay  ; if none of the previous is true, jump to last stage

env_do_attack:
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
   bra advance_env
env_do_decay:
   ; subtract decay rate from phase
   sec
   lda voices::Voice::env::phaseL, x
   sbc timbres::Timbre::env::decayL, y
   sta voices::Voice::env::phaseL, x
   lda voices::Voice::env::phaseH, x
   sbc timbres::Timbre::env::decayH, y
   sta voices::Voice::env::phaseH, x
   ; high byte still in accumulator after subtraction
   bcc env_finish       ; if overflow occured during subtraction of high byte means we're finished
                        ; because we would have reached a negative value
   bra advance_env
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
   stz voices::Voice::active, x
   ; and register for voice release
   txa
   ldx voices::Voicemap::rvsp
   sta voices::Voicemap::releasevoicestack, x
   inc voices::Voicemap::rvsp
   ; mute every oscillator
   ldx timbres::Timbre::n_oscs, y   ; that was the last use of the timbre index in Y, can now be used for other stuff
   ldy voice_index   ; acts as offset to access PSG indices
@loop:
   lda voices::Voice::osc_psg_map, y
   VERA_MUTE_VOICE_A
   tya
   clc
   adc #N_VOICES
   tay
   dex
   bne @loop
   ; everything that needs to be done when the voice is deactivated
   ; must be done here
   ; (although it might not be the only place that can trigger
   ; a voice deactivation in the future ... thinking of voice stealing)
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
   ;advance index for Voice data
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


   ; ---------------
   ; ---------------
   ; - VOICE PITCH -
   ; ---------------
   ; ---------------

   ; This section of code determines the *voice* pitch. Voice pitch depends
   ; only on the note played and on the porta settings.
   ; The resulting pitch will be added to all oscillators with enabled
   ; keyboard tracking.

   ; x: voice index

   ; check portamento
   lda voices::Voice::porta::active, x
   beq @skip_porta   ; porta inactive?
   cmp #1            ; porta upwards?
   beq @porta_up     ; if not, it is going down:

   ;porta downwards
   lda voices::Voice::porta::posL, x
   sec
   sbc voices::Voice::porta::rateL, x
   sta voices::Voice::porta::posL, x
   sta voi_fine
   lda voices::Voice::porta::posH, x
   sbc voices::Voice::porta::rateH, x
   sta voices::Voice::porta::posH, x
   sta voi_pitch
   cmp voices::Voice::pitch, x
   ; porta still going? if not, end it
   bcs @voice_pitch_done
   stz voices::Voice::porta::active, x
   stz voi_fine
   lda voices::Voice::pitch, x
   sta voi_pitch
   bra @voice_pitch_done
@porta_up:
   ; porta upwards
   lda voices::Voice::porta::rateL, x
   clc
   adc voices::Voice::porta::posL, x
   sta voices::Voice::porta::posL, x
   sta voi_fine
   lda voices::Voice::porta::rateH, x
   adc voices::Voice::porta::posH, x
   sta voices::Voice::porta::posH, x
   sta voi_pitch
   cmp voices::Voice::pitch, x
   ; porta still going? if not, end it
   bcc @voice_pitch_done
   stz voices::Voice::porta::active, x
   stz voi_fine
   lda voices::Voice::pitch, x
   sta voi_pitch
   bra @voice_pitch_done
@skip_porta:
   ; normal keyboard note
   lda voices::Voice::pitch, x
   sta voi_pitch
   stz voi_fine
@voice_pitch_done:










   ; ---------------
   ; ---------------
   ; - OSCILLATORS -
   ; ---------------
   ; ---------------

   ; x: offset for envelope/lfo data access, and multi purpose indexing register
   ; y: offset for oscillator timbre data access ... starting at timbre index, increased by N_TIMBRES
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

next_osc:

   ; do oscillator volume control
   ldx timbres::Timbre::osc::amp_sel, y
   lda voi_modsourcesH, x
   clc
   ror
   clc
   adc timbres::Timbre::osc::lrmid, y
   sta osc_volume


   ; do oscillator pitch control
   lda voi_fine
   clc
   adc timbres::Timbre::osc::fine, y
   sta osc_fine
   lda voi_pitch
   adc timbres::Timbre::osc::pitch, y
   sta osc_pitch
   ; compute frequency
   phy
   COMPUTE_FREQUENCY osc_pitch,osc_fine,osc_freq
   ply

   ; do oscillator waveform control
   lda timbres::Timbre::osc::waveform, y
   sta osc_wave

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