; Copyright 2021 Carl Georg Biermann


; This file contains a range of macros used by the synth engine.
; Some macros do VERA stuff, some macros do various types of
; multiplication. Some are for memory allocation.

.ifndef ::SYNTH_ENGINE_SYNTH_MACROS_ASM
::SYNTH_ENGINE_SYNTH_MACROS_ASM = 1

; Synth engine definitions
.define N_VOICES 16
.define N_INSTRUMENTS 32
.define N_OSCILLATORS 16 ; total number of PSG voices, which correspond to oscillators
.define N_FM_VOICES 8
.define MAX_OSCS_PER_VOICE 4
.define MAX_ENVS_PER_VOICE 3
.define MAX_LFOS_PER_VOICE 1
.define N_TOT_MODSOURCES MAX_ENVS_PER_VOICE+MAX_LFOS_PER_VOICE
.define MAX_VOLUME 63
.define MAX_VOLUME_INTERNAL 64
.define ENV_PEAK 127
.define N_OPERATORS 4
.define MINIMAL_VIBRATO_DEPTH 28 ; when changing this, update create_vibrato_table.py accordingly (and run the script to generate a new table)!
.define MAX_FILENAME_LENGTH 8
.define NOTRACK_CENTER 60 ; when oscillator tracking is disabled, this is the default pitch value
.define FILE_VERSION 0 ; 0-255 specifying which version of Concerto presets is used, stays zero during alpha releases despite possibly breaking changes in between
; clock sources
.define CONCERTO_CLOCK_AFLOW 1
.define CONCERTO_CLOCK_VIA1_T1 2

.macro VOICE_BYTE_FIELD
   .repeat N_VOICES, I
      .byte 0
   .endrep
.endmacro

.macro INSTRUMENT_BYTE_FIELD
   .repeat N_INSTRUMENTS, I
      .byte 0
   .endrep
.endmacro

.macro OSCILLATOR_BYTE_FIELD
   .repeat N_OSCILLATORS, I
      .byte 0
   .endrep
.endmacro

; osc1: instrument1 instrument2 instrument3 ... osc2: instrument1 instrument2 instrument3 ... 
; ---> this format saves multiplication when accessing with arbitrary instrument indes
.macro OSCILLATOR_INSTRUMENT_BYTE_FIELD
   .repeat MAX_OSCS_PER_VOICE*N_INSTRUMENTS
      .byte 0
   .endrep
.endmacro

; osc1: voice1 voice2 voice3 ... osc2: voice1 voice2 voice3 ...
.macro OSCILLATOR_VOICE_BYTE_FIELD
   .repeat MAX_OSCS_PER_VOICE*N_VOICES
      .byte 0
   .endrep
.endmacro

; env1: instrument1 instrument2 instrument3 ... env2: instrument1 instrument2 tibre3 ...
; ---> this format saves multiplication when accessing with arbitrary instrument indices
.macro ENVELOPE_INSTRUMENT_BYTE_FIELD
   .repeat MAX_ENVS_PER_VOICE*N_INSTRUMENTS
      .byte 0
   .endrep
.endmacro

; env1: voice1 voice2 voice3 ... env2: voice1 voice2 voice3 ...
.macro ENVELOPE_VOICE_BYTE_FIELD
   .repeat MAX_ENVS_PER_VOICE*N_VOICES
      .byte 0
   .endrep
.endmacro

; lfo1: instrument1 instrument2 instrument3 ... lfo2: instrument1 instrument2 tibre3 ...
; ---> this format saves multiplication when accessing with arbitrary instrument indices
.macro LFO_INSTRUMENT_BYTE_FIELD
   .repeat MAX_LFOS_PER_VOICE*N_INSTRUMENTS
      .byte 0
   .endrep
.endmacro

; lfo1: voice1 voice2 voice3 ... lfo2: voice1 voice2 voice3 ...
.macro LFO_VOICE_BYTE_FIELD
   .repeat MAX_LFOS_PER_VOICE*N_VOICES
      .byte 0
   .endrep
.endmacro

.macro OPERATOR_INSTRUMENT_BYTE_FIELD
   .repeat N_OPERATORS*N_INSTRUMENTS
      .byte 0
   .endrep
