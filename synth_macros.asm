.ifndef SYNTH_MACROS_INC
SYNTH_MACROS_INC = 1

.macro VERA_SET_VOICE_PARAMS n_voice, frequency, volume, waveform
    VERA_SET_ADDR $1F9C0+4*n_voice, 1
    stz VERA_ctrl
    lda #<frequency
    sta VERA_data0
    lda #>frequency
    sta VERA_data0
    lda #volume
    sta VERA_data0
    lda #waveform
    sta VERA_data0
.endmacro

; parameters in memory, but PSG voice number A
.macro VERA_SET_VOICE_PARAMS_MEM_A frequency, volume, waveform
    pha
    lda #$11
	sta VERA_addr_bank
	lda #$F9
	sta VERA_addr_high
	pla
    asl
    asl
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

; mutes a voice
.macro VERA_MUTE_VOICE n_voice
    VERA_SET_ADDR ($1F9C0+4*n_voice+2), 1
    lda #0
    sta VERA_ctrl
    stz VERA_data0
.endmacro

; sets volume to value stored in register X
.macro VERA_SET_VOICE_VOLUME_X n_voice, channels
    VERA_SET_ADDR ($1F9C0+4*n_voice+2), 1
    lda #0
    sta VERA_ctrl
    txa
    clc
    adc #channels
    sta VERA_data0
.endmacro

; mutes PSG voice with index stored in register X
.macro VERA_MUTE_VOICE_X
    lda #$11
	sta VERA_addr_bank
	lda #$F9
	sta VERA_addr_high
    txa
    asl
    asl
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
   sta VERA_addr_bank
   lda #$F9
   sta VERA_addr_high
   pla
   asl
   asl
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



; computes the frequency of a given pitch+fine combo
; may have to redo it with indirect mode for more flexibility later
; Pitch Computation Variables
.macro COMPUTE_FREQUENCY cf_pitch, cf_fine, cf_output ; done in ISR
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

   clc
   ror mzpwb+1
   ror mzpwb
   bbr7 mzpbf, @skip_bit7
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1 ; 38 cycles
@skip_bit7:
   clc
   ror mzpwb+1
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
   clc
   ror mzpwb+1
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
   clc
   ror mzpwb+1
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
   clc
   ror mzpwb+1
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
   clc
   ror mzpwb+1
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
   clc
   ror mzpwb+1
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
   clc
   ror mzpwb+1
   ror mzpwb
   bbr0 mzpbf, @skip_bit0
   clc
   lda mzpwb
   adc cf_output
   sta cf_output
   lda mzpwb+1
   adc cf_output+1
   sta cf_output+1 ; 38 * 8 cycles = 304 cycles
   ; total 373 cycles + page crossings ~= 47 us
@skip_bit0:
.endmacro





; this is used for various modulation depth scalings of 16 bit modulation values
; modulation depth is assumed to be indexed by register Y
; modulation source is assumed to be indexed by register X
; result is added to the literal addesses
; moddepth is allowed to have a sign bit (bit 7)
; moddepth has the format  %SLLLHHHH
; where %HHHH is the number of rightshifts to be applied to the 16 bit mod source
; and %LLL is the number of the sub-level
; skipping is NOT done in this macro if modsource select is "none"
.macro SCALE5_16 modsourceL, modsourceH, moddepth, resultL, resultH

    ; initialize zero page 16 bit value
    lda modsourceL, x
    sta mzpwb
    lda modsourceH, x
    sta mzpwb+1        ; 14 cycles


    ; do %HHHH rightshifts
    ; instead of the naive approach of looping over rightshifting a 16 bit variable
    ; we are taking a more efficient approach of testing each bit
    ; of the %HHHH value and perform suitable actions
    ; alternative rightshifts: binary branching
    .local @skipH3
    .local @skipH2
    .local @skipH1
    .local @skipH0
    .local @endH
    .local @loopH
    ; check bit 3
    lda moddepth, y
    and #%00001000
    beq @skipH3
    ; 8 rightshifts = copy high byte to low byte, set high byte to 0
    ; the subsequent rightshifting can be done entirely inside accumulator
    lda moddepth, y
    and #%00000111
    bne :+          ; if no other bit is set, we just move the bytes and are done
    lda mzpwb+1
    sta mzpwb
    stz mzpwb+1
    jmp @endH
:   phx ; if we got here, we've got a nonzero number of rightshifts to be done in register A
    tax
    lda mzpwb+1
@loopH:
    clc
    ror
    dex
    bne @loopH
    plx
    sta mzpwb
    stz mzpwb+1
    jmp @endH    ; worst case if bit 3 is set: 15 rightshifts, makes 9*7 + 35 cycles = 98 cycles
@skipH3:
    ; check bit 2
    lda moddepth, y
    and #%00000100
    beq @skipH2
    ; as we are doing 4 rightshifts, a little trickery is useful to prevent us from
    ; doing CLC every time:
    ; we take the low byte into the accumulator and AND it with %11110000 -> 2 cycles instead of 6
    lda mzpwb
    and #%11110000
    clc
    ror mzpwb+1
    ror
    ror mzpwb+1
    ror
    ror mzpwb+1
    ror
    ror mzpwb+1
    ror
    sta mzpwb
@skipH2:
    ; check bit 1
    lda moddepth, y
    and #%00000010
    beq @skipH1
    lda mzpwb
    clc
    ror mzpwb+1
    ror
    clc
    ror mzpwb+1
    ror
    sta mzpwb
@skipH1:
    ; check bit 1
    lda moddepth, y
    and #%00000001
    beq @skipH0
    clc
    ror mzpwb+1
    ror mzpwb
