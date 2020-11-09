.macro PRESET_BRIGHT_PLUCK patch_no
   ; global parameters
   ldx #patch_no
   lda #3
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
   lda #63
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #0
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #63
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
.endmacro



.macro PRESET_SNARE_DRUM patch_no
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
   lda #63
   sta timbres::Timbre::env::attackH, x
   lda #128
   sta timbres::Timbre::env::decayL, x
   lda #6
   sta timbres::Timbre::env::decayH, x
   ; env 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #0
   sta timbres::Timbre::env::attackL, x
   lda #63
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
   ; oscillator 1
   ldx #(1*N_TIMBRES+patch_no)
   lda #192
   sta timbres::Timbre::osc::waveform, x
   lda #75
   sta timbres::Timbre::osc::pitch, x
   lda #0
   sta timbres::Timbre::osc::fine, x
   lda #192
   sta timbres::Timbre::osc::lrmid, x
   lda #0
   sta timbres::Timbre::osc::amp_sel, x
.endmacro