.endmacro

.macro FM_VOICE_BYTE_FIELD
   .repeat N_FM_VOICES
      .byte 0
   .endrep
.endmacro


; parameters in memory, but PSG voice number A
.macro VERA_SET_VOICE_PARAMS_MEM_A frequency, volume, waveform
   pha
   lda #$11
   sta VERA_addr_high
   lda #$F9
   sta VERA_addr_mid
   pla
   asl
   asl
.ifdef ::concerto_enable_zsound_recording
   phy
   pha
   ldx frequency
   pha
   jsr zsm_recording::psg_write
   pla
   inc
   ldx frequency+1
   pha
   jsr zsm_recording::psg_write
   pla
   inc
   ldx volume
   pha
   jsr zsm_recording::psg_write
   pla
   inc
   ldx waveform
   jsr zsm_recording::psg_write
   pla
   ply
.endif
   clc
   adc #$C0
   sta VERA_addr_low
   stz VERA_ctrl

   lda frequency
   sta VERA_data0
   lda frequency+1
   sta VERA_data0
   lda volume
   sta VERA_data0
   lda waveform
   sta VERA_data0
.endmacro

; mutes PSG voice with index stored in register X
.macro VERA_MUTE_VOICE_X
   lda #$11
   sta VERA_addr_high
   lda #$F9
	sta VERA_addr_mid
   txa
   asl
   asl
.ifdef ::concerto_enable_zsound_recording
   pha
   phx
   phy

   inc
   inc
   ldx #0
   jsr zsm_recording::psg_write

   ply
   plx
   pla
.endif
   clc
   adc #$C2
	sta VERA_addr_low
   stz VERA_ctrl
   stz VERA_data0
.endmacro

; mutes PSG voice with index stored in register A
.macro VERA_MUTE_VOICE_A
   pha
   lda #$11
   sta VERA_addr_high
   lda #$F9
   sta VERA_addr_mid
   pla
   asl
   asl
.ifdef ::concerto_enable_zsound_recording
   pha
   phx
   phy

   inc
   inc
   ldx #0
   jsr zsm_recording::psg_write

   ply
   plx
   pla
.endif
   clc
   adc #$C2
   sta VERA_addr_low
   stz VERA_ctrl
   stz VERA_data0
.endmacro


; naive writing to a register in the YM2151
; Potentially burns a lot of cycles in the waiting loop
.macro SET_YM reg, data
:  bit YM_data
   bmi :-

   lda #reg
   sta YM_reg
   lda #data
   sta YM_data
.endmacro


; These macros support multiplication with VERA FX.
; They require multiplication::setup subroutine to be called once in the beginning.
; We currently make the assumption that VERA FX is *only* used for multiplication.
.macro SETUP_MULTIPLICATION
   stz VERA_addr_low ; set low address of ADDR0 scratchpad
   lda #>vram_assets::vera_fx_scratchpad ; we assume it's aligned with 256 bytes as a small optimization
   sta VERA_addr_mid ; set mid address of ADDR0 scratchpad                        (under ideal circumstances, e.g. no PSG writes in between multiplications, we need to do this only once)
   lda #$10          ; set high address of scratchpad, as well as auto-increment  (under ideal circumstances, e.g. no PSG writes in between multiplications, we need to do this only once)
   sta VERA_addr_high
   lda #(6 << 1)
   sta VERA_ctrl ; DCSEL=6, brings up the 32-bit cache registers
   lda VERA_FX_ACCUM_RESET   ; reset accumulator (DCSEL=6)
   ; 26 cycles
.endmacro


.macro WRITE_MULTIPLICATION_RESULT
   ; Assumes: addr0 points at scratchpad, factors are in VERA's 32-bit cache, auto-increment is set to 1
   lda #(2 << 1)
   sta VERA_ctrl        ; DCSEL=2
   lda #%01000000       ; Cache Write Enable
   sta VERA_FX_CTRL
   stz VERA_data0       ; write out multiplication result to VRAM (all 4 bytes at once). At the same time, this advances addr0 which skips the uninteresting least significant byte of the result.
   ; 16 cycles
.endmacro



