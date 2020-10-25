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

.macro VERA_SET_VOICE_PARAMS_MEM frequency, volume, waveform
    VERA_SET_ADDR $1F9C0, 1
    lda #0
    sta VERA_ctrl
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
.macro COMPUTE_FREQUENCY cf_pitch, cf_fine, cf_output
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
    sta CP_diff
    inx
    iny
    lda pitch_data,y
    sbc pitch_data,x
    sta CP_diff+1 ; 38 cycles

    ; add 0.fine * CP_diff to output
    lda cf_fine
    sta my_bit_register ; 8 cycles

    clc
    ror CP_diff+1
    ror CP_diff
    bbr7 my_bit_register, @skip_bit7
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1 ; 42 cycles
@skip_bit7:
    clc
    ror CP_diff+1
    ror CP_diff
    bbr6 my_bit_register, @skip_bit6
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1
@skip_bit6:
    clc
    ror CP_diff+1
    ror CP_diff
    bbr5 my_bit_register, @skip_bit5
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1
@skip_bit5:
    clc
    ror CP_diff+1
    ror CP_diff
    bbr4 my_bit_register, @skip_bit4
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1
@skip_bit4:
    clc
    ror CP_diff+1
    ror CP_diff
    bbr3 my_bit_register, @skip_bit3
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1
@skip_bit3:
    clc
    ror CP_diff+1
    ror CP_diff
    bbr2 my_bit_register, @skip_bit2
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1
@skip_bit2:
    clc
    ror CP_diff+1
    ror CP_diff
    bbr1 my_bit_register, @skip_bit1
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1
@skip_bit1:
    clc
    ror CP_diff+1
    ror CP_diff
    bbr0 my_bit_register, @skip_bit0
    clc
    lda CP_diff
    adc cf_output
    sta cf_output
    lda CP_diff+1
    adc cf_output+1
    sta cf_output+1 ; 42 * 8 cycles = 336 cycles
    ; total 418 cycles + page crossings = 53 us
@skip_bit0:
.endmacro



.endif