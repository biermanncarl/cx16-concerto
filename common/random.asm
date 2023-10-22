; Copyright 2023 Carl Georg Biermann

; A decent(ish) pseudo random number generator intended for testing purposes.
; For that reason, focus was put on simplicity of implementation and
; a long period.

; Seeding makes tests reproducible.
; We use a 24 bit LFSR (linear feedback shift register)

.ifndef COMMON_RANDOM_ASM
COMMON_RANDOM_ASM = 1

.scope rng
    ; We treat the state as follows:
    ; The high bit of the first byte is the "entrance" where new bits are pushed in.
    ; The low bit of the last byte is the "exit" where bits are pushed out.
    state:
        .res 3
    scratchpad_bit:
        .res 1
    scratchpad_byte:
        .res 1

    .macro RNG_SEED s1, s2, s3
        lda #s1
        ldx #s2
        ldy #s3
        jsr rng::seed
    .endmacro

    ; seeds the RNG with the contents of .A, .X and .Y
    .proc seed
        ; TODO: consider XORing a constant random sequence of bits to "initiate" randomness (otherwise, the first 24 random bits will just reproduce the seed)
        sta state
        stx state+1
        sty state+2
        rts
    .endproc

    ; Maximum period LFSR polynomial for 24 bits with the taps 111000010000000000000000  (but mirrored left<->right)
    ; https://en.wikipedia.org/wiki/Linear-feedback_shift_register#Example_polynomials_for_maximal_LFSRs
    ; Random bit is returned in carry.
    ; Preserves .X and .Y
    .proc random_bit
        ; we use the lowest bit of scratchpad as the accumulator for our XOR operations
        lda state+2
        ; store bit 23 (the last bit)
        sta scratchpad_bit
        ; accumulate bit 16
        bpl :+
        inc scratchpad_bit
    :   ; accumulate bit 22
        lsr
        bcc :+
        inc scratchpad_bit
    :   ; accumulate bit 21
        lsr
        bcc :+
        inc scratchpad_bit
    :   ; read out the bit
        lda scratchpad_bit
        lsr ; accumulated bit is now in carry
        ; stick it into the shift register
        ror state
        ror state+1
        ror state+2
        ; final output bit is in carry
        rts
    .endproc

    ; Random byte is returned in .A
    ; preserves .Y
    .proc random_byte
        stz scratchpad_byte
        ldx #8
    @loop:
        jsr random_bit
        ror scratchpad_byte
        dex
        bne @loop
        lda scratchpad_byte
        rts
    .endproc
.endscope

.endif ; .ifndef COMMON_RANDOM_ASM