; In this macro, the slide distance is multiplied by the portamento (base-)rate.
; The result is the effective portamento rate.
; It guarantees that the portamento time is constant regardless of how far
; two notes are apart.
; Expects voice index in X, instrument index in Y, slide distance in mzpbb
.macro MUL8x8_PORTA ; uses ZP variables in the process
   mp_slide_distance = cn_slide_distance ; must be the same as in "continue_note"!
   mp_return_value = mzpwb
   ; the idea is that portamento is finished in a constant time
   ; that means, rate must be higher, the larger the porta distance is
   ; This is achieved by multiplying the "base rate" by the porta distance
   
   ; initialization
   ; mp_return_value stores the porta rate. It needs a 16 bit variable because it is left shifted
   ; throughout the multiplication
   lda instruments::Instrument::porta_r, y
   sta mp_return_value+1
   stz mp_return_value
   stz Voice::pitch_slide::rateL, x
   stz Voice::pitch_slide::rateH, x

   ; multiplication
   bbr0 mp_slide_distance, :+
   lda mp_return_value+1
   sta Voice::pitch_slide::rateL, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr1 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::pitch_slide::rateL, x
   sta Voice::pitch_slide::rateL, x
   lda mp_return_value
   adc Voice::pitch_slide::rateH, x
   sta Voice::pitch_slide::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr2 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::pitch_slide::rateL, x
   sta Voice::pitch_slide::rateL, x
   lda mp_return_value
   adc Voice::pitch_slide::rateH, x
   sta Voice::pitch_slide::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr3 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::pitch_slide::rateL, x
   sta Voice::pitch_slide::rateL, x
   lda mp_return_value
   adc Voice::pitch_slide::rateH, x
   sta Voice::pitch_slide::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr4 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::pitch_slide::rateL, x
   sta Voice::pitch_slide::rateL, x
   lda mp_return_value
   adc Voice::pitch_slide::rateH, x
   sta Voice::pitch_slide::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr5 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::pitch_slide::rateL, x
   sta Voice::pitch_slide::rateL, x
   lda mp_return_value
   adc Voice::pitch_slide::rateH, x
   sta Voice::pitch_slide::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr6 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::pitch_slide::rateL, x
   sta Voice::pitch_slide::rateL, x
   lda mp_return_value
   adc Voice::pitch_slide::rateH, x
   sta Voice::pitch_slide::rateH, x
:  clc
   rol mp_return_value+1
   rol mp_return_value
   bbr7 mp_slide_distance, :+
   clc
   lda mp_return_value+1
   adc Voice::pitch_slide::rateL, x
   sta Voice::pitch_slide::rateL, x
   lda mp_return_value
   adc Voice::pitch_slide::rateH, x
   sta Voice::pitch_slide::rateH, x

:  ; check if porta going down. if yes, invert rate
   lda Voice::pitch_slide::active, x
   cmp #2
   bne :+
   lda Voice::pitch_slide::rateL, x
   eor #%11111111
   inc
   sta Voice::pitch_slide::rateL, x
   lda Voice::pitch_slide::rateH, x
   eor #%11111111
   sta Voice::pitch_slide::rateH, x
:
.endmacro



; computes the frequency of a given pitch+fine combo
.macro COMPUTE_FREQUENCY cf_pitch, cf_fine, cf_output
   ; constant 136 cycles
   SETUP_MULTIPLICATION

   ; Store fine pitch (unsigned) in first factor
   lda cf_fine
   sta VERA_FX_CACHE_L
   stz VERA_FX_CACHE_M
   ; Load current pitch into .X
   ldx cf_pitch
   ; copy lower frequency to output
   lda pitch_dataL,x
   sta cf_output
   lda pitch_dataH,x
   sta cf_output+1

   ; compute difference between higher and lower frequency
   ldy cf_pitch
   iny
   sec
   lda pitch_dataL,y
   sbc pitch_dataL,x
   sta VERA_FX_CACHE_H ; here: contains frequency difference between the two adjacent half steps

   lda pitch_dataH,y
   sbc pitch_dataH,x
   sta VERA_FX_CACHE_U

   WRITE_MULTIPLICATION_RESULT

   ; fetch result from VRAM and add to coarse frequency
   lda VERA_data0
   clc
   adc cf_output
   sta cf_output
   lda VERA_data0
   adc cf_output+1
   sta cf_output+1

   stz VERA_FX_CTRL ; Cache Write Enable off