@skipH0:    ; worst case if bit 3 is not set: 107 cycles.
@endH:
    ; maximum number of cycles for rightshifts is 107 cycles. Good compared to 230 from naive approach.
    ; still hurts tho.


    ; do sublevel scaling
    .local @endL
    .local @tableL
    .local @sublevel_1
    .local @sublevel_2
    .local @sublevel_3
    .local @sublevel_4
    ; select subroutine
    lda moddepth, y
    and #%01110000
    beq :+
    clc
    ror
    ror
    ror
    tax
    jmp (@tableL-2, x)  ; if x=0, nothing has to be done. if x=2,4,6 or 8, jump to respective subroutine
:   jmp @endL
    ; 24 cycles
@tableL:
    .word @sublevel_1
    .word @sublevel_2
    .word @sublevel_3
    .word @sublevel_4
@sublevel_1:
    ; 2^(1/5) ~= %1.001
    ; do first ROR while copying to mzpwc
    lda mzpwb+1
    clc
    ror
    sta mzpwc+1
    lda mzpwb
    ror
    sta mzpwc
    ; then do remaining RORS with high byte in accumulator and low byte in memory
    lda mzpwc+1
    clc
    ror
    ror mzpwc
    clc
    ror
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
    clc
    ror
    sta mzpwc+1
    lda mzpwb
    ror
    sta mzpwc
    ; do second ROR and addition
    clc
    ror mzpwc+1
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
    clc
    ror
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
    lda mzpwb+1
    clc
    ror
    sta mzpwc+1
    lda mzpwb
    ror
    sta mzpwc
    clc
    adc mzpwb
    sta mzpwb
    lda mzpwc+1
    adc mzpwb+1
    sta mzpwb+1
    clc
    ror
    sta mzpwc+1
    lda mzpwc
    ror
    clc
    adc mzpwb
    sta mzpwb
    lda mzpwc+1
    adc mzpwb+1
    sta mzpwb+1  ; 64 cycles ... ouch!!
@endL:



    ; now add/subtract scaling result to modulation destiny, according to sign
    .local @minusS
    .local @endS
    lda moddepth, y
    and #%10000000
    bne @minusS
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
    ; worst case overall: 35 + 64 + 24 + 107 + 14 = 244 cycles ... much more than I hoped.
.endmacro




; this is used for volume scaling
; modulation depth is assumed to be indexed by register Y
; value to be scaled is assumed to be in register A
; result is returned in register A
; volume is moddepth
; moddepth has the format  %0LLL0HHH
; where %HHHH is the number of rightshifts to be applied to the volume signal
; and %LLL is the number of the sub-level
.macro VOLUME_SCALE5_8 moddepth

    ; initialize zero page 8 bit value
    sta mzpwb   ; only low byte is used  (3 cycles)

    ; do %0HHH rightshifts (highest bit is discarded, because 7 rightshifts is maximum)
    ; TODO: check highest bit first ... (if that gives us any advantage)
    .local @endH
    .local @loopH
    .local @skipH2
    clc ; do a clc so every branch below can assume carry is cleared
    ; check bit 2, and do 4 RORs if it's set
    lda moddepth, y
    and #%00000100
    beq @skipH2 ; or skip this part if it's clear
    lda mzpwb
    and #%11110000
    ror
    ror
    ror
    ror
    sta mzpwb
@skipH2:
    lda moddepth, y
    and #%00000011
    bne :+          ; if no bit is set, we are done
    jmp @endH
:   phx ; if we got here, we've got a nonzero number of rightshifts to be done in register A
    tax
    lda mzpwb
@loopH:
    ror
    clc ; doing clc after, because we assume it's cleared and we leave it clear (just as we do with toilets)
    dex
    bne @loopH
    plx
    sta mzpwb   ; worst case: 7 rightshifts, makes 45 + 3*9 = 72 cycles  (naive approach without bit 2 checking would be 84 ... almost not worth it to check it separately)
@endH:

    ; do sublevel scaling
    .local @endL
    .local @tableL
    .local @sublevel_1
    .local @sublevel_2
    .local @sublevel_3
    .local @sublevel_4
    ; select subroutine
    lda moddepth, y
    and #%01110000
    beq :+
    clc
    ror
    ror
    ror
    tax
    jmp (@tableL-2, x)  ; if x=0, nothing has to be done. if x=2,4,6 or 8, jump to respective subroutine
:   lda mzpwb
    jmp @endL
    ; 24 cycles
@tableL:
    .word @sublevel_1
    .word @sublevel_2
    .word @sublevel_3
    .word @sublevel_4
@sublevel_1:
    ; 2^(1/5) ~= %1.001
    lda mzpwb
    and #%11111000  ; saves 3 clc=4 cycles, adds 2 cycles --> saves 4 cycles
    ; no clc is needed in the beginning, since the select subroutine code guarantees it's cleared
    ror
    ror
    ror
    adc mzpwb
    jmp @endL  ; 17 cycles
@sublevel_2:
    ; 2^(2/5) ~= %1.01
    ; refer to @sublevel_1 for code commentary
    lda mzpwb
    and #%11111100
    ror
    ror
    adc mzpwb
    jmp @endL  ; 15 cycles
@sublevel_3:
    ; 2^(3/5) ~= %1.1
    lda mzpwb
    ror
    clc
    adc mzpwb
    jmp @endL  ; 13 cycles
@sublevel_4:
    ; 2^(4/5) ~= %1.11
    lda mzpwb
    ror
    sta mzpwb+1 ; save intermediate
    clc
    ror
    clc
    adc mzpwb+1 ; no clc after this ... if we get a carry, result is broken anyway
    adc mzpwb   ; 20 cycles
@endL:
    ; result is in register A

    ; worst case overall: 20 + 24 + 72 + 3 = 119 cycles ... more than I hoped.
.endmacro



.endif