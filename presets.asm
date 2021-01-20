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
   sta timbres::Timbre::porta, x
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #44
   sta timbres::Timbre::osc::pulse, x
   lda #244
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
.endmacro


.macro PRESET_GUITAR_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #3
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::porta, x
   lda #1
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #10
   sta timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #155
   sta timbres::Timbre::env::decayL, x
   lda #1
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #22
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #28
   sta timbres::Timbre::env::releaseH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #44
   sta timbres::Timbre::osc::pulse, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #48
   sta timbres::Timbre::osc::pulse, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #8
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #39
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #0
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(128+17)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #53
   sta timbres::Timbre::osc::pitch, x
   lda #20
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #62
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
.endmacro


.macro PRESET_FAT_PLUCK patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #1
   sta timbres::Timbre::porta, x
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #41
   sta timbres::Timbre::osc::pulse, x
   lda #256-24
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #0
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #12
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::pwm_sel, x
   lda #28
   sta timbres::Timbre::osc::pwm_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #64
   sta timbres::Timbre::osc::waveform, x
   lda #255-12
   sta timbres::Timbre::osc::pitch, x
   lda #236
   sta timbres::Timbre::osc::fine, x
   lda #128
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #56
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #64
   sta timbres::Timbre::osc::waveform, x
   lda #256-12
   sta timbres::Timbre::osc::pitch, x
   lda #20
   sta timbres::Timbre::osc::fine, x
   lda #64
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #56
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #2
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
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
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(128 + 0 * 16 + 4)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
.endmacro


.macro PRESET_SNARE_DRUM_4 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #3
   sta timbres::Timbre::n_envs, x
   lda #0
   sta timbres::Timbre::n_lfos, x
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
   lda #5
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #12
   sta timbres::Timbre::env::decayH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #7
   sta timbres::Timbre::env::decayH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #70
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #0
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #40
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #(0 * 16 + 0)
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #127
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(0 * 16 + 0)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(128 + 2 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #61
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #(0 * 16 + 1)
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0 * 16 + 6)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro


.macro PRESET_SNARE_DRUM_5 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #3
   sta timbres::Timbre::n_envs, x
   lda #0
   sta timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #20
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::porta, x
   lda #1
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #5
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #35
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #45
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #16
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #70
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #0
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #38
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #0
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(16)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #0
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(4 * 16 + 4)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #128
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #2
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(128+20)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #2
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(128 + 3 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #132
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #70
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 2)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0 * 16 + 6)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 3
   ldx #(3*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #42
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #(0 * 16 + 0)
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0 * 16 + 6)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
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
   lda #1
   sta timbres::Timbre::porta, x
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #2
   sta timbres::Timbre::env::decayH, x
   lda #62
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #48
   sta timbres::Timbre::env::releaseH, x
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #2
   sta timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #14
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #1
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #30
   sta timbres::Timbre::osc::pulse, x
   lda #1
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(1*128+20)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(2*16+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro

.macro PRESET_TAMBOURINE patch_no  ; or rather Hihat
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   lda #1
   sta timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::porta, x
   lda #1
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #7
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #2
   sta timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #39
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #38
   sta timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #1
   sta timbres::Timbre::lfo::wave, x
   lda #64
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #1
   sta timbres::Timbre::lfo::retrig, x
   lda #0
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #22
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #120
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #50
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(5) ; 51
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(128+5+16*2) ; -53
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #21
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #127
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #52
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(128+7+4*16) ; -45
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #20
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #107
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #43
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(7+1*16) ; 42
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(15)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
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
   lda #128
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #12
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #80
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #24
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #40
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
.endmacro




.macro PRESET_LEAD_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   lda #1
   sta timbres::Timbre::n_lfos, x
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
   lda #2
   sta timbres::Timbre::env::decayH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #11
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #10
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #50
   sta timbres::Timbre::osc::pulse, x
   lda #3
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(128+2*16+2)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #244
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #(16*1+1)
   sta timbres::Timbre::osc::volume, x
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #50
   sta timbres::Timbre::osc::pulse, x
   lda #1
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(128+2*16+2)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #20
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro


.macro PRESET_KEY_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   lda #1
   sta timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::porta, x
   lda #1
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #3
   sta timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #126
   sta timbres::Timbre::env::decayL, x
   lda #4
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #3
   sta timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #11
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #0
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #0
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(128*0+0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #24
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #3
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(16)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #50
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(128+2*16+2)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #60
   sta timbres::Timbre::osc::pitch, x
   lda #20
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #32
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(16*0+2)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro


.macro PRESET_PAD_1 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta timbres::Timbre::n_oscs, x
   lda #1
   sta timbres::Timbre::n_envs, x
   lda #0
   sta timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::porta, x
   lda #1
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #4
   sta timbres::Timbre::env::attackH, x
   lda #127
   sta timbres::Timbre::env::decayL, x
   lda #1
   sta timbres::Timbre::env::decayH, x
   lda #63
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #1
   sta timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #126
   sta timbres::Timbre::env::decayL, x
   lda #4
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #3
   sta timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #11
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #0
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #0
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(128*0+0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(16)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #50
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #12
   sta timbres::Timbre::osc::pitch, x
   lda #20
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #50
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(16*0+2)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro


.macro PRESET_KEY_2 patch_no
   ; global parameters
   ldx #patch_no
   lda #2
   sta timbres::Timbre::n_oscs, x
   lda #2
   sta timbres::Timbre::n_envs, x
   lda #0
   sta timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #30
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::porta, x
   lda #1
   sta timbres::Timbre::retrig, x
   ; env 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #132
   sta timbres::Timbre::env::decayL, x
   lda #0
   sta timbres::Timbre::env::decayH, x
   lda #15
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #34
   sta timbres::Timbre::env::releaseH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #1
   sta timbres::Timbre::env::decayH, x
   lda #3
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #2
   sta timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #11
   sta timbres::Timbre::lfo::rateH, x
   lda #0
   sta timbres::Timbre::lfo::rateL, x
   lda #0
   sta timbres::Timbre::lfo::retrig, x
   lda #128
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #0
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(128*0+0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #0
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(16)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #50
   sta timbres::Timbre::osc::pulse, x
   lda #128
   sta timbres::Timbre::osc::pwm_sel, x
   lda #(0)
   sta timbres::Timbre::osc::pwm_dep, x
   lda #12
   sta timbres::Timbre::osc::pitch, x
   lda #2
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #1
   sta timbres::Timbre::osc::amp_sel, x
   lda #48
   sta timbres::Timbre::osc::volume, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(16*0+2)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #1
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(16*1+8)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_dep2, x
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
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(1)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(2 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #127
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(1 * 16 + 1)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 5)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro

.macro PRESET_KICK_DRUM_2 patch_no
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
   lda #22
   sta timbres::Timbre::env::decayH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #30
   sta timbres::Timbre::env::decayH, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #32
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
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(1)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(2 * 16 + 2)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #127
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(1 * 16 + 1)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 5)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #36
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #(16*2+1)
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(1)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(2 * 16 + 2)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro

.macro PRESET_KICK_DRUM_3 patch_no
   ; global parameters
   ldx #patch_no
   lda #3
   sta timbres::Timbre::n_oscs, x
   lda #3
   sta timbres::Timbre::n_envs, x
   lda #1
   sta timbres::Timbre::n_lfos, x
   ; set mono & porta rate
   lda #20
   sta timbres::Timbre::porta_r, x
   lda #0
   sta timbres::Timbre::porta, x
   lda #1
   sta timbres::Timbre::retrig, x
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
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
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; env 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #127
   sta timbres::Timbre::env::attackH, x
   lda #0
   sta timbres::Timbre::env::decayL, x
   lda #36
   sta timbres::Timbre::env::decayH, x
   lda #0
   sta timbres::Timbre::env::sustain, x
   lda #0
   sta timbres::Timbre::env::releaseL, x
   lda #64
   sta timbres::Timbre::env::releaseH, x
   ; lfo 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::lfo::wave, x
   lda #90
   sta timbres::Timbre::lfo::rateH, x
   lda #1
   sta timbres::Timbre::lfo::rateL, x
   lda #1
   sta timbres::Timbre::lfo::retrig, x
   lda #0
   sta timbres::Timbre::lfo::offs, x
   ; set oscillator parameters
   ; oscillator 0
   ldx #(0*N_TIMBRES+patch_no)
   lda #128
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #32
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #64
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #0
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(70)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(4 * 16 + 4)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #2
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #127
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #48
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #2
   sta timbres::Timbre::osc::amp_sel, x
   lda #128
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(0)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #1
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(0 * 16 + 5)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(0)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
   ; oscillator 2
   ldx #(2*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::osc::waveform, x
   lda #63
   sta timbres::Timbre::osc::pulse, x
   lda #38
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #38
   sta timbres::Timbre::osc::volume, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
   lda #1
   sta timbres::Timbre::osc::vol_mod_sel, x
   lda #(128+8)
   sta timbres::Timbre::osc::vol_mod_dep, x
   lda #0
   sta timbres::Timbre::osc::track, x
   lda #3
   sta timbres::Timbre::osc::pitch_mod_sel1, x
   lda #(2 * 16 + 3)
   sta timbres::Timbre::osc::pitch_mod_dep1, x
   lda #128
   sta timbres::Timbre::osc::pitch_mod_sel2, x
   lda #(2 * 16 + 2)
   sta timbres::Timbre::osc::pitch_mod_dep2, x
.endmacro