.endmacro


; This is used for modulation of the parameters that are only 6 bits wide,
; namely volume and pulse width.
; Modulation depth is at specified location, INDEXED BY .Y !  (-127 ... 127, 1 sign-bit, 7 magnitude bits)
; Modulation source is assumed to be in register A (-127 ... 127, 1 sign-bit, 7 magnitude bits)
; Modulation amount is returned in register A (twos-complement, -128 ... 127; yes, we deliberately use a range that is too large)
; This function changes .X, preserves .Y
.macro SCALE_S6 moddepth
   ; worst case: 99 cycles, best case: 97 cycles
   .local @result_positive
   .local @result_negative
   .local @end

   tax ; temporarily store mod source
   SETUP_MULTIPLICATION

   ; Mod source: extract sign and store lower 7 bits in operand
   txa
   and #%01111111 ; remove sign bit
   sta VERA_FX_CACHE_L
   stz VERA_FX_CACHE_M

   ; Mod depth: extract sign and store lower 7 bits in operand
   lda moddepth, y
   and #%01111111 ; remove sign bit
   sta VERA_FX_CACHE_H
   stz VERA_FX_CACHE_U

   WRITE_MULTIPLICATION_RESULT

   ; Determine sign of result
   txa
   and #%10000000 ; get sign bit of mod source
   clc
   adc moddepth, y ; overall sign bit is in negative flag now
   bmi @result_negative
@result_positive:
   lda VERA_data0
   bra @end
@result_negative:
   lda VERA_data0
   eor #$ff
   inc
@end:
   stz VERA_FX_CTRL ; Cache Write Enable off
.endmacro





; this is used for various modulation depth scalings of 16 bit modulation values (mainly pitch)
; modulation depth is assumed to be indexed by register Y
; modulation source is assumed to be indexed by register X (not preserved)
; result is added to the literal addresses resultL and resultH
; moddepth is in Scale5 format (see scale5.asm), passed at absolute address scale5_moddepth
; skipping is NOT done in this macro if modsource select is "none"
; modsourceL,x:modsourceH,x contain a twos-complement 16 bit value
; Must preserve .Y
.macro SCALE5_16 modsourceL, modsourceH, resultL, resultH
   SETUP_MULTIPLICATION
   lda modsourceL, x
   sta VERA_FX_CACHE_L
   lda modsourceH, x
   sta VERA_FX_CACHE_M
   ; from now on, the mod source isn't directly accessed anymore, so we can discard X

   lda scale5_moddepth
   and #%01110000
   lsr
   lsr
   lsr
   lsr
   tax
   lda scale5_mantissa_lut, x
   .local @moddepth_positive
   .local @moddepth_negative
   .local @sign_done
   ldx scale5_moddepth
   bmi @moddepth_negative
@moddepth_positive:
   sta VERA_FX_CACHE_H
   lda #1
   bra @sign_done
@moddepth_negative:
   eor #$ff
   inc
   sta VERA_FX_CACHE_H
   lda #$fe
@sign_done:
   sta VERA_FX_CACHE_U

   ; Put multiplication result in VRAM
   WRITE_MULTIPLICATION_RESULT

   ; Do bit-shifting
   ; The final result is expected in mzpwb
   ; can use mzpwb, mzpwb, mzpwf and mzpbf  (really, so many?)
   .local @shift_8_or_more
   .local @shift_7_or_less
   .local @shift_continue
   lda scale5_moddepth
   and #%00001000 ; see if we shift by 8 or more bits
   bne @shift_8_or_more
   @shift_7_or_less:
      lda scale5_moddepth
      and #%00000111
      tax
      lda VERA_data0
      sta mzpwb
      lda VERA_data0
      sta mzpwb+1
      lda VERA_data0;128 cycles
      @shift8_loop: ; maximum 7 iterations
         lsr
         ror mzpwb+1
         ror mzpwb
         dex
         bne @shift8_loop
      bra @shift_continue
   @shift_8_or_more:
      lda scale5_moddepth
      and #%00000111
      tax
      lda VERA_data0 ; we can straight ignore the LSB of the result
      lda VERA_data0
      sta mzpwb
      lda VERA_data0 ; high byte consists of either all ones or all zeros. We need that both as high byte, and as source of bits to shift from
      sta mzpwb+1
      @shift8_loop: ; maximum 7 iterations
         lsr
         ror mzpwb
         dex
         bne @shift8_loop
      stz mzpwb
