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

; sets volume to value stored in register X
.macro VERA_SET_VOICE_FREQUENCY svf_n_voice, svf_frequency
   VERA_SET_ADDR ($1F9C0+4*svf_n_voice), 1
   lda #0
   sta VERA_ctrl
   lda svf_frequency
   sta VERA_data0
   lda svf_frequency+1
   sta VERA_data0
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
; may have to redo it with indirect mode for more flexibility later
; Pitch Computation Variables
.macro COMPUTE_FREQUENCY cf_pitch, cf_fine, cf_output ; done in ISR
   .local @skip_bit0
   .local @skip_bit1
   .local @skip_bit2
   .local @skip_bit3
   .local @skip_bit4
   .local @skip_bit5
   .local @skip_bit6
   .local @skip_bit7
   ldx cf_pitch
   ; copy lower frequency to output
   lda pitch_dataL,x
   sta cf_output
   lda pitch_dataH,x
   sta cf_output+1 ; 20 cycles

   ; compute difference between higher and lower frequency
   ldy cf_pitch
   iny
   sec
   lda pitch_dataL,y
   sbc pitch_dataL,x
   sta mzpwb   ; here: contains frequency difference between the two adjacent half steps

   lda pitch_dataH,y
   sbc pitch_dataH,x
   sta mzpwb+1 ; 32 cycles

   ; add 0.fine * mzpwb to output
   lda cf_fine
   sta mzpbf ; 7 cycles

   lsr mzpwb+1
   ror mzpwb
   bbr7 mzpbf, @skip_bit7
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1 ; 36 cycles
@skip_bit7:
   lsr mzpwb+1
   ror mzpwb
   bbr6 mzpbf, @skip_bit6
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1
@skip_bit6:
   lsr mzpwb+1
   ror mzpwb
   bbr5 mzpbf, @skip_bit5
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1
@skip_bit5:
   lsr mzpwb+1
   ror mzpwb
   bbr4 mzpbf, @skip_bit4
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1
@skip_bit4:
   lsr mzpwb+1
   ror mzpwb
   bbr3 mzpbf, @skip_bit3
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1
@skip_bit3:
   lsr mzpwb+1
   ror mzpwb
   bbr2 mzpbf, @skip_bit2
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1
@skip_bit2:
   lsr mzpwb+1
   ror mzpwb
   bbr1 mzpbf, @skip_bit1
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1
@skip_bit1:
   lsr mzpwb+1
   ror mzpwb
   bbr0 mzpbf, @skip_bit0
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1 ; 36 * 8 cycles = 288 cycles
   ; total 357 cycles + page crossings ~= 45 us
@skip_bit0:
.endmacro



; This macro multiplies the value in the accumulator with a value in memory.
; Only the 7 lowest bits of the memory value are considered.
; The result will be right-shifted 6 times,
; meaning that multiplying with 64 is actually multiplying with 1.
; The result is returned in the accumulator.
; Index denotes, whether the memory held value is indexed by X (1), by Y (2), or not at all (0)
.macro SCALE_U7 su7_value, index
   .local @skip_bit0
   .local @skip_bit1
   .local @skip_bit2
   .local @skip_bit3
   .local @skip_bit4
   .local @skip_bit5
   .local @skip_bit6
   ; ZP variables available for multiplication:
   ; mzpwb, mzpbf
   sta mzpwb   ; this will hold the right-shifted value
   .if(index=0)
      lda su7_value
   .endif
   .if(index=1)
      lda su7_value, x
   .endif
   .if(index=2)
      lda su7_value, y
   .endif
   sta mzpbf   ; this is used for bit-testing
   lda #0

   bbr6 mzpbf, @skip_bit6
   clc
   adc mzpwb
@skip_bit6:
   lsr mzpwb

   bbr5 mzpbf, @skip_bit5
   clc
   adc mzpwb
@skip_bit5:
   lsr mzpwb

   bbr4 mzpbf, @skip_bit4
   clc
   adc mzpwb
@skip_bit4:
   lsr mzpwb

   bbr3 mzpbf, @skip_bit3
   clc
   adc mzpwb
