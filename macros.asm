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

; not working yet
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

    ;txa
    ;clc
    ;adc #192    ; activate channels LR
    ;sta VERA_data0
.endmacro