@shift_continue:
   ; worst case 247

   lda mzpwb
   clc
   ; ---- end generic ----
   adc resultL
   sta resultL
   lda mzpwb+1
   adc resultH
   sta resultH

   stz VERA_FX_CTRL ; Cache Write Enable off
   ; Worst case 277 cycles
.endmacro






; this is used for various modulation depth scalings of 16 bit modulation values (mainly pitch)
; modulation depth is assumed to be indexed by register Y
; modulation source is assumed to be indexed by register X (not preserved)
; result is added to the literal addesses
; moddepth is allowed to have a sign bit (bit 7), passed at absolute address scale5_moddepth
; moddepth has the format  %SLLLHHHH
; where %HHHH is the number of rightshifts to be applied to the 16 bit mod source
; and %LLL is the number of the sub-level
; skipping is NOT done in this macro if modsource select is "none"
; modsourceH is also allowed to have a sign bit (bit 7)
.macro SCALE5_16_OLD modsourceL, modsourceH, resultL, resultH
   ; mzpbf will hold the sign
   stz mzpbf

   ; initialize zero page 16 bit value
   lda modsourceL, x
   sta mzpwb
   lda modsourceH, x
   and #%01111111
   cmp modsourceH, x
   sta mzpwb+1
   ; from now on, the mod source isn't directly accessed anymore, so we can discard X
   ; store the modulation sign
   beq :+
   inc mzpbf
:  ; 27 cycles worst case

   ; jump to macro-parameter independent code, which can be reused (hence, it is outside the macro)
   ; you can read that subroutine as if it was part of this macro.
   jsr scale5_16_internal ; worst case 226 (excluding JSR/RTS)

   ; now add/subtract scaling result to modulation destiny, according to sign
   .local @minusS
   .local @endS
   lda mzpbf
   ror
   bcs @minusS
   ; if we're here, sign is positive --> add
   clc
   lda mzpwb
   adc resultL
   sta resultL
   lda mzpwb+1
   adc resultH
   sta resultH
   bra @endS
@minusS:
   ; if we're here, sign is negative --> sub
   sec
   lda resultL
   sbc mzpwb
   sta resultL
   lda resultH
   sbc mzpwb+1
   sta resultH
@endS:
   ; worst case total: 260 cycles
.endmacro


scale5_moddepth:
   .byte 0
; does the heavy lifting of the above macro scale5_16. Reusable code here.
scale5_16_internal:
   ; do %HHHH rightshifts
   ; cycle counting needs to be redone, because initially, I forgot about LSR, so I CLCed before each ROR
   ; instead of the naive approach of looping over rightshifting a 16 bit variable
   ; we are taking a more efficient approach of testing each bit
   ; of the %HHHH value and perform suitable actions
   ; alternative rightshifts: binary branching
   ; check bit 3
   lda scale5_moddepth
   and #%00001000
   beq @skipH3
   ; 8 rightshifts = copy high byte to low byte, set high byte to 0
   ; the subsequent rightshifting can be done entirely inside accumulator, no memory access needed
   lda scale5_moddepth
   and #%00000111
   bne :+          ; if no other bit is set, we just move the bytes and are done
   lda mzpwb+1
   sta mzpwb
   stz mzpwb+1
   jmp @endH
:  ; if we got here, we've got a nonzero number of rightshifts to be done in register A
   tax
   lda mzpwb+1;22 cycles
@loopH:
   lsr
   dex
   bne @loopH
   sta mzpwb
   stz mzpwb+1
   jmp @endH    ; worst case if bit 3 is set: 15 rightshifts, makes 57 cycles (including this jmp)
@skipH3:
   ; check bit 2
   lda scale5_moddepth
   and #%00000100
   beq @skipH2
   lda mzpwb
   lsr mzpwb+1
   ror
   lsr mzpwb+1
   ror
   lsr mzpwb+1
   ror
   lsr mzpwb+1
   ror
   sta mzpwb;51 cycles