@skip_bit3:
   lsr mzpwb

   bbr2 mzpbf, @skip_bit2
   clc
   adc mzpwb
@skip_bit2:
   lsr mzpwb

   bbr1 mzpbf, @skip_bit1
   clc
   adc mzpwb
@skip_bit1:
   lsr mzpwb

   bbr0 mzpbf, @skip_bit0
   clc
   adc mzpwb
@skip_bit0:
   ; worst case: 91 cycles. best case: 63 cycles. Average: 77 cycles.
.endmacro



; This is used for modulation of the parameters that are only 6 bits wide,
; namely volume and pulse width.
; The index parameter can be 0, 1 or 2. It influences how the modulation depth is indexed (no indexing, by X, by Y)
; modulation source is assumed to be in register A (and all flags from loading of A)
; result is returned in register A
.macro SCALE_S6 moddepth, index
   ; with this sequence, we do several tasks at once:
   ; We extract the sign from the modulation source and store it in mzpbf
   ; We truncate the sign from the modulation source
   ; and right shift it effectively once, because the amplitude of any modulation source is too high anyway
   stz mzpwc+1
   asl         ; push sign out
   rol mzpwc+1   ; push sign into variable
   lsr
   lsr
   ; initialize zero page 8 bit value
   sta mzpwc   ; only low byte is used

   .local @skip_bit0
   .local @skip_bit1
   .local @skip_bit2
   .local @skip_bit3
   .local @skip_bit4
   .local @skip_bit5
   .local @skip_bit6
   ; ZP variables available for multiplication:
   ; mzpwb, mzpbf
   sta mzpwb   ; this will hold the right-shifted value
   .if(index=0)
      lda moddepth
   .endif
   .if(index=1)
      lda moddepth, x
   .endif
   .if(index=2)
      lda moddepth, y
   .endif
   sta mzpbf   ; this is used for bit-testing
   lda #0

   bbr6 mzpbf, @skip_bit6
   clc
   adc mzpwb
@skip_bit6:
   lsr mzpwb

   bbr5 mzpbf, @skip_bit5
   clc
   adc mzpwb
@skip_bit5:
   lsr mzpwb

   bbr4 mzpbf, @skip_bit4
   clc
   adc mzpwb
@skip_bit4:
   lsr mzpwb

   bbr3 mzpbf, @skip_bit3
   clc
   adc mzpwb
@skip_bit3:
   lsr mzpwb

   bbr2 mzpbf, @skip_bit2
   clc
   adc mzpwb
@skip_bit2:
   lsr mzpwb

   bbr1 mzpbf, @skip_bit1
   clc
   adc mzpwb
@skip_bit1:
   lsr mzpwb

   bbr0 mzpbf, @skip_bit0
   clc
   adc mzpwb
@skip_bit0:
   ; result is in register A
   sta mzpwb   ; save it

   ; determine overall sign (mod source * mod depth)
   .if(index=0)
      lda moddepth
   .endif
   .if(index=1)
      lda moddepth, x
   .endif
   .if(index=2)
      lda moddepth, y
   .endif
   and #%10000000
   beq :+
   inc mzpwc+1
:  ; now if lowest bit of mzpbf is even, sign is positive and if it's odd, sign is negative

   ; now add/subtract scaling result to modulation destiny, according to sign
   .local @minusS
   .local @endS
   lda mzpwc+1
   ror
   bcs @minusS
   ; if we're here, sign is positive
   lda mzpwb
   bra @endS
@minusS:
   ; if we're here, sign is negative
   lda mzpwb
   eor #%11111111
   inc
@endS:
.endmacro



