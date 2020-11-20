.macro PRESET_BRIGHT_PLUCK patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #1
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #1
   sta timbres::Timbre::mono, x
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #1
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #6
   sta timbres::Timbre::env::decayH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0+44
   sta timbres::Timbre::osc::waveform, x
   lda #244
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #64
   sta timbres::Timbre::osc::waveform, x
   lda #255
   sta timbres::Timbre::osc::pitch, x
   lda #236
   sta timbres::Timbre::osc::fine, x
   lda #128
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #64
   sta timbres::Timbre::osc::waveform, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #20
   sta timbres::Timbre::osc::fine, x
   lda #64
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
.endmacro



.macro PRESET_SNARE_DRUM_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta timbres::Timbre::n_oscs, x
   lda #1
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #20
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::mono, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #6
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #3
   sta timbres::Timbre::env::decayH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0+63
   sta timbres::Timbre::osc::waveform, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #115
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
.endmacro

.macro PRESET_SNARE_DRUM_2 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #3
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #20
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::mono, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #30
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #6
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #6
   sta timbres::Timbre::env::decayH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #70
   sta timbres::Timbre::env::decayH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0+63
   sta timbres::Timbre::osc::waveform, x
   lda #51
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #2
   sta timbres::Timbre::osc::pitch_mod_sel, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #130
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #115
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
.endmacro




.macro PRESET_SNARE_DRUM_3 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #20
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::mono, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #7
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #40
   sta timbres::Timbre::env::decayH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #51
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(0 * 16 + 0)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #61
   sta timbres::Timbre::osc::pitch, x
   lda #128
   sta timbres::Timbre::osc::fine, x
   lda #(4 * 16 + 2)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #120
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(0 * 16 + 0)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel, x
   lda #(128 + 0 * 16 + 4)
   sta timbres::Timbre::osc::pitch_mod_dep, x
.endmacro



.macro PRESET_ONE_OSC_PATCH patch_no
   ; global parameters
   ldx #patch_no
   lda #1
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   lda #1
   sta timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::mono, x
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #0
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #126
   sta timbres::Timbre::env::decayL, x
   lda #3
   sta timbres::Timbre::env::decayH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #1
   sta timbres::Timbre::lfo::wave, x
   lda #14
   sta timbres::Timbre::lfo::rateH, x
   lda #8
   sta timbres::Timbre::lfo::rateL, x
   lda #1
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #64
   sta timbres::Timbre::osc::waveform, x
   lda #244
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel, x
   lda #(0 * 128 + 2 * 16  +  4)
   sta timbres::Timbre::osc::pitch_mod_dep, x
.endmacro


.macro PRESET_BASS_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #40
   sta timbres::Timbre::porta_r, x
   lda #1
   sta timbres::Timbre::mono, x
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #0
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #1
   sta timbres::Timbre::env::decayH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(0 * 16 + 0)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #12
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(2 * 16 + 1)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #24
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(2 * 16 + 2)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel, x
.endmacro





.macro PRESET_KICK_DRUM_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta timbres::Timbre::n_oscs, x
   lda #3
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #20
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::mono, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #3
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #10
   sta timbres::Timbre::env::decayH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #70
   sta timbres::Timbre::env::decayH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #36
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(0+0)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel, x
   lda #(2 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #120
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(1 * 16 + 1)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel, x
   lda #(0 * 16 + 5)
   sta timbres::Timbre::osc::pitch_mod_dep, x
.endmacro