.ifndef SYNTH_MACROS_INC
SYNTH_MACROS_INC = 1

.macro VERA_SET_VOICE_PARAMS n_voice, frequency, volume, waveform
    VERA_SET_ADDR $1F9C0+4*n_voice, 1
    lda #0
    sta VERA_ctrl
    lda #<frequency
    sta VERA_data0
    lda #>frequency
    sta VERA_data0
    lda #volume
    sta VERA_data0
    lda #waveform
    sta VERA_data0
.endmacro

; parameters in memory, but PSG voice number X
.macro VERA_SET_VOICE_PARAMS_MEM_X frequency, volume, waveform
    lda #$11
	sta VERA_addr_bank
	lda #$F9
	sta VERA_addr_high
	txa
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

; mutes PSG voice with index stored in register x
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
CP_diff:
   .word 0
.macro COMPUTE_FREQUENCY cf_pitch, cf_fine, cf_output ; done in ISR
    lda cf_pitch
    asl         ; multiply by 2 to get address
    tax
    ; copy lower frequency to output
    lda pitch_data,x
    sta cf_output
    inx
    lda pitch_data,x
    sta cf_output+1 ; 26 cycles

    ; compute difference between higher and lower frequency
    txa
    tay
    iny
    dex
    sec
    lda pitch_data,y
    sbc pitch_data,x
    sta mzpwb   ; here: contains frequency difference between the two adjacent half steps
    inx
    iny
    lda pitch_data,y
    sbc pitch_data,x
    sta mzpwb+1 ; 36 cycles

    ; add 0.fine * mzpwb to output
    lda cf_fine
    sta mzpbb ; 7 cycles

    clc
    ror mzpwb+1
    ror mzpwb
    bbr7 mzpbb, @skip_bit7
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
    bbr6 mzpbb, @skip_bit6
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
    bbr5 mzpbb, @skip_bit5
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
    bbr4 mzpbb, @skip_bit4
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
    bbr3 mzpbb, @skip_bit3
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
    bbr2 mzpbb, @skip_bit2
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
    bbr1 mzpbb, @skip_bit1
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
    bbr0 mzpbb, @skip_bit0
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



.endif