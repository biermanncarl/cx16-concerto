; Copyright 2021-2025 Carl Georg Biermann


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
; Expects voice index in X, instrument index in Y, slide distance in mp_slide_distance
.macro MUL8x8_PORTA ; uses ZP variables in the process
   .local @slide_up
   .local @slide_down
   .local @end
   mp_slide_distance = cn_slide_distance ; must be the same as in "continue_note"!

   ; the idea is that portamento is finished in a constant time
   ; that means, rate must be higher, the larger the porta distance is
   ; This is achieved by multiplying the "base rate" by the porta distance

   SETUP_MULTIPLICATION

   lda instruments::Instrument::porta_r, y
   sta VERA_FX_CACHE_L
   stz VERA_FX_CACHE_M
   lda mp_slide_distance
   sta VERA_FX_CACHE_H
   stz VERA_FX_CACHE_U

   WRITE_MULTIPLICATION_RESULT
   stz VERA_addr_low ; here, we actually need the least significant byte, as well, so need to return the address

   ; check if porta going down. if yes, invert rate
   lda Voice::pitch_slide::active, x
   cmp #2
   beq @slide_down
@slide_up:
   lda VERA_data0
   sta Voice::pitch_slide::rateL, x
   lda VERA_data0
   sta Voice::pitch_slide::rateH, x
   bra @end
@slide_down:
   lda VERA_data0
   eor #$ff
   inc
   sta Voice::pitch_slide::rateL, x
   clc
   bne :+
   sec
:  lda VERA_data0
   eor #$ff
   adc #0
   sta Voice::pitch_slide::rateH, x
@end:
   stz VERA_FX_CTRL ; Cache Write Enable off
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
   ; worst case: 95 cycles, best case: 93 cycles
   .local @result_positive
   .local @result_negative
   .local @end

   tax ; temporarily store mod source
   SETUP_MULTIPLICATION

   ; Mod source: extract sign and store lower 7 bits in operand
   txa
   asl ; remove sign bit, and increase modulation range at the same time
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





; TODO: make scale5_moddepth a ZP variable

; this is used for various modulation depth scalings of 16 bit modulation values (mainly pitch)
; modulation depth is assumed to be indexed by register Y
; modulation source is assumed to be indexed by register X (not preserved)
; result is added to the literal addresses resultL and resultH
; moddepth is in Scale5 format (see scale5.asm), passed at absolute address scale5_moddepth
; skipping is NOT done in this macro if modsource select is "none"
; modsourceL,x:modsourceH,x contain a sign bit (bit 7 of the high byte) and 15 magnitude bits
; Must preserve .Y
.macro SCALE5_16 modsourceL, modsourceH, resultL, resultH
   .local @result_positive
   .local @result_negative
   .local @end
   SETUP_MULTIPLICATION

   ; mzpbf will aid in determining the sign of the modulation

   ; Get the absolute value of the modsource into the 32bit cache, and extract the sign.
   lda modsourceH, x
   sta mzpbf ; for sign calculation later
   and #%01111111 ; remove sign
   sta VERA_FX_CACHE_M
   lda modsourceL, x
   sta VERA_FX_CACHE_L

   ; from now on, the mod source isn't directly accessed anymore, so we can discard X

   jsr scale5_16_internal

   bpl @result_positive
@result_negative:
   lda resultL
   sec
   sbc mzpwb
   sta resultL
   lda resultH
   sbc mzpwb+1
   sta resultH
   bra @end
@result_positive:
   lda resultL
   clc
   adc mzpwb
   sta resultL
   lda mzpwb+1
   adc resultH
   sta resultH

@end:
   stz VERA_FX_CTRL ; Cache Write Enable off
   ; Worst case 223 cycles
.endmacro


scale5_moddepth = mzpwf ; only the first byte is used

; does the heavy lifting of the above macro scale5_16. Reusable code here.
.proc scale5_16_internal
   lda scale5_moddepth
   and #%01110000
   lsr
   lsr
   lsr
   lsr
   tax
   lda scale5_mantissa_lut, x
   sta VERA_FX_CACHE_H
   lda #1
   sta VERA_FX_CACHE_U;77

   ; Put multiplication result in VRAM
   WRITE_MULTIPLICATION_RESULT;93

   ; Do bit-shifting
   ; The final result is expected in mzpwb
   ; can use mzpwb, mzpwc, mzpwf and mzpbf  (really, so many?)
   lda scale5_moddepth
   and #%00001000 ; see if we shift by 8 or more bits   ;99
   beq @shift_7_or_less
   @shift_8_or_more:
      lda scale5_moddepth
      and #%00000111
      tax
      lda VERA_data0 ; we can straight ignore the LSB of the result
      lda VERA_data0
      cpx #0
      beq @shift8_loop_end
      @shift8_loop: ; maximum 7 iterations
         lsr
         dex
         bne @shift8_loop
      @shift8_loop_end:
      sta mzpwb
      stz mzpwb+1
      bra @shift_continue; worst case 180 cycles (incl. this bra)
   @shift_7_or_less:
         lda scale5_moddepth
         and #%00000111
         asl
         tax
         lda VERA_data0
         sta mzpwb
         lda VERA_data0
         jmp (@jmptbl, x)
      @jmptbl:
         .word @unrolled_loop + 7 * 3
         .word @unrolled_loop + 6 * 3
         .word @unrolled_loop + 5 * 3
         .word @unrolled_loop + 4 * 3
         .word @unrolled_loop + 3 * 3
         .word @unrolled_loop + 2 * 3
         .word @unrolled_loop + 1 * 3
         .word @unrolled_loop + 0 * 3
      @unrolled_loop:
         lsr
         ror mzpwb
         lsr
         ror mzpwb
         lsr
         ror mzpwb
         lsr
         ror mzpwb
         lsr
         ror mzpwb
         lsr
         ror mzpwb
         lsr
         ror mzpwb
         sta mzpwb+1

@shift_continue:
   ; worst case 181

   ; Determine sign of output
   lda mzpbf
   and #%10000000 ; isolate the sign bit of the mod source
   adc scale5_moddepth  ; $ff isn't a valid scale5 value, so for the sake of determining the overflow of this calculation, the carry flag doesn't matter
   ; overall sign bit is in negative flag now

   ; return to macro
   rts
.endproc


.endif ; .ifndef ::SYNTH_ENGINE_SYNTH_MACROS_ASM