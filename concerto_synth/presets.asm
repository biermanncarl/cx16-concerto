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


; A multitude of macros representing patches for the synth engine.
; Only a few of them will work properly.
; They are just here for test purposes and will eventually be replaced by
; patches loaded from files at runtime.

; Calling this macro loads the factory presets.
; Call this AFTER concerto_synth::initialize!
; Caution! This also bloats your executable. It's meant as an aid for developers.
.macro CONCERTO_LOAD_FACTORY_PRESETS
  CONCERTO_PRESET_BRIGHT_PLUCK 0
  CONCERTO_PRESET_FAT_PLUCK 1
  CONCERTO_PRESET_KEY_2 2
  CONCERTO_PRESET_KEY_1 3
  CONCERTO_PRESET_GUITAR_1 4
  CONCERTO_PRESET_KICK_DRUM_1 5
  CONCERTO_PRESET_SNARE_DRUM_1 6
  CONCERTO_PRESET_TAMBOURINE 7
  CONCERTO_PRESET_SNARE_DRUM_2 8
.endmacro


.macro CONCERTO_PRESET_BRIGHT_PLUCK patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #1
   sta concerto_synth::timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #30
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #1
   sta concerto_synth::timbres::Timbre::porta, x
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   lda #%0001
   sta concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #128
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #1
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #6
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #44
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #244
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #64
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #255
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #236
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #64
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #20
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #64
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
.endmacro


.macro CONCERTO_PRESET_GUITAR_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #3
   sta concerto_synth::timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #30
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #0
   sta concerto_synth::timbres::Timbre::porta, x
   lda #1
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   lda #%0001
   sta concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #128
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #10
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #165
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #22
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #28
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #44
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #48
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #8
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #30
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(128+17)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #53
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #20
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #57
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
.endmacro


.macro CONCERTO_PRESET_FAT_PLUCK patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #2
   sta concerto_synth::timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #30
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #1
   sta concerto_synth::timbres::Timbre::porta, x
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   stz concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #128
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #1
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #6
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #41
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #256-24
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #12
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #28
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #64
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #255-12
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #236
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #47
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #64
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #256-12
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #20
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #64
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #47
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
.endmacro

.macro CONCERTO_PRESET_SNARE_DRUM_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #3
   sta concerto_synth::timbres::Timbre::n_envs, x
   lda #0
   sta concerto_synth::timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #20
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #0
   sta concerto_synth::timbres::Timbre::porta, x
   lda #1
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   stz concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #5
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #35
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #45
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #16
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::wave, x
   lda #70
   sta concerto_synth::timbres::Timbre::lfo::rateH, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::rateL, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::retrig, x
   lda #128
   sta concerto_synth::timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #63
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #38
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(16)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(4 * 16 + 4)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(128+20)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(128 + 3 * 16 + 3)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #192
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #63
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #132
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #70
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 2)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0 * 16 + 6)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro


.macro CONCERTO_PRESET_TAMBOURINE patch_no  ; or rather Hihat
   ; global parameters
   ldx #patch_no
   lda #3
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #2
   sta concerto_synth::timbres::Timbre::n_envs, x
   lda #1
   sta concerto_synth::timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #0
   sta concerto_synth::timbres::Timbre::porta, x
   lda #1
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   stz concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #7
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #2
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #39
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #38
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #1
   sta concerto_synth::timbres::Timbre::lfo::wave, x
   lda #64
   sta concerto_synth::timbres::Timbre::lfo::rateH, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::rateL, x
   lda #1
   sta concerto_synth::timbres::Timbre::lfo::retrig, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #22
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #120
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #41
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #3
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(5) ; 51
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(128+5+16*2) ; -53
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #21
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #127
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #43
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #3
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(128+7+4*16) ; -45
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #20
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #107
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #34
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #3
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(7+1*16) ; 42
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(15)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro


.macro CONCERTO_PRESET_KEY_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #2
   sta concerto_synth::timbres::Timbre::n_envs, x
   lda #1
   sta concerto_synth::timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #0
   sta concerto_synth::timbres::Timbre::porta, x
   lda #1
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   stz concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #128
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #3
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #126
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #1
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #3
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::wave, x
   lda #11
   sta concerto_synth::timbres::Timbre::lfo::rateH, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::rateL, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::retrig, x
   lda #128
   sta concerto_synth::timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(128*0+0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #24
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #3
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(16)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #50
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(128+2*16+2)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #60
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #20
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #23
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(16*0+2)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro

.macro CONCERTO_PRESET_KEY_2 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #2
   sta concerto_synth::timbres::Timbre::n_envs, x
   lda #0
   sta concerto_synth::timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #0
   sta concerto_synth::timbres::Timbre::porta, x
   lda #1
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   stz concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #132
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #15
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #34
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #110
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #3
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #2
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::wave, x
   lda #11
   sta concerto_synth::timbres::Timbre::lfo::rateH, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::rateL, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::retrig, x
   lda #128
   sta concerto_synth::timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(128*0+0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(16)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #50
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   lda #12
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #39
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(16*0+2)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro

.macro CONCERTO_PRESET_KICK_DRUM_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #3
   sta concerto_synth::timbres::Timbre::n_envs, x
   lda #1
   sta concerto_synth::timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #20
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #0
   sta concerto_synth::timbres::Timbre::porta, x
   lda #1
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   stz concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #128
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #3
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #10
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #36
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #64
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::wave, x
   lda #90
   sta concerto_synth::timbres::Timbre::lfo::rateH, x
   lda #1
   sta concerto_synth::timbres::Timbre::lfo::rateL, x
   lda #1
   sta concerto_synth::timbres::Timbre::lfo::retrig, x
   lda #0
   sta concerto_synth::timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #63
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #32
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #60
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(70)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(4 * 16 + 4)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0 * 16 + 3)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #127
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #39
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 5)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #63
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #38
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::fine, x
   lda #29
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   lda #(128+8)
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #3
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(2 * 16 + 3)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(2 * 16 + 2)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro


.macro CONCERTO_PRESET_SNARE_DRUM_2 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta concerto_synth::timbres::Timbre::n_oscs, x
   lda #3
   sta concerto_synth::timbres::Timbre::n_envs, x
   lda #0
   sta concerto_synth::timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta concerto_synth::timbres::Timbre::porta_r, x
   lda #0
   sta concerto_synth::timbres::Timbre::porta, x
   lda #1
   sta concerto_synth::timbres::Timbre::retrig, x
   ; set FM stuff
   stz concerto_synth::timbres::Timbre::fm_general::op_en, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #10
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #3
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #78
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #2
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::env::attackL, x
   lda #127
   sta concerto_synth::timbres::Timbre::env::attackH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::decayL, x
   lda #24
   sta concerto_synth::timbres::Timbre::env::decayH, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::sustain, x
   lda #0
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   lda #2
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #192
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #123
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #55
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #1
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(128+16*4+3)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   lda #63
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   lda #47
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   lda #192
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   lda #57
   sta concerto_synth::timbres::Timbre::osc::volume, x
   lda #0
   sta concerto_synth::timbres::Timbre::osc::track, x
   lda #2
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*4+5)
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
.endmacro