@skipH2:
   ; check bit 1
   lda scale5_moddepth
   and #%00000010
   beq @skipH1
   lda mzpwb
   lsr mzpwb+1
   ror
   lsr mzpwb+1
   ror
   sta mzpwb;78 cycles
@skipH1:
   ; check bit 0
   lda scale5_moddepth
   and #%00000001
   beq @skipH0
   lsr mzpwb+1
   ror mzpwb;96 cycles worst case
@skipH0:
@endH:
   ; maximum number of cycles for rightshifts is 96 cycles. Good compared to 230 from naive approach.
   ; still hurts tho.

   ; do sublevel scaling
   ; select subroutine
   lda scale5_moddepth
   and #%01110000
   beq :+
   lsr
   ror
   ror
   tax
   jmp (@tableL-2, x)  ; if x=0, nothing has to be done. if x=2,4,6 or 8, jump to respective subroutine
:  jmp @endL
   ; 22 cycles
@tableL:
   .word @sublevel_1
   .word @sublevel_2
   .word @sublevel_3
   .word @sublevel_4
@sublevel_1:
   ; 2^(1/5) ~= %1.001
   ; do first ROR while copying to mzpwc
   lda mzpwb+1
   lsr
   sta mzpwc+1
   lda mzpwb
   ror
   sta mzpwc
   ; then do remaining RORS with high byte in accumulator and low byte in memory
   lda mzpwc+1
   lsr
   ror mzpwc
   lsr
   ; but last low byte ROR already in accumulator, since we are going to do addition with it
   sta mzpwc+1
   lda mzpwc
   ror
   clc
   adc mzpwb
   sta mzpwb
   lda mzpwc+1
   adc mzpwb+1
   sta mzpwb+1
   jmp @endL  ; 62 cycles ... ouch!
@sublevel_2:
   ; 2^(2/5) ~= %1.01
   ; do first ROR while copying to mzpwc
   lda mzpwb+1
   lsr
   sta mzpwc+1
   lda mzpwb
   ror
   sta mzpwc
   ; do second ROR and addition
   lsr mzpwc+1
   lda mzpwc
   ror
   clc
   adc mzpwb
   sta mzpwb
   lda mzpwc+1
   adc mzpwb+1
   sta mzpwb+1  
   jmp @endL   ; 49 cycles
@sublevel_3:
   ; 2^(3/5) ~= %1.1
   lda mzpwb+1
   lsr
   sta mzpwc+1
   lda mzpwb
   ror
   clc
   adc mzpwb
   sta mzpwb
   lda mzpwc+1
   adc mzpwb+1
   sta mzpwb+1
   jmp @endL  ; 35 cycles
@sublevel_4:
   ; 2^(4/5) ~= %1.11
   ; do first ROR while copying to mzpwc
   lda mzpwb+1
   lsr
   sta mzpwc+1
   lda mzpwb
   ror
   sta mzpwc
   ; do second ROR while copying to mzpwf
   lda mzpwc+1
   lsr
   sta mzpwf+1
   lda mzpwc
   ror
   ;sta mzpwf ;redundant, because we don't read from it anyway
   ; do all additions
   ; first addition
   clc
   adc mzpwc ; mzpwf still in A
   sta mzpwc
   lda mzpwf+1
   adc mzpwc+1
   sta mzpwc+1
   ; second addition
   clc
   lda mzpwc
   adc mzpwb
   sta mzpwb
   lda mzpwc+1
   adc mzpwb+1
   sta mzpwb+1
   ; 66 cycles ... ouch!!
@endL:
   ; worst case 90 cycles (sublevel scaling only)

   ; determine overall sign (mod source * mod depth)
   lda scale5_moddepth
   and #%10000000
   beq :+
   inc mzpbf
:  ; now if lowest bit of mzpbf is even, sign is positive and if it's odd, sign is negative

   ; worst case right shift: 96 cycles
   ; worst case sublevel scaling: 103 cycles
   ; worst case total: 199 cycles

   ; return to macro
   rts




.endif ; .ifndef ::SYNTH_ENGINE_SYNTH_MACROS_ASM