; this is used for various modulation depth scalings of 16 bit modulation values (mainly pitch)
; modulation depth is assumed to be indexed by register Y
; modulation source is assumed to be indexed by register X (not preserved)
; result is added to the literal addesses
; moddepth is allowed to have a sign bit (bit 7)
; moddepth has the format  %SLLLHHHH
; where %HHHH is the number of rightshifts to be applied to the 16 bit mod source
; and %LLL is the number of the sub-level
; skipping is NOT done in this macro if modsource select is "none"
; modsourceH is also allowed to have a sign bit (bit 7)
.macro SCALE5_16 modsourceL, modsourceH, resultL, resultH
   ; mzpbf will hold the sign
   stz mzpbf

   ; initialize zero page 16 bit value
   lda modsourceL, x
   sta mzpwb
   lda modsourceH, x
   and #%01111111
   cmp modsourceH, x
   sta mzpwb+1        ; 14 cycles
   ; from now on, the mod source isn't directly accessed anymore, so we can discard X
   ; store the modulation sign
   beq :+
   inc mzpbf
:

   ; jump to macro-parameter independent code, which can be reused (hence, it is outside the macro)
   ; you can read that subroutine as if it was part of this macro.
   jsr scale5_16_internal

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
   ; 35 cycles
   ; worst case overall: 35 + 64 + 24 + 107 + 14 = 244 cycles ... much more than I hoped. (even more now with proper sign handling)
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
   lda mzpwb+1
@loopH:
   lsr
   dex
   bne @loopH
   sta mzpwb
   stz mzpwb+1
   jmp @endH    ; worst case if bit 3 is set: 15 rightshifts, makes 9*7 + 35 cycles = 98 cycles
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
   sta mzpwb
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
   sta mzpwb
@skipH1:
   ; check bit 1
   lda scale5_moddepth
   and #%00000001
   beq @skipH0
   lsr mzpwb+1
   ror mzpwb
@skipH0:    ; worst case if bit 3 is not set: 107 cycles.
@endH:
   ; maximum number of cycles for rightshifts is 107 cycles. Good compared to 230 from naive approach.
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

   ; determine overall sign (mod source * mod depth)
   lda scale5_moddepth
   and #%10000000
   beq :+
   inc mzpbf
:  ; now if lowest bit of mzpbf is even, sign is positive and if it's odd, sign is negative

   ; return to macro
   rts




; This macro multiplies the value in the accumulator with a value in memory.
; The result will be right-shifted 7 times,
; meaning that multiplying with 128 is actually multiplying with 1.
; The result is returned in the accumulator.
; Index denotes, whether the memory held value is indexed by X (1), by Y (2), or not at all (0)
.macro SCALE_U8 su8_value, index
   .local @skip_bit0
   .local @skip_bit1
   .local @skip_bit2
   .local @skip_bit3
   .local @skip_bit4
   .local @skip_bit5
   .local @skip_bit6
   .local @skip_bit7
   ; ZP variables available for multiplication:
   ; mzpwb, mzpbf
   sta mzpwb   ; this will hold the right-shifted value
   .if(index=0)
      lda su8_value
   .endif
   .if(index=1)
      lda su8_value, x
   .endif
   .if(index=2)
      lda su8_value, y
   .endif
   sta mzpbf   ; this is used for bit-testing
   lda #0

   bbr7 mzpbf, @skip_bit7
   clc
   adc mzpwb
@skip_bit7:
   lsr mzpwb

   bbr6 mzpbf, @skip_bit6
   clc
   adc mzpwb
@skip_bit6:
   lsr mzpwb

   bbr5 mzpbf, @skip_bit5
   clc
   adc mzpwb
@skip_bit5:
   lsr mzpwb

   bbr4 mzpbf, @skip_bit4
   clc
   adc mzpwb
@skip_bit4:
   lsr mzpwb

   bbr3 mzpbf, @skip_bit3
   clc
   adc mzpwb
@skip_bit3:
   lsr mzpwb

   bbr2 mzpbf, @skip_bit2
   clc
   adc mzpwb
@skip_bit2:
   lsr mzpwb

   bbr1 mzpbf, @skip_bit1
   clc
   adc mzpwb
@skip_bit1:
   lsr mzpwb

   bbr0 mzpbf, @skip_bit0
   clc
   adc mzpwb
@skip_bit0:
   ; worst case: 103 cycles. best case: 71 cycles. Average: 87 cycles.
.endmacro

.endif ; .ifndef ::SYNTH_ENGINE_SYNTH_MACROS_ASM