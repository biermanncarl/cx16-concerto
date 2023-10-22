; Copyright 2023 Carl Georg Biermann

; * https://medium.com/unitychain/provable-randomness-how-to-test-rngs-55ac6726c5a3
;   * the "Testing for runs" sounds like a good and easy test!
;   * what is expected? For N random bits, the average number of "runs" (contiguous number of same bits) is (N+1)/2. I proved it.


.code
    jmp start

.include "../../testing/testing.asm"
.include "../random.asm"

; how many random bits to be generated
number_of_iterations = 4096

expected_avg_runs = (number_of_iterations + 1) / 2
shot_noise = 45 ; square root of 2048, expected average number of runs

runs_counter:
    .word $0001 ; we implicitly count the first run
loop_counter: 
    .word number_of_iterations-1 ; we generate the first bit manually
previous_bit:
    .byte 0

start:
    START_TEST

    RNG_SEED 42, 43, 44

; generate the first bit
    jsr rng::random_bit
    rol ; push it into bit 0 of .A
    and #%00000001
    sta previous_bit

@generator_loop:
    jsr rng::random_bit
    rol ; push it into bit 0 of .A
    and #%00000001
    pha
    eor previous_bit
    beq :+
    inc runs_counter
    bne :+
    inc runs_counter+1
:   pla
    sta previous_bit

    lda loop_counter
    sec
    sbc #1
    sta loop_counter
    lda loop_counter+1
    sbc #0
    sta loop_counter+1
    bcs @generator_loop

    ; check the result
    ldx runs_counter+1
    lda runs_counter
    EXPECT_GE_16 (expected_avg_runs - 2 * shot_noise)
    EXPECT_LE_16 (expected_avg_runs + 2 * shot_noise)

    FINISH_TEST
    rts
